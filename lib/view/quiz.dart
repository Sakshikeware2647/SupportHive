import 'package:flutter/material.dart';
import 'screens/counselling/ai_chat_screen.dart'; // adjust path to your AIChatScreen

class QuizQuestion {
  final String question;
  final String category;
  final List<String> options;

  const QuizQuestion({
    required this.question,
    required this.category,
    required this.options,
  });
}

class QuizResult {
  final Map<String, int> categoryScores;
  final int totalScore;
  final String overallMood;
  final DateTime completedAt;

  QuizResult({
    required this.categoryScores,
    required this.totalScore,
    required this.overallMood,
    required this.completedAt,
  });

  String toPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('The user just completed a wellness quiz. Here are their results:');
    buffer.writeln('Overall mood score: $totalScore/24 ($overallMood)');
    buffer.writeln('Breakdown by category:');
    for (final entry in categoryScores.entries) {
      final label = _scoreLabel(entry.value);
      buffer.writeln('  - ${entry.key}: ${entry.value}/3 ($label)');
    }
    buffer.writeln();
    buffer.writeln(
      'Based on these results, give the user a warm, personalised wellness message. '
      'Mention the areas where they scored low (0–1) as areas to focus on, '
      'celebrate areas where they scored high (2–3), '
      'and give 2–3 specific Dos and Don\'ts tailored to their results. '
      'Keep it supportive, non-clinical, and under 200 words.',
    );
    return buffer.toString();
  }

  String _scoreLabel(int score) {
    switch (score) {
      case 0:  return 'Needs attention';
      case 1:  return 'Below average';
      case 2:  return 'Good';
      case 3:  return 'Excellent';
      default: return '';
    }
  }

  Map<String, dynamic> toMap() => {
        'categoryScores': categoryScores,
        'totalScore': totalScore,
        'overallMood': overallMood,
        'completedAt': completedAt.toIso8601String(),
      };
}

class WellnessQuizScreen extends StatefulWidget {
  final bool sendResultsToAI;
  const WellnessQuizScreen({super.key, this.sendResultsToAI = true});

  @override
  State<WellnessQuizScreen> createState() => _WellnessQuizScreenState();
}

class _WellnessQuizScreenState extends State<WellnessQuizScreen> {
  static const _green      = Color(0xFF3D5A35);
  static const _lightGreen = Color(0xFFE8EDE6);

  int _currentIndex = 0;
  final List<int?> _answers = List.filled(8, null);

  final List<QuizQuestion> _questions = const [
    QuizQuestion(
      question: 'How often have you felt overwhelmed by stress in the past week?',
      category: 'Emotional Stress',
      options: ['Often', 'Sometimes', 'Rarely', 'Never'],
    ),
    QuizQuestion(
      question: 'How would you rate your overall mood today?',
      category: 'Mood',
      options: ['Very Low', 'Low', 'Neutral', 'High'],
    ),
    QuizQuestion(
      question: 'How satisfied are you with your sleep quality this week?',
      category: 'Sleep',
      options: ['Very Unsatisfied', 'Unsatisfied', 'Satisfied', 'Very Satisfied'],
    ),
    QuizQuestion(
      question: 'How often did you engage in physical activity this week?',
      category: 'Physical Health',
      options: ['Never', 'Once', '2–3 times', 'Daily'],
    ),
    QuizQuestion(
      question: 'How connected do you feel to the people around you?',
      category: 'Social Wellness',
      options: ['Very Disconnected', 'Somewhat Disconnected', 'Connected', 'Very Connected'],
    ),
    QuizQuestion(
      question: 'How often did you take breaks to relax during your day?',
      category: 'Relaxation',
      options: ['Never', 'Rarely', 'Sometimes', 'Often'],
    ),
    QuizQuestion(
      question: 'How well have you been able to focus on tasks recently?',
      category: 'Focus',
      options: ['Very Poorly', 'Poorly', 'Well', 'Very Well'],
    ),
    QuizQuestion(
      question: 'How happy do you feel overall right now?',
      category: 'Happiness',
      options: ['Very Unhappy', 'Unhappy', 'Happy', 'Very Happy'],
    ),
  ];

  int _scoreForAnswer(int optionIndex) => optionIndex;

  QuizResult _buildResult() {
    final Map<String, int> scores = {};
    int total = 0;
    for (int i = 0; i < _questions.length; i++) {
      final score = _scoreForAnswer(_answers[i] ?? 0);
      scores[_questions[i].category] = score;
      total += score;
    }

    final String mood;
    if (total >= 20)      mood = 'Thriving';
    else if (total >= 14) mood = 'Doing Well';
    else if (total >= 8)  mood = 'Struggling a Bit';
    else                  mood = 'Needs Support';

    return QuizResult(
      categoryScores: scores,
      totalScore: total,
      overallMood: mood,
      completedAt: DateTime.now(),
    );
  }

  void _next() {
    if (_answers[_currentIndex] == null) return;
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finish();
    }
  }

  void _previous() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _finish() {
    final result = _buildResult();
    if (widget.sendResultsToAI) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AIChatScreen(quizResult: result)),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _skip() {
    if (widget.sendResultsToAI) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AIChatScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final selected = _answers[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    ),
                    child: const Icon(Icons.help_outline, size: 16, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wellness Quiz',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Assess your stress, mood, and happiness levels',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Quiz Card ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EFE9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Progress header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${_currentIndex + 1} of ${_questions.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                question.category,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF555555)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade300,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_green),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Question text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: question.options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final isSelected = selected == i;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _answers[_currentIndex] = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? _lightGreen : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? _green : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? _green
                                              : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? _green
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              size: 12, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      question.options[i],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? _green
                                            : const Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Navigation buttons (FIXED: no overflow) ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous — fixed width so it never steals space
                            SizedBox(
                              width: 110,
                              child: TextButton(
                                onPressed: _currentIndex > 0 ? _previous : null,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  backgroundColor: _currentIndex > 0
                                      ? Colors.grey.shade200
                                      : Colors.grey.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Previous',
                                  style: TextStyle(
                                    color: _currentIndex > 0
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            // Next / Finish — Flexible prevents right-side overflow
                            Flexible(
                              child: ElevatedButton(
                                onPressed: _answers[_currentIndex] != null
                                    ? _next
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _currentIndex == _questions.length - 1
                                      ? 'Finish & Get Advice'
                                      : 'Next',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Skip
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: _skip,
                          child: const Text(
                            'Skip Quiz for Now',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}