import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DashboardKpiGridWidget extends StatefulWidget {
  final bool tabletMode;
  final int totalProducts;
  final int lowStockCount;

  const DashboardKpiGridWidget({
    super.key,
    this.tabletMode = false,
    this.totalProducts = 0,
    this.lowStockCount = 0,
  });

  @override
  State<DashboardKpiGridWidget> createState() => _DashboardKpiGridWidgetState();
}

class _DashboardKpiGridWidgetState extends State<DashboardKpiGridWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  List<Map<String, dynamic>> get _kpiData => [
    {
      'label': 'Kabuuang SKU',
      'value': widget.totalProducts,
      'suffix': ' items',
      'icon': Icons.inventory_2_outlined,
      'color': AppTheme.primary,
      'bgColor': const Color(0xFFE8F5F1),
      'change': 'Live data mula Supabase',
      'changePositive': true,
    },
    {
      'label': 'Mababa ang Stock',
      'value': widget.lowStockCount,
      'suffix': ' produkto',
      'icon': Icons.warning_amber_rounded,
      'color': AppTheme.lowStock,
      'bgColor': const Color(0xFFFFF3E0),
      'change': 'Kailangan i-restock',
      'changePositive': false,
    },
    {
      'label': 'Wala na',
      'value': 0, // Placeholder
      'suffix': ' produkto',
      'icon': Icons.remove_shopping_cart_outlined,
      'color': AppTheme.error,
      'bgColor': const Color(0xFFFFEBEE),
      'change': '₱0 na nawalang benta',
      'changePositive': false,
    },
    {
      'label': 'Halaga ng Stock',
      'value': 0, // Placeholder
      'suffix': '',
      'prefix': '₱',
      'icon': Icons.account_balance_wallet_outlined,
      'color': const Color(0xFF1565C0),
      'bgColor': const Color(0xFFE3F2FD),
      'change': 'Halaga ng iyong tindahan',
      'changePositive': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _kpiData.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + i * 100),
      ),
    );
    _animations = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.tabletMode ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: widget.tabletMode ? 1.1 : 1.35,
      ),
      itemCount: _kpiData.length,
      itemBuilder: (context, index) {
        final kpi = _kpiData[index];
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Opacity(
              opacity: _animations[index].value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _animations[index].value)),
                child: child,
              ),
            );
          },
          child: _KpiCard(kpi: kpi, animation: _animations[index]),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final Map<String, dynamic> kpi;
  final Animation<double> animation;

  const _KpiCard({required this.kpi, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kpi['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  kpi['icon'] as IconData,
                  color: kpi['color'] as Color,
                  size: 18,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: kpi['changePositive'] as bool
                      ? AppTheme.success
                      : AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final targetValue = kpi['value'] as int;
                  final displayValue = (targetValue * animation.value).round();
                  final isLarge = targetValue > 9999;
                  return Text(
                    '${kpi['prefix'] ?? ''}${isLarge ? _formatLarge(displayValue) : displayValue}${kpi['suffix']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isLarge ? 20 : 24,
                      fontWeight: FontWeight.w800,
                      color: kpi['color'] as Color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1.1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                kpi['label'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                kpi['change'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: kpi['changePositive'] as bool
                      ? AppTheme.success
                      : AppTheme.lowStock,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLarge(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
