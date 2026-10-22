// ─────────────────────────────────────────────────────────────────
// view/screens/intern/intern_dashboard_screen.dart  (INTERN SIDE)
//
// Fixes vs broken original:
//   • Correct imports (no bare 'package:...' paths)
//   • StreamSubscription typed as StreamSubscription<List<CallModel>>
// ─────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../../model/call_model.dart';
import '../../../service/call_service.dart';
import 'intern_incoming_call_screen.dart';
import 'intern_theme.dart';

class InternDashboardScreen extends StatefulWidget {
  final String internId;
  final String internName;

  const InternDashboardScreen({
    super.key,
    required this.internId,
    required this.internName,
  });

  @override
  State<InternDashboardScreen> createState() =>
      _InternDashboardScreenState();
}

class _InternDashboardScreenState extends State<InternDashboardScreen> {
  bool _isAvailable = false;
  bool _toggling    = false;
  StreamSubscription<List<CallModel>>? _callSub;
  String? _activeCallId;

  @override
  void initState() {
    super.initState();
    _ensureInternExists();
    _listenForCalls();
  }

  Future<void> _ensureInternExists() async {
    try {
      final ref = FirebaseFirestore.instance.collection('interns').doc(widget.internId);
      final snap = await ref.get();
      
      String token = '';
      try {
        await FirebaseMessaging.instance.requestPermission();
        token = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (_) {}

      if (!snap.exists) {
        await ref.set({
          'name': widget.internName,
          'email': 'kartik@supporthive.com',
          'phone': '+91 99999 99999',
          'specialization': 'Anxiety | Stress | CBT',
          'rating': 4.9,
          'isAvailable': false,
          'fcmToken': token,
          'bio': 'Trained student psychologist, ready to listen and support.',
          'sessionCount': 24,
        });
      } else {
        final data = snap.data();
        if (data != null && mounted) {
          setState(() {
            _isAvailable = data['isAvailable'] ?? false;
          });
        }
        if (token.isNotEmpty) {
          await ref.update({'fcmToken': token});
        }
      }
    } catch (e) {
      debugPrint('Error ensuring intern document exists: $e');
    }
  }

  void _listenForCalls() {
    _callSub = CallService.listenForIncomingCalls(widget.internId)
        .listen((calls) {
      if (calls.isEmpty) return;
      final incoming = calls.first;

      if (_activeCallId == incoming.callId) return;
      _activeCallId = incoming.callId;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InternIncomingCallScreen(call: incoming),
          fullscreenDialog: true,
        ),
      ).then((_) => _activeCallId = null);
    });
  }

  Future<void> _toggleAvailability() async {
    setState(() => _toggling = true);
    final next = !_isAvailable;
    await CallService.setInternAvailability(widget.internId, next);
    setState(() {
      _isAvailable = next;
      _toggling    = false;
    });
  }

  Future<void> _signOut() async {
    await CallService.setInternAvailability(widget.internId, false);
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InternTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Intern Dashboard',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: InternTheme.textDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: InternTheme.textMid),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── Profile card ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: InternTheme.cardDecoration,
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(
                  gradient: InternTheme.headerGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.internName
                        .split(' ')
                        .where((e) => e.isNotEmpty)
                        .map((e) => e[0])
                        .take(2)
                        .join(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.internName,
                        style: const TextStyle(
                            color: InternTheme.textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _isAvailable
                              ? InternTheme.available
                              : InternTheme.unavailable,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isAvailable ? 'You are Online' : 'You are Offline',
                        style: TextStyle(
                            color: _isAvailable
                                ? InternTheme.available
                                : InternTheme.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Availability toggle ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: InternTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Availability',
                    style: TextStyle(
                        color: InternTheme.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  _isAvailable
                      ? 'You are visible to users. You can receive calls.'
                      : 'You are hidden from users. No calls will come.',
                  style: const TextStyle(
                      color: InternTheme.textMid,
                      fontSize: 13,
                      height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: _isAvailable
                          ? null
                          : InternTheme.headerGradient,
                      color: _isAvailable
                          ? InternTheme.danger.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      border: _isAvailable
                          ? Border.all(
                              color: InternTheme.danger.withOpacity(0.4))
                          : null,
                    ),
                    child: TextButton(
                      onPressed: _toggling ? null : _toggleAvailability,
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _toggling
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: InternTheme.primary))
                          : Text(
                              _isAvailable
                                  ? 'Go Offline'
                                  : 'Go Online & Accept Calls',
                              style: TextStyle(
                                color: _isAvailable
                                    ? InternTheme.danger
                                    : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Info card ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: InternTheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: InternTheme.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: InternTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'When a user calls you, a popup will appear automatically. '
                  'Keep the app open to receive calls.',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: InternTheme.primary,
                      height: 1.5),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}