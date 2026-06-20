import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../../model/intern_model.dart';

class InternCallScreen extends StatefulWidget {
  final Intern intern;

  const InternCallScreen({super.key, required this.intern});

  @override
  State<InternCallScreen> createState() => _InternCallScreenState();
}

class _InternCallScreenState extends State<InternCallScreen> {
  bool _isConnecting = true;
  final JitsiMeet _jitsi = JitsiMeet();

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    final roomId =
        'SupportHive_Intern_${widget.intern.name}'.replaceAll(' ', '_');

    final options = JitsiMeetConferenceOptions(
      room: roomId,
      serverURL: 'https://meet.jit.si',
      userInfo: JitsiMeetUserInfo(displayName: 'User'),
      featureFlags: {
        FeatureFlags.welcomePageEnabled: false,
        FeatureFlags.calenderEnabled: false,
      },
      configOverrides: {
        'startWithVideoMuted': true,
        'startWithAudioMuted': false,
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                  child: const Icon(Icons.phone_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 24),
                const Text('Starting Call',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Connecting to ${widget.intern.name}…',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}