import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '/model/expert_model.dart';
import '/model/booking_model.dart';
import '/view/screens/counselling/expert_app_theme.dart';

class CallScreen extends StatefulWidget {
  final Expert expert;
  final Booking booking;

  const CallScreen({
    super.key,
    required this.expert,
    required this.booking,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isConnecting = true;
  final JitsiMeet _jitsi = JitsiMeet();

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    final isVideo = widget.booking.sessionType == SessionType.video;
    final roomId =
        'SupportHive_${widget.expert.id}_${widget.booking.id}'
            .replaceAll(' ', '_');

    final options = JitsiMeetConferenceOptions(
      room: roomId,
      serverURL: 'https://meet.jit.si',
      userInfo: JitsiMeetUserInfo(
        displayName: 'User',
        email: '',
      ),
      featureFlags: {
        FeatureFlags.welcomePageEnabled: false,
        FeatureFlags.calenderEnabled: false,   // ← fixed typo (calender → calendar)
        FeatureFlags.callIntegrationEnabled: false,
        if (!isVideo) FeatureFlags.videoMuteEnabled: false,
      },
      configOverrides: {
        'startWithVideoMuted': !isVideo,
        'startWithAudioMuted': false,
        'disableDeepLinking': true,
        'prejoinPageEnabled': false,
      },
    );

    final listener = JitsiMeetEventListener(
      conferenceJoined: (url) => setState(() => _isConnecting = false),
      conferenceTerminated: (url, error) {
        if (mounted) Navigator.pop(context);
      },
      conferenceWillJoin: (url) {},
    );

    await _jitsi.join(options, listener);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnecting) return const SizedBox.shrink();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.booking.sessionType == SessionType.video
                        ? Icons.videocam_rounded
                        : Icons.phone_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.booking.sessionType == SessionType.video
                      ? 'Starting Video Call'
                      : 'Starting Audio Call',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connecting to ${widget.expert.name}…',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}