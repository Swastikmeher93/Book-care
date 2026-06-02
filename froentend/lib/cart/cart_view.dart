import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'cart_controller.dart';
import '../providers/patient_provider.dart';

class CartView extends ConsumerStatefulWidget {
  const CartView({super.key});

  @override
  ConsumerState<CartView> createState() => _CartViewState();
}

class _CartViewState extends ConsumerState<CartView> {
  bool _isCheckingOut = false;

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(String patientId) async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      final bookingResponse = await ref.read(cartProvider.notifier).checkout(patientId);
      if (mounted) {
        context.push('/cart/booking-confirmed', extra: {'booking': bookingResponse});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final serviceFee = ref.watch(cartServiceFeeProvider);
    final total = ref.watch(cartTotalProvider);
    final patientProfileAsync = ref.watch(patientProfileProvider);

    final patientId = patientProfileAsync.value?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => context.pop(),
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
          'Your Cart',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111216),
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
          if (cartItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9098A3),
                  ),
                ),
              ),
            )
          else
            ...cartItems.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartCard(
                    item: item,
                    onRemove: () => ref.read(cartProvider.notifier).remove(index),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          // ── Payment Summary ───────────────────────────────────────────────
          _PaymentSummaryCard(
            subtotal: subtotal,
            serviceFee: serviceFee,
            total: total,
          ),
          const SizedBox(height: 24),
          // ── Checkout Button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: cartItems.isEmpty || _isCheckingOut
                  ? null
                  : () {
                      if (patientId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Patient profile not loaded yet. Please wait.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      _handleCheckout(patientId);
                    },
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
              icon: _isCheckingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined, size: 20),
              label: Text(_isCheckingOut ? 'Processing Checkout...' : 'Proceed to Checkout'),
            ),
          ),
          const SizedBox(height: 12),
          // ── Clear Cart Button ─────────────────────────────────────────────
          TextButton(
            onPressed: cartItems.isEmpty || _isCheckingOut
                ? null
                : () => _showClearConfirm(context),
            style: TextButton.styleFrom(
              foregroundColor: cartItems.isEmpty
                  ? const Color(0xFFADB5C4)
                  : const Color(0xFF2F80FF),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }
}

// ── Cart Card ──────────────────────────────────────────────────────────────
class _CartCard extends StatelessWidget {
  const _CartCard({required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFF9098A3), size: 14),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.room,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4D4F), size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onRemove,
              ),
              const SizedBox(height: 12),
              Text(
                '\$${item.price}',
                style: const TextStyle(
                  fontSize: 16,
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

// ── Payment Summary ───────────────────────────────────────────────
class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.subtotal,
    required this.serviceFee,
    required this.total,
  });

  final int subtotal;
  final int serviceFee;
  final int total;

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
          _SummaryRow(label: 'Subtotal', value: '\$$subtotal', valueBold: false),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Service Fee', value: '\$$serviceFee', valueBold: false),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Estimated Total',
            value: '\$$total',
            valueBold: true,
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

// ── Shared ────────────────────────────────────────────────────────────────────
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