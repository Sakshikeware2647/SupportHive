// ─────────────────────────────────────────────────────────────────
// view/screens/intern/intern_chat_screen.dart
//
// Fixes vs broken original:
//   • Correct imports
//   • `_scrollToBottom` renamed consistently (was `scrollToBottom`)
//   • `_controller` used consistently (was `controller` in one place)
//   • `onSubmitted` signature corrected: (String) not ()
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../model/intern_model.dart';
import 'intern_theme.dart';

class InternChatScreen extends StatefulWidget {
  final Intern intern;
  const InternChatScreen({super.key, required this.intern});

  @override
  State<InternChatScreen> createState() => _InternChatScreenState();
}

class _InternChatScreenState extends State<InternChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  static const List<String> _blockedWords = [
    'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'damn', 'crap',
    'idiot', 'stupid', 'moron', 'hell', 'cunt', 'dick', 'ass',
  ];

  bool _containsVulgarWords(String text) {
    final lower = text.toLowerCase();
    return _blockedWords.any((w) => lower.contains(w));
  }

  static const String _adminEmail = 'admin@supporthive.com';

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_containsVulgarWords(text)) {
      _showBanner('Please keep the conversation respectful 🙏');
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isMe: true));
      _controller.clear();
      _sending = true;
    });

    _scrollToBottom();

    final subject = Uri.encodeComponent(
        'SupportHive Chat | User → ${widget.intern.name}');
    final body = Uri.encodeComponent(
        'Message for ${widget.intern.name} (${widget.intern.email}):\n\n$text');
    final mailUri = Uri.parse('mailto:$_adminEmail?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
        setState(() {
          _messages.add(_ChatMessage(
            text:
                '✅ Your message has been sent to ${widget.intern.name}. They will reply shortly.',
            isMe: false,
            isSystem: true,
          ));
        });
      } else {
        _showBanner('Could not open mail app. Please try again.');
      }
    } catch (_) {
      _showBanner('Failed to send. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _showBanner(String msg) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(msg,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: InternTheme.danger,
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child:
                const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 3),
        () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner());
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

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InternTheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _Avatar(intern: widget.intern, size: 34),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.intern.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: InternTheme.textDark)),
              Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: widget.intern.isAvailable
                        ? InternTheme.available
                        : InternTheme.unavailable,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.intern.isAvailable ? 'Available' : 'Away',
                  style: TextStyle(
                      fontSize: 11,
                      color: widget.intern.isAvailable
                          ? InternTheme.available
                          : InternTheme.textLight),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: InternTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InternTheme.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded,
            size: 16, color: InternTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Messages are relayed via email. Responses may take a few hours.',
            style: TextStyle(
                fontSize: 11.5,
                color: InternTheme.primary,
                fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: InternTheme.textLight),
            const SizedBox(height: 12),
            Text('Send a message to get started',
                style: TextStyle(
                    color: InternTheme.textLight, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: InternTheme.available.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg.text,
            style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF166534),
                fontWeight: FontWeight.w500)),
      );
    }

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: msg.isMe ? InternTheme.headerGradient : null,
          color: msg.isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(msg.text,
            style: TextStyle(
                fontSize: 14,
                color: msg.isMe ? Colors.white : InternTheme.textDark,
                height: 1.4)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: InternTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: InternTheme.primary.withOpacity(0.15)),
            ),
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(
                  fontSize: 14, color: InternTheme.textDark),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(
                    color: InternTheme.textLight, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              // onSubmitted requires (String) signature
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sending ? null : _sendMessage,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: _sending ? null : InternTheme.headerGradient,
              color: _sending ? InternTheme.textLight : null,
              shape: BoxShape.circle,
            ),
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isMe;
  final bool isSystem;

  _ChatMessage({
    required this.text,
    required this.isMe,
    this.isSystem = false,
  });
}

// ── Reusable avatar ────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Intern intern;
  final double size;
  const _Avatar({required this.intern, this.size = 44});

  static const List<List<Color>> _palettes = [
    [Color(0xFF0A9E8A), Color(0xFF38EF7D)],
    [Color(0xFF7C3AED), Color(0xFFC4B5FD)],
    [Color(0xFFEA580C), Color(0xFFFBBF24)],
    [Color(0xFF0369A1), Color(0xFF38BDF8)],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[intern.name.length % _palettes.length];
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: palette),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          intern.avatarInitials,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.35),
        ),
      ),
    );
  }
}