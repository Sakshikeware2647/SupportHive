// ─────────────────────────────────────────────────────────────────
// activities_section.dart  — fully self-contained
// Model + Controller (SharedPreferences) + View
//
// What it does:
//   • Shows daily wellness activities (Breathe, Journal, Quiz,
//     Mindfulness, AI Chat, Schedule)
//   • Tracks completion state per-day in SharedPreferences
//     → resets automatically at midnight (new day)
//   • Tapping "Start" navigates to the real screen
//   • Completed items show a green check, button says "Done ✓"
//   • Progress bar at top shows X/N completed
// ─────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Your real screen imports ──────────────────────────────────────
import 'package:supporthive1/view/notes_screen.dart';
import 'package:supporthive1/view/quiz.dart';
import 'package:supporthive1/view/screens/counselling/ai_chat_screen.dart';
import 'package:supporthive1/view/widgets/schedule_screen.dart';
import 'package:supporthive1/view/widgets/wellness_status_screen.dart';

// ═════════════════════════════════════════════════════════════════
// MODEL
// ═════════════════════════════════════════════════════════════════

enum ActivityType {
  breathing,
  journal,
  quiz,
  mindfulness,
  aiChat,
  schedule,
}

class ActivityItem {
  final ActivityType type;
  final String title;
  final String subtitle;
  final String buttonText;
  final IconData icon;
  bool isCompleted;

  ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'isCompleted': isCompleted,
      };

  factory ActivityItem.fromDefaults(ActivityType type) {
    switch (type) {
      case ActivityType.breathing:
        return ActivityItem(
          type: type,
          title: 'Breathing Exercise',
          subtitle: '5-min calm breathing session',
          buttonText: 'Start',
          icon: Icons.air_rounded,
        );
      case ActivityType.journal:
        return ActivityItem(
          type: type,
          title: 'Daily Journal',
          subtitle: 'Write how you feel today',
          buttonText: 'Write',
          icon: Icons.menu_book_rounded,
        );
      case ActivityType.quiz:
        return ActivityItem(
          type: type,
          title: 'Wellness Quiz',
          subtitle: 'Check your mood & stress level',
          buttonText: 'Take Quiz',
          icon: Icons.quiz_rounded,
        );
      case ActivityType.mindfulness:
        return ActivityItem(
          type: type,
          title: 'Mindfulness',
          subtitle: 'Track your wellness points',
          buttonText: 'Open',
          icon: Icons.self_improvement_rounded,
        );
      case ActivityType.aiChat:
        return ActivityItem(
          type: type,
          title: 'Chat with Hive AI',
          subtitle: 'Talk to your wellness assistant',
          buttonText: 'Chat',
          icon: Icons.chat_bubble_rounded,
        );
      case ActivityType.schedule:
        return ActivityItem(
          type: type,
          title: 'Plan Your Day',
          subtitle: 'Review or set your schedule',
          buttonText: 'View',
          icon: Icons.calendar_today_rounded,
        );
    }
  }
}

// ═════════════════════════════════════════════════════════════════
// CONTROLLER
// ═════════════════════════════════════════════════════════════════

class ActivitiesController extends ChangeNotifier {
  static const _prefsKey = 'activities_state_v1';
  static const _dateKey  = 'activities_date_v1';

  // Today's fixed activity list (order matters for display)
  static const List<ActivityType> _dailyTypes = [
    ActivityType.breathing,
    ActivityType.journal,
    ActivityType.quiz,
    ActivityType.mindfulness,
    ActivityType.aiChat,
    ActivityType.schedule,
  ];

  List<ActivityItem> _activities = [];
  bool _loading = true;

  List<ActivityItem> get activities => _activities;
  bool get loading => _loading;

  int get completedCount => _activities.where((a) => a.isCompleted).length;
  int get totalCount => _activities.length;
  double get progress =>
      totalCount == 0 ? 0 : completedCount / totalCount;
  bool get allDone => completedCount == totalCount;

  // ── Init ─────────────────────────────────────────────────────
  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final savedDate = prefs.getString(_dateKey) ?? '';

