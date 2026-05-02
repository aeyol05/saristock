import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DashboardRecentTransactionsWidget extends StatelessWidget {
  final bool compact;
  final List<Map<String, dynamic>> transactions;

  const DashboardRecentTransactionsWidget({
    super.key,
    this.compact = false,
    this.transactions = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Wala pang kamakailang transaksyon.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.outline,
            ),
          ),
        ),
      );
    }
    final displayCount = compact ? 4 : transactions.length;
    return Column(
      children: List.generate(
        displayCount.clamp(0, transactions.length),
        (index) => _TransactionItem(txn: transactions[index], index: index),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> txn;
  final int index;

  const _TransactionItem({required this.txn, required this.index});

  @override
  Widget build(BuildContext context) {
    final isRestock = txn['type'] == 'restock';
    final isDeduct = txn['type'] == 'deduct';
    final qty = txn['quantityChange'] as int;
    final color = isRestock
        ? AppTheme.success
        : isDeduct
        ? AppTheme.error
        : AppTheme.warning;
    final bgColor = isRestock
        ? AppTheme.successContainer
        : isDeduct
        ? AppTheme.errorContainer
        : AppTheme.warningContainer;
    final icon = isRestock
        ? Icons.add_circle_outline_rounded
        : isDeduct
        ? Icons.remove_circle_outline_rounded
        : Icons.tune_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn['productName'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        txn['operator'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppTheme.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        txn['timestamp'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.outline,
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
              children: [
                Text(
                  '${qty > 0 ? '+' : ''}$qty',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  txn['unit'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
