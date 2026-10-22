import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../model/message_model.dart';
import '../service/AI_chat_service.dart';
import '../view/quiz.dart'; // QuizResult lives here

class ChatController extends ChangeNotifier {
  final ChatService _service = ChatService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<Message> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;
  bool _disposed = false;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isLoading => _isLoading;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  /// Firestore collection that stores each quiz attempt.
  CollectionReference get _quizResultsRef =>
      _db.collection('users').doc(_uid).collection('quizResults');

  ChatController() {
    _init();
  }

  // ── Safe notify (guards against post-dispose calls) ───────────
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ── Initialise: load Firestore history, seed greeting if empty ─
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
    } catch (e) {
      debugPrint('❌ ChatController._init error: $e');
      _messages.clear();
      final greeting = _service.createInitialMessage();
      _messages.add(greeting);
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // ── Regular user message → AI reply ──────────────────────────
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

    // Fire-and-forget save — keeps UI snappy
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

  // ── Send quiz result: save to Firestore + get AI advice ───────
  Future<void> sendQuizResult(QuizResult result) async {
    if (_isTyping) return;

    // 1. Persist the quiz result to Firestore
    await _saveQuizResultToFirestore(result);

    // 2. Build a readable user-bubble that shows what the user answered
    final summaryText = _buildQuizSummaryMessage(result);
    final summaryMsg = Message(
      id: const Uuid().v4(),
      text: summaryText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(summaryMsg);
    _isTyping = true;
    _safeNotify();

    await _service.saveMessage(summaryMsg);

    // 3. Send the detailed AI prompt (includes category breakdown + instruction)
    //    This is what Gemini actually uses to craft personalised advice.
    final aiPrompt = result.toPrompt();
    final replyText = await _service.sendAndGetReply(
      aiPrompt,
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

    await _service.saveMessage(aiMsg);
  }

  // ── Build a human-readable bubble from quiz answers ───────────
  String _buildQuizSummaryMessage(QuizResult result) {
    final buffer = StringBuffer();
    buffer.writeln('I just completed the Wellness Quiz 📋');
    buffer.writeln();
    buffer.writeln('My results:');
    for (final entry in result.categoryScores.entries) {
      final bar = _scoreBar(entry.value);
      buffer.writeln('  ${entry.key}: $bar (${entry.value}/3)');
    }
    buffer.writeln();
    buffer.writeln('Overall: ${result.overallMood} (${result.totalScore}/24)');
    buffer.writeln();
    buffer.write('Based on these results, what should I focus on?');
    return buffer.toString();
  }

  /// Renders a simple dot-bar for a 0–3 score, e.g. "● ● ○"
  String _scoreBar(int score) {
    const filled = '●';
    const empty  = '○';
    return List.generate(3, (i) => i < score ? filled : empty).join(' ');
  }

  // ── Persist QuizResult to Firestore ──────────────────────────
  Future<void> _saveQuizResultToFirestore(QuizResult result) async {
    try {
      await _quizResultsRef.add({
        ...result.toMap(),
        'savedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Quiz result saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save quiz result: $e');
    }
  }

  // ── Clear chat (Firestore + in-memory) ───────────────────────
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