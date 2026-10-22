/// ─────────────────────────────────────────────────────────────────────────────
/// view/screens/admin/admin_bookings_tab.dart
///
/// Shows all bookings in real-time. Admin can approve or reject pending ones.
/// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/service/admin_firestore_service.dart';

class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  String _filter = 'all'; // all | pending | confirmed | cancelled

  static const _primary = Color(0xFF7C3AED);
  static const _bg = Color(0xFF0F0A1E);
  static const _surface = Color(0xFF1A1033);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AdminFirestoreService.instance.bookingsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: _primary));
                }

                var bookings = snap.data ?? [];

                if (_filter != 'all') {
                  bookings = bookings
                      .where((b) => b['status'] == _filter)
                      .toList();
                }

                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 56,
                            color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 14),
                        Text(
                          _filter == 'all'
                              ? 'No bookings yet.'
                              : 'No $_filter bookings.',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: bookings.length,
                  itemBuilder: (_, i) =>
                      _BookingCard(booking: bookings[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    const filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('confirmed', 'Confirmed'),
      ('cancelled', 'Cancelled'),
    ];
    return Container(
      color: _surface,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters
            .map((f) => _FilterChip(
                  label: f.$2,
                  selected: _filter == f.$1,
                  onTap: () => setState(() => _filter = f.$1),
                ))
            .toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7C3AED)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.white54),
        ),
      ),
    );
  }
}

// ── Booking card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  static const _surface = Color(0xFF1A1033);

  String get _bookingId => booking['id'] as String? ?? '';
  String get _status => booking['status'] as String? ?? 'pending';
  bool get _isPaid => booking['isPaid'] as bool? ?? false;

  DateTime? get _scheduledAt {
    final ts = booking['scheduledAt'];
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  Color get _statusColor {
    switch (_status) {
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['expertName'] ?? 'Unknown Expert',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking['expertSpecialization'] ?? '',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _status[0].toUpperCase() + _status.substring(1),
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // ── Details grid ───────────────────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (_scheduledAt != null)
                _info(Icons.calendar_today_rounded,
                    _formatDate(_scheduledAt!)),
              _info(
                booking['sessionType'] == 'video'
                    ? Icons.videocam_rounded
                    : Icons.phone_rounded,
                '${(booking['sessionType'] ?? 'audio').toString()[0].toUpperCase()}'
                '${(booking['sessionType'] ?? 'audio').toString().substring(1)} Call',
              ),
              _info(
                Icons.currency_rupee_rounded,
                '₹${booking['totalAmount'] ?? 0}',
              ),
              _info(
                _isPaid
                    ? Icons.check_circle_rounded
                    : Icons.pending_rounded,
                _isPaid ? 'Paid' : 'Unpaid',
              ),
            ],
          ),

          // ── Action buttons (only for pending) ──────────────────────────
          if (_status == 'pending' && _bookingId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        AdminFirestoreService.instance
                            .rejectBooking(_bookingId),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reject',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        AdminFirestoreService.instance
                            .approveBooking(_bookingId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Approve',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, '
        '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}