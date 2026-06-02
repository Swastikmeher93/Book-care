import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/patient_provider.dart';

class BookingConfirmedView extends ConsumerWidget {
  const BookingConfirmedView({super.key, this.bookingData});

  final Map<String, dynamic>? bookingData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookingData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Booking details not available.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final patientAsync = ref.watch(patientProfileProvider);
    final firstName = patientAsync.maybeWhen(
      data: (profile) => profile != null ? profile.firstName : 'User',
      orElse: () => 'User',
    );

    final total = (bookingData?['total_price'] as num? ?? 0.0).toDouble();
    final double serviceFee = total > 0 ? 8.0 : 0.0;
    final double subtotal = total - serviceFee;

    final List itemsList = bookingData?['items'] as List? ?? [];
    final confirmedItems = itemsList.map((item) {
      final serviceName = item['service_name'] as String? ?? 'Service';
      final cgFirst = item['caregiver_first_name'] as String? ?? '';
      final cgLast = item['caregiver_last_name'] as String? ?? '';
      final caregiverName = cgFirst.isEmpty && cgLast.isEmpty
          ? 'Assigned Staff'
          : 'Dr. $cgFirst $cgLast';

      final rawDate = item['scheduled_date'] as String? ?? '';
      final rawTime = item['start_time'] as String? ?? '';

      return _ConfirmedItem(
        title: serviceName,
        icon: _getIconForName(serviceName),
        date: _formatScheduledDate(rawDate),
        time: _formatStartTime(rawTime),
        room: 'Clinic Room',
        price: (item['price'] as num? ?? 0.0).toDouble(),
        caregiverName: caregiverName,
        caregiverId: item['caregiver_id'] as String? ?? '',
      );
    }).toList();

    final orderId = bookingData?['id']?.toString() ?? 'CB-20847';
    final displayOrderId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => context.go('/home'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F3F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFF111216), size: 20),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Booking Confirmed',
          style: TextStyle(
            color: Color(0xFF111216),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEFF3)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
        children: [
          // ── Success icon ──────────────────────────────────────────────────
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD6E8FF),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            "You're all set, $firstName!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111216),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your appointments have been booked successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9098A3),
            ),
          ),
          const SizedBox(height: 16),

          // ── Order number pill ─────────────────────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag, color: Color(0xFF2F80FF), size: 17),
                  const SizedBox(width: 6),
                  Text(
                    'Order #$displayOrderId',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111216),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Confirmed Bookings ────────────────────────────────────────────
          const Text(
            'Confirmed Bookings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111216),
            ),
          ),
          const SizedBox(height: 14),
          ...confirmedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ConfirmedBookingCard(item: item),
            ),
          ),
          const SizedBox(height: 8),

          // ── Payment Summary ───────────────────────────────────────────────
          _ConfirmedPaymentSummaryCard(
            subtotal: subtotal,
            serviceFee: serviceFee,
            total: total,
          ),
          const SizedBox(height: 24),

          // ── Add to Calendar ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2F80FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              label: const Text('Add to Calendar'),
            ),
          ),
          const SizedBox(height: 12),

          // ── Download Receipt ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF111216),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.download_outlined, size: 20),
              label: const Text('Download Receipt'),
            ),
          ),
          const SizedBox(height: 12),

          // ── Back to Home ──────────────────────────────────────────────────
          TextButton(
            onPressed: () => context.go('/home'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2F80FF),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Back to Home'),
          ),
          const SizedBox(height: 16),

          // ── Email confirmation ────────────────────────────────────────────
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF9098A3), size: 16),
              SizedBox(width: 6),
              Text(
                'A confirmation has been sent to your email',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9098A3),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmedItem {
  const _ConfirmedItem({
    required this.title,
    required this.icon,
    required this.date,
    required this.time,
    required this.room,
    required this.price,
    required this.caregiverName,
    required this.caregiverId,
  });

  final String title;
  final IconData icon;
  final String date;
  final String time;
  final String room;
  final double price;
  final String caregiverName;
  final String caregiverId;
}

class _ConfirmedBookingCard extends StatelessWidget {
  const _ConfirmedBookingCard({required this.item});

  final _ConfirmedItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceIconTile(icon: item.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111216),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9098A3),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TimePill(time: item.time),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline,
                        color: Color(0xFF9098A3), size: 14),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.caregiverName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9098A3),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${item.price.toInt()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F80FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedPaymentSummaryCard extends StatelessWidget {
  const _ConfirmedPaymentSummaryCard({
    required this.subtotal,
    required this.serviceFee,
    required this.total,
  });

  final double subtotal;
  final double serviceFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111216),
            ),
          ),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Subtotal', value: '\$${subtotal.toInt()}', valueBold: false),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Service Fee', value: '\$${serviceFee.toInt()}', valueBold: false),
          const SizedBox(height: 10),
          const _SummaryRow(
            label: 'Payment Method',
            value: 'Visa \u2022\u2022\u2022\u2022 4242',
            valueBold: false,
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFD4E3FF), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111216),
                ),
              ),
              Text(
                '\$${total.toInt()}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2F80FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueBold,
  });

  final String label;
  final String value;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9098A3),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF111216),
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ServiceIconTile extends StatelessWidget {
  const _ServiceIconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: const Color(0xFF2F80FF), size: 24),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_outlined,
              color: Color(0xFF2F80FF), size: 14),
          const SizedBox(width: 5),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F80FF),
            ),
          ),
        ],
      ),
    );
  }
}

const _fullDayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatDate(DateTime d) {
  final day = _fullDayNames[d.weekday - 1];
  final month = _monthNames[d.month - 1];
  return '$day, ${d.day} $month ${d.year}';
}

String _formatScheduledDate(String dateStr) {
  try {
    final parsed = DateTime.parse(dateStr);
    return _formatDate(parsed);
  } catch (_) {
    return dateStr;
  }
}

String _formatStartTime(String timeStr) {
  try {
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    var hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  } catch (_) {
    return timeStr;
  }
}

IconData _getIconForName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('wound') || lower.contains('dressing')) {
    return Icons.grid_view_rounded;
  } else if (lower.contains('physio') || lower.contains('therapy')) {
    return Icons.show_chart;
  } else if (lower.contains('vaccin') || lower.contains('immun')) {
    return Icons.vaccines_outlined;
  } else if (lower.contains('checkup') || lower.contains('assess')) {
    return Icons.health_and_safety_outlined;
  } else if (lower.contains('dental') || lower.contains('clean')) {
    return Icons.sentiment_satisfied_alt_outlined;
  }
  return Icons.medical_services_outlined;
}