import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StockStatus { inStock, lowStock, outOfStock, restocked }

class StatusBadgeWidget extends StatelessWidget {
  final StockStatus status;
  final bool compact;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            config.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return _StatusConfig(
          label: 'In Stock',
          bgColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFFA5D6A7),
          dotColor: const Color(0xFF2E7D32),
          textColor: const Color(0xFF1B5E20),
        );
      case StockStatus.lowStock:
        return _StatusConfig(
          label: 'Low Stock',
          bgColor: const Color(0xFFFFF3E0),
          borderColor: const Color(0xFFFFCC80),
          dotColor: const Color(0xFFE65100),
          textColor: const Color(0xFFBF360C),
        );
      case StockStatus.outOfStock:
        return _StatusConfig(
          label: 'Out of Stock',
          bgColor: const Color(0xFFFFEBEE),
          borderColor: const Color(0xFFEF9A9A),
          dotColor: const Color(0xFFC62828),
          textColor: const Color(0xFF7F0000),
        );
      case StockStatus.restocked:
        return _StatusConfig(
          label: 'Restocked',
          bgColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFF90CAF9),
          dotColor: const Color(0xFF1565C0),
          textColor: const Color(0xFF0D47A1),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color dotColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.dotColor,
    required this.textColor,
  });
}
