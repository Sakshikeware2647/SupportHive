/// ─────────────────────────────────────────────────────────────────────────────
/// view/screens/admin/admin_expert_form.dart
///
/// Bottom-sheet form used for both ADDING and EDITING an expert.
/// Key difference from the user-side AddExpertScreen:
///   • Includes a Phone Number field (required).
///   • Writes to Firestore via AdminFirestoreService (not ExpertFirestoreService).
///   • Dark theme to match the admin panel.
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '/model/admin_expert_model.dart';
import '/service/admin_firestore_service.dart';

class AdminExpertForm extends StatefulWidget {
  /// Pass null to create a new expert; pass an existing one to edit.
  final AdminExpert? existing;

  const AdminExpertForm({super.key, this.existing});

  @override
  State<AdminExpertForm> createState() => _AdminExpertFormState();
}

class _AdminExpertFormState extends State<AdminExpertForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _spec;
  late final TextEditingController _clinic;
  late final TextEditingController _price;
  late final TextEditingController _exp;
  late final TextEditingController _bio;
  late final TextEditingController _tags;
  late final TextEditingController _phone;

  late String _category;
  late bool _isAvailable;
  late bool _audio;
  late bool _video;
  late bool _chat;
  late String _selectedColor;
  bool _loading = false;

  static const _primary = Color(0xFF7C3AED);
  static const _surface = Color(0xFF1A1033);
  static const _card = Color(0xFF241848);

  final List<String> _categories = [
    'anxiety', 'depression', 'sleep', 'child', 'medical', 'general'
  ];

  final List<_Clr> _colors = [
    _Clr('#7C3AED', 'Violet'),
    _Clr('#EC4899', 'Pink'),
    _Clr('#10B981', 'Green'),
    _Clr('#0EA5E9', 'Blue'),
    _Clr('#F59E0B', 'Amber'),
    _Clr('#EF4444', 'Red'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _spec = TextEditingController(text: e?.specialization ?? '');
    _clinic = TextEditingController(text: e?.clinic ?? '');
    _price = TextEditingController(text: e != null ? '${e.price}' : '');
    _exp = TextEditingController(
        text: e != null ? '${e.experienceYears}' : '');
    _bio = TextEditingController(text: e?.bio ?? '');
    _tags = TextEditingController(text: e?.tags.join(', ') ?? '');
    _phone = TextEditingController(text: e?.phoneNumber ?? '');
    _category = e?.category ?? 'anxiety';
    _isAvailable = e?.isAvailable ?? true;
    _audio = e?.offersAudio ?? true;
    _video = e?.offersVideo ?? true;
    _chat = e?.offersChat ?? true;
    _selectedColor = e?.avatarColor ?? '#7C3AED';
  }

  @override
  void dispose() {
    for (final c in [_name, _spec, _clinic, _price, _exp, _bio, _tags, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final initials = _name.text
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final expert = AdminExpert(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      specialization: _spec.text.trim(),
      category: _category,
      rating: widget.existing?.rating ?? 0.0,
      reviewCount: widget.existing?.reviewCount ?? 0,
      isAvailable: _isAvailable,
      price: int.tryParse(_price.text) ?? 1000,
      experienceYears: int.tryParse(_exp.text) ?? 0,
      tags: _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      clinic: _clinic.text.trim(),
      avatarInitials: initials.isEmpty ? 'DR' : initials,
      avatarColor: _selectedColor,
      bio: _bio.text.trim(),
      offersAudio: _audio,
      offersVideo: _video,
      offersChat: _chat,
      phoneNumber: _phone.text.trim(),
    );

    try {
      if (widget.existing == null) {
        await AdminFirestoreService.instance.addExpert(expert);
      } else {
        await AdminFirestoreService.instance.updateExpert(expert);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.existing == null
              ? 'Expert added successfully! 🎉'
              : 'Expert updated successfully! ✅'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  widget.existing == null ? 'Add Expert' : 'Edit Expert',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Basic Information'),
                    _field(_name, 'Full Name', Icons.person_rounded,
                        hint: 'Dr. Rajesh Kumar'),
                    _field(_spec, 'Specialization', Icons.school_rounded,
                        hint: 'MD Psychiatry'),
                    _field(_clinic, 'Clinic / Hospital',
                        Icons.local_hospital_rounded,
                        hint: 'Mind & Soul Center'),

                    // ── Phone number (admin-only field) ──────────────────────
                    _section('Expert Contact (Admin Only)'),
                    _field(
                      _phone,
                      'Phone Number',
                      Icons.phone_rounded,
                      hint: '+919876543210',
                      keyboardType: TextInputType.phone,
                      helperText:
                          'SMS join-link is sent to this number when a user books.',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        // Allow digits, +, spaces, dashes
                        if (!RegExp(r'^[+\d\s\-]{7,15}$')
                            .hasMatch(v.trim())) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    // ────────────────────────────────────────────────────────

                    _section('Category'),
                    _categoryPicker(),
                    const SizedBox(height: 16),

                    _section('Details'),
                    Row(children: [
                      Expanded(
                          child: _field(_price, 'Price (₹)',
                              Icons.currency_rupee_rounded,
                              hint: '1200',
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field(
                              _exp, 'Experience (yrs)', Icons.work_rounded,
                              hint: '10',
                              keyboardType: TextInputType.number)),
                    ]),
                    _field(_tags, 'Tags (comma separated)',
                        Icons.label_rounded,
                        hint: 'Anxiety, PTSD, CBT',
                        required: false),
                    _field(_bio, 'Bio', Icons.info_rounded,
                        hint: 'Short description…',
                        maxLines: 3,
                        required: false),

                    _section('Avatar Color'),
                    _colorPicker(),
                    const SizedBox(height: 16),

                    _section('Services & Availability'),
                    _switches(),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _primary,
                          disabledBackgroundColor:
                              _primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                widget.existing == null
                                    ? 'Add Expert'
                                    : 'Save Changes',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String hint = '',
    int maxLines = 1,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: validator ??
            (required
                ? (v) => (v == null || v.isEmpty) ? 'Required' : null
                : null),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          helperText: helperText,
          helperStyle:
              const TextStyle(color: Colors.white38, fontSize: 11),
          prefixIcon: Icon(icon, size: 18, color: _primary),
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent)),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _categoryPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final sel = _category == cat;
        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _primary : _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: sel ? _primary : Colors.white.withOpacity(0.1)),
            ),
            child: Text(cat[0].toUpperCase() + cat.substring(1),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : Colors.white54)),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorPicker() {
    return Wrap(
      spacing: 10,
      children: _colors.map((opt) {
        final color =
            Color(int.parse(opt.hex.replaceFirst('#', '0xFF')));
        final sel = _selectedColor == opt.hex;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = opt.hex),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: sel ? Border.all(color: Colors.white, width: 2.5) : null,
              boxShadow: sel
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                  : [],
            ),
            child: sel
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _switches() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _switchRow('Available', _isAvailable,
              (v) => setState(() => _isAvailable = v)),
          _switchRow('Offers Audio Call', _audio,
              (v) => setState(() => _audio = v)),
          _switchRow('Offers Video Call', _video,
              (v) => setState(() => _video = v)),
          _switchRow('Offers Chat', _chat, (v) => setState(() => _chat = v),
              isLast: true),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChange,
      {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            Switch.adaptive(
              value: value,
              onChanged: onChange,
              activeColor: _primary,
            ),
          ],
        ),
        if (!isLast)
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
      ],
    );
  }
}

class _Clr {
  final String hex, name;
  _Clr(this.hex, this.name);
}