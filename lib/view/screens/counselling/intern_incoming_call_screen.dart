// ─────────────────────────────────────────────────────────────────
// view/screens/intern/intern_incoming_call_screen.dart  (INTERN SIDE)
//
// Fixes vs broken original:
//   • Correct imports
//   • `_jitsi.hangUp()` reference was `jitsi.hangUp()` (missing underscore)
//   • Jitsi join() listener is positional arg (not named)
// ─────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import '../../../model/call_model.dart';
import '../../../service/call_service.dart';
import 'intern_theme.dart';

class InternIncomingCallScreen extends StatefulWidget {
  final CallModel call;
  const InternIncomingCallScreen({super.key, required this.call});

  @override
  State<InternIncomingCallScreen> createState() =>
      _InternIncomingCallScreenState();
}

class _InternIncomingCallScreenState extends State<InternIncomingCallScreen>
    with SingleTickerProviderStateMixin {

  final JitsiMeet _jitsi = JitsiMeet();
  _CallState _callState = _CallState.ringing;
  Timer? _callTimer;
  int _callSeconds = 0;
  bool _remoteJoined = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.92, end: 1.08).animate(_pulseCtrl);
  }

  // ── Accept ─────────────────────────────────────────────────────
  Future<void> _acceptCall() async {
    setState(() => _callState = _CallState.connecting);
    await CallService.acceptCall(widget.call.callId);
    await _joinJitsiCall();
  }

  // ── Decline ────────────────────────────────────────────────────
  Future<void> _declineCall() async {
    await CallService.declineCall(widget.call.callId);
    if (mounted) Navigator.pop(context);
  }

  // ── Join Jitsi (audio only) ────────────────────────────────────
  Future<void> _joinJitsiCall() async {
    try {
      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: widget.call.channelName,
        userInfo: JitsiMeetUserInfo(
          displayName: widget.call.internName,
        ),
        configOverrides: {
          'startWithAudioMuted'   : false,
          'startWithVideoMuted'   : true,
          'startAudioOnly'        : true,
          'disableVideoMuteButton': true,
          'toolbarButtons'        : ['microphone', 'hangup'],
        },
        featureFlags: {
          'video-mute.enabled'           : false,
          'welcomepage.enabled'          : false,
          'unsaferoomwarning.enabled'    : false,
          'prejoinpage.enabled'          : false,
          'invite.enabled'               : false,
          'chat.enabled'                 : false,
          'recording.enabled'            : false,
          'live-streaming.enabled'       : false,
          'pip.enabled'                  : false,
          'kick-out.enabled'             : false,
          'ios.screensharing.enabled'    : false,
          'android.screensharing.enabled': false,
        },
      );

      // ✅ Correct jitsi_meet_flutter_sdk ^12 API
      await _jitsi.join(
        options,
        JitsiMeetEventListener(
          conferenceJoined: (url) {
            if (!mounted) return;
            setState(() => _callState = _CallState.inCall);
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
      _showSnack('Could not join call: $e');
      if (mounted) setState(() => _callState = _CallState.ringing);
    }
  }

  // ── End call ───────────────────────────────────────────────────
  Future<void> _endCall() async {
    _callTimer?.cancel();
    try { await _jitsi.hangUp(); } catch (_) {}
    await CallService.endCall(widget.call.callId);
    if (mounted) setState(() => _callState = _CallState.ended);
  }

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
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: InternTheme.headerGradient),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (_callState) {
              _CallState.ringing    => _buildRinging(const ValueKey('r')),
              _CallState.connecting => _buildConnecting(const ValueKey('c')),
              _CallState.inCall     => _buildInCall(const ValueKey('i')),
              _CallState.ended      => _buildEnded(const ValueKey('e')),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRinging(Key key) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(scale: _pulseAnim, child: _callerAvatar(100)),
            const SizedBox(height: 28),
            Text(widget.call.userDisplayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Incoming Audio Call',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 15)),
            const SizedBox(height: 56),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callActionBtn(
                  icon: Icons.call_end_rounded,
                  color: InternTheme.danger,
                  label: 'Decline',
                  onTap: _declineCall,
                ),
                _callActionBtn(
                  icon: Icons.phone_rounded,
                  color: const Color(0xFF22C55E),
                  label: 'Accept',
                  onTap: _acceptCall,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildConnecting(Key key) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _callerAvatar(90),
            const SizedBox(height: 24),
            Text(widget.call.userDisplayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('Connecting audio…',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14)),
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
              _callerAvatar(90),
            ]),
            const SizedBox(height: 20),
            Text(widget.call.userDisplayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(_formattedTime,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _callActionBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 18)
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
      const SizedBox(height: 10),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]);
  }

  Widget _callerAvatar(double size) {
    final initials = widget.call.userDisplayName
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();
    return Container(
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
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.33)),
      ),
    );
  }
}

enum _CallState { ringing, connecting, inCall, ended }