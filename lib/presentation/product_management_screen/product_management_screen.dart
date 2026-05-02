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
      appBar: AppBar(
        title: Text(
          'Pamamahala ng Produkto',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchProducts,
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? _buildEmptyState()
              : _buildProductList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: 2, // Assuming index 2 for products
        onDestinationSelected: (index) {
           if (index == 0) Navigator.pushNamed(context, AppRoutes.inventoryDashboardScreen);
           if (index == 1) Navigator.pushNamed(context, AppRoutes.barcodeScannerScreen);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.outline),
          const SizedBox(height: 16),
          Text(
            'Wala pang mga produkto.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showAddProductDialog,
            child: const Text('Magdagdag ng Produkto'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              product['name'] ?? 'Walang Pangalan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${product['category'] ?? 'General'} • ₱${product['price']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock: ${product['stock']}',
                      style: GoogleFonts.plusJakartaSans(
                        color: (product['stock'] ?? 0) < 5 ? AppTheme.error : AppTheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₱${product['price']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                  onPressed: () => _deleteProduct(product['id']),
                ),
              ],
            ),
            onTap: () => _showProductDialog(product: product),
          ),
        );
      },
    );
  }
}
