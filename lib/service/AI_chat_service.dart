// ─────────────────────────────────────────────
//  service/AI_chat_service.dart  –  SupportHive
// ─────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../model/message_model.dart';
import '../core/api_keys.dart';

// ── Journal AI insight model ──────────────────
class JournalInsight {
  final String summary;
  final List<String> doList;
  final List<String> dontList;
  final List<String> affirmations;
  final String emotionalTone;
  final String emoji;

  const JournalInsight({
    required this.summary,
    required this.doList,
    required this.dontList,
    required this.affirmations,
    required this.emotionalTone,
    required this.emoji,
  });
}

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final GenerativeModel _model;
  late final GenerativeModel _journalModel;
  ChatSession? _chatSession;

  // ── Track recent replies to avoid repetition ──
  final List<String> _recentReplies = [];
  static const int _maxRecentReplies = 5;

  ChatService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: ApiKeys.geminiApiKey,
      
      generationConfig: GenerationConfig(
        temperature: 0.85,        // Slightly higher = more varied responses
        maxOutputTokens: 512,
        topP: 0.92,
        topK: 40,
      ),
      systemInstruction: Content.system(_systemPrompt),
    );

    // Separate model instance for journal analysis
    _journalModel = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: ApiKeys.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 800,
      ),
      systemInstruction: Content.system(_journalSystemPrompt),
    );
  }

  // ── Chat system prompt ────────────────────────
  static const String _systemPrompt = """
You are Hive, a compassionate AI wellness assistant for the SupportHive app.
Your two roles:

ROLE 1 — Stress & Mental Health Support:
- Answer questions about stress, anxiety, depression, burnout, loneliness,
  sleep problems, and emotional wellbeing with empathy and evidence-based advice.
- Keep answers calm, supportive, and concise (under 120 words).
- If the user seems in crisis, gently suggest professional help.
- IMPORTANT: Never give the same response twice for similar questions.
  Vary your phrasing, examples, metaphors, and advice angle each time.
  If the user repeats a question, acknowledge it and offer a fresh perspective.

ROLE 2 — App Navigation Guide:
SupportHive has these features. When a user asks where something is, guide them:
  Home tab         -> Daily quote, music, podcasts, activities
  Search tab       -> Search for resources and content
  Counselling tab  -> Book a session with a counsellor (bottom nav, 2nd icon)
  Games tab        -> Mindful games for stress relief (bottom nav, 4th icon)
  AI Chat          -> This chat (drawer -> AI Chat)
  Journal/Diary    -> Home -> Quiz & Journal section -> Open Diary
  Wellness Quiz    -> Home -> Quiz & Journal section -> Take Quiz
  Wellness Status  -> Home -> Quiz & Journal section -> Check Status
  Music Player     -> Home -> Music section -> tap any track
  Podcast Player   -> Home -> Podcast section -> tap any podcast
  Profile          -> Top-right avatar icon on home screen
  Notifications    -> Top-right bell icon on home screen
  Settings         -> Drawer menu -> Settings
  Video/Call       -> Counselling screen -> Book Session

IMPORTANT STYLE RULES:
- Always respond in plain text. No markdown symbols like ** or ## or bullet dashes.
- Be warm, friendly, and human. Never give medical diagnoses.
- Vary sentence structures and vocabulary naturally across responses.
- If the question is off-topic, politely redirect back to wellness or app help.
- Use a different opening phrase each time (not always "I understand" or "That's great").
- Occasionally use gentle metaphors to explain concepts (nature, light, seasons).
""";

  // ── Journal analysis system prompt ────────────
  static const String _journalSystemPrompt = """
You are Hive, a compassionate wellness AI reading someone's private journal entry.
Your task is to provide a warm, insightful analysis in structured JSON format.

Analyze the journal entry and respond ONLY with valid JSON (no markdown, no backticks):
{
  "summary": "A 2-3 sentence empathetic summary of what the person is experiencing",
  "emotionalTone": "One word describing the dominant emotion (e.g. Anxious, Hopeful, Drained, Grateful)",
  "emoji": "One relevant emoji that matches their emotional tone",
  "doList": [
    "Action-oriented, specific, kind suggestion 1",
    "Action-oriented, specific, kind suggestion 2",
    "Action-oriented, specific, kind suggestion 3"
  ],
  "dontList": [
    "Gentle warning or what to avoid 1",
    "Gentle warning or what to avoid 2"
  ],
  "affirmations": [
    "Short, personal affirmation based on their entry 1",
    "Short, personal affirmation based on their entry 2",
    "Short, personal affirmation based on their entry 3"
  ]
}

Rules:
- Be honest but always kind and non-judgmental.
- Do suggestions must be practical and specific to their entry.
- Don't suggestions must be gentle, never harsh or preachy.
- Affirmations must feel personal, not generic.
- Keep each item under 15 words.
- Never diagnose. Never be alarmist.
- If entry is very short, still provide thoughtful analysis.
""";

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';
  CollectionReference get _chatRef =>
      _db.collection('users').doc(_uid).collection('chatHistory');

  // ── Session management ────────────────────────
  void _initChatSession(List<Message> history) {
    final geminiHistory = <Content>[];
    for (final msg in history) {
      if (msg.text == createInitialMessage().text) continue;
      geminiHistory.add(
        msg.isUser
            ? Content.text(msg.text)
            : Content.model([TextPart(msg.text)]),
      );
    }
    _chatSession = _model.startChat(history: geminiHistory);
    debugPrint('✅ ChatSession initialized with ${geminiHistory.length} messages');
  }

  // ── Similarity check to avoid repetition ──────
  bool _isTooSimilar(String newReply) {
    if (_recentReplies.isEmpty) return false;
    for (final prev in _recentReplies) {
      final newWords = newReply.toLowerCase().split(' ').toSet();
      final prevWords = prev.toLowerCase().split(' ').toSet();
      final intersection = newWords.intersection(prevWords);
      final union = newWords.union(prevWords);
      final similarity = intersection.length / union.length;
      if (similarity > 0.65) return true; // More than 65% overlap = too similar
    }
    return false;
  }

  void _trackReply(String reply) {
    _recentReplies.add(reply);
    if (_recentReplies.length > _maxRecentReplies) {
      _recentReplies.removeAt(0);
    }
  }

  // ── Firestore ops ────────────────────────────
  Future<void> saveMessage(Message message) async {
    try {
      await _chatRef.doc(message.id).set(message.toMap());
    } catch (e) {
      debugPrint('❌ saveMessage error: $e');
    }
  }

  Future<List<Message>> loadHistory() async {
    try {
      final snap = await _chatRef
          .orderBy('timestamp', descending: false)
          .limitToLast(50)
          .get();
      final messages = snap.docs
          .map((d) => Message.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      debugPrint('✅ Loaded ${messages.length} messages from Firestore');
      return messages;
    } catch (e) {
      debugPrint('❌ loadHistory error: $e');
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final snap = await _chatRef.get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _chatSession = null;
      _recentReplies.clear();
      debugPrint('✅ Chat history cleared');
    } catch (e) {
      debugPrint('❌ clearHistory error: $e');
    }
  }

  Future<List<Message>> loadHistoryAndInitSession() async {
    final history = await loadHistory();
    _initChatSession(history);
    return history;
  }

  // ── Send message with variation enforcement ───
  Future<String> sendAndGetReply(
    String userMessage,
    List<Message> history,
  ) async {
    try {
      _chatSession ??= _model.startChat();

      debugPrint('📤 Sending to Gemini: $userMessage');

      // First attempt
      var response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );
      var reply = (response.text ?? '').trim();

      // If too similar to recent replies, ask for a different angle
      if (_isTooSimilar(reply) && reply.isNotEmpty) {
        debugPrint('⚠️ Reply too similar, requesting fresh perspective...');
        final retryResponse = await _chatSession!.sendMessage(
          Content.text(
            'Please provide a completely different perspective or approach to the previous question.',
          ),
        );
        final retryReply = (retryResponse.text ?? '').trim();
        if (retryReply.isNotEmpty) {
          reply = retryReply;
        }
      }

      debugPrint('📥 Gemini replied: $reply');

      if (reply.isEmpty) {
        return "I'm here for you. Tell me more 💚";
      }

      _trackReply(reply);
      return reply;
    } on GenerativeAIException catch (e) {
      debugPrint('❌ GenerativeAIException: ${e.message}');
      if (e.message.contains('API_KEY_INVALID') ||
          e.message.contains('API key not valid')) {
        return "There's a configuration issue. Please contact support. 💚";
      } else if (e.message.contains('quota') ||
          e.message.contains('RESOURCE_EXHAUSTED')) {
        return "I'm a bit busy right now. Please try again in a moment. 💚";
      }
      return "Something went wrong on my end. Please try again. 💚";
    } catch (e) {
      debugPrint('❌ sendAndGetReply error: $e');
      return "I'm having a little trouble right now. Please try again in a moment. 💚";
    }
  }

  // ── Journal AI analysis ───────────────────────
  Future<JournalInsight?> analyzeJournalEntry({
    required String title,
    required String content,
    String? mood,
  }) async {
    try {
      final entryText = '''
Title: ${title.isEmpty ? 'Untitled' : title}
Mood: ${mood ?? 'Not specified'}
Entry: ${content.isEmpty ? 'No content written yet.' : content}
''';

      debugPrint('📓 Analyzing journal entry...');

      final response = await _journalModel.generateContent([
        Content.text(entryText),
      ]);

      final rawJson = (response.text ?? '').trim();
      debugPrint('📓 Journal analysis raw: $rawJson');

      if (rawJson.isEmpty) return null;

      // Strip any accidental markdown fences
      final cleaned = rawJson
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Parse JSON manually for reliability
      return _parseInsight(cleaned);
    } catch (e) {
      debugPrint('❌ analyzeJournalEntry error: $e');
      return null;
    }
  }

  JournalInsight? _parseInsight(String json) {
    try {
      // Simple reliable JSON parsing
      String extract(String key) {
        final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
        return pattern.firstMatch(json)?.group(1) ?? '';
      }

      List<String> extractList(String key) {
        final pattern = RegExp('"$key"\\s*:\\s*\\[([^\\]]+)\\]', dotAll: true);
        final match = pattern.firstMatch(json);
        if (match == null) return [];
        final content = match.group(1) ?? '';
        final items = RegExp('"([^"]+)"').allMatches(content);
        return items.map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty).toList();
      }

      final summary = extract('summary');
      final emotionalTone = extract('emotionalTone');
      final emoji = extract('emoji');
      final doList = extractList('doList');
      final dontList = extractList('dontList');
      final affirmations = extractList('affirmations');

      if (summary.isEmpty) return null;

      return JournalInsight(
        summary: summary,
        doList: doList.isNotEmpty ? doList : ['Take one small step today', 'Rest when you need to', 'Be gentle with yourself'],
        dontList: dontList.isNotEmpty ? dontList : ['Don\'t be too hard on yourself', 'Avoid isolating completely'],
        affirmations: affirmations.isNotEmpty ? affirmations : ['You are doing better than you think', 'Your feelings are valid', 'You are enough'],
        emotionalTone: emotionalTone.isNotEmpty ? emotionalTone : 'Reflective',
        emoji: emoji.isNotEmpty ? emoji : '💚',
      );
    } catch (e) {
      debugPrint('❌ _parseInsight error: $e');
      return null;
    }
  }

  Message createInitialMessage() {
    return Message(
      id: 'init_${DateTime.now().millisecondsSinceEpoch}',
      text:
          "Hi, I'm Hive 🐝 — your SupportHive wellness companion.\n\nI can help you with stress, anxiety, sleep, and emotional wellbeing. I can also guide you to any feature in the app.\n\nHow are you feeling today?",
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}