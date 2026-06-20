// ─────────────────────────────────────────────────────────────────────────────
// view/screens/peer_support_screen.dart
//
// KEY FIX: after initUser() succeeds, this screen subscribes to
// PeerChatController.incomingChatStream(myId).
// When User A creates a chat room with User B, Firestore emits the new room
// document → this stream fires → User B is auto-navigated into PeerChatScreen
// with the correct chatRoomId already set via ctrl.acceptRoom().
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supporthive1/controller/peer_controller.dart';
import 'package:supporthive1/controller/peer_chat_controller.dart';
import 'package:supporthive1/model/peer_user_model.dart';
import 'package:supporthive1/view/widgets/peer_widgets.dart';
import 'peer_list_screen.dart';
import 'peer_chat_screen.dart';

class PeerSupportScreen extends StatefulWidget {
  const PeerSupportScreen({super.key});

  @override
  State<PeerSupportScreen> createState() => _PeerSupportScreenState();
}

class _PeerSupportScreenState extends State<PeerSupportScreen> {
  final TextEditingController _textController = TextEditingController();
  final PeerController        _peerController = PeerController();
  // Each incoming chat gets its own controller so the room state is isolated
  PeerChatController?         _incomingCtrl;

  bool _isAvailable    = false;
  bool _isFinding      = false;
  bool _isInitialising = true;
  bool _navigating     = false; // guard: prevent duplicate push

  StreamSubscription<Map<String, dynamic>?>? _incomingSub;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    await _peerController.initUser();
    if (!mounted) return;
    setState(() => _isInitialising = false);
    _subscribeToIncomingChats();
  }

  // ── Subscribe to incoming chats ───────────────────────────────────────────
  // This is what makes the RECEIVER side work.
  // As long as User B is on PeerSupportScreen (i.e. available), Firestore
  // is being watched for any chat room where B is a participant but not the
  // initiator. The moment User A creates a room, this fires.
  void _subscribeToIncomingChats() {
    final myId = _peerController.currentUser.id;
    final tempCtrl = PeerChatController();

    _incomingSub = tempCtrl
        .incomingChatStream(myId)
        .listen((incoming) async {
      if (incoming == null || !mounted || _navigating) return;

      final chatRoomId   = incoming['chatRoomId']  as String;
      final initiatorId  = incoming['initiatorId'] as String;

      // Already navigated into this room — skip duplicate events
      if (_incomingCtrl?.chatRoomId == chatRoomId) return;

      _navigating = true;

      // Wire up the controller with the existing Firestore room
      _incomingCtrl = PeerChatController()..acceptRoom(chatRoomId);

      // Build a minimal PeerUser for the initiator (only id matters for the
      // chat room; the username comes from the peers collection but we can
      // fetch it or just show a placeholder — the chat still works either way)
      final initiatorUser = await _fetchPeerUser(initiatorId);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PeerChatScreen(
            peer:            initiatorUser,
            myUserId:        myId,
            existingRoomId:  chatRoomId,   // ← tells the screen NOT to create a new room
          ),
        ),
      );

      // After the chat screen is popped, reset so a new chat can come in
      _navigating    = false;
      _incomingCtrl  = null;
    });
  }

  // Fetch peer user document from Firestore so we can show their username
  Future<PeerUser> _fetchPeerUser(String uid) async {
    final peers = await _peerController.peersStream().first;
    final match = peers.where((p) => p.id == uid).toList();
    if (match.isNotEmpty) return match.first;
    // Fallback: construct from uid suffix if not found in available list
    final suffix = uid.length >= 4 ? uid.substring(uid.length - 4) : uid;
    return PeerUser(id: uid, username: '@user_$suffix', isAvailable: true);
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    _textController.dispose();
    _peerController.goOffline();
    super.dispose();
  }

  // ── Find peer support ──────────────────────────────────────────────────────
  Future<void> _findPeerSupport() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please describe how you are feeling first.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isFinding = true);
    await _peerController.findPeers();
    if (!mounted) return;
    setState(() => _isFinding = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeerListScreen(
          peers:       _peerController.availablePeers,
          myUserId:    _peerController.currentUser.id,
          peersStream: _peerController.peersStream(),
        ),
      ),
    );
  }

  // ── Toggle availability ────────────────────────────────────────────────────
  Future<void> _toggleAvailability(bool val) async {
    setState(() => _isAvailable = val);
    await _peerController.toggleAvailability(val);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(val
            ? 'You are now available to help others'
            : 'You are now unavailable'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: val ? PeerTheme.sage : Colors.grey.shade700,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isInitialising) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: PeerTheme.mist,
      appBar: AppBar(
        title: const Text('Peer Support',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildToggleCard(),
            const SizedBox(height: 16),
            _buildAnonymousCard(),
            const SizedBox(height: 16),
            _buildRequestCard(),
            const SizedBox(height: 16),
            _buildGuidelines(),
            const SizedBox(height: 16),
            _buildHowItWorks(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peer Support',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Connect with understanding peers',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ]),
      );

  Widget _buildToggleCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardStyle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAvailable
                        ? 'Available for Peer Support'
                        : 'Currently Unavailable',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isAvailable
                          ? PeerTheme.sage
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Toggle to help others in need',
                      style:
                          TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            Switch(
              value: _isAvailable,
              onChanged: _toggleAvailability,
              activeColor: PeerTheme.sage,
            ),
          ],
        ),
      );

  Widget _buildAnonymousCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardStyle(),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PeerTheme.sage.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined,
                color: PeerTheme.sage, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('100% Anonymous Support',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                    'Only usernames are visible. No personal data is stored.',
                    style:
                        TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
        ]),
      );

  Widget _buildRequestCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardStyle(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Peer Support',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "I'm feeling anxious about…",
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: PeerTheme.mist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: PeerTheme.sage, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isFinding ? null : _findPeerSupport,
                icon: _isFinding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, color: Colors.white),
                label: Text(
                  _isFinding ? 'Finding peers…' : 'Find Peer Support',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PeerTheme.seaBlue,
                  disabledBackgroundColor:
                      PeerTheme.seaBlue.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildGuidelines() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardStyle(borderColor: Colors.orange.shade200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.gavel_outlined,
                  color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              const Text('Community Guidelines',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            const GuidelineTile('Be kind and respectful at all times'),
            const GuidelineTile('Keep all conversations confidential'),
            const GuidelineTile('Do not share any personal information'),
            const GuidelineTile('No inappropriate or harmful language'),
          ],
        ),
      );

  Widget _buildHowItWorks() {
    final steps = [
      'Share how you are feeling in the text box above',
      'Available anonymous peers will appear',
      'Start a private chat — messages clear after the session',
      'Rate your experience when the chat ends',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How It Works',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                            color: PeerTheme.seaBlue,
                            shape: BoxShape.circle),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87)),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  BoxDecoration _cardStyle({Color borderColor = Colors.transparent}) =>
      BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      );
}