    if (savedDate != today) {
      // New day → reset everything
      _activities = _dailyTypes
          .map((t) => ActivityItem.fromDefaults(t))
          .toList();
      await _persist(prefs, today);
    } else {
      // Same day → restore completion state
      final raw = prefs.getString(_prefsKey);
      _activities = _dailyTypes
          .map((t) => ActivityItem.fromDefaults(t))
          .toList();

      if (raw != null) {
        final List decoded = jsonDecode(raw);
        for (final map in decoded) {
          final typeName = map['type'] as String;
          final done = map['isCompleted'] as bool;
          final idx = _activities.indexWhere((a) => a.type.name == typeName);
          if (idx != -1) _activities[idx].isCompleted = done;
        }
      }
    }

    _loading = false;
    notifyListeners();
  }

  // ── Mark complete ─────────────────────────────────────────────
  Future<void> markCompleted(ActivityType type) async {
    final idx = _activities.indexWhere((a) => a.type == type);
    if (idx == -1 || _activities[idx].isCompleted) return;

    _activities[idx].isCompleted = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs, _todayString());
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _persist(SharedPreferences prefs, String today) async {
    await prefs.setString(_dateKey, today);
    await prefs.setString(
      _prefsKey,
      jsonEncode(_activities.map((a) => a.toJson()).toList()),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// VIEW  —  drop-in widget, manages its own controller lifecycle
// ═════════════════════════════════════════════════════════════════

class ActivitiesSection extends StatefulWidget {
  const ActivitiesSection({super.key});

  @override
  State<ActivitiesSection> createState() => _ActivitiesSectionState();
}

class _ActivitiesSectionState extends State<ActivitiesSection> {
  final _ctrl = ActivitiesController();

  @override
  void initState() {
    super.initState();
    _ctrl.load();
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Navigate to the real screen, then mark done ───────────────
  Future<void> _onStart(ActivityItem activity) async {
    if (activity.isCompleted) return;

    Widget? destination;

    switch (activity.type) {
      case ActivityType.breathing:
        // Breathing is handled inline (bottom sheet)
        _showBreathingSheet();
        return;
      case ActivityType.journal:
        destination = const NotesScreen();
        break;
      case ActivityType.quiz:
        destination = const WellnessQuizScreen();
        break;
      case ActivityType.mindfulness:
        destination = const WellnessStatusScreen();
        break;
      case ActivityType.aiChat:
        destination = const AIChatScreen();
        break;
      case ActivityType.schedule:
        destination = const ScheduleScreen();
        break;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination!),
    );

    // Mark done when user comes back (they visited the screen)
    await _ctrl.markCompleted(activity.type);
  }

  // ── Breathing bottom sheet (no external screen needed) ────────
  void _showBreathingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BreathingSheet(
        onDone: () async {
          Navigator.pop(context);
          await _ctrl.markCompleted(ActivityType.breathing);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_ctrl.loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildProgressBar(),
          const SizedBox(height: 14),
          _buildList(),
          if (_ctrl.allDone) ...[
            const SizedBox(height: 14),
            _buildAllDoneBanner(),
          ],
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6741).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Color(0xFF4A6741), size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Activities",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A)),
                ),
                Text(
                  'Your wellness agenda for today',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4A6741).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_ctrl.completedCount}/${_ctrl.totalCount} done',
            style: const TextStyle(
                color: Color(0xFF4A6741),
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ── Progress bar ──────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _ctrl.progress,
            minHeight: 7,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              _ctrl.allDone
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF4A6741),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _ctrl.allDone
              ? '🎉 All done for today!'
              : '${_ctrl.completedCount} of ${_ctrl.totalCount} completed',
          style: TextStyle(
              fontSize: 11,
              color: _ctrl.allDone
                  ? const Color(0xFF22C55E)
                  : Colors.grey.shade500),
        ),
      ],
    );
  }

  // ── Activity list ─────────────────────────────────────────────
  Widget _buildList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _ctrl.activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isLast = index == _ctrl.activities.length - 1;
          return Column(
            children: [
              _ActivityTile(
                activity: activity,
                index: index,
                onTap: () => _onStart(activity),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 20,
                  color: Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── All done banner ───────────────────────────────────────────
  Widget _buildAllDoneBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6741), Color(0xFF22C55E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Goal Achieved! 🎉',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('You completed all wellness activities today.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SINGLE ACTIVITY TILE
// ═════════════════════════════════════════════════════════════════

class _ActivityTile extends StatefulWidget {
  final ActivityItem activity;
  final int index;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.activity,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  static const List<Color> _colors = [
    Color(0xFF4A6741),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
    Color(0xFFE65100),
    Color(0xFF37474F),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 80),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colors[widget.index % _colors.length];
    final done  = widget.activity.isCompleted;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon with checkmark overlay when done
              Stack(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFF22C55E).withOpacity(0.12)
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.activity.icon,
                      color: done ? const Color(0xFF22C55E) : color,
                      size: 22,
                    ),
                  ),
                  if (done)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activity.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: done
                            ? Colors.grey.shade400
                            : const Color(0xFF1A1A1A),
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.activity.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              // Button
              _ActionBtn(
                label: done ? 'Done ✓' : widget.activity.buttonText,
                color: done ? const Color(0xFF22C55E) : color,
                isDone: done,
                onTap: widget.onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// ACTION BUTTON
// ═════════════════════════════════════════════════════════════════

class _ActionBtn extends StatefulWidget {
  final String label;
  final Color color;
  final bool isDone;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.isDone,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0, upperBound: 0.05,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDone) {
      // Non-tappable "Done" badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.3)),
        ),
        child: const Text(
          'Done ✓',
          style: TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// BREATHING BOTTOM SHEET  (inline — no external screen needed)
// ═════════════════════════════════════════════════════════════════

class _BreathingSheet extends StatefulWidget {
  final VoidCallback onDone;
  const _BreathingSheet({required this.onDone});

  @override
  State<_BreathingSheet> createState() => _BreathingSheetState();
}

class _BreathingSheetState extends State<_BreathingSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  // 4-7-8 breathing pattern (inhale 4s, hold 7s, exhale 8s)
  static const _phases = ['Inhale', 'Hold', 'Exhale'];
  static const _durations = [4, 7, 8]; // seconds
  static const _totalCycles = 3;

  int _phaseIndex = 0;
  int _cycle = 0;
  int _secondsLeft = 4;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _startPhase();
  }

  void _startPhase() {
    setState(() => _secondsLeft = _durations[_phaseIndex]);
    _ctrl.duration =
        Duration(seconds: _durations[_phaseIndex]);
    if (_phaseIndex == 0) {
      _ctrl.forward(from: 0);
    } else if (_phaseIndex == 2) {
      _ctrl.reverse(from: 1);
    }
    // For hold phase, keep scale as-is

    _tick();
  }

  void _tick() {
    if (!mounted) return;
    if (_secondsLeft <= 0) {
      _nextPhase();
      return;
    }
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      _tick();
    });
  }

  void _nextPhase() {
    if (_phaseIndex < _phases.length - 1) {
      setState(() => _phaseIndex++);
      _startPhase();
    } else {
      // End of cycle
      if (_cycle < _totalCycles - 1) {
        setState(() {
          _cycle++;
          _phaseIndex = 0;
        });
        _startPhase();
      } else {
        setState(() => _done = true);
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: _done ? _buildDone() : _buildBreathing(),
    );
  }

  Widget _buildBreathing() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 28),
        const Text('Breathing Exercise',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Cycle ${_cycle + 1} of $_totalCycles',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const Spacer(),
        ScaleTransition(
          scale: _scale,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF4A6741).withOpacity(0.7),
                const Color(0xFF4A6741).withOpacity(0.15),
              ]),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _phases[_phaseIndex],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_secondsLeft s',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: widget.onDone,
          child: Text('Skip',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF22C55E), size: 72),
        const SizedBox(height: 20),
        const Text('Great job! 🌿',
            style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('You completed your breathing session.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6741),
            padding: const EdgeInsets.symmetric(
                horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: widget.onDone,
          child: const Text('Done',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ),
      ],
    );
  }
}