import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supporthive1/model/user_profile_model.dart';
import 'package:supporthive1/service/profile_service.dart';
import 'package:supporthive1/view/sign_in_screen.dart';

/// ProfileScreen expects [initialProfile] to be passed in from the screen
/// that navigates here (e.g. HomeScreen or after sign-in).
/// This guarantees the screen is never blank — it renders immediately.
class ProfileScreen extends StatefulWidget {
  final UserProfileModel initialProfile;

  const ProfileScreen({super.key, required this.initialProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _service = ProfileService();

  late UserProfileModel _profile;
  bool _isUploadingPhoto = false;
  File? _pendingImageFile;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color _brandGreen = Color(0xFF4A6741);
  static const Color _brandLight = Color(0xFF6FAF5B);
  static const Color _bgColor = Color(0xFFF5F5F0);

  @override
  void initState() {
    super.initState();
    // Use the passed-in profile immediately — no loading state needed
    _profile = widget.initialProfile;

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    // Start animation immediately since profile is already available
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Image picker sheet ────────────────────────────────────────────────────
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Update Profile Photo',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _sheetTile(Icons.photo_library_outlined, 'Choose from Gallery',
                () => _pickImage(fromCamera: false)),
            _sheetTile(Icons.camera_alt_outlined, 'Take a Photo',
                () => _pickImage(fromCamera: true)),
            if (_profile.photoUrl.isNotEmpty)
              _sheetTile(Icons.delete_outline, 'Remove Photo', _removePhoto,
                  isDestructive: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading:
          Icon(icon, color: isDestructive ? Colors.red : _brandGreen),
      title: Text(label,
          style: TextStyle(
              color: isDestructive ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final file = await _service.pickImage(fromCamera: fromCamera);
    if (file == null || !mounted) return;
    setState(() {
      _pendingImageFile = file;
      _isUploadingPhoto = true;
    });
    final url = await _service.uploadProfilePhoto(file);
    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      if (url != null) {
        _profile = _profile.copyWith(photoUrl: url);
        _pendingImageFile = null;
      }
    });
    _showSnack(url != null
        ? 'Profile photo updated!'
        : 'Photo upload failed. Please try again.',
        isError: url == null);
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploadingPhoto = true);
    await _service.removeProfilePhoto();
    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      _pendingImageFile = null;
      _profile = _profile.copyWith(photoUrl: '');
    });
    _showSnack('Profile photo removed.');
  }

  // ── Edit profile bottom sheet ─────────────────────────────────────────────
  void _showEditSheet() {
    final nameCtrl = TextEditingController(text: _profile.name);
    final phoneCtrl = TextEditingController(text: _profile.phone);
    final bioCtrl = TextEditingController(text: _profile.bio);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Edit Profile',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _editField(nameCtrl, 'Full Name', Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null),
                const SizedBox(height: 14),
                _editField(
                    phoneCtrl, 'Phone Number', Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    }),
                const SizedBox(height: 14),
                _editField(bioCtrl, 'Bio (optional)', Icons.info_outline,
                    maxLines: 3),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setBS(() => saving = true);
                            try {
                              await _service.updateProfile(
                                name: nameCtrl.text,
                                phone: phoneCtrl.text,
                                bio: bioCtrl.text,
                              );
                              // Update local state instantly — stream will
                              // also update but this gives instant feedback
                              if (mounted) {
                                setState(() {
                                  _profile = _profile.copyWith(
                                    name: nameCtrl.text.trim(),
                                    phone: phoneCtrl.text.trim(),
                                    bio: bioCtrl.text.trim(),
                                  );
                                });
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _showSnack('Profile updated!');
                            } catch (e) {
                              setBS(() => saving = false);
                              _showSnack('Update failed. Try again.',
                                  isError: true);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandGreen,
                      disabledBackgroundColor:
                          _brandGreen.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Save Changes',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: _brandGreen),
        filled: true,
        fillColor: _bgColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _brandGreen, width: 1.5)),
      ),
    );
  }

  // ── Change password ───────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
            'A password reset link will be sent to ${_profile.email}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send',
                  style: TextStyle(
                      color: _brandGreen,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.sendPasswordReset();
      _showSnack('Reset email sent! Check your inbox.');
    } catch (_) {
      _showSnack('Failed to send reset email.', isError: true);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  // ── Delete account ────────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red)),
        content: const Text(
            'This will permanently delete your account and all data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteAccount();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
    } on FirebaseException catch (e) {
      _showSnack(
          e.code == 'requires-recent-login'
              ? 'Please sign out and sign back in before deleting your account.'
              : 'Failed to delete account.',
          isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : _brandGreen,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Profile',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _brandGreen),
            tooltip: 'Edit Profile',
            onPressed: _showEditSheet,
          ),
        ],
      ),
      // StreamBuilder keeps the screen in sync with real-time Firestore updates
      // but the profile is already visible immediately from widget.initialProfile
      body: StreamBuilder<UserProfileModel?>(
        stream: _service.profileStream(),
        builder: (ctx, snap) {
          // Update local state when stream emits fresh data
          if (snap.hasData && snap.data != null) {
            // Schedule update after build to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && snap.data != null) {
                setState(() => _profile = snap.data!);
              }
            });
          }
          // Always render with _profile (which starts from initialProfile)
          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStats(),
                    const SizedBox(height: 20),
                    if (_profile.bio.isNotEmpty) ...[
                      _buildBioCard(),
                      const SizedBox(height: 20),
                    ],
                    _buildOptions(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandGreen, _brandLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // ── Avatar ────────────────────────────────────────────────────────
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: ClipOval(child: _buildAvatarContent()),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _brandGreen, width: 1.5),
                  ),
                  child: _isUploadingPhoto
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _brandGreen))
                      : const Icon(Icons.camera_alt,
                          size: 16, color: _brandGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Name ──────────────────────────────────────────────────────────
          Text(
            _profile.name.isNotEmpty ? _profile.name : 'Your Name',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),

          // ── Email ─────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                _profile.email.isNotEmpty ? _profile.email : '—',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),

          // ── Phone ─────────────────────────────────────────────────────────
          if (_profile.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(_profile.phone,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Priority 1: Local pending image (just picked, uploading)
    if (_pendingImageFile != null) {
      return Image.file(_pendingImageFile!,
          fit: BoxFit.cover, width: 100, height: 100);
    }
    // Priority 2: Network photo from Firestore/Cloudinary
    if (_profile.photoUrl.isNotEmpty) {
      return Image.network(
        _profile.photoUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (_, __, ___) => _initialsAvatar(),
      );
    }
    // Priority 3: Initials fallback
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return Container(
      color: _brandGreen,
      alignment: Alignment.center,
      child: Text(
        _profile.initials,
        style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard(
              'Sessions', '${_profile.sessions}', Icons.calendar_today),
          const SizedBox(width: 12),
          _statCard('Podcasts', '${_profile.podcastsListened}',
              Icons.headphones),
          const SizedBox(width: 12),
          _statCard('Wellness', _profile.wellnessScore, Icons.favorite),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: _brandGreen, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _brandGreen)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  // ── Bio card ──────────────────────────────────────────────────────────────
  Widget _buildBioCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: _brandGreen),
              const SizedBox(width: 6),
              const Text('About Me',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_profile.bio,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5)),
        ],
      ),
    );
  }

  // ── Options ───────────────────────────────────────────────────────────────
  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Account'),
          _tile(Icons.person_outline, 'Edit Profile',
              onTap: _showEditSheet),
          _tile(Icons.camera_alt_outlined, 'Change Photo',
              onTap: _showImageSourceSheet),
          _tile(Icons.lock_outline, 'Change Password',
              onTap: _changePassword),
          const SizedBox(height: 16),
          _sectionLabel('App'),
          _tile(Icons.notifications_outlined, 'Notifications',
              onTap: () => _showSnack('Coming soon!')),
          _tile(Icons.privacy_tip_outlined, 'Privacy Policy',
              onTap: () => _showSnack('Coming soon!')),
          _tile(Icons.help_outline, 'Help & Support',
              onTap: () => _showSnack('Coming soon!')),
          _tile(Icons.info_outline, 'About SupportHive',
              onTap: _showAbout),
          const SizedBox(height: 16),
          _sectionLabel('Session'),
          _tile(Icons.logout, 'Sign Out',
              onTap: _logout, isDestructive: true),
          _tile(Icons.delete_forever_outlined, 'Delete Account',
              onTap: _deleteAccount, isDestructive: true),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.8)),
    );
  }

  Widget _tile(IconData icon, String title,
      {VoidCallback? onTap, bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.08)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 20,
              color: isDestructive ? Colors.red : _brandGreen),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDestructive ? Colors.red : Colors.black87)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 14, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'SupportHive',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
            color: _brandGreen,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.spa_outlined,
            color: Colors.white, size: 28),
      ),
      children: [
        const Text(
            'SupportHive is your personal wellness companion — built to help you relax, recharge, and reflect.'),
      ],
    );
  }
}