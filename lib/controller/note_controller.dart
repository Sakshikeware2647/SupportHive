// ─────────────────────────────────────────────
//  controller/note_controller.dart  –  SupportHive
// ─────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/note.dart';
import '../service/note_service.dart';

class NoteController extends ChangeNotifier {
  final NoteService _service = NoteService();

  List<Note> _notes = [];
  String _query = '';
  bool _isLoading = true;
  String? _editingId;        // Firestore doc id of note being edited
  String? _tempTitle;        // last autosaved title (for new-note guard)
  StreamSubscription<List<Note>>? _sub;

  NoteController() {
    _subscribeToNotes();
  }

  // ── Getters ───────────────────────────────
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  List<Note> get filteredNotes {
    if (_query.isEmpty) return _notes;
    final q = _query.toLowerCase();
    return _notes
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q))
        .toList();
  }

  // ── Firestore subscription ────────────────
  void _subscribeToNotes() {
    _sub = _service.notesStream().listen(
      (notes) {
        _notes = notes;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('NoteController stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Search ────────────────────────────────
  void updateSearch(String query) {
    _query = query;
    notifyListeners();
  }

  // ── Editing helpers ───────────────────────

  /// Call before pushing the editor for a NEW note.
  void startNewNote() {
    _editingId = null;
    _tempTitle = null;
  }

  /// Call before pushing the editor for an EXISTING note.
  void setEditingId(String? id) {
    _editingId = id;
  }

  // ── Auto-save (debounced from editor) ─────
  Future<void> autoSave(
    String title,
    String content, {
    String? mood,
  }) async {
    final trimTitle = title.trim();
    final trimContent = content.trim();

    // Don't save a completely empty note
    if (trimTitle.isEmpty && trimContent.isEmpty) return;

    final note = Note(
      id: _editingId,
      title: trimTitle.isEmpty ? 'Untitled' : trimTitle,
      content: trimContent,
      date: DateTime.now(),
      mood: mood,
    );

    if (_editingId == null) {
      // First save → create document
      final newId = await _service.add(note);
      _editingId = newId;
    } else {
      // Subsequent saves → update existing document
      await _service.update(_editingId!, note);
    }
  }

  // ── Delete ────────────────────────────────
  Future<void> deleteNote(String id) async {
    await _service.delete(id);
    // Stream will update _notes automatically
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}