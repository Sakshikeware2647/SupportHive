/// ─────────────────────────────────────────────────────────────────────────────
/// admin_config.dart
///
/// Single source of truth for admin credentials and routing logic.
/// Change [adminEmail] to whatever email you use for the admin account.
/// This file is the ONLY place you need to update if credentials change.
/// ─────────────────────────────────────────────────────────────────────────────

class AdminConfig {
  AdminConfig._();

  /// The Firebase Auth email that unlocks the admin panel.
  /// Must exactly match the email used in Firebase Authentication.
  static const String adminEmail = 'admin1@supporthive.com';

  /// Quick check — call this after FirebaseAuth.currentUser is loaded.
  static bool isAdmin(String? email) =>
      email != null && email.toLowerCase() == adminEmail.toLowerCase();
}