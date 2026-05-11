import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DashboardChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> categoryData;

  const DashboardChartWidget({
    super.key,
    this.categoryData = const [],
  });

  @override
  State<DashboardChartWidget> createState() => _DashboardChartWidgetState();
}

class _DashboardChartWidgetState extends State<DashboardChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Magdagdag ng produkto para makita ang chart.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant.withAlpha(150),
          ),
        ),
      );
    }

    // Calculate total units for header
    final totalUnits = widget.categoryData.fold<double>(0, (sum, item) => sum + (item['value'] as double));
    final totalProducts = widget.categoryData.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.label_important_outline, size: 18, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                Text(
                  'Stock sa Kategorya',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Lahat >',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
          ],
        ),
        Text(
          '${totalUnits.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} kabuuang units sa $totalProducts kategorya',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant.withAlpha(150),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(widget.categoryData.length, (index) {
              final cat = widget.categoryData[index];
              final percentage = totalUnits > 0 ? (cat['value'] as double) / totalUnits : 0.0;
              
              return _buildCategoryRow(
                label: cat['label'] as String,
                units: (cat['value'] as double).toInt(),
                percentage: percentage,
                color: cat['color'] as Color,
                isLast: index == widget.categoryData.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow({
    required String label,
    required int units,
    required double percentage,
    required Color color,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$units units',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant.withAlpha(180),
                ),
              ),
              Text(
                '18 produkto', // TODO: Pass real count
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant.withAlpha(150),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: percentage * _animation.value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(40),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.background),
          ],
        ],
      ),
    );
  }
}