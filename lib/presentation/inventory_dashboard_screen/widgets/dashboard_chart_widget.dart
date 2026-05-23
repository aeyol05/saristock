import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DashboardChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> categoryData;

  const DashboardChartWidget({super.key, this.categoryData = const []});

  @override
  State<DashboardChartWidget> createState() => _DashboardChartWidgetState();
}

class _DashboardChartWidgetState extends State<DashboardChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.donut_large_rounded, size: 40, color: AppTheme.outlineVariant),
            const SizedBox(height: 8),
            Text('Magdagdag ng produkto para makita ang chart.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.onSurfaceVariant.withAlpha(150))),
          ],
        ),
      );
    }

    final total = widget.categoryData.fold<double>(0, (sum, item) => sum + (item['value'] as double));

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Donut chart with center label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: _buildSections(total),
                      centerSpaceRadius: 54,
                      sectionsSpace: 0,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                          setState(() {
                            if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                              _touchedIndex = -1;
                            } else {
                              _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                            }
                          });
                        },
                      ),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 600),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                  // Center label
                  _touchedIndex >= 0 && _touchedIndex < widget.categoryData.length
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (widget.categoryData[_touchedIndex]['value'] as double).toInt().toString(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: widget.categoryData[_touchedIndex]['color'] as Color),
                            ),
                            Text(
                              'units',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant.withAlpha(150)),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              total.toInt().toString(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
                            ),
                            Text(
                              'units',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant.withAlpha(150)),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppTheme.outlineVariant),
          // Legend
          ...widget.categoryData.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            final isLast = index == widget.categoryData.length - 1;
            final percentage = total > 0 ? (cat['value'] as double) / total : 0.0;
            return _buildLegendRow(index: index, label: cat['label'] as String, units: (cat['value'] as double).toInt(), percentage: percentage, color: cat['color'] as Color, isLast: isLast, isSelected: index == _touchedIndex);
          }),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    return widget.categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value;
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        color: cat['color'] as Color,
        value: cat['value'] as double,
        title: '',
        radius: isTouched ? 64 : 56,
        showTitle: false,
      );
    }).toList();
  }

  Widget _buildLegendRow({required int index, required String label, required int units, required double percentage, required Color color, bool isLast = false, bool isSelected = false}) {
    return GestureDetector(
      onTap: () => setState(() => _touchedIndex = isSelected ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected ? color.withAlpha(12) : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 12 : 10,
                  height: isSelected ? 12 : 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? color : AppTheme.onSurface),
                  ),
                ),
                Text(
                  '$units units',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant.withAlpha(150)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 40,
                  child: Text(
                    percentage * 100 < 1 ? '<1%' : '${(percentage * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
            if (!isLast) ...[const SizedBox(height: 10), Divider(height: 1, color: AppTheme.outlineVariant)],
          ],
        ),
      ),
    );
  }
}
