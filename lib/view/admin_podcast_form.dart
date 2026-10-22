/// ─────────────────────────────────────────────────────────────────────────────
/// view/screens/admin/admin_podcast_form.dart
///
/// Full-screen form for creating or editing a Podcast.
/// Pass [podcast] to edit an existing one; omit it to create a new one.
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/model/podcast.dart';
import '/service/admin_firestore_service.dart';

class AdminPodcastForm extends StatefulWidget {
  /// Non-null → edit mode. Null → create mode.
  final Podcast? podcast;

  const AdminPodcastForm({super.key, this.podcast});

  @override
  State<AdminPodcastForm> createState() => _AdminPodcastFormState();
}

class _AdminPodcastFormState extends State<AdminPodcastForm> {
  // ── Palette (matches your admin dashboard purple theme) ─────────────────────
  static const Color _primary = Color(0xFF7C3AED);
  static const Color _surface = Color(0xFFF8F7FF);

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // ── Controllers ──────────────────────────────────────────────────────────────
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _duration;
  late final TextEditingController _audioUrl;
  late final TextEditingController _videoUrl;
  late final TextEditingController _imageUrl;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _tags;

  // ── Dropdown / toggle state ──────────────────────────────────────────────────
  String _category = 'Mental Health';
  bool _isPremium = false;
  bool _isNew = false;

  static const List<String> _categories = [
    'Mental Health',
    'Mindfulness',
    'Anxiety',
    'Sleep',
    'Stress',
    'Motivation',
  ];

  bool get _isEdit => widget.podcast != null;

  @override
  void initState() {
    super.initState();
    final p = widget.podcast;
    _title = TextEditingController(text: p?.title ?? '');
    _author = TextEditingController(text: p?.author ?? '');
    _duration = TextEditingController(text: p?.duration ?? '');
    _audioUrl = TextEditingController(text: p?.audioUrl ?? '');
    _videoUrl = TextEditingController(text: p?.videoUrl ?? '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
        text: p != null && p.price > 0 ? p.price.toStringAsFixed(0) : '');
    _tags = TextEditingController(text: p?.tags.join(', ') ?? '');
    _category = p?.category ?? 'Mental Health';
    _isPremium = p?.isPremium ?? false;
    _isNew = p?.isNew ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _title, _author, _duration, _audioUrl,
      _videoUrl, _imageUrl, _description, _price, _tags
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final tagList = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final podcast = Podcast(
      id: widget.podcast?.id ?? '',
      title: _title.text.trim(),
      author: _author.text.trim(),
      category: _category,
      duration: _duration.text.trim(),
      audioUrl: _audioUrl.text.trim(),
      videoUrl: _videoUrl.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      description: _description.text.trim(),
      isPremium: _isPremium,
      isNew: _isNew,
      price: _isPremium ? (double.tryParse(_price.text) ?? 0) : 0,
      tags: tagList,
      // preserve existing counts on edit
      playCount: widget.podcast?.playCount ?? 0,
      likeCount: widget.podcast?.likeCount ?? 0,
    );

    try {
      if (_isEdit) {
        await AdminFirestoreService.instance.updatePodcast(podcast);
      } else {
        await AdminFirestoreService.instance.addPodcast(podcast);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(_isEdit ? 'Podcast updated!' : 'Podcast added!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true); // signal refresh to parent
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Podcast' : 'Add Podcast'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('SAVE',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Basic info ───────────────────────────────────────────────────
            _sectionHeader('Basic Info'),
            _field(
              controller: _title,
              label: 'Title',
              hint: 'e.g. The Anxiety Solution',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            _field(
              controller: _author,
              label: 'Author / Host',
              hint: 'e.g. Dr. Priya Mehta',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Author is required' : null,
            ),
            _field(
              controller: _duration,
              label: 'Duration',
              hint: 'e.g. 18:30',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Duration is required' : null,
            ),
            _field(
              controller: _description,
              label: 'Description',
              hint: 'Short summary shown on the card.',
              maxLines: 3,
            ),

            const SizedBox(height: 8),

            // ── Category ─────────────────────────────────────────────────────
            _sectionHeader('Category'),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDeco('Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),

            const SizedBox(height: 20),

            // ── Media URLs ───────────────────────────────────────────────────
            _sectionHeader('Media URLs'),
            _field(
              controller: _audioUrl,
              label: 'Audio URL',
              hint: 'https://... or assets/audios/file.mp3',
            ),
            _field(
              controller: _videoUrl,
              label: 'Video URL (optional)',
              hint: 'https://...',
            ),
            _field(
              controller: _imageUrl,
              label: 'Cover Image URL (optional)',
              hint: 'https://...',
            ),

            const SizedBox(height: 8),

            // ── Premium & pricing ────────────────────────────────────────────
            _sectionHeader('Access & Pricing'),
            _toggleTile(
              title: 'Premium',
              subtitle: 'Requires payment to unlock',
              value: _isPremium,
              onChanged: (v) => setState(() {
                _isPremium = v;
                if (!v) _price.clear();
              }),
            ),
            if (_isPremium) ...[
              const SizedBox(height: 8),
              _field(
                controller: _price,
                label: 'Price (₹)',
                hint: 'e.g. 99',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (!_isPremium) return null;
                  if (v == null || v.trim().isEmpty) return 'Set a price';
                  if ((double.tryParse(v) ?? 0) <= 0)
                    return 'Price must be > 0';
                  return null;
                },
              ),
            ],

            // ── Badges ────────────────────────────────────────────────────────
            _sectionHeader('Badges'),
            _toggleTile(
              title: 'Mark as NEW',
              subtitle: 'Shows a red NEW badge on the card',
              value: _isNew,
              onChanged: (v) => setState(() => _isNew = v),
            ),

            const SizedBox(height: 8),

            // ── Tags ──────────────────────────────────────────────────────────
            _sectionHeader('Tags'),
            _field(
              controller: _tags,
              label: 'Tags (comma-separated)',
              hint: 'e.g. anxiety, mental health, wellness',
            ),

            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: _primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _isEdit ? 'Update Podcast' : 'Add Podcast',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _primary.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: _inputDeco(label, hint: hint),
      ),
    );
  }

  InputDecoration _inputDeco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: _primary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}