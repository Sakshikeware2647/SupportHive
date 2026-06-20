import 'package:flutter/material.dart';
import 'package:supporthive1/view/quiz.dart';
import 'package:supporthive1/view/notes_screen.dart';
import 'package:supporthive1/service/wellness_service.dart';

class WellnessStatusScreen extends StatefulWidget {
  const WellnessStatusScreen({super.key});

  @override
  State<WellnessStatusScreen> createState() => _WellnessStatusScreenState();
}

class _WellnessStatusScreenState extends State<WellnessStatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  final _svc = WellnessService();
  WellnessData _data = WellnessData.empty();
  bool _loading = true;

  static const _green = Color(0xFF4A6741);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  Future<void> _load() async {
    final d = await _svc.loadData();
    if (mounted) setState(() { _data = d; _loading = false; });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : FadeTransition(
              opacity: _fade,
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: _green,
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          _buildScoreHero(),
                          const SizedBox(height: 4),
                          _buildProgressBar(),
                          const SizedBox(height: 16),
                          _buildStreakBanner(),
                          const SizedBox(height: 12),
                          _buildTodaySection(),
                          const SizedBox(height: 12),
                          _buildRecommendationCard(),
                          const SizedBox(height: 12),
                          _buildInsightsRow(),
                          const SizedBox(height: 12),
                          _buildPointsBreakdown(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: 16, right: 16,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: _green.withOpacity(0.4),
                      ),
                      child: const Text('Got it!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Wellness Status',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }

  // ─── Score Hero ───────────────────────────────────────────────────────────
  Widget _buildScoreHero() {
    final score = _data.wellnessScore;
    final label = score == 0 ? 'Getting Started'
        : score < 30 ? 'Needs Attention'
        : score < 60 ? 'Getting Better'
        : score < 85 ? 'Doing Great'
        : 'Excellent! 🌟';
    final sub = score == 0
        ? 'Complete tasks below to earn your first points!'
        : score >= 85
            ? 'You\'re crushing it! Keep the momentum going.'
            : 'Complete daily tasks to improve your score.';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6741), Color(0xFF2F6B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Wellness', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Animated score ring
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72, height: 72,
                  child: CircularProgressIndicator(
                    value: val / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$val', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('pts', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress Bar ─────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    final score = _data.wellnessScore;
    final color = score < 30 ? Colors.red.shade400
        : score < 60 ? Colors.orange
        : _green;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wellness Score', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('$score / 100', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total points earned: ${_data.totalPoints}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ─── Streak Banner ────────────────────────────────────────────────────────
  Widget _buildStreakBanner() {
    final streak = _data.streakDays;
    if (streak == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange.shade400]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$streak-Day Streak!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  streak % 7 == 0
                      ? '🎉 7-day milestone! +${WellnessService.pointsStreakBonus} bonus points earned!'
                      : '${7 - streak % 7} more days to earn +${WellnessService.pointsStreakBonus} bonus pts',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('🏆 $streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Today's Tasks ────────────────────────────────────────────────────────
  Widget _buildTodaySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${_data.completedToday} / 2 done',
                  style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TaskCard(
            icon: Icons.quiz_rounded,
            title: 'Wellness Quiz',
            subtitle: _data.taskDone('quiz')
                ? 'Completed today ✓  (+${WellnessService.pointsQuiz} pts earned)'
                : 'Answer a few questions • Earn ${WellnessService.pointsQuiz} pts',
            buttonText: _data.taskDone('quiz') ? 'Retake' : 'Take Quiz',
            done: _data.taskDone('quiz'),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessQuizScreen()));
              // Award points when returning (quiz screen should call this itself ideally)
              await _svc.awardPoints('quiz');
              _load();
            },
          ),
          const SizedBox(height: 10),
          _TaskCard(
            icon: Icons.menu_book_rounded,
            title: 'Daily Journal',
            subtitle: _data.taskDone('journal')
                ? 'Entry written today ✓  (+${WellnessService.pointsJournal} pts earned)'
                : 'Write how you feel • Earn ${WellnessService.pointsJournal} pts',
            buttonText: _data.taskDone('journal') ? 'Edit Entry' : 'Write Entry',
            done: _data.taskDone('journal'),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
              await _svc.awardPoints('journal');
              _load();
            },
          ),
        ],
      ),
    );
  }

  // ─── Recommendation Card ──────────────────────────────────────────────────
  Widget _buildRecommendationCard() {
    final recs = _buildRecs();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A6741), Color(0xFF2F6B2F)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Recommendations for You',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          ...recs.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                const Text('•', style: TextStyle(color: Colors.white60, fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<String> _buildRecs() {
    final recs = <String>[];
    if (!_data.taskDone('quiz'))    recs.add('Take today\'s wellness quiz to earn ${WellnessService.pointsQuiz} points');
    if (!_data.taskDone('journal')) recs.add('Write your daily journal entry (+${WellnessService.pointsJournal} pts)');
    if (!_data.taskDone('podcast')) recs.add('Listen to a wellness podcast (+${WellnessService.pointsPodcast} pts)');
    if (!_data.taskDone('game'))    recs.add('Play a mindful game to sharpen focus (+${WellnessService.pointsMindGame} pts)');
    if (_data.streakDays == 0)      recs.add('Start your streak — come back tomorrow to build momentum!');
    if (_data.wellnessScore >= 80)  recs.add('You\'re doing amazing! Try an expert counselling session today.');
    if (recs.isEmpty) recs.add('All tasks done for today! Come back tomorrow 🎉');
    return recs.take(4).toList();
  }

  // ─── Insights Row ─────────────────────────────────────────────────────────
  Widget _buildInsightsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _InsightTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Current Streak',
            value: '${_data.streakDays} days',
            color: Colors.orange,
          )),
          const SizedBox(width: 12),
          Expanded(child: _InsightTile(
            icon: Icons.check_circle_outline_rounded,
            label: 'Tasks Today',
            value: '${_data.completedToday} / 2',
            color: _green,
          )),
        ],
      ),
    );
  }

  // ─── Points Breakdown ─────────────────────────────────────────────────────
  Widget _buildPointsBreakdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How to Earn Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 14),
          ...[
            ('🧠', 'Wellness Quiz',      WellnessService.pointsQuiz,        _data.taskDone('quiz')),
            ('📓', 'Daily Journal',       WellnessService.pointsJournal,     _data.taskDone('journal')),
            ('🎙️', 'Listen Podcast',     WellnessService.pointsPodcast,     _data.taskDone('podcast')),
            ('🎵', 'Music Session',       WellnessService.pointsMusic,       _data.taskDone('music')),
            ('🎮', 'Mindful Games',       WellnessService.pointsMindGame,    _data.taskDone('game')),
            ('🐝', 'Chat with Hive AI',  WellnessService.pointsAIChat,      _data.taskDone('ai_chat')),
          ].map((e) => _PointsRow(emoji: e.$1, label: e.$2, pts: e.$3, done: e.$4)),
          const Divider(height: 20),
          _PointsRow(emoji: '🔥', label: '7-Day Streak Bonus', pts: WellnessService.pointsStreakBonus, done: false, isBonus: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Card
// ─────────────────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final bool done;
  final VoidCallback onTap;

  const _TaskCard({
    required this.icon, required this.title, required this.subtitle,
    required this.buttonText, required this.done, required this.onTap,
  });

  static const _green = Color(0xFF4A6741);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: done ? Border.all(color: _green.withOpacity(0.3)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: done ? _green.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(done ? Icons.check_circle_rounded : icon,
                color: done ? _green : Colors.grey, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: done ? _green : Colors.grey.shade600, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: done ? Colors.grey.shade100 : _green,
              foregroundColor: done ? Colors.grey : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insight Tile
// ─────────────────────────────────────────────────────────────────────────────
class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Points Row
// ─────────────────────────────────────────────────────────────────────────────
class _PointsRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int pts;
  final bool done;
  final bool isBonus;

  const _PointsRow({
    required this.emoji, required this.label, required this.pts, required this.done,
    this.isBonus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 13, color: done ? Colors.grey : Colors.black87,
                  decoration: done ? TextDecoration.lineThrough : null))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isBonus ? Colors.orange.withOpacity(0.12)
                  : done ? Colors.green.withOpacity(0.1)
                  : const Color(0xFF4A6741).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              done ? '✓ Earned' : '+$pts pts',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: isBonus ? Colors.orange.shade700
                    : done ? Colors.green.shade700
                    : const Color(0xFF4A6741),
              ),
            ),
          ),
        ],
      ),
    );
  }
}