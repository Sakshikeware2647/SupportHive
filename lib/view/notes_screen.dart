// ─────────────────────────────────────────────
//  screens/notes/notes_screen.dart  –  SupportHive
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../controller/note_controller.dart';
import '../../model/note.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  // Single controller instance lives here — shared with editor so the
  // Firestore stream is not re-created on every navigation.
  final NoteController _controller = NoteController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnim;
  bool _showSearch = false;

  // ── Clean theme aligned with profile ─────────────────
static const List<Color> _cardColors = [
  Color(0xFFFFFFFF), // pure white (primary)
  Color(0xFFF5F5F0), // background soft
  Color(0xFFE8F5E9), // subtle green tint
  Color(0xFFF0F4EF), // light neutral green-grey
];

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color _cardColor(int index) => _cardColors[index % _cardColors.length];

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── Open Editor ───────────────────────────
  Future<void> _openNew() async {
    _controller.startNewNote();
    await Navigator.push(context, _slideRoute(
      NoteEditorScreen(controller: _controller),
    ));
    // Stream auto-refreshes – no manual setState needed
  }

  Future<void> _openExisting(Note note) async {
    _controller.setEditingId(note.id);
    await Navigator.push(context, _slideRoute(
      NoteEditorScreen(controller: _controller, existingNote: note),
    ));
  }

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      );

  // ── Confirm delete ────────────────────────
  Future<void> _confirmDelete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF8F6FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Note',
          style: TextStyle(
              fontFamily: 'Georgia', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete "${note.title}"?\nThis cannot be undone.',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black45)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true && note.id != null) {
      await _controller.deleteNote(note.id!);
    }
  }

  // ── Build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_showSearch) _buildSearchBar(),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Header ────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD8D0F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Color(0xFF6B52AE), size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Journal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Georgia',
                  color: Color(0xFF2D2640),
                  letterSpacing: 0.3,
                ),
              ),
              ListenableBuilder(
                listenable: _controller,
                builder: (_, __) {
                  final count = _controller.notes.length;
                  return Text(
                    count == 0
                        ? 'Begin your story'
                        : '$count entr${count == 1 ? 'y' : 'ies'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A7FBE),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          _iconBtn(
            icon: _showSearch ? Icons.close : Icons.search_rounded,
            onTap: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _controller.updateSearch('');
              }
            }),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B52AE).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _controller.updateSearch,
          decoration: const InputDecoration(
            hintText: 'Search notes…',
            hintStyle: TextStyle(color: Color(0xFFBBB3D8), fontSize: 14),
            border: InputBorder.none,
            prefixIcon:
                Icon(Icons.search, color: Color(0xFF8A7FBE), size: 20),
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────
  Widget _buildBody() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        if (_controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6B52AE),
              strokeWidth: 2,
            ),
          );
        }

        final notes = _controller.filteredNotes;
        if (notes.isEmpty) return _buildEmpty();

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: notes.length,
          itemBuilder: (_, i) => _buildCard(notes[i], i),
        );
      },
    );
  }

  // ── Empty state ───────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_note_rounded,
                color: Color(0xFF8A7FBE), size: 44),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your journal is empty',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'Georgia',
              color: Color(0xFF4A4060),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to write your first entry\nand start feeling better',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9B93C0),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Note card ─────────────────────────────
  Widget _buildCard(Note note, int index) {
    final bg = _cardColor(index);
    final accent = HSLColor.fromColor(bg)
        .withLightness(0.60)
        .withSaturation(0.45)
        .toColor();

    return GestureDetector(
      onTap: () => _openExisting(note),
      onLongPress: () => _confirmDelete(note),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: accent dot + mood emoji + options
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (note.mood != null)
                    Text(note.mood!,
                        style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _confirmDelete(note),
                    child: Icon(Icons.more_horiz,
                        color: accent.withOpacity(0.7), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2D2640),
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  fontFamily: 'Georgia',
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),

              // Content preview
              Expanded(
                child: Text(
                  note.content,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: Color(0xFF6B6380),
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Date chip
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 11, color: accent),
                  const SizedBox(width: 4),
                  Text(
                    _timeAgo(note.date),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────
  Widget _buildFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
      child: FloatingActionButton.extended(
        onPressed: _openNew,
        backgroundColor: const Color(0xFF6B52AE),
        elevation: 6,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ── Helper ────────────────────────────────
  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B52AE).withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF6B52AE), size: 20),
      ),
    );
  }
}