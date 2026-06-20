// ─────────────────────────────────────────────────────────────────────────────
// view/screens/peer_rating_screen.dart
// Shown after chat ends — displays session duration and lets user rate the peer
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../controller/peer_chat_controller.dart';
import 'package:supporthive1/model/chat_model.dart';
import '../widgets/peer_widgets.dart';

class PeerRatingScreen extends StatefulWidget {
  final String myUserId;
  final String peerUsername;
  final PeerChatController controller;
  final ChatSession? session;

  const PeerRatingScreen({
    super.key,
    required this.myUserId,
    required this.peerUsername,
    required this.controller,
    this.session,
  });

  @override
  State<PeerRatingScreen> createState() => _PeerRatingScreenState();
}

class _PeerRatingScreenState extends State<PeerRatingScreen> {
  int _selectedRating = 0;
  bool _submitted = false;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating before submitting.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    await widget.controller.submitRating(
      raterUserId: widget.myUserId,
      stars: _selectedRating,
    );
    if (!mounted) return;
    setState(() {
      _submitted = true;
      _submitting = false;
    });
  }

  void _done() {
    // Pop back to the root peer support screen
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return WillPopScope(
      onWillPop: () async {
        _done();
        return false;
      },
      child: Scaffold(
        backgroundColor: PeerTheme.mist,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
          title: const Text('Chat Ended',
              style: TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // ── Session summary card ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    PeerAvatar(
                        username: widget.peerUsername,
                        radius: 32,
                        showOnlineDot: false),
                    const SizedBox(height: 12),
                    Text(
                      'Chat with ${widget.peerUsername}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    if (session?.formattedDuration != null &&
                        session!.formattedDuration != '—')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(
                            'Duration: ${session.formattedDuration}',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: PeerTheme.sageLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🔒  All messages have been deleted for privacy',
                        style: TextStyle(
                            fontSize: 11, color: PeerTheme.sage),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Rating card ────────────────────────────────────────────
              if (!_submitted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'How was your experience?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rate your chat with ${widget.peerUsername}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      StarRating(
                        initialRating: _selectedRating,
                        onRated: (r) =>
                            setState(() => _selectedRating = r),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ratingLabel(_selectedRating),
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PeerTheme.seaBlue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : const Text('Submit Rating',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      TextButton(
                        onPressed: _done,
                        child: const Text('Skip',
                            style: TextStyle(color: Colors.black45)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // ── Thank-you state ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 56, color: PeerTheme.sage),
                      const SizedBox(height: 12),
                      const Text(
                        'Thank you for your feedback!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your rating helps improve the peer support community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _done,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PeerTheme.sage,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Done',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Great';
      case 5: return 'Excellent!';
      default: return 'Tap a star to rate';
    }
  }
}