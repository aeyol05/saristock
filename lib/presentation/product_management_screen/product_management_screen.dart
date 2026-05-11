import 'package:fluttertoast/fluttertoast.dart';
import '../../core/app_export.dart';
import '../../core/services/supabase_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      if (!_supabaseService.isInitialized) {
        // Fallback to mock data for demonstration
        setState(() {
          _products = [];
          _isLoading = false;
        });
        return;
      }
      final products = await _supabaseService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: AppTheme.error,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name']);
    final priceController = TextEditingController(text: product?['price']?.toString());
    final stockController = TextEditingController(text: product?['stock']?.toString());
    final categoryController = TextEditingController(text: product?['category']);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          product == null ? 'Dagdag Bagong Produkto' : 'I-edit ang Produkto',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Pangalan ng Produkto'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Presyo'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Kategorya'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('I-cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newProduct = {
                'name': nameController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'stock': int.tryParse(stockController.text) ?? 0,
                'category': categoryController.text,
              };
              
              try {
                if (!_supabaseService.isInitialized) {
                   // Mock add for demo
                   if (product == null) {
                     _products.add({'id': DateTime.now().millisecondsSinceEpoch, ...newProduct});
                   } else {
                     final index = _products.indexWhere((p) => p['id'] == product['id']);
                     if (index != -1) _products[index] = {'id': product['id'], ...newProduct};
                   }
                   Fluttertoast.showToast(msg: 'Demo: Product saved locally (Supabase not connected)');
                } else {
                  if (product == null) {
                    await _supabaseService.addProduct(newProduct);
                  } else {
                    await _supabaseService.updateProduct(product['id'], newProduct);
                  }
                  Fluttertoast.showToast(msg: 'Produkto na-save!');
                }
                
                if (mounted) {
                  Navigator.pop(dialogContext);
                  _fetchProducts();
                }
              } catch (e) {
                Fluttertoast.showToast(
                  msg: 'Error: ${e.toString()}',
                  backgroundColor: AppTheme.error,
                  toastLength: Toast.LENGTH_LONG,
                );
              }
            },
            child: const Text('I-save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sigurado ka ba?'),
        content: const Text('Mabubura ang produktong ito sa inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hindi')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oo, Burahin')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (!_supabaseService.isInitialized) {
          setState(() {
            _products.removeWhere((p) => p['id'] == id);
          });
          Fluttertoast.showToast(msg: 'Demo: Product deleted locally');
        } else {
          await _supabaseService.deleteProduct(id);
          Fluttertoast.showToast(msg: 'Produkto binura!');
        }
        _fetchProducts();
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: AppTheme.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            sliver: _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _products.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : _buildProductList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Dagdag Produkto',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.inventoryDashboardScreen);
          if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.barcodeScannerScreen);
          if (index == 3) Navigator.pushReplacementNamed(context, AppRoutes.profileScreen);
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      expandedHeight: 80,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
        ),
      ),
      title: Text(
        'Pamamahala ng Produkto',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _fetchProducts,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Wala pang mga produkto.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Magdagdag ng produkto para masimulan\nang iyong inventory.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = _products[index];
          final isLowStock = (product['stock'] ?? 0) < 5;
          
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () => _showProductDialog(product: product),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] ?? 'Walang Pangalan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLowStock ? AppTheme.cardRose.colors.first.withAlpha(20) : AppTheme.cardTeal.colors.first.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isLowStock ? 'MABABA' : 'IN STOCK',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isLowStock ? AppTheme.cardRose.colors.first : AppTheme.cardTeal.colors.first,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.category_outlined, size: 14, color: AppTheme.onSurfaceVariant.withAlpha(150)),
                            const SizedBox(width: 4),
                            Text(
                              '${product['category'] ?? 'General'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant.withAlpha(180),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '₱${product['price']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'kada unit',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.onSurfaceVariant.withAlpha(120),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${product['stock']} units left',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isLowStock ? AppTheme.cardRose.colors.first : AppTheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: _products.length,
      ),
    );
  }
}
