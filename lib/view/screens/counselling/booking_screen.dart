import 'package:flutter/material.dart';
import 'package:supporthive1/view/screens/counselling/expert_app_theme.dart';
import '/model/expert_model.dart';
import '/model/booking_model.dart';
import '/service/booking_service.dart';


class BookingScreen extends StatefulWidget {
  final Expert expert;
  final String? initialType;

  const BookingScreen({super.key, required this.expert, this.initialType});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  SessionType _sessionType = SessionType.audio;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isOnline = true;
  bool _isLoading = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  final List<TimeOfDay> _timeSlots = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
    const TimeOfDay(hour: 18, minute: 0),
    const TimeOfDay(hour: 19, minute: 0),
    const TimeOfDay(hour: 20, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialType == 'video') _sessionType = SessionType.video;
    _selectedDate = DateTime.now();

    BookingService.instance.init();

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    BookingService.instance.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  List<DateTime> get _availableDates {
    final dates = <DateTime>[];
    var day = DateTime.now();
    while (dates.length < 7) {
      dates.add(day);
      day = day.add(const Duration(days: 1));
    }
    return dates;
  }

  bool _isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  Map<String, int> get _fees =>
      BookingService.calculateFees(widget.expert.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: SlideTransition(
        position: _slideAnim,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSessionType(),
                        const SizedBox(height: 24),
                        _buildModeToggle(),
                        const SizedBox(height: 24),
                        _buildDatePicker(),
                        const SizedBox(height: 24),
                        _buildTimeSlots(),
                        const SizedBox(height: 24),
                        _buildFeeCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildPayButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2))),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Book Session',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              Text('with ${widget.expert.name}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionLabel('Select Session Type'),
        const SizedBox(height: 12),
        Row(
          children: [
            _SessionTypeCard(
              label: 'Audio Call',
              subtitle: 'Voice only',
              icon: Icons.phone_rounded,
              selected: _sessionType == SessionType.audio,
              onTap: () => setState(() => _sessionType = SessionType.audio),
            ),
            const SizedBox(width: 12),
            _SessionTypeCard(
              label: 'Video Call',
              subtitle: 'Face to face',
              icon: Icons.videocam_rounded,
              selected: _sessionType == SessionType.video,
              onTap: () => setState(() => _sessionType = SessionType.video),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    final isWeekend = _selectedDate != null && _isWeekend(_selectedDate!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Session Mode'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              _ModeTab(
                  label: 'Online',
                  icon: Icons.wifi_rounded,
                  selected: _isOnline,
                  onTap: () => setState(() => _isOnline = true)),
              _ModeTab(
                label: 'Offline',
                icon: Icons.location_on_rounded,
                selected: !_isOnline,
                onTap:
                    isWeekend ? null : () => setState(() => _isOnline = false),
                disabled: isWeekend,
                disabledHint: isWeekend ? 'Weekends: Online only' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Select Date', icon: Icons.calendar_today_rounded),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            itemBuilder: (_, i) {
              final date = _availableDates[i];
              final selected = _selectedDate != null &&
                  date.day == _selectedDate!.day &&
                  date.month == _selectedDate!.month;
              final isWknd = _isWeekend(date);

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = date;
                  if (isWknd) _isOnline = true;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 60,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.divider),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_weekdayShort(date.weekday),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? Colors.white70
                                  : AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${date.day}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textPrimary)),
                      Text(_monthShort(date.month),
                          style: TextStyle(
                              fontSize: 9,
                              color: selected
                                  ? Colors.white60
                                  : AppTheme.textSecondary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Select Time Slot', icon: Icons.access_time_rounded),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeSlots.map((slot) {
            final selected = _selectedTime == slot;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          selected ? AppTheme.primary : AppTheme.divider),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: AppTheme.primary.withOpacity(0.25),
                              blurRadius: 6)
                        ]
                      : [],
                ),
                child: Text(_formatSlot(slot),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : AppTheme.textPrimary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeeCard() {
    final fees = _fees;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _feeRow('Session Fee', '₹${fees['price']}'),
          const SizedBox(height: 8),
          _feeRow('Platform Fee', '₹0'),
          const SizedBox(height: 8),
          _feeRow('GST (18%)', '₹${fees['gst']}'),
          const Divider(height: 20, color: Color(0xFFDDD6FE)),
          _feeRow('Total Amount', '₹${fees['total']}', isMain: true),
        ],
      ),
    );
  }

  Widget _feeRow(String label, String value, {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: isMain ? AppTheme.titleSm : AppTheme.bodySm),
        Text(value,
            style: isMain
                ? AppTheme.titleSm.copyWith(color: AppTheme.primary)
                : AppTheme.bodySm),
      ],
    );
  }

  Widget _buildPayButton() {
    final enabled = _selectedDate != null && _selectedTime != null;
    final fees = _fees;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 11, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                  'Secure payment via Razorpay • All transactions are encrypted',
                  style: AppTheme.labelSm.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: enabled && !_isLoading ? _onPay : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: enabled
                    ? AppTheme.headerGradient
                    : const LinearGradient(
                        colors: [Color(0xFFD1D5DB), Color(0xFFD1D5DB)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ]
                    : [],
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          enabled
                              ? 'Pay ₹${fees['total']} via Razorpay'
                              : 'Select date & time to continue',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text('💯 100% Money-back guarantee if session is cancelled',
              style: AppTheme.labelSm
                  .copyWith(fontSize: 10, color: AppTheme.accent)),
        ],
      ),
    );
  }

  void _onPay() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final scheduled = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() => _isLoading = true);

    try {
      await BookingService.instance.bookAndPay(
        expert: widget.expert,
        sessionType: _sessionType,
        scheduledAt: scheduled,
        isOnline: _isOnline,
        context: context,
        onFailure: () {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Payment failed. Please try again.'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Widget _sectionLabel(String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppTheme.primary),
          const SizedBox(width: 6),
        ],
        Text(text,
            style: AppTheme.titleSm
                .copyWith(fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }

  String _weekdayShort(int wd) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[wd - 1];
  }

  String _monthShort(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  String _formatSlot(TimeOfDay t) {
    final h =
        t.hour > 12 ? t.hour - 12 : t.hour == 0 ? 12 : t.hour;
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:${t.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _SessionTypeCard extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SessionTypeCard(
      {required this.label,
      required this.subtitle,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.divider,
                width: selected ? 2 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: AppTheme.primary.withOpacity(0.15),
                        blurRadius: 10)
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 24,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textPrimary)),
              Text(subtitle,
                  style: AppTheme.bodySm.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;
  final String? disabledHint;

  const _ModeTab(
      {required this.label,
      required this.icon,
      required this.selected,
      this.onTap,
      this.disabled = false,
      this.disabledHint});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: disabledHint ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 14,
                    color: disabled
                        ? Colors.grey.shade400
                        : selected
                            ? Colors.white
                            : AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: disabled
                            ? Colors.grey.shade400
                            : selected
                                ? Colors.white
                                : AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
