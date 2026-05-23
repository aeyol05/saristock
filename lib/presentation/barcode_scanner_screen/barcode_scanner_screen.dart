import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import './widgets/scanner_camera_widget.dart';
import './widgets/scanner_manual_entry_widget.dart';
import './widgets/scanner_result_panel_widget.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production state management
  int _selectedNavIndex = 1;
  Map<String, dynamic>? _scannedProduct;
  bool _isSearching = false;
  bool _torchEnabled = false;
  String? _lastScannedBarcode;
  late AnimationController _resultPanelController;
  late Animation<Offset> _resultPanelAnimation;

  @override
  void initState() {
    super.initState();
    _resultPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _resultPanelAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _resultPanelController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _resultPanelController.dispose();
    super.dispose();
  }

  final SupabaseService _supabaseService = SupabaseService();

  void _onBarcodeDetected(String barcode) async {
    if (barcode == _lastScannedBarcode && _scannedProduct != null) return;
    _lastScannedBarcode = barcode;

    setState(() {
      _isSearching = true;
      _scannedProduct = null;
    });

    try {
      final product = await _supabaseService.getProductByBarcode(barcode);
      
      if (mounted) {
        setState(() {
          _scannedProduct = product ?? _getPlaceholderProduct(barcode);
          _isSearching = false;
        });
        _resultPanelController.forward();
      }
    } catch (e) {
      debugPrint('Error looking up product: $e');
      if (mounted) {
        setState(() {
          _scannedProduct = _getPlaceholderProduct(barcode);
          _isSearching = false;
        });
        _resultPanelController.forward();
      }
    }
  }

  Map<String, dynamic> _getPlaceholderProduct(String barcode) {
    return {
      'id': 'P_NEW',
      'name': 'Bagong Produkto (Hindi pa nakarehistro)',
      'category': 'Uncategorized',
      'barcode': barcode,
      'currentStock': 0,
      'reorderLevel': 10,
      'unit': 'pcs',
      'supplier': 'Hindi pa kilala',
      'price': 0.0,
      'status': 'outOfStock',
      'imageUrl': null,
      'semanticLabel': 'Product not yet registered in the system',
      'isNew': true,
    };
  }

  void _clearScan() {
    _resultPanelController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _scannedProduct = null;
          _lastScannedBarcode = null;
        });
      }
    });
  }

  void _onNavSelected(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, AppRoutes.inventoryDashboardScreen);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.productManagementScreen);
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, AppRoutes.profileScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
      bottomNavigationBar: isTablet
          ? null
          : Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: Colors.black.withAlpha(230),
                  indicatorColor: AppTheme.primaryContainer,
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(
                        color: AppTheme.primary,
                        size: 24,
                      );
                    }
                    return const IconThemeData(color: Colors.white60, size: 24);
                  }),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      );
                    }
                    return GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white60,
                    );
                  }),
                ),
              ),
              child: AppNavigation(
                currentIndex: _selectedNavIndex,
                onDestinationSelected: _onNavSelected,
              ),
            ),
    );
  }

  Widget _buildPhoneLayout() {
    return Stack(
      children: [
        // Camera or web fallback
        Positioned.fill(
          child: kIsWeb
              ? Container(
                  color: AppTheme.background,
                  child: ScannerManualEntryWidget(onBarcodeSubmitted: _onBarcodeDetected),
                )
              : ScannerCameraWidget(
                  onBarcodeDetected: _onBarcodeDetected,
                  torchEnabled: _torchEnabled,
                  onTorchToggle: () =>
                      setState(() => _torchEnabled = !_torchEnabled),
                ),
        ),

        // Top bar overlay
        Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

        // Viewfinder overlay
        if (!kIsWeb && _scannedProduct == null)
          Positioned.fill(child: _buildViewfinderOverlay()),

        // Searching indicator — centered over viewfinder
        if (_isSearching)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Kinikilala ang produkto...',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.onSurface, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Result panel slides up from bottom
        if (_scannedProduct != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _resultPanelAnimation,
              child: ScannerResultPanelWidget(
                product: _scannedProduct!,
                onClose: _clearScan,
                onStockUpdated: (newQty) {
                  setState(() {
                    _scannedProduct!['currentStock'] = newQty;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left: Camera panel
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Positioned.fill(
                child: kIsWeb
                    ? ScannerManualEntryWidget(
                        onBarcodeSubmitted: _onBarcodeDetected,
                      )
                    : ScannerCameraWidget(
                        onBarcodeDetected: _onBarcodeDetected,
                        torchEnabled: _torchEnabled,
                        onTorchToggle: () =>
                            setState(() => _torchEnabled = !_torchEnabled),
                      ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
            ],
          ),
        ),

        // Right: Result panel
        Container(
          width: 360,
          color: AppTheme.background,
          child: _scannedProduct != null
              ? ScannerResultPanelWidget(
                  product: _scannedProduct!,
                  onClose: _clearScan,
                  onStockUpdated: (newQty) {
                    setState(() {
                      _scannedProduct!['currentStock'] = newQty;
                    });
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppTheme.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'I-scan ang Barcode',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ituro ang camera sa barcode\nng produkto para maghanap',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.outline,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildViewfinderOverlay() {
    return CustomPaint(
      painter: _ViewfinderPainter(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 220),
            Text(
              'Ituro sa barcode ng produkto',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withAlpha(150), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.inventoryDashboardScreen,
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barcode Scanner',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  kIsWeb
                      ? 'I-type ang barcode number'
                      : 'Ituro sa barcode ng produkto',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          if (!kIsWeb)
            GestureDetector(
              onTap: () => setState(() => _torchEnabled = !_torchEnabled),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _torchEnabled
                      ? AppTheme.secondary
                      : Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _torchEnabled ? Colors.white : Colors.white.withAlpha(60),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _torchEnabled
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  static const double _frameWidth = 260;
  static const double _frameHeight = 160;
  static const double _cornerLen = 28;
  static const double _cornerRadius = 6;
  static const double _strokeWidth = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    final left = cx - _frameWidth / 2;
    final top = cy - _frameHeight / 2;
    final right = cx + _frameWidth / 2;
    final bottom = cy + _frameHeight / 2;

    // Dark overlay outside the frame
    final overlayPaint = Paint()..color = Colors.black.withAlpha(140);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, bottom, size.width, size.height - bottom), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, _frameHeight), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, _frameHeight), overlayPaint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final r = _cornerRadius;
    // Top-left
    canvas.drawLine(Offset(left + r, top), Offset(left + _cornerLen, top), cornerPaint);
    canvas.drawLine(Offset(left, top + r), Offset(left, top + _cornerLen), cornerPaint);
    canvas.drawArc(Rect.fromLTWH(left, top, r * 2, r * 2), 3.14159, 3.14159 / 2, false, cornerPaint);
    // Top-right
    canvas.drawLine(Offset(right - _cornerLen, top), Offset(right - r, top), cornerPaint);
    canvas.drawLine(Offset(right, top + r), Offset(right, top + _cornerLen), cornerPaint);
    canvas.drawArc(Rect.fromLTWH(right - r * 2, top, r * 2, r * 2), -3.14159 / 2, 3.14159 / 2, false, cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left + r, bottom), Offset(left + _cornerLen, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom - _cornerLen), Offset(left, bottom - r), cornerPaint);
    canvas.drawArc(Rect.fromLTWH(left, bottom - r * 2, r * 2, r * 2), 3.14159 / 2, 3.14159 / 2, false, cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(right - _cornerLen, bottom), Offset(right - r, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom - _cornerLen), Offset(right, bottom - r), cornerPaint);
    canvas.drawArc(Rect.fromLTWH(right - r * 2, bottom - r * 2, r * 2, r * 2), 0, 3.14159 / 2, false, cornerPaint);

    // Scan line inside frame
    final linePaint = Paint()
      ..color = AppTheme.primary.withAlpha(200)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left + 12, cy), Offset(right - 12, cy), linePaint);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => false;
}
