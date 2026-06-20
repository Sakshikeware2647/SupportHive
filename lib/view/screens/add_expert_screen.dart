import 'package:flutter/material.dart';
import '/model/expert_model.dart';
import '/service/expert_firestore_service.dart';
import '/view/screens/counselling/expert_app_theme.dart';

class AddExpertScreen extends StatefulWidget {
  const AddExpertScreen({super.key});

  @override
  State<AddExpertScreen> createState() => _AddExpertScreenState();
}

class _AddExpertScreenState extends State<AddExpertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _specialization = TextEditingController();
  final _clinic = TextEditingController();
  final _price = TextEditingController();
  final _experience = TextEditingController();
  final _bio = TextEditingController();
  final _tags = TextEditingController();

  String _category = 'anxiety';
  bool _isAvailable = true;
  bool _offersAudio = true;
  bool _offersVideo = true;
  bool _offersChat = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'anxiety', 'depression', 'sleep', 'child', 'medical', 'general'
  ];

  final List<_ColorOption> _colorOptions = [
    _ColorOption('#7C3AED', 'Violet'),
    _ColorOption('#EC4899', 'Pink'),
    _ColorOption('#10B981', 'Green'),
    _ColorOption('#0EA5E9', 'Blue'),
    _ColorOption('#F59E0B', 'Amber'),
    _ColorOption('#EF4444', 'Red'),
  ];
  String _selectedColor = '#7C3AED';

  @override
  void dispose() {
    for (final c in [_name, _specialization, _clinic, _price, _experience, _bio, _tags]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final initials = _name.text
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final expert = Expert(
      id: '',
      name: _name.text.trim(),
      specialization: _specialization.text.trim(),
      category: _category,
      rating: 0.0,
      reviewCount: 0,
      isAvailable: _isAvailable,
      price: int.tryParse(_price.text) ?? 1000,
      experienceYears: int.tryParse(_experience.text) ?? 0,
      tags: _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      clinic: _clinic.text.trim(),
      avatarInitials: initials,
      avatarColor: _selectedColor,
      bio: _bio.text.trim(),
      offersAudio: _offersAudio,
      offersVideo: _offersVideo,
      offersChat: _offersChat,
    );

    try {
      await ExpertFirestoreService.instance.addExpert(expert);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Expert added successfully! 🎉'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add New Expert', style: AppTheme.titleSm),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Basic Information'),
              _field(_name, 'Full Name', Icons.person_rounded,
                  hint: 'Dr. Rajesh Kumar'),
              _field(_specialization, 'Specialization',
                  Icons.school_rounded,
                  hint: 'MD Psychiatry'),
              _field(_clinic, 'Clinic / Hospital',
                  Icons.local_hospital_rounded,
                  hint: 'Mind & Soul Center'),
              const SizedBox(height: 16),
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
                    child: _field(_experience, 'Experience (yrs)',
                        Icons.work_rounded,
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
              const SizedBox(height: 16),
              _section('Avatar Color'),
              _colorPicker(),
              const SizedBox(height: 16),
              _section('Services & Availability'),
              _switches(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Add Expert',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: AppTheme.titleSm.copyWith(
              fontSize: 13, color: AppTheme.textSecondary)),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String hint = '',
    int maxLines = 1,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 2)),
        ),
      ),
    );
  }

  Widget _categoryPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _category == cat;
        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                      selected ? AppTheme.primary : AppTheme.divider),
            ),
            child: Text(cat[0].toUpperCase() + cat.substring(1),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textSecondary)),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorPicker() {
    return Row(
      children: _colorOptions.map((opt) {
        final color = Color(int.parse(opt.hex.replaceFirst('#', '0xFF')));
        final selected = _selectedColor == opt.hex;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = opt.hex),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Colors.black, width: 2.5)
                  : null,
              boxShadow: selected
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                  : [],
            ),
            child: selected
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _switchRow('Available Now', _isAvailable,
              (v) => setState(() => _isAvailable = v)),
          _switchRow('Offers Audio Call', _offersAudio,
              (v) => setState(() => _offersAudio = v)),
          _switchRow('Offers Video Call', _offersVideo,
              (v) => setState(() => _offersVideo = v)),
          _switchRow('Offers Chat', _offersChat,
              (v) => setState(() => _offersChat = v),
              isLast: true),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged,
      {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.titleSm.copyWith(fontSize: 13)),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primary,
            ),
          ],
        ),
        if (!isLast) const Divider(color: AppTheme.divider, height: 1),
      ],
    );
  }
}

class _ColorOption {
  final String hex, name;
  _ColorOption(this.hex, this.name);
}
