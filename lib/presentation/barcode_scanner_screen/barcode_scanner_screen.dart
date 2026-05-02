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
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.inventoryDashboardScreen,
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.productManagementScreen);
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
              ? ScannerManualEntryWidget(onBarcodeSubmitted: _onBarcodeDetected)
              : ScannerCameraWidget(
                  onBarcodeDetected: _onBarcodeDetected,
                  torchEnabled: _torchEnabled,
                  onTorchToggle: () =>
                      setState(() => _torchEnabled = !_torchEnabled),
                ),
        ),

        // Top bar overlay
        Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

        // Searching indicator
        if (_isSearching)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(179),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Hinahanap sa inventory...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withAlpha(179), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.inventoryDashboardScreen,
              (route) => false,
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(102),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barcode Scanner',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  kIsWeb
                      ? 'I-type ang barcode number'
                      : 'Ituro sa barcode ng produkto',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (!kIsWeb)
            GestureDetector(
              onTap: () => setState(() => _torchEnabled = !_torchEnabled),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _torchEnabled
                      ? AppTheme.secondary.withAlpha(230)
                      : Colors.black.withAlpha(102),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Icon(
                  _torchEnabled
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
