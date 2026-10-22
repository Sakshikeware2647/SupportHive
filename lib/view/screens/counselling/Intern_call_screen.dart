// ─────────────────────────────────────────────────────────────────
// view/screens/intern/intern_call_screen.dart  (USER SIDE)
//
// Fixes applied vs the broken original:
//   • Correct imports (no 'package:dart', no bare 'package:...')
//   • All typos fixed: `pulseCtrl` → `_pulseCtrl`, `razorpay` → `_razorpay`
//     `_scrollToBottom` consistent name, `_buildRingAnimation` self-contained
//   • Jitsi join() uses correct positional listener arg (jitsi_meet_flutter_sdk ^12)
//   • StreamSubscription typed correctly
//   • Razorpay EVENT_EXTERNAL_WALLET handler is a proper closure
//   • No dangling references
// ─────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../model/call_model.dart';
import '../../../model/intern_model.dart';
import '../../../service/call_service.dart';
import '../../../service/call_usage_service.dart';
import '../../../service/fcm_service.dart';
import 'intern_theme.dart';

class InternCallScreen extends StatefulWidget {
  final Intern intern;
  const InternCallScreen({super.key, required this.intern});

  @override
  State<InternCallScreen> createState() => _InternCallScreenState();
}

class _InternCallScreenState extends State<InternCallScreen>
    with SingleTickerProviderStateMixin {

  // ── Jitsi ──────────────────────────────────────────────────────
  final JitsiMeet _jitsi = JitsiMeet();

  // ── State ──────────────────────────────────────────────────────
  _ScreenState _screenState = _ScreenState.checkingLimit;
  int _remainingCalls = 3;
  CallModel? _activeCall;
  StreamSubscription<CallModel?>? _callStatusSub;
  Timer? _callTimer;
  Timer? _ringTimer;
  int _callSeconds = 0;
  bool _remoteJoined = false;

  // ── Razorpay ───────────────────────────────────────────────────
  late Razorpay _razorpay;
  static const String _razorpayKey  = 'rzp_test_T4bcn93utqElpD';
  static const int    _callPackPrice = 99;

  // ── Animation ──────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(_pulseCtrl);

    _initRazorpay();
    _checkLimit();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  Future<void> _checkLimit() async {
    final r = await CallUsageService.remainingFreeCalls();
    if (!mounted) return;
    setState(() {
      _remainingCalls = r;
      _screenState =
          r > 0 ? _ScreenState.readyToCall : _ScreenState.limitReached;
    });
  }

  // ── STEP 1: create Firestore call doc + send FCM ───────────────
  Future<void> _startCall() async {
    final hasFree = await CallUsageService.hasFreeCalls();
    if (!hasFree) {
      setState(() => _screenState = _ScreenState.limitReached);
      return;
    }

    setState(() => _screenState = _ScreenState.ringing);

    final call = await CallService.initiateCall(widget.intern);
    if (call == null) {
      _showSnack('Could not connect. Please try again.');
      setState(() => _screenState = _ScreenState.readyToCall);
      return;
    }

    _activeCall = call;

    // Also send FCM from client side (belt-and-suspenders with Cloud Function)
    final currentUser = FirebaseAuth.instance.currentUser;
    final callerName =
        currentUser?.displayName ?? currentUser?.email ?? 'Someone';

    if (widget.intern.fcmToken.isNotEmpty) {
      await FCMService.sendCallNotification(
        internFcmToken: widget.intern.fcmToken,
        callId        : call.callId,
        channelName   : call.channelName,
        callerName    : callerName,
        internName    : widget.intern.name,
      );
    } else {
      _showSnack('⚠️ Intern may be offline. Waiting…');
    }

    // Auto-cancel after 45 s if intern doesn't respond
    _ringTimer = Timer(const Duration(seconds: 45), () {
      if (_screenState == _ScreenState.ringing) {
        _cancelRinging(missed: true);
      }
    });

    // STEP 2: watch Firestore for intern's response
    _callStatusSub =
        CallService.watchCallStatus(call.callId).listen(_onCallStatusChanged);
  }

  // ── STEP 2: react to intern accepting / declining ──────────────
  void _onCallStatusChanged(CallModel? updated) async {
    if (updated == null) return;

    if (updated.status == CallStatus.accepted) {
      _ringTimer?.cancel();
      await _joinJitsiCall(updated.channelName);
    }

    if (updated.status == CallStatus.declined) {
      _ringTimer?.cancel();
      _callStatusSub?.cancel();
      if (_activeCall != null) {
        await CallUsageService.refundCall();
      }
      if (mounted) {
        _showSnack('${widget.intern.name} is unavailable right now.');
        setState(() => _screenState = _ScreenState.readyToCall);
      }
    }

    if (updated.status == CallStatus.ended) {
      await _endCall();
    }
  }

  // ── STEP 3: join Jitsi audio-only room ────────────────────────
  Future<void> _joinJitsiCall(String channelName) async {
    if (!mounted) return;
    setState(() => _screenState = _ScreenState.connecting);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final displayName =
          currentUser?.displayName ?? currentUser?.email ?? 'User';

      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: channelName,
        userInfo: JitsiMeetUserInfo(
          displayName: displayName,
          email: currentUser?.email ?? '',
        ),
        configOverrides: {
          'startWithAudioMuted'     : false,
          'startWithVideoMuted'     : true,
          'startAudioOnly'          : true,
          'disableVideoMuteButton'  : true,
          'disableFilmstripAutohiding': true,
          'toolbarButtons'          : ['microphone', 'hangup'],
        },
        featureFlags: {
          'video-mute.enabled'             : false,
          'welcomepage.enabled'            : false,
          'unsaferoomwarning.enabled'      : false,
          'prejoinpage.enabled'            : false,
          'invite.enabled'                 : false,
          'chat.enabled'                   : false,
          'recording.enabled'              : false,
          'live-streaming.enabled'         : false,
          'pip.enabled'                    : false,
          'kick-out.enabled'               : false,
          'ios.screensharing.enabled'      : false,
          'android.screensharing.enabled'  : false,
        },
      );

      // ✅ Correct jitsi_meet_flutter_sdk ^12 API:
      //    join(options, listener) — listener is a positional arg, NOT named.
      await _jitsi.join(
        options,
        JitsiMeetEventListener(
          conferenceJoined: (url) {
            if (!mounted) return;
            setState(() {
              _screenState = _ScreenState.inCall;
              _callSeconds = 0;
            });
            _callTimer = Timer.periodic(
              const Duration(seconds: 1),
              (_) { if (mounted) setState(() => _callSeconds++); },
            );
          },
          participantJoined: (email, name, role, id) {
            if (mounted) setState(() => _remoteJoined = true);
          },
          participantLeft: (id) {
            if (_remoteJoined) _endCall();
          },
          conferenceTerminated: (url, error) {
            _endCall();
          },
        ),
      );
    } catch (e) {
      _showSnack('Could not start audio call: $e');
      if (mounted) setState(() => _screenState = _ScreenState.readyToCall);
    }
  }

  // ── STEP 4: end the call ───────────────────────────────────────
  Future<void> _endCall() async {
    _callTimer?.cancel();
    _ringTimer?.cancel();
    _callStatusSub?.cancel();

    try { await _jitsi.hangUp(); } catch (_) {}

    if (_activeCall != null) {
      await CallService.endCall(_activeCall!.callId);
    }

    // Refresh remaining count
    final r = await CallUsageService.remainingFreeCalls();
    if (mounted) {
      setState(() {
        _remainingCalls = r;
        _screenState = _ScreenState.callEnded;
      });
    }
  }

  Future<void> _cancelRinging({bool missed = false}) async {
    _ringTimer?.cancel();
    _callStatusSub?.cancel();
    if (_activeCall != null) {
      await CallService.endCall(_activeCall!.callId, missed: missed);
      await CallUsageService.refundCall();
    }
    final r = await CallUsageService.remainingFreeCalls();
    if (mounted) {
      setState(() {
        _remainingCalls = r;
        _screenState = _ScreenState.readyToCall;
      });
      if (missed) _showSnack('No answer from ${widget.intern.name}.');
    }
  }

  // ── Razorpay ───────────────────────────────────────────────────
  void _openRazorpay() {
    _razorpay.open(<String, dynamic>{
      'key'        : _razorpayKey,
      'amount'     : _callPackPrice * 100,
      'name'       : 'SupportHive',
      'description': '5 Intern Audio Call Pack',
      'currency'   : 'INR',
      'prefill'    : {'contact': '9999999999', 'email': 'user@supporthive.com'},
      'theme'      : {'color': '#0A9E8A'},
      'modal'      : {'confirm_close': true},
    });
  }

  void _onPaySuccess(PaymentSuccessResponse r) async {
    await CallUsageService.resetAfterPayment();
    final remaining = await CallUsageService.remainingFreeCalls();
    if (!mounted) return;
    setState(() {
      _remainingCalls = remaining;
      _screenState    = _ScreenState.readyToCall;
    });
    _showSnack('✅ Payment done! You have $remaining calls now.');
  }

  void _onPayError(PaymentFailureResponse r) =>
      _showSnack('Payment failed: ${r.message}');

  void _onExternalWallet(ExternalWalletResponse r) {}

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String get _formattedTime {
    final m = _callSeconds ~/ 60;
    final s = _callSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _ringTimer?.cancel();
    _callStatusSub?.cancel();
    _pulseCtrl.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _screenState != _ScreenState.inCall &&
              _screenState != _ScreenState.connecting &&
              _screenState != _ScreenState.ringing,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          if (_screenState == _ScreenState.ringing) {
            await _cancelRinging();
          } else {
            await _endCall();
          }
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: InternTheme.headerGradient),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (_screenState) {
                _ScreenState.checkingLimit => _buildLoader(const ValueKey('l')),
                _ScreenState.readyToCall  => _buildReady(const ValueKey('r')),
                _ScreenState.ringing      => _buildRinging(const ValueKey('ri')),
                _ScreenState.connecting   => _buildConnecting(const ValueKey('c')),
                _ScreenState.inCall       => _buildInCall(const ValueKey('ic')),
                _ScreenState.callEnded    => _buildEnded(const ValueKey('e')),
                _ScreenState.limitReached => _buildPaywall(const ValueKey('p')),
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Screens ────────────────────────────────────────────────────

  Widget _buildLoader(Key key) => Center(
        key: key,
        child: const CircularProgressIndicator(color: Colors.white),
      );

  Widget _buildReady(Key key) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(scale: _pulseAnim, child: _avatar(100)),
            const SizedBox(height: 28),
            _name(),
            _spec(),
            const SizedBox(height: 28),
            _badge('$_remainingCalls free ${_remainingCalls == 1 ? 'call' : 'calls'} remaining'),
            _badge('🎤 Audio only · private & secure'),
            const SizedBox(height: 44),
            _greenBtn(_startCall),
            const SizedBox(height: 20),
            _backBtn(),
          ],
        ),
      );

  Widget _buildRinging(Key key) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(scale: _pulseAnim, child: _avatar(90)),
            const SizedBox(height: 24),
            _name(),
            const SizedBox(height: 10),
            Text('Calling…',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 16)),
            const SizedBox(height: 6),
            Text('Waiting for ${widget.intern.name} to accept',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 40),
            _buildRingAnimation(),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => _cancelRinging(),
              child: Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  color: InternTheme.danger,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: InternTheme.danger.withOpacity(0.4),
                        blurRadius: 20)
                  ],
                ),
                child: const Icon(Icons.call_end_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Tap to cancel',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );

  Widget _buildRingAnimation() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        return SizedBox(
          width: 60, height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Transform.scale(
                  scale: 0.5 +
                      (_pulseCtrl.value + i * 0.33).clamp(0.0, 1.0) * 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(
                            (1 - (_pulseCtrl.value + i * 0.33)
                                    .clamp(0.0, 1.0)) *
                                0.6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              const Icon(Icons.phone_rounded,
                  color: Colors.white, size: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnecting(Key key) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _avatar(90),
            const SizedBox(height: 24),
            _name(),
            const SizedBox(height: 10),
            Text('Connecting audio…',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 14)),
            const SizedBox(height: 8),
            Text('Joining Jitsi secure room…',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          ],
        ),
      );

  Widget _buildInCall(Key key) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(alignment: Alignment.center, children: [
              if (_remoteJoined)
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                  ),
                ),
              _avatar(90),
            ]),
            const SizedBox(height: 20),
            _name(),
            const SizedBox(height: 6),
            Text(
              _remoteJoined ? _formattedTime : 'Waiting for intern to join…',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: _remoteJoined ? 22 : 13,
                fontWeight:
                    _remoteJoined ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🎤 Audio Only · Jitsi Secure',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: InternTheme.danger,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: InternTheme.danger.withOpacity(0.45),
                        blurRadius: 22)
                  ],
                ),
                child: const Icon(Icons.call_end_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Tap to end call',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            Text('Audio controls are in the Jitsi toolbar',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ],
        ),
      );

  Widget _buildEnded(Key key) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            const Text('Call Ended',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Duration: $_formattedTime',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 10),
            Text('$_remainingCalls free calls remaining',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: InternTheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  Widget _buildPaywall(Key key) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 24),
            const Text('Free calls used up',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              "You've used all $_remainingCalls free calls.\nUnlock more with a small top-up.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Column(children: [
                const Text('CALL PACK',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const Text('₹99',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        height: 1)),
                const SizedBox(height: 6),
                Text('5 audio call sessions',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: InternTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _openRazorpay,
                child: const Text('Pay ₹99 with Razorpay',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe later',
                  style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      );

  // ── Reusable sub-widgets ───────────────────────────────────────

  Widget _avatar(double size) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: Center(
          child: Text(
            widget.intern.avatarInitials,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.33),
          ),
        ),
      );

  Widget _name() => Text(widget.intern.name,
      style: const TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800));

  Widget _spec() => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(widget.intern.specialization,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 13)),
      );

  Widget _badge(String label) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _greenBtn(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.45),
                  blurRadius: 26,
                  spreadRadius: 3)
            ],
          ),
          child: const Icon(Icons.phone_rounded,
              color: Colors.white, size: 32),
        ),
      );

  Widget _backBtn() => TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Back',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
      );
}

enum _ScreenState {
  checkingLimit,
  readyToCall,
  ringing,
  connecting,
  inCall,
  callEnded,
  limitReached,
}