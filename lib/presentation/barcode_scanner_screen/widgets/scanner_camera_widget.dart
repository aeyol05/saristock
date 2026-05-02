import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../theme/app_theme.dart';

class ScannerCameraWidget extends StatefulWidget {
  final Function(String barcode) onBarcodeDetected;
  final bool torchEnabled;
  final VoidCallback onTorchToggle;

  const ScannerCameraWidget({
    super.key,
    required this.onBarcodeDetected,
    required this.torchEnabled,
    required this.onTorchToggle,
  });

  @override
  State<ScannerCameraWidget> createState() => _ScannerCameraWidgetState();
}

class _ScannerCameraWidgetState extends State<ScannerCameraWidget>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  bool _hasPermission = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: widget.torchEnabled,
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    // TODO: Use permission_handler for production permission flow
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _hasPermission = true;
        _isInitializing = false;
      });
    }
  }

  @override
  void didUpdateWidget(ScannerCameraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.torchEnabled != widget.torchEnabled) {
      _scannerController.toggleTorch();
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionDenied();
    }

    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              widget.onBarcodeDetected(barcodes.first.rawValue!);
            }
          },
        ),

        // Dark overlay with scan frame cutout
        Positioned.fill(child: CustomPaint(painter: _ScanOverlayPainter())),

        // Animated scan line inside frame
        Positioned.fill(
          child: Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Corner brackets
                      ..._buildCornerBrackets(),

                      // Scan line
                      Positioned(
                        top: 10 + (_scanLineAnimation.value * 220),
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primary.withAlpha(230),
                                AppTheme.secondary,
                                AppTheme.primary.withAlpha(230),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(128),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        // Hint text below frame
        Positioned(
          bottom: 200,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ilagay ang barcode sa loob ng frame',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCornerBrackets() {
    const cornerSize = 24.0;
    const strokeWidth = 3.5;
    const color = AppTheme.primary;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: CustomPaint(
          painter: _CornerPainter(
            color: color,
            size: cornerSize,
            strokeWidth: strokeWidth,
            topLeft: true,
          ),
          size: const Size(cornerSize, cornerSize),
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: CustomPaint(
          painter: _CornerPainter(
            color: color,
            size: cornerSize,
            strokeWidth: strokeWidth,
            topRight: true,
          ),
          size: const Size(cornerSize, cornerSize),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: CustomPaint(
          painter: _CornerPainter(
            color: color,
            size: cornerSize,
            strokeWidth: strokeWidth,
            bottomLeft: true,
          ),
          size: const Size(cornerSize, cornerSize),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: CustomPaint(
          painter: _CornerPainter(
            color: color,
            size: cornerSize,
            strokeWidth: strokeWidth,
            bottomRight: true,
          ),
          size: const Size(cornerSize, cornerSize),
        ),
      ),
    ];
  }

  Widget _buildPermissionDenied() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Kailangan ang Camera Permission',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pumunta sa Settings at i-allow ang camera access para ma-scan ang mga barcode.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white60,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Subukan Ulit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 260.0;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = (size.height - frameSize) / 2;
    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize);

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = Colors.black.withAlpha(158));
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double size;
  final double strokeWidth;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({
    required this.color,
    required this.size,
    required this.strokeWidth,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (topLeft) {
      canvas.drawLine(Offset(0, size), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(size, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(size, 0), paint);
      canvas.drawLine(Offset(size, 0), Offset(size, size), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(0, size), paint);
      canvas.drawLine(Offset(0, size), Offset(size, size), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(size, 0), Offset(size, size), paint);
      canvas.drawLine(Offset(0, size), Offset(size, size), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
