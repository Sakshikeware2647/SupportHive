// ─────────────────────────────────────────────
//  screens/notes/note_editor_screen.dart  –  SupportHive
// ─────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../../controller/note_controller.dart';
import '../../model/note.dart';
import '../../service/AI_chat_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteController controller;
  final Note? existingNote;

  const NoteEditorScreen({
    super.key,
    required this.controller,
    this.existingNote,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  // ── Text controllers ───────────────────────
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  // ── State ─────────────────────────────────
  Timer? _debounce;
  bool _isSaving = false;
  bool _saved = false;
  int _wordCount = 0;
  int _charCount = 0;
  String? _selectedMood;

  // ── AI Help state ──────────────────────────
  final ChatService _chatService = ChatService();
  JournalInsight? _insight;
  bool _isAnalyzing = false;
  bool _showInsight = false;

  late AnimationController _fadeIn;
  late Animation<double> _fadeAnim;

  // ── Mood options ───────────────────────────
  static const _moods = ['😌', '😔', '😤', '😢', '🥰', '😰', '😴', '✨'];

  // ── Colors ────────────────────────────────
  static const _bgColor = Color(0xFFFAF8FF);
  static const _accentColor = Color(0xFF6B52AE);
  static const _softText = Color(0xFF9B93C0);
  static const _darkText = Color(0xFF2D2640);

  // AI panel colors
  static const _aiPanelBg = Color(0xFFF0EBFF);
  static const _doColor = Color(0xFF3D8B6A);
  static const _dontColor = Color(0xFFB0514A);
  static const _affirmColor = Color(0xFF5A6BAE);

  @override
  void initState() {
    super.initState();

    if (widget.existingNote != null) {
      _titleCtrl.text = widget.existingNote!.title;
      _contentCtrl.text = widget.existingNote!.content;
      _selectedMood = widget.existingNote!.mood;
      _updateCounts(widget.existingNote!.content);
    }

    _titleCtrl.addListener(_onTextChanged);
    _contentCtrl.addListener(() {
      _onTextChanged();
      _updateCounts(_contentCtrl.text);
    });

    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut);
    _fadeIn.forward();

    if (widget.existingNote == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_titleFocus);
      });
    }
  }

  // ── Helpers ───────────────────────────────
  void _updateCounts(String text) {
    setState(() {
      _charCount = text.length;
      _wordCount = text.trim().isEmpty
          ? 0
          : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  void _onTextChanged() {
    // Hide AI panel when user edits so they can re-analyze fresh
    if (_showInsight) {
      setState(() {
        _showInsight = false;
        _insight = null;
      });
    }
    setState(() {
      _saved = false;
      _isSaving = true;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () async {
      await widget.controller.autoSave(
        _titleCtrl.text,
        _contentCtrl.text,
        mood: _selectedMood,
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saved = true;
        });
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saved = false);
        });
      }
    });
  }

  void _onMoodChanged(String? mood) {
    setState(() => _selectedMood = mood);
    _onTextChanged();
  }

  // ── AI Help trigger ───────────────────────
  Future<void> _onAiHelpTapped() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Write something in your journal first ✍️',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: _accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Unfocus keyboard so panel is visible
    FocusScope.of(context).unfocus();

    setState(() {
      _isAnalyzing = true;
      _showInsight = true;
      _insight = null;
    });

    final result = await _chatService.analyzeJournalEntry(
      title: title,
      content: content,
      mood: _selectedMood,
    );

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _insight = result;
      });
    }
  }

  void _dismissInsight() {
    setState(() {
      _showInsight = false;
      _insight = null;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fadeIn.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  // ── Save status ───────────────────────────
  Widget _saveStatus() {
    if (_isSaving) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 11,
            height: 11,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _softText),
          ),
          SizedBox(width: 5),
          Text('Saving…', style: TextStyle(fontSize: 11, color: _softText)),
        ],
      );
    }
    if (_saved) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done_outlined, size: 13, color: Color(0xFF6BAE8A)),
          SizedBox(width: 4),
          Text('Saved',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6BAE8A),
                  fontWeight: FontWeight.w600)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // ── Build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final date = widget.existingNote?.date ?? DateTime.now();
    final dateStr =
        '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} ${date.year}';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildTopBar(dateStr),
              _buildMoodRow(),
              const Divider(height: 1, color: Color(0xFFE8E2F5)),
              Expanded(
                child: _showInsight
                    ? _buildInsightView()
                    : _buildEditorView(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────
  Widget _buildTopBar(String dateStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _accentColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _softText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                _saveStatus(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_wordCount w · $_charCount c',
              style: const TextStyle(
                fontSize: 10.5,
                color: _accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mood selector ─────────────────────────
  Widget _buildMoodRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 11,
              color: _softText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _moods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final mood = _moods[i];
                final selected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () => _onMoodChanged(selected ? null : mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected ? _accentColor : const Color(0xFFEDE9FF),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _accentColor.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(mood, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Editor view ───────────────────────────
  Widget _buildEditorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            focusNode: _titleFocus,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              color: _darkText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Georgia',
              height: 1.3,
            ),
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Give your entry a title…',
              hintStyle: TextStyle(
                color: Color(0xFFCCC7E0),
                fontSize: 22,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w800,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_contentFocus),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 48,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtrl,
            focusNode: _contentFocus,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              color: Color(0xFF4A4060),
              fontSize: 15,
              height: 1.75,
              letterSpacing: 0.1,
            ),
            decoration: const InputDecoration(
              hintText:
                  'Write freely… this is your safe space.\nNo judgement, just your thoughts.',
              hintStyle: TextStyle(
                color: Color(0xFFCCC7E0),
                fontSize: 15,
                height: 1.75,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ── AI Insight view ───────────────────────
  Widget _buildInsightView() {
    // Loading state
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🐝', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reading your journal…',
              style: TextStyle(
                fontSize: 16,
                color: _accentColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hive is understanding your feelings',
              style: TextStyle(fontSize: 13, color: _softText),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: _accentColor,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_insight == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😔', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Couldn\'t analyze your entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _softText),
              ),
              const SizedBox(height: 24),
              _aiHelpButton(retrying: true),
            ],
          ),
        ),
      );
    }

    // Success state — rich insight panel
    final insight = _insight!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🐝', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hive\'s Insight',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _darkText,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    Text(
                      'Based on your journal entry',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _dismissInsight,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: _accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Emotional tone badge ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B52AE), Color(0xFF8B72CE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  insight.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.emotionalTone,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      Text(
                        insight.summary,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── What to DO ──
          _insightSection(
            icon: Icons.check_circle_outline_rounded,
            iconColor: _doColor,
            bgColor: const Color(0xFFEDF7F2),
            borderColor: const Color(0xFFB8E0CC),
            label: 'What to Do',
            labelColor: _doColor,
            items: insight.doList,
            itemColor: const Color(0xFF2D5A45),
            bullet: '✓',
            bulletColor: _doColor,
          ),
          const SizedBox(height: 12),

          // ── What NOT to do ──
          _insightSection(
            icon: Icons.remove_circle_outline_rounded,
            iconColor: _dontColor,
            bgColor: const Color(0xFFFFF1F0),
            borderColor: const Color(0xFFEDC4C2),
            label: 'What to Avoid',
            labelColor: _dontColor,
            items: insight.dontList,
            itemColor: const Color(0xFF6B2B27),
            bullet: '○',
            bulletColor: _dontColor,
          ),
          const SizedBox(height: 12),

          // ── Affirmations ──
          _affirmationsSection(insight.affirmations),
          const SizedBox(height: 16),

          // ── Back to writing button ──
          GestureDetector(
            onTap: _dismissInsight,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _accentColor.withOpacity(0.3), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded,
                      color: _accentColor, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Back to Writing',
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightSection({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String label,
    required Color labelColor,
    required List<String> items,
    required Color itemColor,
    required String bullet,
    required Color bulletColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$bullet  ',
                      style: TextStyle(
                        color: bulletColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: itemColor,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _affirmationsSection(List<String> affirmations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF0EBFF),
            const Color(0xFFE8F5E9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _accentColor.withOpacity(0.15), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: _affirmColor, size: 18),
              SizedBox(width: 6),
              Text(
                'Words for You',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _affirmColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...affirmations.map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('💜 ',
                      style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      a,
                      style: const TextStyle(
                        color: Color(0xFF4A3A7E),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Help button ────────────────────────
  Widget _aiHelpButton({bool retrying = false}) {
    return GestureDetector(
      onTap: _isAnalyzing ? null : _onAiHelpTapped,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: _isAnalyzing
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF6B52AE), Color(0xFF8B72CE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isAnalyzing ? const Color(0xFFE0DCF5) : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isAnalyzing
              ? []
              : [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isAnalyzing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: _accentColor,
                    ),
                  )
                : const Text('🐝',
                    style: TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              retrying
                  ? 'Try Again'
                  : _isAnalyzing
                      ? 'Analyzing…'
                      : 'AI Help',
              style: TextStyle(
                fontSize: 12.5,
                color: _isAnalyzing
                    ? _accentColor
                    : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE8E2F5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B52AE).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── AI Help row ──
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: _softText, size: 14),
              const SizedBox(width: 6),
              const Text(
                'Want guidance on what you wrote?',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _softText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _aiHelpButton(),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEEE9F8)),
          const SizedBox(height: 10),

          // ── Writing prompts ──
          const Text(
            'WRITING PROMPTS',
            style: TextStyle(
              fontSize: 9.5,
              color: _softText,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _prompt('What am I grateful for today?'),
                _prompt('What drained my energy?'),
                _prompt('One thing I\'m proud of'),
                _prompt('What do I need right now?'),
                _prompt('A win from today'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prompt(String text) {
    return GestureDetector(
      onTap: () {
        // Don't inject prompts while insight is showing
        if (_showInsight) _dismissInsight();
        final current = _contentCtrl.text;
        final addition = current.isEmpty ? '$text\n' : '\n\n$text\n';
        _contentCtrl.text = current + addition;
        _contentCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _contentCtrl.text.length),
        );
        FocusScope.of(context).requestFocus(_contentFocus);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFFD8D0F5), width: 1),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: _accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Date helpers ──────────────────────────
  String _weekday(int d) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];

  String _month(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}