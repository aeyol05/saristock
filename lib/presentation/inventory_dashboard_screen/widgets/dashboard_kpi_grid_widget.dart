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
      'gradient': AppTheme.cardTeal,
      'change': 'Live data mula Store',
      'changePositive': true,
    },
    {
      'label': 'Mababa ang Stock',
      'value': widget.lowStockCount,
      'suffix': ' produkto',
      'icon': Icons.warning_amber_rounded,
      'gradient': AppTheme.cardAmber,
      'change': 'Stock ay sapat',
      'changePositive': false,
    },
    {
      'label': 'Wala na',
      'value': 0,
      'suffix': ' produkto',
      'icon': Icons.remove_shopping_cart_outlined,
      'gradient': AppTheme.cardRose,
      'change': 'Walang out of stock',
      'changePositive': false,
    },
    {
      'label': 'Halaga ng Stock',
      'value': 0,
      'suffix': '',
      'prefix': '₱',
      'icon': Icons.account_balance_wallet_outlined,
      'gradient': AppTheme.cardViolet,
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
        gradient: kpi['gradient'] as Gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (kpi['gradient'] as LinearGradient).colors.first.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decorative Circle
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      kpi['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
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
                          fontSize: isLarge ? 20 : 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(220),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kpi['change'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha(180),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
