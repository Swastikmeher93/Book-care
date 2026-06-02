import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cart/cart_controller.dart';
import '../services_card/services/services_controller.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _fullDayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

String _formatDate(DateTime d) {
  // "Monday, 24 June 2025"
  final day = _fullDayNames[d.weekday - 1];
  final month = _monthNames[d.month - 1];
  return '$day, ${d.day} $month ${d.year}';
}

/// Generates time slots from 09:00 to 17:30 at [intervalMinutes] intervals.
List<String> _generateTimeSlots({int intervalMinutes = 15}) {
  final slots = <String>[];
  var hour = 9;
  var minute = 0;
  while (hour < 17 || (hour == 17 && minute <= 30)) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    slots.add('${h.toString().padLeft(2, '0')}:$m $period');
    minute += intervalMinutes;
    if (minute >= 60) {
      minute -= 60;
      hour++;
    }
  }
  return slots;
}

// ── Main View ─────────────────────────────────────────────────────────────────

class ServiceDetailView extends ConsumerStatefulWidget {
  const ServiceDetailView({super.key, required this.service});

  final ServiceItem service;

  @override
  ConsumerState<ServiceDetailView> createState() => _ServiceDetailViewState();
}

class _ServiceDetailViewState extends ConsumerState<ServiceDetailView> {
  late final List<String> _timeSlots;
  late final List<DateTime> _dates;

  int _selectedDateIndex = 0;
  int _selectedSlotIndex = -1; // none selected by default

  @override
  void initState() {
    super.initState();
    _timeSlots = _generateTimeSlots(intervalMinutes: 15);
    final today = DateTime.now();
    _dates = List.generate(14, (i) => today.add(Duration(days: i)));
  }

  bool get _canAddToCart => _selectedSlotIndex != -1;

  void _onAddToCart() {
    if (!_canAddToCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final date = _formatDate(_dates[_selectedDateIndex]);
    final time = _timeSlots[_selectedSlotIndex];

    ref.read(cartProvider.notifier).add(
          CartItem(
            title: widget.service.title,
            icon: widget.service.icon,
            date: date,
            time: time,
            room: widget.service.room,
            price: widget.service.price,
          ),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.service.title} added to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2F80FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F3F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back,
                color: Color(0xFF111216), size: 20),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Book a Service',
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                // Hero card
                _HeroCard(service: service),
                const SizedBox(height: 28),

                // Date picker
                const Text(
                  'Select a Date',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111216),
                  ),
                ),
                const SizedBox(height: 16),
                _DateStrip(
                  dates: _dates,
                  selectedIndex: _selectedDateIndex,
                  onSelect: (i) => setState(() {
                    _selectedDateIndex = i;
                    _selectedSlotIndex = -1;
                  }),
                ),
                const SizedBox(height: 28),

                // Time slots
                const Text(
                  'Available Time Slots',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111216),
                  ),
                ),
                const SizedBox(height: 16),
                _TimeSlotsGrid(
                  slots: _timeSlots,
                  selectedIndex: _selectedSlotIndex,
                  unavailableIndices: service.unavailableSlotIndices,
                  onSelect: (i) => setState(() => _selectedSlotIndex = i),
                ),
                const SizedBox(height: 28),

                // Session details
                const Text(
                  'Session Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111216),
                  ),
                ),
                const SizedBox(height: 16),
                _SessionDetailsCard(service: service),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _AddToCartBar(
            enabled: _canAddToCart,
            onTap: _onAddToCart,
          ),
        ],
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2F80FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(service.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                service.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                service.priceDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Date Strip ────────────────────────────────────────────────────────────────

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.dates,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DateTime> dates;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final d = dates[i];
          final isSelected = i == selectedIndex;
          final dayName = _dayNames[d.weekday - 1];
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2F80FF)
                        : const Color(0xFF9098A3),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF2F80FF)
                        : Colors.transparent,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF111216),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Time Slots Grid ───────────────────────────────────────────────────────────

class _TimeSlotsGrid extends StatelessWidget {
  const _TimeSlotsGrid({
    required this.slots,
    required this.selectedIndex,
    required this.unavailableIndices,
    required this.onSelect,
  });

  final List<String> slots;
  final int selectedIndex;
  final Set<int> unavailableIndices;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(slots.length, (i) {
            final isSelected = i == selectedIndex;
            final isUnavailable = unavailableIndices.contains(i);

            return SizedBox(
              width: itemWidth,
              height: 48,
              child: GestureDetector(
                onTap: isUnavailable ? null : () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isUnavailable
                        ? const Color(0xFFF2F3F7)
                        : isSelected
                            ? const Color(0xFF2F80FF)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected || isUnavailable
                        ? null
                        : Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.2),
                  ),
                  child: Center(
                    child: isUnavailable
                        ? Text(
                            slots[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9098A3),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: const Color(0xFF9098A3),
                            ),
                          )
                        : Text(
                            slots[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF111216),
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Session Details Card ──────────────────────────────────────────────────────

class _SessionDetailsCard extends StatelessWidget {
  const _SessionDetailsCard({required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_outlined,
                  color: Color(0xFF2F80FF), size: 20),
            ),
            label: 'Duration',
            value: service.duration,
          ),
          const SizedBox(height: 16),
          _DetailRow(
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF2F80FF), size: 20),
            ),
            label: 'Location',
            value: service.room,
          ),
          const SizedBox(height: 16),
          _DetailRow(
            leading: ClipOval(
              child: Image.network(
                'https://i.pravatar.cc/40?u=${service.staffAvatarSeed}',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Color(0xFF2F80FF), size: 20),
                ),
              ),
            ),
            label: 'Assigned Staff',
            value: service.staffName,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9098A3),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111216),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Add to Cart Bar ───────────────────────────────────────────────────────────

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEFF3))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor:
                enabled ? const Color(0xFF2F80FF) : const Color(0xFFADB5C4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.shopping_cart_outlined, size: 20),
          label: const Text('Add to Cart'),
        ),
      ),
    );
  }
}
