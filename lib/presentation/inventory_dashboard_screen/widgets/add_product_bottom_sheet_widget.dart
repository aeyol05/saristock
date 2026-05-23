import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/services/supabase_service.dart';
import '../../../theme/app_theme.dart';

class AddProductBottomSheetWidget extends StatefulWidget {
  /// Pass an existing product map to enter edit mode.
  final Map<String, dynamic>? product;
  /// Pre-fill the barcode field in add mode (e.g. from a scanner result).
  final String? initialBarcode;

  const AddProductBottomSheetWidget({super.key, this.product, this.initialBarcode});

  bool get isEditMode => product != null;

  @override
  State<AddProductBottomSheetWidget> createState() =>
      _AddProductBottomSheetWidgetState();
}

class _AddProductBottomSheetWidgetState
    extends State<AddProductBottomSheetWidget> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _stockController;
  late final TextEditingController _priceController;
  late String _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Canned Goods',
    'Beverages',
    'Snacks',
    'Condiments',
    'Personal Care',
    'Frozen Goods',
    'Rice & Grains',
    'Instant Noodles',
    'Dairy',
    'Tobacco',
  ];

  static const _categoryMeta = <String, Map<String, Object>>{
    'Canned Goods':    {'icon': Icons.fastfood_rounded,           'color': Color(0xFFFFA000)},
    'Beverages':       {'icon': Icons.local_drink_rounded,         'color': Color(0xFF1565C0)},
    'Snacks':          {'icon': Icons.cookie_rounded,              'color': Color(0xFFE65100)},
    'Condiments':      {'icon': Icons.restaurant_rounded,          'color': Color(0xFF00897B)},
    'Personal Care':   {'icon': Icons.soap_rounded,                'color': Color(0xFF7C4DFF)},
    'Frozen Goods':    {'icon': Icons.ac_unit_rounded,             'color': Color(0xFF0288D1)},
    'Rice & Grains':   {'icon': Icons.grass_rounded,               'color': Color(0xFF558B2F)},
    'Instant Noodles': {'icon': Icons.ramen_dining_rounded,        'color': Color(0xFFBF360C)},
    'Dairy':           {'icon': Icons.local_cafe_rounded,          'color': Color(0xFF546E7A)},
    'Tobacco':         {'icon': Icons.smoking_rooms_rounded,       'color': Color(0xFF795548)},
  };

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?['name'] as String? ?? '');
    _skuController = TextEditingController(
      text: p?['barcode'] as String? ?? widget.initialBarcode ?? '',
    );
    _stockController = TextEditingController(
      text: p != null ? '${p['stock'] ?? 0}' : '',
    );
    _priceController = TextEditingController(
      text: p != null ? '${p['price'] ?? ''}' : '',
    );
    final existingCategory = p?['category'] as String?;
    _selectedCategory = (existingCategory != null &&
            _categories.contains(existingCategory))
        ? existingCategory
        : _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);
      try {
        final data = {
          'name': _nameController.text.trim(),
          'barcode': _skuController.text.trim(),
          'category': _selectedCategory,
          'stock': int.tryParse(_stockController.text) ?? 0,
          'price': double.tryParse(_priceController.text) ?? 0.0,
        };

        if (widget.isEditMode) {
          await _supabaseService.updateProduct(widget.product!['id'] as int, data);
        } else {
          await _supabaseService.addProduct(data);
        }

        if (mounted) {
          Navigator.pop(context, true);
          Fluttertoast.showToast(
            msg: widget.isEditMode
                ? '${_nameController.text} na-update!'
                : '${_nameController.text} naidagdag na sa inventory!',
            backgroundColor: AppTheme.success,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: AppTheme.error,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient header ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
                      ),
                      child: Icon(
                        widget.isEditMode ? Icons.edit_rounded : Icons.add_box_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditMode ? 'I-edit ang Produkto' : 'Dagdag Bagong Produkto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.isEditMode
                              ? 'Baguhin ang impormasyon ng produkto'
                              : 'Punan ang detalye ng bagong produkto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Form body ────────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Section: Product details ─────────────────────────
                    _SectionLabel(label: 'DETALYE NG PRODUKTO'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Pangalan ng Produkto *',
                        hintText: 'hal. Lucky Me Pancit Canton 60g',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ilagay ang pangalan ng produkto'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode / SKU',
                        hintText: '8850987001234',
                        prefixIcon: Icon(Icons.qr_code_outlined),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // ── Category chip grid ───────────────────────────────
                    Text(
                      'Kategorya *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final meta = _categoryMeta[cat];
                        final icon = meta?['icon'] as IconData? ?? Icons.inventory_2_rounded;
                        final color = meta?['color'] as Color? ?? AppTheme.primary;
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withAlpha(25) : AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : AppTheme.outlineVariant,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 14, color: isSelected ? color : AppTheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  cat,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? color : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Section: Stock & Price ───────────────────────────
                    _SectionLabel(label: 'DAMI AT PRESYO'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock *',
                        hintText: '24',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Kailangan' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Presyo *',
                        hintText: '12.00',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        prefixText: '₱ ',
                        prefixStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ilagay ang presyo' : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Save button ──────────────────────────────────────
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(widget.isEditMode
                                ? Icons.save_rounded
                                : Icons.add_rounded),
                        label: Text(
                          _isLoading
                              ? 'Nagse-save...'
                              : widget.isEditMode
                                  ? 'I-save ang Pagbabago'
                                  : 'I-save ang Produkto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
