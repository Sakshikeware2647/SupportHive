import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive/hive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Hive storage  (no code-gen needed — stored as plain Map)
//
// Register & open in main.dart BEFORE runApp():
//   await Hive.openBox('breathingSessions');
//
// Each saved record looks like:
//   { 'date': ISO string, 'duration': int seconds,
//     'cycles': int, 'label': '1 min' | '3 min' | 'Free' }
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Session duration options
// ─────────────────────────────────────────────────────────────────────────────
enum SessionDuration {
  one(60, '1 min'),
  three(180, '3 min'),
  free(0, 'Free');

  final int seconds;
  final String label;
  const SessionDuration(this.seconds, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class GuidedBreathingScreen extends StatefulWidget {
  const GuidedBreathingScreen({super.key});

  @override
  State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen>
    with TickerProviderStateMixin {
  // ── Animations ───────────────────────────────────────────
  late AnimationController _breathController;
  late Animation<double> _breathAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late Animation<double> _pulseOpacity;
  late AnimationController _orbitController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _sessionCompleteAnim;
  late Animation<double> _sessionCompleteScale;

  // ── Breathing state ──────────────────────────────────────
  String _phase = 'Inhale';
  int _cycleCount = 0;
  int _seqIndex = 0;
  Timer? _cycleTimer;

  static const _sequence = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  static const _durations = [4, 4, 4, 4];

  // ── Session timer ────────────────────────────────────────
  SessionDuration _selectedDuration = SessionDuration.one;
  int _sessionSecondsLeft = 60;
  int _sessionSecondsTotal = 60;
  int _elapsedSeconds = 0;
  bool _sessionRunning = false;
  bool _sessionComplete = false;
  bool _isPaused = false;
  Timer? _sessionTimer;

  // ── Sound ────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  // ── Vibration ────────────────────────────────────────────
  bool _vibrationEnabled = true;

  // ── Hive tracking ────────────────────────────────────────
  Box? _box;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initHive();
    _initAnimations();
  }

  Future<void> _initHive() async {
    try {
      _box = Hive.isBoxOpen('breathingSessions')
          ? Hive.box('breathingSessions')
          : await Hive.openBox('breathingSessions');
    } catch (_) {}
  }

  void _initAnimations() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnim = Tween<double>(begin: 100, end: 220).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.45,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.45,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _sessionCompleteAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sessionCompleteScale = CurvedAnimation(
      parent: _sessionCompleteAnim,
      curve: Curves.elasticOut,
    );
  }

  // ── Start session ────────────────────────────────────────
  void _startSession() {
    final dur = _selectedDuration;
    setState(() {
      _sessionSecondsTotal = dur.seconds > 0 ? dur.seconds : 999999;
      _sessionSecondsLeft = _sessionSecondsTotal;
      _elapsedSeconds = 0;
      _sessionRunning = true;
      _sessionComplete = false;
      _cycleCount = 0;
      _seqIndex = 0;
      _phase = 'Inhale';
      _isPaused = false;
    });

    _breathController.reset();
    _pulseController.repeat();
    _orbitController.repeat();
    _startBreathingCycle();
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    if (_selectedDuration == SessionDuration.free) {
      // Free mode: just count up elapsed
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isPaused) return;
        setState(() => _elapsedSeconds++);
      });
      return;
    }

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPaused) return;
      setState(() {
        _sessionSecondsLeft--;
        _elapsedSeconds++;
      });
      if (_sessionSecondsLeft <= 0) {
        t.cancel();
        _onSessionComplete();
      }
    });
  }

  void _onSessionComplete() {
    _cycleTimer?.cancel();
    _breathController.stop();
    _pulseController.stop();
    _orbitController.stop();
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
    _saveSession();
    setState(() => _sessionComplete = true);
    _sessionCompleteAnim.forward();
  }

  void _saveSession() {
    try {
      _box?.add({
        'date': DateTime.now().toIso8601String(),
        'duration': _elapsedSeconds,
        'cycles': _cycleCount,
        'label': _selectedDuration.label,
      });
    } catch (_) {}
  }

  void _pauseResume() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _breathController.stop();
      _pulseController.stop();
      _orbitController.stop();
      _cycleTimer?.cancel();
    } else {
      _pulseController.repeat();
      _orbitController.repeat();
      if (_phase == 'Inhale') {
        _breathController.forward();
      } else if (_phase == 'Exhale') {
        _breathController.reverse();
      }
      _scheduleNext();
    }
  }

  void _endSession() {
    _cycleTimer?.cancel();
    _sessionTimer?.cancel();
    if (_elapsedSeconds > 5) _saveSession();
    _breathController.reset();
    _pulseController.repeat();
    _orbitController.repeat();
    setState(() {
      _sessionRunning = false;
      _sessionComplete = false;
      _isPaused = false;
    });
  }

  // ── Breathing cycle ──────────────────────────────────────
  void _startBreathingCycle() {
    _breathController.forward();
    _fadeController.forward();
    _playPhaseSound('Inhale');
    _scheduleNext();
  }

  void _scheduleNext() {
    _cycleTimer = Timer(Duration(seconds: _durations[_seqIndex]), () {
      if (!mounted || _sessionComplete) return;
      _seqIndex = (_seqIndex + 1) % _sequence.length;
      if (_seqIndex == 0) setState(() => _cycleCount++);

      _fadeController.reverse().then((_) {
        if (!mounted || _sessionComplete) return;
        setState(() => _phase = _sequence[_seqIndex]);

        _playPhaseSound(_phase);
        _doPhaseVibration(_phase);

        if (_phase == 'Inhale') {
          _breathController.forward(from: 0);
        } else if (_phase == 'Exhale') {
          _breathController.reverse(from: 1);
        } else {
          _breathController.stop();
        }

        _fadeController.forward();
        _scheduleNext();
      });
    });
  }

  // ── Sound — single meditation tone ───────────────────────
  // Plays on every phase change (Inhale & Exhale). Hold is silent.
  Future<void> _playPhaseSound(String phase) async {
    if (!_soundEnabled) {
      await _player.stop(); // ← stop any currently playing sound
      return;
    }
    // Skip Hold phases — they should be silent
    if ( phase == 'pause') return;
    try {
      await _player.play(AssetSource('audio/breathing_tone.mp3'), volume: 0.6);
    } catch (_) {}
  }

  // ── Vibration ────────────────────────────────────────────
  void _doPhaseVibration(String phase) {
    if (!_vibrationEnabled) return;
    switch (phase) {
      case 'Inhale':
        HapticFeedback.lightImpact();
        break;
      case 'Exhale':
        HapticFeedback.mediumImpact();
        break;
      case 'Hold':
        HapticFeedback.selectionClick();
        break;
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _sessionTimer?.cancel();
    _breathController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _fadeController.dispose();
    _sessionCompleteAnim.dispose();
    _player.dispose();
    super.dispose();
  }

  // ── Phase theming ────────────────────────────────────────
  Color get _phaseColor {
    switch (_phase) {
      case 'Inhale':
        return const Color(0xFF4BFF91);
      case 'Exhale':
        return const Color(0xFF5BC8FF);
      case 'Hold':
        return const Color(0xFFFFB347);
      default:
        return Colors.white;
    }
  }

  Color get _phaseDim {
    switch (_phase) {
      case 'Inhale':
        return const Color(0xFF00C96A);
      case 'Exhale':
        return const Color(0xFF1E90FF);
      case 'Hold':
        return const Color(0xFFFF8C00);
      default:
        return Colors.white38;
    }
  }

  String get _phaseEmoji {
    switch (_phase) {
      case 'Inhale':
        return '🌿';
      case 'Exhale':
        return '💨';
      case 'Hold':
        return '✨';
      default:
        return '';
    }
  }

  double get _sessionProgress {
    if (_selectedDuration == SessionDuration.free) return 0;
    return (_sessionSecondsTotal - _sessionSecondsLeft) /
        _sessionSecondsTotal.toDouble();
  }

  String get _sessionTimeLabel {
    if (_selectedDuration == SessionDuration.free) {
      return _fmtMmSs(_elapsedSeconds);
    }
    return _fmtMmSs(_sessionSecondsLeft);
  }

  String _fmtMmSs(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  List<Map> get _pastSessions {
    if (_box == null) return [];
    return _box!.values.whereType<Map>().toList().reversed.take(10).toList();
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060F0A),
      body: Stack(
        children: [
          // ── Background ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF060F0A),
                  Color(0xFF0A1C13),
                  Color(0xFF0D2318),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Ambient glow ──────────────────────────────────
          if (_sessionRunning)
            AnimatedBuilder(
              animation: _breathAnim,
              builder: (_, __) => Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: _breathAnim.value * 1.8,
                  height: _breathAnim.value * 1.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _phaseColor.withOpacity(0.12),
                        _phaseDim.withOpacity(0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // ── Orbit dots ────────────────────────────────────
          if (_sessionRunning)
            Center(
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (_, __) => SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: _OrbitDotsPainter(
                      progress: _orbitController.value,
                      color: _phaseColor,
                    ),
                  ),
                ),
              ),
            ),

          // ── Pulse ring ────────────────────────────────────
          if (_sessionRunning)
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => AnimatedBuilder(
                  animation: _breathAnim,
                  builder: (_, __) {
                    final base = _breathAnim.value;
                    return Opacity(
                      opacity: _pulseOpacity.value,
                      child: Container(
                        width: base * _pulseAnim.value,
                        height: base * _pulseAnim.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _phaseColor, width: 1.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Main breath circle ────────────────────────────
          if (_sessionRunning)
            Center(
              child: AnimatedBuilder(
                animation: _breathAnim,
                builder: (_, __) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _breathAnim.value,
                  height: _breathAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _phaseColor.withOpacity(0.55),
                        _phaseDim.withOpacity(0.30),
                        _phaseDim.withOpacity(0.08),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    border: Border.all(
                      color: _phaseColor.withOpacity(0.7),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _phaseColor.withOpacity(0.35),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        _phaseEmoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Arc phase label ───────────────────────────────
          if (_sessionRunning)
            Center(
              child: AnimatedBuilder(
                animation: _breathAnim,
                builder: (_, __) {
                  final arcSize = _breathAnim.value + 90;
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: SizedBox(
                      width: arcSize,
                      height: arcSize,
                      child: CustomPaint(
                        painter: _ArcTextPainter(
                          text: _phase.toUpperCase(),
                          color: _phaseColor,
                          radius: (_breathAnim.value / 2) + 38,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Session progress ring ─────────────────────────
          if (_sessionRunning && _selectedDuration != SessionDuration.free)
            Center(
              child: SizedBox(
                width: size.width * 0.82,
                height: size.width * 0.82,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: _sessionProgress,
                    color: _phaseColor,
                  ),
                ),
              ),
            ),

          // ─────────────────────────────────────────────────
          // LAYOUT COLUMN
          // ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      _PremiumIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _ToggleChip(
                        icon: _soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        active: _soundEnabled,
                        onTap: () {
                          setState(() => _soundEnabled = !_soundEnabled);
                          if (!_soundEnabled) _player.stop(); // ← add this
                        },
                      ),
                      const SizedBox(width: 8),
                      _ToggleChip(
                        icon: _vibrationEnabled
                            ? Icons.vibration_rounded
                            : Icons.phonelink_erase_rounded,
                        active: _vibrationEnabled,
                        onTap: () => setState(
                          () => _vibrationEnabled = !_vibrationEnabled,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ToggleChip(
                        icon: Icons.bar_chart_rounded,
                        active: false,
                        onTap: _showHistorySheet,
                      ),
                    ],
                  ),
                ),

                // ── Duration picker (pre-start only) ──────
                if (!_sessionRunning && !_sessionComplete) ...[
                  const SizedBox(height: 20),
                  _DurationPicker(
                    selected: _selectedDuration,
                    onChanged: (d) => setState(() => _selectedDuration = d),
                  ),
                ],

                const Spacer(),

                // breathing circle vertical space
                SizedBox(height: size.height * 0.30),

                // ── Session timer chip (in-session) ───────
                if (_sessionRunning)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _phaseColor.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: _phaseColor.withOpacity(0.7),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _sessionTimeLabel,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: _phaseColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 16,
                            color: Colors.white12,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.loop_rounded,
                            color: _phaseColor.withOpacity(0.6),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$_cycleCount',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: _phaseColor.withOpacity(0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Phase dots ────────────────────────────
                if (_sessionRunning)
                  _PhaseDots(currentIndex: _seqIndex, phaseColor: _phaseColor),

                const SizedBox(height: 24),

                // ── Begin button ──────────────────────────
                if (!_sessionRunning && !_sessionComplete)
                  _StartButton(onTap: _startSession),

                // ── Pause / End buttons ───────────────────
                if (_sessionRunning)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        icon: _isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        label: _isPaused ? 'Resume' : 'Pause',
                        color: _phaseColor,
                        onTap: _pauseResume,
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.stop_rounded,
                        label: 'End',
                        color: Colors.white30,
                        onTap: _endSession,
                      ),
                    ],
                  ),

                const SizedBox(height: 28),
              ],
            ),
          ),

          // ── Session complete overlay ───────────────────────
          if (_sessionComplete)
            Container(
              color: Colors.black.withOpacity(0.65),
              child: Center(
                child: ScaleTransition(
                  scale: _sessionCompleteScale,
                  child: _SessionCompleteCard(
                    durationLabel: _selectedDuration.label,
                    cycles: _cycleCount,
                    elapsed: _elapsedSeconds,
                    onRestart: () {
                      _sessionCompleteAnim.reset();
                      setState(() {
                        _sessionComplete = false;
                        _sessionRunning = false;
                      });
                    },
                    onExit: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(sessions: _pastSessions),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration Picker
// ─────────────────────────────────────────────────────────────────────────────
class _DurationPicker extends StatelessWidget {
  final SessionDuration selected;
  final ValueChanged<SessionDuration> onChanged;
  const _DurationPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: SessionDuration.values.map((d) {
        final active = d == selected;
        return GestureDetector(
          onTap: () => onChanged(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF4BFF91).withOpacity(0.15)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? const Color(0xFF4BFF91).withOpacity(0.55)
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4BFF91).withOpacity(0.15),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: Text(
              d.label,
              style: TextStyle(
                decoration: TextDecoration.none,
                color: active ? const Color(0xFF4BFF91) : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Start Button
// ─────────────────────────────────────────────────────────────────────────────
class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4BFF91), Color(0xFF00C96A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C96A).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Text(
          'Begin',
          textAlign: TextAlign.center,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: Color(0xFF0A1F12),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button (pause / stop)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                decoration: TextDecoration.none,
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle Chip
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? const Color(0xFF4BFF91).withOpacity(0.12)
              : Colors.black.withOpacity(0.3),
          border: Border.all(
            color: active
                ? const Color(0xFF4BFF91).withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? const Color(0xFF4BFF91) : Colors.white30,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session Complete Card
// ─────────────────────────────────────────────────────────────────────────────
class _SessionCompleteCard extends StatelessWidget {
  final String durationLabel;
  final int cycles;
  final int elapsed;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _SessionCompleteCard({
    required this.durationLabel,
    required this.cycles,
    required this.elapsed,
    required this.onRestart,
    required this.onExit,
  });

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m}m ${sec.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2419), Color(0xFF1C4030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF4BFF91).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.65),
            blurRadius: 50,
            spreadRadius: 12,
          ),
          BoxShadow(
            color: const Color(0xFF4BFF91).withOpacity(0.08),
            blurRadius: 35,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧘', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          const Text(
            'SESSION COMPLETE',
            style: TextStyle(
              decoration: TextDecoration.none,
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          _divider(),
          const SizedBox(height: 16),
          _StatRow(
            label: 'DURATION',
            value: _fmt(elapsed),
            color: const Color(0xFF4BFF91),
          ),
          const SizedBox(height: 10),
          _StatRow(
            label: 'CYCLES',
            value: '$cycles',
            color: const Color(0xFF7DF9C8),
          ),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _GoldButton(
                  label: '🔁  Again',
                  onTap: onRestart,
                  primary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GoldButton(
                  label: '🚪  Exit',
                  onTap: onExit,
                  primary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.15),
          Colors.transparent,
        ],
      ),
    ),
  );
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: color.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _GoldButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFF4BFF91), Color(0xFF00C96A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary ? Colors.transparent : Colors.white.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C96A).withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            decoration: TextDecoration.none,
            color: primary ? const Color(0xFF0A1F12) : Colors.white60,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _HistorySheet extends StatelessWidget {
  final List<Map> sessions;
  const _HistorySheet({required this.sessions});

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    if (m == 0) return '${sec}s';
    return '${m}m ${sec.toString().padLeft(2, '0')}s';
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final now = DateTime.now();
      final isToday =
          d.day == now.day && d.month == now.month && d.year == now.year;
      final time =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      return isToday ? 'Today  $time' : '${d.day}/${d.month}  $time';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2419), Color(0xFF0A1810)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'SESSION HISTORY',
            style: TextStyle(
              decoration: TextDecoration.none,
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 14),

          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No sessions yet.\nComplete your first one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.white24,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ),
            )
          else
            ...sessions.map((s) {
              final date = s['date'] as String? ?? '';
              final dur = s['duration'] as int? ?? 0;
              final cycles = s['cycles'] as int? ?? 0;
              final label = s['label'] as String? ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.07),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4BFF91).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF4BFF91).withOpacity(0.25),
                        ),
                      ),
                      child: const Center(
                        child: Text('🧘', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$label · ${_fmt(dur)}',
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtDate(date),
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$cycles',
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            color: Color(0xFF4BFF91),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text(
                          'cycles',
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.white24,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session progress ring painter
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Orbit dots painter
// ─────────────────────────────────────────────────────────────────────────────
class _OrbitDotsPainter extends CustomPainter {
  final double progress;
  final Color color;
  _OrbitDotsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    for (int i = 0; i < 8; i++) {
      final angle = (2 * pi / 8) * i + (2 * pi * progress);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      final opacity = (sin(angle - pi / 2) * 0.5 + 0.5) * 0.6 + 0.1;
      final radius = (sin(angle - pi / 2) * 0.5 + 0.5) * 2.5 + 1.5;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withOpacity(opacity.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitDotsPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase progress dots
// ─────────────────────────────────────────────────────────────────────────────
class _PhaseDots extends StatelessWidget {
  final int currentIndex;
  final Color phaseColor;
  const _PhaseDots({required this.currentIndex, required this.phaseColor});

  static const _labels = ['Inhale', 'Hold', 'Exhale', 'Hold'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: active ? 28 : 8,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? phaseColor : Colors.white.withOpacity(0.18),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: phaseColor.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(height: 5),
              if (active)
                Text(
                  _labels[i],
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: phaseColor.withOpacity(0.65),
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium icon button
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PremiumIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white60, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arc text painter
// ─────────────────────────────────────────────────────────────────────────────
class _ArcTextPainter extends CustomPainter {
  final String text;
  final Color color;
  final double radius;
  _ArcTextPainter({
    required this.text,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final style = TextStyle(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
      decoration: TextDecoration.none,
    );

    final painters = text.characters.map((ch) {
      final tp = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    }).toList();

    final charAngles = painters.map((tp) => tp.width / radius).toList();
    final totalAngle =
        charAngles.fold(0.0, (a, b) => a + b) +
        (text.length - 1) * (2.5 / radius);

    double angle = -pi / 2 - totalAngle / 2;

    for (int i = 0; i < painters.length; i++) {
      final tp = painters[i];
      final halfChar = charAngles[i] / 2;
      angle += halfChar;
      canvas.save();
      canvas.translate(cx + radius * cos(angle), cy + radius * sin(angle));
      canvas.rotate(angle + pi / 2);
      canvas.translate(-tp.width / 2, -tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
      angle += halfChar + 2.5 / radius;
    }
  }

  @override
  bool shouldRepaint(_ArcTextPainter old) =>
      old.text != text || old.color != color || old.radius != radius;
}






// import 'dart:async';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:hive/hive.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // Hive storage  (no code-gen needed — stored as plain Map)
// //
// // Register & open in main.dart BEFORE runApp():
// //   await Hive.openBox('breathingSessions');
// //
// // Each saved record looks like:
// //   { 'date': ISO string, 'duration': int seconds,
// //     'cycles': int, 'label': '1 min' | '3 min' | 'Free' }
// // ─────────────────────────────────────────────────────────────────────────────

// // ─────────────────────────────────────────────────────────────────────────────
// // Session duration options
// // ─────────────────────────────────────────────────────────────────────────────
// enum SessionDuration {
//   one(60,  '1 min'),
//   three(180, '3 min'),
//   free(0,   'Free');

//   final int seconds;
//   final String label;
//   const SessionDuration(this.seconds, this.label);
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Screen
// // ─────────────────────────────────────────────────────────────────────────────
// class GuidedBreathingScreen extends StatefulWidget {
//   const GuidedBreathingScreen({super.key});

//   @override
//   State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
// }

// class _GuidedBreathingScreenState extends State<GuidedBreathingScreen>
//     with TickerProviderStateMixin {

//   // ── Animations ───────────────────────────────────────────
//   late AnimationController _breathController;
//   late Animation<double>   _breathAnim;
//   late AnimationController _pulseController;
//   late Animation<double>   _pulseAnim;
//   late Animation<double>   _pulseOpacity;
//   late AnimationController _orbitController;
//   late AnimationController _fadeController;
//   late Animation<double>   _fadeAnim;
//   late AnimationController _sessionCompleteAnim;
//   late Animation<double>   _sessionCompleteScale;

//   // ── Breathing state ──────────────────────────────────────
//   String _phase      = 'Inhale';
//   int    _cycleCount = 0;
//   int    _seqIndex   = 0;
//   Timer? _cycleTimer;

//   static const _sequence  = ['Inhale', 'Hold', 'Exhale', 'Hold'];
//   static const _durations = [4, 4, 4, 4];

//   // ── Session timer ────────────────────────────────────────
//   SessionDuration _selectedDuration  = SessionDuration.one;
//   int  _sessionSecondsLeft  = 60;
//   int  _sessionSecondsTotal = 60;
//   int  _elapsedSeconds      = 0;
//   bool _sessionRunning      = false;
//   bool _sessionComplete     = false;
//   bool _isPaused            = false;
//   Timer? _sessionTimer;

//   // ── Sound ────────────────────────────────────────────────
//   final AudioPlayer _player = AudioPlayer();
//   bool _soundEnabled     = true;

//   // ── Vibration ────────────────────────────────────────────
//   bool _vibrationEnabled = true;

//   // ── Hive tracking ────────────────────────────────────────
//   Box? _box;

//   // ─────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     _initHive();
//     _initAnimations();
//   }

//   Future<void> _initHive() async {
//     try {
//       _box = Hive.isBoxOpen('breathingSessions')
//           ? Hive.box('breathingSessions')
//           : await Hive.openBox('breathingSessions');
//     } catch (_) {}
//   }

//   void _initAnimations() {
//     _breathController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 4),
//     );
//     _breathAnim = Tween<double>(begin: 100, end: 220).animate(
//       CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
//     );

//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat();
//     _pulseAnim = Tween<double>(begin: 1.0, end: 1.45).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
//     );
//     _pulseOpacity = Tween<double>(begin: 0.45, end: 0.0).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
//     );

//     _orbitController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 12),
//     )..repeat();

//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );
//     _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

//     _sessionCompleteAnim = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _sessionCompleteScale = CurvedAnimation(
//       parent: _sessionCompleteAnim,
//       curve: Curves.elasticOut,
//     );
//   }

//   // ── Start session ────────────────────────────────────────
//   void _startSession() {
//     final dur = _selectedDuration;
//     setState(() {
//       _sessionSecondsTotal = dur.seconds > 0 ? dur.seconds : 999999;
//       _sessionSecondsLeft  = _sessionSecondsTotal;
//       _elapsedSeconds      = 0;
//       _sessionRunning      = true;
//       _sessionComplete     = false;
//       _cycleCount          = 0;
//       _seqIndex            = 0;
//       _phase               = 'Inhale';
//       _isPaused            = false;
//     });

//     _breathController.reset();
//     _pulseController.repeat();
//     _orbitController.repeat();
//     _startBreathingCycle();
//     _startSessionTimer();
//   }

//   void _startSessionTimer() {
//     _sessionTimer?.cancel();
//     if (_selectedDuration == SessionDuration.free) {
//       // Free mode: just count up elapsed
//       _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//         if (_isPaused) return;
//         setState(() => _elapsedSeconds++);
//       });
//       return;
//     }

//     _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (_isPaused) return;
//       setState(() {
//         _sessionSecondsLeft--;
//         _elapsedSeconds++;
//       });
//       if (_sessionSecondsLeft <= 0) {
//         t.cancel();
//         _onSessionComplete();
//       }
//     });
//   }

//   void _onSessionComplete() {
//     _cycleTimer?.cancel();
//     _breathController.stop();
//     _pulseController.stop();
//     _orbitController.stop();
//     if (_vibrationEnabled) HapticFeedback.heavyImpact();
//     _saveSession();
//     setState(() => _sessionComplete = true);
//     _sessionCompleteAnim.forward();
//   }

//   void _saveSession() {
//     try {
//       _box?.add({
//         'date':     DateTime.now().toIso8601String(),
//         'duration': _elapsedSeconds,
//         'cycles':   _cycleCount,
//         'label':    _selectedDuration.label,
//       });
//     } catch (_) {}
//   }

//   void _pauseResume() {
//     setState(() => _isPaused = !_isPaused);
//     if (_isPaused) {
//       _breathController.stop();
//       _pulseController.stop();
//       _orbitController.stop();
//       _cycleTimer?.cancel();
//     } else {
//       _pulseController.repeat();
//       _orbitController.repeat();
//       if (_phase == 'Inhale') {
//         _breathController.forward();
//       } else if (_phase == 'Exhale') {
//         _breathController.reverse();
//       }
//       _scheduleNext();
//     }
//   }

//   void _endSession() {
//     _cycleTimer?.cancel();
//     _sessionTimer?.cancel();
//     if (_elapsedSeconds > 5) _saveSession();
//     _breathController.reset();
//     _pulseController.repeat();
//     _orbitController.repeat();
//     setState(() {
//       _sessionRunning  = false;
//       _sessionComplete = false;
//       _isPaused        = false;
//     });
//   }

//   // ── Breathing cycle ──────────────────────────────────────
//   void _startBreathingCycle() {
//     _breathController.forward();
//     _fadeController.forward();
//     _playPhaseSound('Inhale');
//     _scheduleNext();
//   }

//   void _scheduleNext() {
//     _cycleTimer = Timer(Duration(seconds: _durations[_seqIndex]), () {
//       if (!mounted || _sessionComplete) return;
//       _seqIndex = (_seqIndex + 1) % _sequence.length;
//       if (_seqIndex == 0) setState(() => _cycleCount++);

//       _fadeController.reverse().then((_) {
//         if (!mounted || _sessionComplete) return;
//         setState(() => _phase = _sequence[_seqIndex]);

//         _playPhaseSound(_phase);
//         _doPhaseVibration(_phase);

//         if (_phase == 'Inhale') {
//           _breathController.forward(from: 0);
//         } else if (_phase == 'Exhale') {
//           _breathController.reverse(from: 1);
//         } else {
//           _breathController.stop();
//         }

//         _fadeController.forward();
//         _scheduleNext();
//       });
//     });
//   }

//   // ── Sound — pure sine tone, no asset files needed ────────
//   // Generates a short WAV in memory and plays via audioplayers BytesSource.
//   // Inhale → rising pitch (440 → 528 Hz), Exhale → falling (528 → 440 Hz).
//   // Hold → silence (intentional).
//   Future<void> _playPhaseSound(String phase) async {
//     if (!_soundEnabled) return;
//     if (phase == 'Hold') return;
//     try {
//       final bool rising = phase == 'Inhale';
//       final bytes = _buildToneWav(
//         fromHz: rising ? 440.0 : 528.0,
//         toHz:   rising ? 528.0 : 440.0,
//         durationMs: 500,
//         volume: 0.45,
//       );
//       await _player.play(BytesSource(bytes), volume: 1.0);
//     } catch (_) {}
//   }

//   /// Builds a 16-bit PCM WAV with a sine sweep from [fromHz] to [toHz].
//   /// The amplitude is faded in/out with a short linear ramp to avoid clicks.
//   Uint8List _buildToneWav({
//     required double fromHz,
//     required double toHz,
//     required int durationMs,
//     required double volume,
//   }) {
//     const sampleRate = 44100;
//     final numSamples = (sampleRate * durationMs / 1000).round();
//     final rampSamples = (sampleRate * 0.04).round(); // 40 ms fade in/out

//     final pcm = Int16List(numSamples);
//     double phase = 0.0;

//     for (int i = 0; i < numSamples; i++) {
//       final t = i / numSamples;
//       final freq = fromHz + (toHz - fromHz) * t;

//       // Amplitude envelope: ramp up → sustain → ramp down
//       double env = 1.0;
//       if (i < rampSamples) {
//         env = i / rampSamples;
//       } else if (i > numSamples - rampSamples) {
//         env = (numSamples - i) / rampSamples;
//       }

//       pcm[i] = (sin(phase) * env * volume * 32767).round().clamp(-32768, 32767);
//       phase += 2 * pi * freq / sampleRate;
//     }

//     return _wrapWav(pcm, sampleRate);
//   }

//   /// Wraps raw Int16 PCM samples in a minimal WAV header.
//   Uint8List _wrapWav(Int16List pcm, int sampleRate) {
//     final dataBytes  = pcm.buffer.asUint8List();
//     final fileSize   = 36 + dataBytes.length;
//     final byteRate   = sampleRate * 2; // 1 channel × 2 bytes/sample
//     final buf        = ByteData(44 + dataBytes.length);
//     int o = 0;

//     void str(String s) { for (final c in s.codeUnits) buf.setUint8(o++, c); }
//     void u16(int v)    { buf.setUint16(o, v, Endian.little); o += 2; }
//     void u32(int v)    { buf.setUint32(o, v, Endian.little); o += 4; }

//     str('RIFF'); u32(fileSize); str('WAVE');
//     str('fmt '); u32(16);       // chunk size
//     u16(1);                     // PCM
//     u16(1);                     // mono
//     u32(sampleRate);
//     u32(byteRate);
//     u16(2);                     // block align
//     u16(16);                    // bits per sample
//     str('data'); u32(dataBytes.length);

//     final out = buf.buffer.asUint8List();
//     out.setRange(44, out.length, dataBytes);
//     return out;
//   }

//   // ── Vibration ────────────────────────────────────────────
//   void _doPhaseVibration(String phase) {
//     if (!_vibrationEnabled) return;
//     switch (phase) {
//       case 'Inhale': HapticFeedback.lightImpact();    break;
//       case 'Exhale': HapticFeedback.mediumImpact();   break;
//       case 'Hold':   HapticFeedback.selectionClick(); break;
//     }
//   }

//   @override
//   void dispose() {
//     _cycleTimer?.cancel();
//     _sessionTimer?.cancel();
//     _breathController.dispose();
//     _pulseController.dispose();
//     _orbitController.dispose();
//     _fadeController.dispose();
//     _sessionCompleteAnim.dispose();
//     _player.dispose();
//     super.dispose();
//   }

//   // ── Phase theming ────────────────────────────────────────
//   Color get _phaseColor {
//     switch (_phase) {
//       case 'Inhale': return const Color(0xFF4BFF91);
//       case 'Exhale': return const Color(0xFF5BC8FF);
//       case 'Hold':   return const Color(0xFFFFB347);
//       default:       return Colors.white;
//     }
//   }

//   Color get _phaseDim {
//     switch (_phase) {
//       case 'Inhale': return const Color(0xFF00C96A);
//       case 'Exhale': return const Color(0xFF1E90FF);
//       case 'Hold':   return const Color(0xFFFF8C00);
//       default:       return Colors.white38;
//     }
//   }

//   String get _phaseEmoji {
//     switch (_phase) {
//       case 'Inhale': return '🌿';
//       case 'Exhale': return '💨';
//       case 'Hold':   return '✨';
//       default:       return '';
//     }
//   }

//   double get _sessionProgress {
//     if (_selectedDuration == SessionDuration.free) return 0;
//     return (_sessionSecondsTotal - _sessionSecondsLeft) /
//         _sessionSecondsTotal.toDouble();
//   }

//   String get _sessionTimeLabel {
//     if (_selectedDuration == SessionDuration.free) {
//       return _fmtMmSs(_elapsedSeconds);
//     }
//     return _fmtMmSs(_sessionSecondsLeft);
//   }

//   String _fmtMmSs(int s) {
//     final m = s ~/ 60;
//     final sec = s % 60;
//     return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
//   }

//   List<Map> get _pastSessions {
//     if (_box == null) return [];
//     return _box!.values
//         .whereType<Map>()
//         .toList()
//         .reversed
//         .take(10)
//         .toList();
//   }

//   // ─────────────────────────────────────────────────────────
//   // BUILD
//   // ─────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: const Color(0xFF060F0A),
//       body: Stack(
//         children: [

//           // ── Background ────────────────────────────────────
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF060F0A),
//                   Color(0xFF0A1C13),
//                   Color(0xFF0D2318),
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),

//           // ── Ambient glow ──────────────────────────────────
//           if (_sessionRunning)
//             AnimatedBuilder(
//               animation: _breathAnim,
//               builder: (_, __) => Center(
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 600),
//                   width:  _breathAnim.value * 1.8,
//                   height: _breathAnim.value * 1.8,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: RadialGradient(
//                       colors: [
//                         _phaseColor.withOpacity(0.12),
//                         _phaseDim.withOpacity(0.04),
//                         Colors.transparent,
//                       ],
//                       stops: const [0.0, 0.5, 1.0],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // ── Orbit dots ────────────────────────────────────
//           if (_sessionRunning)
//             Center(
//               child: AnimatedBuilder(
//                 animation: _orbitController,
//                 builder: (_, __) => SizedBox(
//                   width: 300, height: 300,
//                   child: CustomPaint(
//                     painter: _OrbitDotsPainter(
//                       progress: _orbitController.value,
//                       color: _phaseColor,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // ── Pulse ring ────────────────────────────────────
//           if (_sessionRunning)
//             Center(
//               child: AnimatedBuilder(
//                 animation: _pulseController,
//                 builder: (_, __) => AnimatedBuilder(
//                   animation: _breathAnim,
//                   builder: (_, __) {
//                     final base = _breathAnim.value;
//                     return Opacity(
//                       opacity: _pulseOpacity.value,
//                       child: Container(
//                         width:  base * _pulseAnim.value,
//                         height: base * _pulseAnim.value,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           border: Border.all(color: _phaseColor, width: 1.5),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),

//           // ── Main breath circle ────────────────────────────
//           if (_sessionRunning)
//             Center(
//               child: AnimatedBuilder(
//                 animation: _breathAnim,
//                 builder: (_, __) => AnimatedContainer(
//                   duration: const Duration(milliseconds: 300),
//                   width:  _breathAnim.value,
//                   height: _breathAnim.value,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: RadialGradient(
//                       colors: [
//                         _phaseColor.withOpacity(0.55),
//                         _phaseDim.withOpacity(0.30),
//                         _phaseDim.withOpacity(0.08),
//                       ],
//                       stops: const [0.0, 0.6, 1.0],
//                     ),
//                     border: Border.all(
//                         color: _phaseColor.withOpacity(0.7), width: 2),
//                     boxShadow: [
//                       BoxShadow(
//                         color: _phaseColor.withOpacity(0.35),
//                         blurRadius: 40,
//                         spreadRadius: 8,
//                       ),
//                     ],
//                   ),
//                   child: Center(
//                     child: FadeTransition(
//                       opacity: _fadeAnim,
//                       child: Text(_phaseEmoji,
//                           style: const TextStyle(fontSize: 36)),
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // ── Arc phase label ───────────────────────────────
//           if (_sessionRunning)
//             Center(
//               child: AnimatedBuilder(
//                 animation: _breathAnim,
//                 builder: (_, __) {
//                   final arcSize = _breathAnim.value + 90;
//                   return FadeTransition(
//                     opacity: _fadeAnim,
//                     child: SizedBox(
//                       width: arcSize, height: arcSize,
//                       child: CustomPaint(
//                         painter: _ArcTextPainter(
//                           text: _phase.toUpperCase(),
//                           color: _phaseColor,
//                           radius: (_breathAnim.value / 2) + 38,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),

//           // ── Session progress ring ─────────────────────────
//           if (_sessionRunning && _selectedDuration != SessionDuration.free)
//             Center(
//               child: SizedBox(
//                 width: size.width * 0.82,
//                 height: size.width * 0.82,
//                 child: CustomPaint(
//                   painter: _ProgressRingPainter(
//                     progress: _sessionProgress,
//                     color: _phaseColor,
//                   ),
//                 ),
//               ),
//             ),

//           // ─────────────────────────────────────────────────
//           // LAYOUT COLUMN
//           // ─────────────────────────────────────────────────
//           SafeArea(
//             child: Column(
//               children: [

//                 // ── Top bar ───────────────────────────────
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
//                   child: Row(
//                     children: [
//                       _PremiumIconButton(
//                         icon: Icons.arrow_back_ios_new_rounded,
//                         onTap: () => Navigator.pop(context),
//                       ),
//                       const Spacer(),
//                       _ToggleChip(
//                         icon: _soundEnabled
//                             ? Icons.volume_up_rounded
//                             : Icons.volume_off_rounded,
//                         active: _soundEnabled,
//                         onTap: () =>
//                             setState(() => _soundEnabled = !_soundEnabled),
//                       ),
//                       const SizedBox(width: 8),
//                       _ToggleChip(
//                         icon: _vibrationEnabled
//                             ? Icons.vibration_rounded
//                             : Icons.phonelink_erase_rounded,
//                         active: _vibrationEnabled,
//                         onTap: () => setState(
//                             () => _vibrationEnabled = !_vibrationEnabled),
//                       ),
//                       const SizedBox(width: 8),
//                       _ToggleChip(
//                         icon: Icons.bar_chart_rounded,
//                         active: false,
//                         onTap: _showHistorySheet,
//                       ),
//                     ],
//                   ),
//                 ),

//                 // ── Duration picker (pre-start only) ──────
//                 if (!_sessionRunning && !_sessionComplete) ...[
//                   const SizedBox(height: 20),
//                   _DurationPicker(
//                     selected: _selectedDuration,
//                     onChanged: (d) => setState(() => _selectedDuration = d),
//                   ),
//                 ],

//                 const Spacer(),

//                 // breathing circle vertical space
//                 SizedBox(height: size.height * 0.30),

//                 // ── Session timer chip (in-session) ───────
//                 if (_sessionRunning)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 16),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 20, vertical: 10),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.35),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: _phaseColor.withOpacity(0.25),
//                           width: 1,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.timer_outlined,
//                               color: _phaseColor.withOpacity(0.7), size: 14),
//                           const SizedBox(width: 8),
//                           Text(
//                             _sessionTimeLabel,
//                             style: TextStyle(
//                               decoration: TextDecoration.none,
//                               color: _phaseColor,
//                               fontSize: 22,
//                               fontWeight: FontWeight.w900,
//                               fontFamily: 'monospace',
//                               letterSpacing: 2,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Container(
//                               width: 1, height: 16, color: Colors.white12),
//                           const SizedBox(width: 12),
//                           Icon(Icons.loop_rounded,
//                               color: _phaseColor.withOpacity(0.6), size: 13),
//                           const SizedBox(width: 5),
//                           Text(
//                             '$_cycleCount',
//                             style: TextStyle(
//                               decoration: TextDecoration.none,
//                               color: _phaseColor.withOpacity(0.8),
//                               fontSize: 15,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                 // ── Phase dots ────────────────────────────
//                 if (_sessionRunning)
//                   _PhaseDots(
//                     currentIndex: _seqIndex,
//                     phaseColor: _phaseColor,
//                   ),

//                 const SizedBox(height: 24),

//                 // ── Begin button ──────────────────────────
//                 if (!_sessionRunning && !_sessionComplete)
//                   _StartButton(onTap: _startSession),

//                 // ── Pause / End buttons ───────────────────
//                 if (_sessionRunning)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       _ActionButton(
//                         icon: _isPaused
//                             ? Icons.play_arrow_rounded
//                             : Icons.pause_rounded,
//                         label: _isPaused ? 'Resume' : 'Pause',
//                         color: _phaseColor,
//                         onTap: _pauseResume,
//                       ),
//                       const SizedBox(width: 16),
//                       _ActionButton(
//                         icon: Icons.stop_rounded,
//                         label: 'End',
//                         color: Colors.white30,
//                         onTap: _endSession,
//                       ),
//                     ],
//                   ),

//                 const SizedBox(height: 28),
//               ],
//             ),
//           ),

//           // ── Session complete overlay ───────────────────────
//           if (_sessionComplete)
//             Container(
//               color: Colors.black.withOpacity(0.65),
//               child: Center(
//                 child: ScaleTransition(
//                   scale: _sessionCompleteScale,
//                   child: _SessionCompleteCard(
//                     durationLabel: _selectedDuration.label,
//                     cycles: _cycleCount,
//                     elapsed: _elapsedSeconds,
//                     onRestart: () {
//                       _sessionCompleteAnim.reset();
//                       setState(() {
//                         _sessionComplete = false;
//                         _sessionRunning  = false;
//                       });
//                     },
//                     onExit: () => Navigator.pop(context),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _showHistorySheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _HistorySheet(sessions: _pastSessions),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Duration Picker
// // ─────────────────────────────────────────────────────────────────────────────
// class _DurationPicker extends StatelessWidget {
//   final SessionDuration selected;
//   final ValueChanged<SessionDuration> onChanged;
//   const _DurationPicker({required this.selected, required this.onChanged});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: SessionDuration.values.map((d) {
//         final active = d == selected;
//         return GestureDetector(
//           onTap: () => onChanged(d),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 250),
//             margin: const EdgeInsets.symmetric(horizontal: 6),
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             decoration: BoxDecoration(
//               color: active
//                   ? const Color(0xFF4BFF91).withOpacity(0.15)
//                   : Colors.white.withOpacity(0.04),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(
//                 color: active
//                     ? const Color(0xFF4BFF91).withOpacity(0.55)
//                     : Colors.white.withOpacity(0.1),
//                 width: 1.5,
//               ),
//               boxShadow: active
//                   ? [
//                       BoxShadow(
//                         color: const Color(0xFF4BFF91).withOpacity(0.15),
//                         blurRadius: 12,
//                       )
//                     ]
//                   : [],
//             ),
//             child: Text(
//               d.label,
//               style: TextStyle(
//                 decoration: TextDecoration.none,
//                 color: active ? const Color(0xFF4BFF91) : Colors.white38,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w800,
//                 letterSpacing: 0.5,
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Start Button
// // ─────────────────────────────────────────────────────────────────────────────
// class _StartButton extends StatelessWidget {
//   final VoidCallback onTap;
//   const _StartButton({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 160,
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Color(0xFF4BFF91), Color(0xFF00C96A)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF00C96A).withOpacity(0.45),
//               blurRadius: 24,
//               offset: const Offset(0, 6),
//             ),
//           ],
//         ),
//         child: const Text(
//           'Begin',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             decoration: TextDecoration.none,
//             color: Color(0xFF0A1F12),
//             fontSize: 16,
//             fontWeight: FontWeight.w900,
//             letterSpacing: 1.5,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Action Button (pause / stop)
// // ─────────────────────────────────────────────────────────────────────────────
// class _ActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//   const _ActionButton({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.35),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: color.withOpacity(0.3), width: 1.2),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: color, size: 16),
//             const SizedBox(width: 7),
//             Text(
//               label,
//               style: TextStyle(
//                 decoration: TextDecoration.none,
//                 color: color,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Toggle Chip
// // ─────────────────────────────────────────────────────────────────────────────
// class _ToggleChip extends StatelessWidget {
//   final IconData icon;
//   final bool active;
//   final VoidCallback onTap;
//   const _ToggleChip(
//       {required this.icon, required this.active, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 38, height: 38,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: active
//               ? const Color(0xFF4BFF91).withOpacity(0.12)
//               : Colors.black.withOpacity(0.3),
//           border: Border.all(
//             color: active
//                 ? const Color(0xFF4BFF91).withOpacity(0.4)
//                 : Colors.white.withOpacity(0.1),
//             width: 1.2,
//           ),
//         ),
//         child: Icon(icon, size: 16,
//             color: active ? const Color(0xFF4BFF91) : Colors.white30),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Session Complete Card
// // ─────────────────────────────────────────────────────────────────────────────
// class _SessionCompleteCard extends StatelessWidget {
//   final String durationLabel;
//   final int cycles;
//   final int elapsed;
//   final VoidCallback onRestart;
//   final VoidCallback onExit;

//   const _SessionCompleteCard({
//     required this.durationLabel,
//     required this.cycles,
//     required this.elapsed,
//     required this.onRestart,
//     required this.onExit,
//   });

//   String _fmt(int s) {
//     final m = s ~/ 60;
//     final sec = s % 60;
//     return '${m}m ${sec.toString().padLeft(2, '0')}s';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 310,
//       padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF0F2419), Color(0xFF1C4030)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(
//           color: const Color(0xFF4BFF91).withOpacity(0.3),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.65),
//               blurRadius: 50,
//               spreadRadius: 12),
//           BoxShadow(
//               color: const Color(0xFF4BFF91).withOpacity(0.08),
//               blurRadius: 35,
//               spreadRadius: 4),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text('🧘', style: TextStyle(fontSize: 52)),
//           const SizedBox(height: 10),
//           const Text(
//             'SESSION COMPLETE',
//             style: TextStyle(
//               decoration: TextDecoration.none,
//               color: Colors.white,
//               fontSize: 17,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 3,
//             ),
//           ),
//           const SizedBox(height: 20),
//           _divider(),
//           const SizedBox(height: 16),
//           _StatRow(label: 'DURATION', value: _fmt(elapsed),
//               color: const Color(0xFF4BFF91)),
//           const SizedBox(height: 10),
//           _StatRow(label: 'CYCLES', value: '$cycles',
//               color: const Color(0xFF7DF9C8)),
//           const SizedBox(height: 16),
//           _divider(),
//           const SizedBox(height: 22),
//           Row(
//             children: [
//               Expanded(
//                   child: _GoldButton(
//                       label: '🔁  Again',
//                       onTap: onRestart,
//                       primary: true)),
//               const SizedBox(width: 10),
//               Expanded(
//                   child: _GoldButton(
//                       label: '🚪  Exit',
//                       onTap: onExit,
//                       primary: false)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _divider() => Container(
//         height: 1,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(colors: [
//             Colors.transparent,
//             Colors.white.withOpacity(0.15),
//             Colors.transparent,
//           ]),
//         ),
//       );
// }

// class _StatRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final Color color;
//   const _StatRow(
//       {required this.label, required this.value, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(label,
//             style: TextStyle(
//               decoration: TextDecoration.none,
//               color: color.withOpacity(0.55),
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 2.5,
//             )),
//         Text(value,
//             style: TextStyle(
//               decoration: TextDecoration.none,
//               color: color,
//               fontSize: 24,
//               fontWeight: FontWeight.w900,
//               fontFamily: 'monospace',
//             )),
//       ],
//     );
//   }
// }

// class _GoldButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;
//   final bool primary;
//   const _GoldButton(
//       {required this.label, required this.onTap, required this.primary});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         decoration: BoxDecoration(
//           gradient: primary
//               ? const LinearGradient(
//                   colors: [Color(0xFF4BFF91), Color(0xFF00C96A)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 )
//               : null,
//           color: primary ? null : Colors.white.withOpacity(0.07),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color:
//                 primary ? Colors.transparent : Colors.white.withOpacity(0.2),
//             width: 1.2,
//           ),
//           boxShadow: primary
//               ? [
//                   BoxShadow(
//                     color: const Color(0xFF00C96A).withOpacity(0.4),
//                     blurRadius: 18,
//                     offset: const Offset(0, 4),
//                   )
//                 ]
//               : [],
//         ),
//         child: Text(
//           label,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             decoration: TextDecoration.none,
//             color: primary ? const Color(0xFF0A1F12) : Colors.white60,
//             fontWeight: FontWeight.w800,
//             fontSize: 13,
//             letterSpacing: 0.5,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // History Bottom Sheet
// // ─────────────────────────────────────────────────────────────────────────────
// class _HistorySheet extends StatelessWidget {
//   final List<Map> sessions;
//   const _HistorySheet({required this.sessions});

//   String _fmt(int s) {
//     final m = s ~/ 60;
//     final sec = s % 60;
//     if (m == 0) return '${sec}s';
//     return '${m}m ${sec.toString().padLeft(2, '0')}s';
//   }

//   String _fmtDate(String iso) {
//     try {
//       final d   = DateTime.parse(iso);
//       final now = DateTime.now();
//       final isToday = d.day == now.day &&
//           d.month == now.month &&
//           d.year == now.year;
//       final time =
//           '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
//       return isToday ? 'Today  $time' : '${d.day}/${d.month}  $time';
//     } catch (_) {
//       return '—';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF0F2419), Color(0xFF0A1810)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Container(
//               width: 40, height: 4,
//               margin: const EdgeInsets.only(bottom: 18),
//               decoration: BoxDecoration(
//                 color: Colors.white24,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           const Text(
//             'SESSION HISTORY',
//             style: TextStyle(
//               decoration: TextDecoration.none,
//               color: Colors.white38,
//               fontSize: 11,
//               fontWeight: FontWeight.w800,
//               letterSpacing: 3,
//             ),
//           ),
//           const SizedBox(height: 14),

//           if (sessions.isEmpty)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 28),
//               child: Center(
//                 child: Text(
//                   'No sessions yet.\nComplete your first one!',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     decoration: TextDecoration.none,
//                     color: Colors.white24,
//                     fontSize: 14,
//                     height: 1.7,
//                   ),
//                 ),
//               ),
//             )
//           else
//             ...sessions.map((s) {
//               final date   = s['date']     as String? ?? '';
//               final dur    = s['duration'] as int?    ?? 0;
//               final cycles = s['cycles']   as int?    ?? 0;
//               final label  = s['label']    as String? ?? '';
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 10),
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 16, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.04),
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.07),
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 36, height: 36,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: const Color(0xFF4BFF91).withOpacity(0.1),
//                         border: Border.all(
//                           color: const Color(0xFF4BFF91).withOpacity(0.25),
//                         ),
//                       ),
//                       child: const Center(
//                           child: Text('🧘',
//                               style: TextStyle(fontSize: 16))),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '$label · ${_fmt(dur)}',
//                             style: const TextStyle(
//                               decoration: TextDecoration.none,
//                               color: Colors.white,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             _fmtDate(date),
//                             style: const TextStyle(
//                               decoration: TextDecoration.none,
//                               color: Colors.white38,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           '$cycles',
//                           style: const TextStyle(
//                             decoration: TextDecoration.none,
//                             color: Color(0xFF4BFF91),
//                             fontSize: 18,
//                             fontWeight: FontWeight.w900,
//                             fontFamily: 'monospace',
//                           ),
//                         ),
//                         const Text(
//                           'cycles',
//                           style: TextStyle(
//                             decoration: TextDecoration.none,
//                             color: Colors.white24,
//                             fontSize: 10,
//                             letterSpacing: 1,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             }),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Session progress ring painter
// // ─────────────────────────────────────────────────────────────────────────────
// class _ProgressRingPainter extends CustomPainter {
//   final double progress;
//   final Color  color;
//   _ProgressRingPainter({required this.progress, required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final cx = size.width  / 2;
//     final cy = size.height / 2;
//     final r  = size.width  / 2 - 4;

//     canvas.drawCircle(Offset(cx, cy), r,
//         Paint()
//           ..color       = Colors.white.withOpacity(0.05)
//           ..style       = PaintingStyle.stroke
//           ..strokeWidth = 2);

//     if (progress > 0) {
//       canvas.drawArc(
//         Rect.fromCircle(center: Offset(cx, cy), radius: r),
//         -pi / 2,
//         2 * pi * progress,
//         false,
//         Paint()
//           ..color       = color.withOpacity(0.55)
//           ..style       = PaintingStyle.stroke
//           ..strokeWidth = 2.5
//           ..strokeCap   = StrokeCap.round,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(_ProgressRingPainter old) =>
//       old.progress != progress || old.color != color;
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Orbit dots painter
// // ─────────────────────────────────────────────────────────────────────────────
// class _OrbitDotsPainter extends CustomPainter {
//   final double progress;
//   final Color  color;
//   _OrbitDotsPainter({required this.progress, required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final cx = size.width  / 2;
//     final cy = size.height / 2;
//     final r  = size.width  / 2;

//     for (int i = 0; i < 8; i++) {
//       final angle   = (2 * pi / 8) * i + (2 * pi * progress);
//       final x       = cx + r * cos(angle);
//       final y       = cy + r * sin(angle);
//       final opacity = (sin(angle - pi / 2) * 0.5 + 0.5) * 0.6 + 0.1;
//       final radius  = (sin(angle - pi / 2) * 0.5 + 0.5) * 2.5 + 1.5;
//       canvas.drawCircle(Offset(x, y), radius,
//           Paint()..color = color.withOpacity(opacity.clamp(0.0, 1.0)));
//     }
//   }

//   @override
//   bool shouldRepaint(_OrbitDotsPainter old) =>
//       old.progress != progress || old.color != color;
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Phase progress dots
// // ─────────────────────────────────────────────────────────────────────────────
// class _PhaseDots extends StatelessWidget {
//   final int   currentIndex;
//   final Color phaseColor;
//   const _PhaseDots({required this.currentIndex, required this.phaseColor});

//   static const _labels = ['Inhale', 'Hold', 'Exhale', 'Hold'];

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(4, (i) {
//         final active = i == currentIndex;
//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 350),
//           curve: Curves.easeOut,
//           margin: const EdgeInsets.symmetric(horizontal: 5),
//           child: Column(
//             children: [
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 350),
//                 width:  active ? 28 : 8,
//                 height: 6,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(3),
//                   color: active
//                       ? phaseColor
//                       : Colors.white.withOpacity(0.18),
//                   boxShadow: active
//                       ? [BoxShadow(
//                           color: phaseColor.withOpacity(0.5),
//                           blurRadius: 8)]
//                       : [],
//                 ),
//               ),
//               const SizedBox(height: 5),
//               if (active)
//                 Text(
//                   _labels[i],
//                   style: TextStyle(
//                     decoration: TextDecoration.none,
//                     color: phaseColor.withOpacity(0.65),
//                     fontSize: 9,
//                     letterSpacing: 1.5,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Premium icon button
// // ─────────────────────────────────────────────────────────────────────────────
// class _PremiumIconButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   const _PremiumIconButton({required this.icon, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 42, height: 42,
//         margin: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.black.withOpacity(0.35),
//           border: Border.all(
//               color: Colors.white.withOpacity(0.12), width: 1.5),
//         ),
//         child: Icon(icon, color: Colors.white60, size: 18),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Arc text painter
// // ─────────────────────────────────────────────────────────────────────────────
// class _ArcTextPainter extends CustomPainter {
//   final String text;
//   final Color  color;
//   final double radius;
//   _ArcTextPainter(
//       {required this.text, required this.color, required this.radius});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final cx = size.width  / 2;
//     final cy = size.height / 2;

//     final style = TextStyle(
//       color:         color,
//       fontSize:      13,
//       fontWeight:    FontWeight.w800,
//       letterSpacing: 2,
//       decoration:    TextDecoration.none,
//     );

//     final painters = text.characters.map((ch) {
//       final tp = TextPainter(
//         text: TextSpan(text: ch, style: style),
//         textDirection: TextDirection.ltr,
//       )..layout();
//       return tp;
//     }).toList();

//     final charAngles = painters.map((tp) => tp.width / radius).toList();
//     final totalAngle = charAngles.fold(0.0, (a, b) => a + b)
//         + (text.length - 1) * (2.5 / radius);

//     double angle = -pi / 2 - totalAngle / 2;

//     for (int i = 0; i < painters.length; i++) {
//       final tp       = painters[i];
//       final halfChar = charAngles[i] / 2;
//       angle += halfChar;
//       canvas.save();
//       canvas.translate(cx + radius * cos(angle), cy + radius * sin(angle));
//       canvas.rotate(angle + pi / 2);
//       canvas.translate(-tp.width / 2, -tp.height / 2);
//       tp.paint(canvas, Offset.zero);
//       canvas.restore();
//       angle += halfChar + 2.5 / radius;
//     }
//   }

//   @override
//   bool shouldRepaint(_ArcTextPainter old) =>
//       old.text != text || old.color != color || old.radius != radius;
// }