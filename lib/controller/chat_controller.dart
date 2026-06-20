import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../model/message_model.dart';
import '../service/AI_chat_service.dart';

class ChatController extends ChangeNotifier {
  final ChatService _service = ChatService();
  final List<Message> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;
  bool _disposed = false;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isLoading => _isLoading;

  ChatController() {
    _init();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _init() async {
    _isLoading = true;
    _safeNotify();
    try {
      final history = await _service.loadHistoryAndInitSession(); 
      _messages.clear();
      if (history.isEmpty) {
        final greeting = _service.createInitialMessage();
        _messages.add(greeting);
        await _service.saveMessage(greeting);
      } else {
        _messages.addAll(history);
      }
    } catch (_) {
      _messages.clear();
      final greeting = _service.createInitialMessage();
      _messages.add(greeting);
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    final userMsg = Message(
      id: const Uuid().v4(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isTyping = true;
    _safeNotify();

    // Fire-and-forget save — don't await to keep UI snappy
    _service.saveMessage(userMsg);

    final replyText = await _service.sendAndGetReply(
      trimmed,
      List.from(_messages),
    );

    final aiMsg = Message(
      id: const Uuid().v4(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(aiMsg);
    _isTyping = false;
    _safeNotify();

    _service.saveMessage(aiMsg);
  }

  Future<void> clearChat() async {
    _isLoading = true;
    _safeNotify();
    await _service.clearHistory();
    _messages.clear();
    final greeting = _service.createInitialMessage();
    _messages.add(greeting);
    await _service.saveMessage(greeting);
    _isLoading = false;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}