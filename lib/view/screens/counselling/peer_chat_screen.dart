// ─────────────────────────────────────────────────────────────────────────────
// view/screens/peer_chat_screen.dart
//
// Works for BOTH sides:
//   • Initiator (User A): passes peer + myUserId, existingRoomId = null
//     → calls ctrl.initRoom() which creates the Firestore doc
//   • Receiver  (User B): passes peer + myUserId + existingRoomId
//     → calls ctrl.acceptRoom() which skips creation, uses existing doc
//
// Both sides end up with the same chatRoomId → same Firestore path →
// same messages sub-collection → real-time delivery works on both devices.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supporthive1/controller/peer_chat_controller.dart';
import 'package:supporthive1/model/chat_model.dart';
import 'package:supporthive1/model/peer_user_model.dart';
import 'package:supporthive1/view/widgets/peer_widgets.dart';
import 'package:supporthive1/view/screens/peer_rating_screen.dart';

class PeerChatScreen extends StatefulWidget {
  final PeerUser peer;
  final String   myUserId;
  /// If non-null, the room already exists — skip creation (receiver side).
  final String?  existingRoomId;

  const PeerChatScreen({
    super.key,
    required this.peer,
    required this.myUserId,
    this.existingRoomId,
  });

  @override
  State<PeerChatScreen> createState() => _PeerChatScreenState();
}

class _PeerChatScreenState extends State<PeerChatScreen> {
  final PeerChatController    _ctrl   = PeerChatController();
  final TextEditingController _input  = TextEditingController();
  final ScrollController      _scroll = ScrollController();

  bool   _isLoading = true;
  bool   _isSending = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _ctrl.setTyping(widget.myUserId, false);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initRoom() async {
    if (widget.existingRoomId != null) {
      // RECEIVER side: room was already created by the initiator
      _ctrl.acceptRoom(widget.existingRoomId!);
    } else {
      // INITIATOR side: create the room in Firestore (triggers receiver stream)
      await _ctrl.initRoom(widget.myUserId, widget.peer.id);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    _ctrl.markRead(widget.myUserId);
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _isSending) return;

    _input.clear();
    _typingTimer?.cancel();
    await _ctrl.setTyping(widget.myUserId, false);

    setState(() => _isSending = true);
    final sent = await _ctrl.sendMessage(
      senderId: widget.myUserId,
      text: text,
    );
    setState(() => _isSending = false);

    if (!sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '⚠️ Message blocked — please keep the conversation respectful.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    _scrollToBottom();
  }

  void _onTyping(String value) {
    _ctrl.setTyping(widget.myUserId, value.isNotEmpty);
    _typingTimer?.cancel();
    if (value.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _ctrl.setTyping(widget.myUserId, false);
      });
    }
  }

  // ── End session → rating screen ───────────────────────────────────────────
  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Conversation?'),
        content: const Text(
            'All messages will be permanently deleted for both participants. You can then rate this session.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('End & Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await _ctrl.endSession();
    final session = await _ctrl.fetchSession();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PeerRatingScreen(
          myUserId:     widget.myUserId,
          peerUsername: widget.peer.username,
          controller:   _ctrl,
          session:      session,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeerTheme.mist,
      appBar: _buildAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              const AnonymityBanner(),
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ]),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext ctx) => AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(ctx),
        ),
        title: Row(children: [
          PeerAvatar(username: widget.peer.username, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.peer.username,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                StreamBuilder<bool>(
                  stream: _ctrl.peerTypingStream(widget.peer.id),
                  builder: (_, snap) {
                    final typing = snap.data ?? false;
                    return Row(children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: PeerTheme.sage,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(
                          typing ? 'typing…' : 'Online · Anonymous',
                          style: const TextStyle(
                              fontSize: 11, color: PeerTheme.sage)),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (v) {
              if (v == 'end') _endSession();
              if (v == 'report') _showReportDialog(ctx);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'end', child: Text('End conversation')),
              const PopupMenuItem(
                  value: 'report', child: Text('Report')),
            ],
          ),
        ],
      );

  Widget _buildMessageList() => StreamBuilder<List<ChatMessage>>(
        stream: _ctrl.messagesStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final msgs = snap.data ?? [];

          // Scroll and mark-read whenever new messages arrive
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
          _ctrl.markRead(widget.myUserId);

          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
            itemCount: msgs.length + 2, // date + typing slot
            itemBuilder: (ctx, i) {
              if (i == 0) return const DateDivider();

              // Typing bubble at the very end
              if (i == msgs.length + 1) {
                return StreamBuilder<bool>(
                  stream: _ctrl.peerTypingStream(widget.peer.id),
                  builder: (_, snap) => (snap.data ?? false)
                      ? TypingBubble(username: widget.peer.username)
                      : const SizedBox.shrink(),
                );
              }

              final msg = msgs[i - 1];
              return ChatBubble(
                text:         msg.text,
                isMe:         msg.senderId == widget.myUserId,
                time:         _fmt(msg.sentAt),
                peerUsername: widget.peer.username,
                isRead:       msg.isRead,
                isBlocked:    msg.isBlocked,
              );
            },
          );
        },
      );

  Widget _buildInputBar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onTyping,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: PeerTheme.mist,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isSending
                      ? PeerTheme.seaBlue.withOpacity(0.6)
                      : PeerTheme.seaBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      );

  void _showReportDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Report User'),
        content: const Text(
            'Are you sure you want to report this user? The conversation will end and be reviewed by our team.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Report submitted. Thank you.'),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ),
              );
              Future.delayed(const Duration(seconds: 1), _endSession);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}