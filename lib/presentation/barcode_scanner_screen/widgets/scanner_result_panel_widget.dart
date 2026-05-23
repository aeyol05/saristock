import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../inventory_dashboard_screen/widgets/add_product_bottom_sheet_widget.dart';

class ScannerResultPanelWidget extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onClose;
  final Function(int newQty) onStockUpdated;

  const ScannerResultPanelWidget({
    super.key,
    required this.product,
    required this.onClose,
    required this.onStockUpdated,
  });

  @override
  State<ScannerResultPanelWidget> createState() =>
      _ScannerResultPanelWidgetState();
}

class _ScannerResultPanelWidgetState extends State<ScannerResultPanelWidget> {
  late int _adjustmentQty;
  late int _currentStock;
  bool _isSaving = false;
  String _adjustmentType = 'add'; // 'add' or 'deduct'

  @override
  void initState() {
    super.initState();
    _currentStock = widget.product['currentStock'] as int;
    _adjustmentQty = 1;
  }

  StockStatus _getStatus(int qty, int reorderLevel) {
    if (qty == 0) return StockStatus.outOfStock;
    if (qty <= reorderLevel ~/ 2) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  void _increment() => setState(() => _adjustmentQty++);
  void _decrement() {
    if (_adjustmentQty > 1) setState(() => _adjustmentQty--);
  }

  Future<void> _updateStock() async {
    setState(() => _isSaving = true);
    // TODO: Replace with real stock update API call
    await Future.delayed(const Duration(milliseconds: 800));

    final newQty = _adjustmentType == 'add'
        ? _currentStock + _adjustmentQty
        : (_currentStock - _adjustmentQty).clamp(0, 99999);

    if (mounted) {
      setState(() {
        _currentStock = newQty;
        _isSaving = false;
        _adjustmentQty = 1;
      });
      widget.onStockUpdated(newQty);
      Fluttertoast.showToast(
        msg:
            '${widget.product['name']} na-update: $newQty ${widget.product['unit']}',
        backgroundColor: AppTheme.success,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.product['isNew'] == true;
    final reorderLevel = widget.product['reorderLevel'] as int;
    final status = _getStatus(_currentStock, reorderLevel);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Row(
                  children: [
                    // Product image/icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.product['imageUrl'] != null
                            ? Image.network(
                                widget.product['imageUrl'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppTheme.outline,
                                  size: 28,
                                ),
                              )
                            : const Icon(
                                Icons.inventory_2_outlined,
                                color: AppTheme.outline,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              StatusBadgeWidget(status: status, compact: true),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.product['category'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.outline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metadata chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MetaChip(
                        icon: Icons.qr_code_rounded,
                        label: widget.product['barcode'] as String,
                      ),
                      const SizedBox(width: 8),
                      _MetaChip(
                        icon: Icons.local_shipping_outlined,
                        label: widget.product['supplier'] as String,
                      ),
                      const SizedBox(width: 8),
                      _MetaChip(
                        icon: Icons.payments_outlined,
                        label:
                            '₱${(widget.product['price'] as double).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Current stock display
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: status == StockStatus.outOfStock
                        ? AppTheme.errorContainer
                        : status == StockStatus.lowStock
                        ? AppTheme.lowStockContainer
                        : AppTheme.successContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: status == StockStatus.outOfStock
                          ? AppTheme.error.withAlpha(77)
                          : status == StockStatus.lowStock
                          ? AppTheme.lowStock.withAlpha(77)
                          : AppTheme.success.withAlpha(77),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kasalukuyang Stock',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_currentStock',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: status == StockStatus.outOfStock
                                      ? AppTheme.error
                                      : status == StockStatus.lowStock
                                      ? AppTheme.lowStock
                                      : AppTheme.success,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.product['unit'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Reorder Level',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$reorderLevel ${widget.product['unit']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (!isNew) ...[
                  // Adjustment type toggle
                  Row(
                    children: [
                      Expanded(
                        child: _AdjustmentTypeButton(
                          label: 'Dagdag Stock',
                          icon: Icons.add_circle_outline_rounded,
                          isSelected: _adjustmentType == 'add',
                          color: AppTheme.success,
                          onTap: () => setState(() => _adjustmentType = 'add'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AdjustmentTypeButton(
                          label: 'Bawas Stock',
                          icon: Icons.remove_circle_outline_rounded,
                          isSelected: _adjustmentType == 'deduct',
                          color: AppTheme.error,
                          onTap: () =>
                              setState(() => _adjustmentType = 'deduct'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quantity adjuster
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dami',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          children: [
                            _QtyButton(
                              icon: Icons.remove_rounded,
                              onTap: _decrement,
                              enabled: _adjustmentQty > 1,
                            ),
                            Container(
                              width: 52,
                              alignment: Alignment.center,
                              child: Text(
                                '$_adjustmentQty',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add_rounded,
                              onTap: _increment,
                              enabled: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Update button
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _updateStock,
                      style: FilledButton.styleFrom(
                        backgroundColor: _adjustmentType == 'add'
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _adjustmentType == 'add'
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.remove_circle_outline_rounded,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Nagse-save...'
                            : _adjustmentType == 'add'
                            ? 'Dagdag $_adjustmentQty ${widget.product['unit']}'
                            : 'Bawas $_adjustmentQty ${widget.product['unit']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // New product CTA
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final barcode = widget.product['barcode'] as String?;
                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddProductBottomSheetWidget(
                            initialBarcode: barcode,
                          ),
                        );
                        if (result == true) widget.onClose();
                      },
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(
                        'Irehistro ang Bagong Produkto',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AdjustmentTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(31) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppTheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : AppTheme.outline),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primary : AppTheme.outlineVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : AppTheme.outline,
        ),
      ),
    );
  }
}
