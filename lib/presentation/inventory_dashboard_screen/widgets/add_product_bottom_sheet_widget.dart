import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/services/supabase_service.dart';
import '../../../theme/app_theme.dart';

class AddProductBottomSheetWidget extends StatefulWidget {
  const AddProductBottomSheetWidget({super.key});

  @override
  State<AddProductBottomSheetWidget> createState() =>
      _AddProductBottomSheetWidgetState();
}

class _AddProductBottomSheetWidgetState
    extends State<AddProductBottomSheetWidget> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockController = TextEditingController();
  final _reorderController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Canned Goods';
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

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _reorderController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _supabaseService.addProduct({
          'name': _nameController.text,
          'barcode': _skuController.text,
          'category': _selectedCategory,
          'stock': int.tryParse(_stockController.text) ?? 0,
          'price': double.tryParse(_priceController.text) ?? 0.0,
        });

        if (mounted) {
          Navigator.pop(context, true); // Return true to signal success
          Fluttertoast.showToast(
            msg: '${_nameController.text} naidagdag na sa inventory!',
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
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_box_outlined,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Dagdag Bagong Produkto',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Pangalan ng Produkto *',
                    hintText: 'hal. Lucky Me Pancit Canton 60g',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ilagay ang pangalan ng produkto'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode / SKU *',
                    hintText: '8850987001234',
                    prefixIcon: Icon(Icons.qr_code_outlined),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ilagay ang barcode o SKU'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategorya *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.onSurface,
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Kasalukuyang Stock *',
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
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _reorderController,
                        decoration: const InputDecoration(
                          labelText: 'Reorder Level *',
                          hintText: '12',
                          prefixIcon: Icon(Icons.warning_amber_outlined),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Kailangan' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Presyo (₱) *',
                    hintText: '12.00',
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ilagay ang presyo' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
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
                        : const Icon(Icons.add_rounded),
                    label: Text(
                      _isLoading ? 'Nagse-save...' : 'I-save ang Produkto',
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
    );
  }
}
