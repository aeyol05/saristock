import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/app_export.dart';
import '../../core/services/supabase_service.dart';
import '../inventory_dashboard_screen/widgets/add_product_bottom_sheet_widget.dart';

enum _SortOption { nameAZ, nameZA, stockLow, stockHigh, category }

extension _SortOptionLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.nameAZ: return 'Pangalan A–Z';
      case _SortOption.nameZA: return 'Pangalan Z–A';
      case _SortOption.stockLow: return 'Stock: Mababa → Mataas';
      case _SortOption.stockHigh: return 'Stock: Mataas → Mababa';
      case _SortOption.category: return 'Kategorya';
    }
  }
  IconData get icon {
    switch (this) {
      case _SortOption.nameAZ: return Icons.sort_by_alpha_rounded;
      case _SortOption.nameZA: return Icons.sort_by_alpha_rounded;
      case _SortOption.stockLow: return Icons.arrow_upward_rounded;
      case _SortOption.stockHigh: return Icons.arrow_downward_rounded;
      case _SortOption.category: return Icons.category_outlined;
    }
  }
}

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasError = false;
  _SortOption _sortOption = _SortOption.nameAZ;

  List<Map<String, dynamic>> get _filteredProducts {
    var list = _products.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (p['name'] as String? ?? '').toLowerCase();
      final category = (p['category'] as String? ?? '').toLowerCase();
      return name.contains(q) || category.contains(q);
    }).toList();

    switch (_sortOption) {
      case _SortOption.nameAZ:
        list.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
      case _SortOption.nameZA:
        list.sort((a, b) => (b['name'] as String? ?? '').compareTo(a['name'] as String? ?? ''));
      case _SortOption.stockLow:
        list.sort((a, b) => ((a['stock'] ?? 0) as int).compareTo((b['stock'] ?? 0) as int));
      case _SortOption.stockHigh:
        list.sort((a, b) => ((b['stock'] ?? 0) as int).compareTo((a['stock'] ?? 0) as int));
      case _SortOption.category:
        list.sort((a, b) => (a['category'] as String? ?? '').compareTo(b['category'] as String? ?? ''));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      if (!_supabaseService.isInitialized) {
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
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: AppTheme.error,
        );
      }
    }
  }

  Future<bool?> _confirmDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sigurado ka ba?'),
        content: const Text('Mabubura ang produktong ito sa inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hindi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Burahin'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(int id) async {
    try {
      if (!_supabaseService.isInitialized) {
        if (mounted) setState(() => _products.removeWhere((p) => p['id'] == id));
        Fluttertoast.showToast(msg: 'Demo: Product deleted locally');
      } else {
        await _supabaseService.deleteProduct(id);
        Fluttertoast.showToast(msg: 'Produkto binura!');
      }
      if (mounted) _fetchProducts();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: AppTheme.error,
      );
    }
  }

  void _showProductSheet({Map<String, dynamic>? product}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductBottomSheetWidget(product: product),
    );
    if (result == true) _fetchProducts();
  }

  static Map<String, dynamic> _getCategoryStyle(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('pagkain') || cat.contains('food') || cat.contains('bigas') || cat.contains('rice') || cat.contains('canned')) {
      return {'icon': Icons.fastfood_rounded, 'color': const Color(0xFFFFA000)};
    }
    if (cat.contains('inumin') || cat.contains('drink') || cat.contains('juice') || cat.contains('beverage') || cat.contains('tubig')) {
      return {'icon': Icons.local_drink_rounded, 'color': const Color(0xFF1565C0)};
    }
    if (cat.contains('snack') || cat.contains('meryenda') || cat.contains('chips') || cat.contains('instant')) {
      return {'icon': Icons.cookie_rounded, 'color': const Color(0xFFE65100)};
    }
    if (cat.contains('personal') || cat.contains('hygiene') || cat.contains('care') || cat.contains('sabon')) {
      return {'icon': Icons.soap_rounded, 'color': const Color(0xFF7C4DFF)};
    }
    if (cat.contains('linis') || cat.contains('cleaning') || cat.contains('detergent') || cat.contains('condiment')) {
      return {'icon': Icons.cleaning_services_rounded, 'color': const Color(0xFF00897B)};
    }
    if (cat.contains('gamot') || cat.contains('medicine') || cat.contains('health') || cat.contains('dairy')) {
      return {'icon': Icons.medical_services_rounded, 'color': const Color(0xFFD32F2F)};
    }
    if (cat.contains('kuryente') || cat.contains('electric') || cat.contains('tobacco') || cat.contains('frozen')) {
      return {'icon': Icons.bolt_rounded, 'color': const Color(0xFFF9A825)};
    }
    return {'icon': Icons.inventory_2_rounded, 'color': AppTheme.primary};
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            // Search bar
            if (!_isLoading && !_hasError)
              SliverToBoxAdapter(child: _buildSearchBar()),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: _buildSliverContent(isTablet, filtered),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showProductSheet();
        },
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Hanapin ang produkto...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSliverContent(bool isTablet, List<Map<String, dynamic>> filtered) {
    if (_isLoading) {
      return const SliverFillRemaining(child: ProductListSkeletonWidget());
    }
    if (_hasError) {
      return SliverFillRemaining(child: _buildErrorState());
    }
    if (_products.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(noProducts: true));
    }
    if (filtered.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(noProducts: false));
    }
    if (isTablet) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildProductGridCard(filtered[index]),
            childCount: filtered.length,
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildDismissibleTile(filtered[index]),
        childCount: filtered.length,
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
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
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
        PopupMenuButton<_SortOption>(
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
          tooltip: 'Ayusin ang listahan',
          onSelected: (opt) {
            HapticFeedback.selectionClick();
            setState(() => _sortOption = opt);
          },
          itemBuilder: (_) => _SortOption.values.map((opt) {
            return PopupMenuItem(
              value: opt,
              child: Row(
                children: [
                  Icon(opt.icon, size: 18,
                      color: _sortOption == opt ? AppTheme.primary : AppTheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text(
                    opt.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: _sortOption == opt ? FontWeight.w700 : FontWeight.w500,
                      color: _sortOption == opt ? AppTheme.primary : AppTheme.onSurface,
                    ),
                  ),
                  if (_sortOption == opt) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, size: 16, color: AppTheme.primary),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
        IconButton(
          onPressed: _fetchProducts,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState({required bool noProducts}) {
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
            child: Icon(
              noProducts ? Icons.inventory_2_outlined : Icons.search_off_rounded,
              size: 64,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            noProducts ? 'Wala pang mga produkto.' : 'Walang nahanap na produkto.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noProducts
                ? 'Magdagdag ng produkto para masimulan\nang iyong inventory.'
                : 'Subukan ang ibang salita sa paghahanap.',
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Hindi ma-load ang mga produkto',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suriin ang iyong internet connection at subukang muli.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Subukang Muli',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Swipe-to-delete wrapper ──────────────────────────────────────────────────

  Widget _buildDismissibleTile(Map<String, dynamic> product) {
    return Dismissible(
      key: ValueKey(product['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return _confirmDeleteDialog();
      },
      onDismissed: (_) => _performDelete(product['id'] as int),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              'Burahin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      child: _buildProductListTile(product),
    );
  }

  // ── Phone list tile ──────────────────────────────────────────────────────────

  Widget _buildProductListTile(Map<String, dynamic> product) {
    final stock = (product['stock'] ?? 0) as int;
    final isOutOfStock = stock == 0;
    final isLowStock = stock > 0 && stock < 5;
    final categoryStyle = _getCategoryStyle(product['category'] ?? 'General');
    final categoryColor = categoryStyle['color'] as Color;
    final categoryIcon = categoryStyle['icon'] as IconData;

    String statusLabel;
    Color statusColor;
    if (isOutOfStock) {
      statusLabel = 'WALA NA';
      statusColor = AppTheme.cardRose.colors.first;
    } else if (isLowStock) {
      statusLabel = 'MABABA';
      statusColor = AppTheme.cardAmber.colors.first;
    } else {
      statusLabel = 'IN STOCK';
      statusColor = AppTheme.cardTeal.colors.first;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Subtle red-left gradient for out-of-stock items
          gradient: isOutOfStock
              ? LinearGradient(
                  colors: [AppTheme.errorContainer.withAlpha(90), Colors.white],
                  begin: Alignment.centerLeft,
                  end: const Alignment(0.4, 0),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isOutOfStock
                  ? AppTheme.error.withAlpha(12)
                  : Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showProductSheet(product: product);
              },
              onLongPress: () async {
                HapticFeedback.mediumImpact();
                final ok = await _confirmDeleteDialog();
                if (ok == true) _performDelete(product['id'] as int);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category icon box
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: categoryColor.withAlpha(18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(categoryIcon, color: categoryColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'] ?? 'Walang Pangalan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.category_outlined, size: 13, color: categoryColor.withAlpha(180)),
                              const SizedBox(width: 4),
                              Text(
                                product['category'] ?? 'General',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant.withAlpha(180),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                                      color: isOutOfStock
                                          ? AppTheme.onSurfaceVariant.withAlpha(120)
                                          : AppTheme.primaryLight,
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(isOutOfStock ? 18 : 12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$stock units left',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: (isOutOfStock || isLowStock) ? statusColor : AppTheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Tablet grid card ─────────────────────────────────────────────────────────

  Widget _buildProductGridCard(Map<String, dynamic> product) {
    final stock = (product['stock'] ?? 0) as int;
    final isOutOfStock = stock == 0;
    final isLowStock = stock > 0 && stock < 5;
    final categoryStyle = _getCategoryStyle(product['category'] ?? 'General');
    final categoryColor = categoryStyle['color'] as Color;
    final categoryIcon = categoryStyle['icon'] as IconData;

    String statusLabel;
    Color statusColor;
    if (isOutOfStock) {
      statusLabel = 'WALA NA';
      statusColor = AppTheme.cardRose.colors.first;
    } else if (isLowStock) {
      statusLabel = 'MABABA';
      statusColor = AppTheme.cardAmber.colors.first;
    } else {
      statusLabel = 'IN STOCK';
      statusColor = AppTheme.cardTeal.colors.first;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        gradient: isOutOfStock
            ? LinearGradient(
                colors: [AppTheme.errorContainer.withAlpha(90), Colors.white],
                begin: Alignment.centerLeft,
                end: const Alignment(0.6, 0),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isOutOfStock ? AppTheme.error.withAlpha(12) : Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showProductSheet(product: product);
            },
            onLongPress: () async {
              HapticFeedback.mediumImpact();
              final ok = await _confirmDeleteDialog();
              if (ok == true) _performDelete(product['id'] as int);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: categoryColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(categoryIcon, color: categoryColor, size: 20),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product['name'] ?? 'Walang Pangalan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product['category'] ?? 'General',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: categoryColor.withAlpha(200),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${product['price']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isOutOfStock
                              ? AppTheme.onSurfaceVariant.withAlpha(120)
                              : AppTheme.primaryLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(isOutOfStock ? 18 : 12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$stock units',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: (isOutOfStock || isLowStock) ? statusColor : AppTheme.onSurface,
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
  }
}
