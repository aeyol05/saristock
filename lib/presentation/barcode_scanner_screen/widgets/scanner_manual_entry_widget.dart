import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ScannerManualEntryWidget extends StatefulWidget {
  final Function(String barcode) onBarcodeSubmitted;

  const ScannerManualEntryWidget({super.key, required this.onBarcodeSubmitted});

  @override
  State<ScannerManualEntryWidget> createState() =>
      _ScannerManualEntryWidgetState();
}

class _ScannerManualEntryWidgetState extends State<ScannerManualEntryWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // Demo barcodes for testing
  final List<Map<String, String>> _demoBarcodes = [
    {'name': 'Lucky Me Pancit Canton', 'barcode': '8850987001234'},
    {'name': 'Milo Active Go 300g', 'barcode': '4800888109160'},
    {'name': 'Silver Swan Soy Sauce', 'barcode': '4800028011502'},
    {'name': 'Bagong Produkto (demo)', 'barcode': '1234567890123'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      widget.onBarcodeSubmitted(value);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1A17),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Web notice banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sa web browser, i-type ang barcode number. Para sa live camera scanning, i-download ang mobile app.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Large barcode icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(38),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(102),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppTheme.primary,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  'I-type ang Barcode Number',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Hanapin ang produkto gamit ang barcode',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Manual barcode entry
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'hal. 8850987001234',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor: Colors.white.withAlpha(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.barcode_reader,
                          color: AppTheme.primary,
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Text(
                'Mga Demo Barcode',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              ..._demoBarcodes.map(
                (demo) => _DemoBarcodeChip(
                  name: demo['name']!,
                  barcode: demo['barcode']!,
                  onTap: () {
                    _controller.text = demo['barcode']!;
                    widget.onBarcodeSubmitted(demo['barcode']!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoBarcodeChip extends StatelessWidget {
  final String name;
  final String barcode;
  final VoidCallback onTap;

  const _DemoBarcodeChip({
    required this.name,
    required this.barcode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.qr_code_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              barcode,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white38,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white38,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
