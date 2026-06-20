import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supporthive1/view/screens/counselling/expert_app_theme.dart';
import '/model/expert_model.dart';

/// Chat between current user and an expert.
/// Messages are stored at:
///   chats/{chatId}/messages/{messageId}
/// where chatId = "uid_expertId" (alphabetically sorted for consistency)
class ExpertChatScreen extends StatefulWidget {
  final Expert expert;
  const ExpertChatScreen({super.key, required this.expert});

  @override
  State<ExpertChatScreen> createState() => _ExpertChatScreenState();
}

class _ExpertChatScreenState extends State<ExpertChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String _chatId;
  late String _uid;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser?.uid ?? '';
    // Deterministic chat ID — same regardless of who opens it
    final ids = [_uid, widget.expert.id]..sort();
    _chatId = ids.join('_');
    _initChat();
  }

  // Create chat document if it doesn't exist yet
  Future<void> _initChat() async {
    final ref = _db.collection('chats').doc(_chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'expertId': widget.expert.id,
        'expertName': widget.expert.name,
        'userId': _uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) setState(() => _initialized = true);
  }

  CollectionReference<Map<String, dynamic>> get _messagesCol =>
      _db.collection('chats').doc(_chatId).collection('messages');

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();

    final user = _auth.currentUser;
    await _messagesCol.add({
      'text': text,
      'senderId': _uid,
      'senderName': user?.displayName ?? 'You',
      'isFromExpert': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update last message on chat doc
    await _db.collection('chats').doc(_chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // Scroll to bottom
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

  Color get _avatarColor {
    if (widget.expert.avatarColor != null) {
      try {
        return Color(
            int.parse(widget.expert.avatarColor!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return AppTheme.primary;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFreeBanner(),
          Expanded(child: _buildMessageList()),
          _buildInput(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            size: 18, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _avatarColor,
            child: Text(widget.expert.avatarInitials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.expert.name,
                  style: AppTheme.titleSm.copyWith(fontSize: 14)),
              Row(
                children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppTheme.available, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Online',
                      style:
                          TextStyle(fontSize: 11, color: AppTheme.available)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('FREE',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildFreeBanner() {
    return Container(
      color: AppTheme.accent.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🎉 You have 30 minutes of FREE chat with ${widget.expert.name}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (!_initialized) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesCol
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final docs = snap.data?.docs ?? [];

        // Auto scroll on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients && docs.isNotEmpty) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 56,
                    color: AppTheme.primary.withOpacity(0.25)),
                const SizedBox(height: 12),
                Text('Start the conversation!',
                    style: AppTheme.bodySm
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildBubble(docs[i].data()),
        );
      },
    );
  }

  Widget _buildBubble(Map<String, dynamic> data) {
    final isMe = (data['senderId'] ?? '') == _uid;
    final text = data['text'] ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final time = ts?.toDate() ?? DateTime.now();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Show sender name for expert messages
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  data['senderName'] ?? widget.expert.name,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _avatarColor),
                ),
              ),
            Text(text,
                style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.4)),
            const SizedBox(height: 4),
            Text(_formatTime(time),
                style: TextStyle(
                    fontSize: 9,
                    color: isMe ? Colors.white54 : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
