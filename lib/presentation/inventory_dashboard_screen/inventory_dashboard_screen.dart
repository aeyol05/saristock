import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/loading_skeleton_widget.dart';
import './widgets/add_product_bottom_sheet_widget.dart';
import './widgets/dashboard_chart_widget.dart';
import './widgets/dashboard_kpi_grid_widget.dart';
import './widgets/dashboard_low_stock_widget.dart';

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  // TODO: Replace with Riverpod/Bloc for production state management
  int _selectedNavIndex = 0;
  bool _isLoading = true;
  String _selectedFilter = 'Lahat';

  final List<String> _filters = ['Lahat', 'Mababa', 'Wala na', 'Bago'];

  final SupabaseService _supabaseService = SupabaseService();
  int _totalProducts = 0;
  int _lowStockCount = 0;
  int _outOfStockCount = 0;
  double _totalStockValue = 0.0;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _categoryData = [];
  String _storeName = 'Aking Tindahan';
  String _ownerInitials = 'AN';

  List<Map<String, dynamic>> get _filteredSectionProducts {
    switch (_selectedFilter) {
      case 'Mababa':
        return _allProducts
            .where((p) => (p['stock'] ?? 0) > 0 && (p['stock'] ?? 0) < 5)
            .take(5)
            .toList();
      case 'Wala na':
        return _allProducts
            .where((p) => (p['stock'] ?? 0) == 0)
            .take(5)
            .toList();
      case 'Bago':
        return _allProducts.reversed.take(5).toList();
      default:
        return _lowStockProducts;
    }
  }

  String get _sectionTitle {
    switch (_selectedFilter) {
      case 'Mababa': return '⚠️ Mababa na ang Stock';
      case 'Wala na': return '🚫 Wala na ang Stock';
      case 'Bago':    return '🆕 Bagong Idinagdag';
      default:        return '⚠️ Mababa na ang Stock';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _supabaseService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _storeName = profile['store_name'] ?? 'Aking Tindahan';
        final ownerName = (profile['owner_name'] as String?) ?? '';
        _ownerInitials = _computeInitials(ownerName);
      });
    }
  }

  String _computeInitials(String name) {
    if (name.isEmpty) return 'AN';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final products = await _supabaseService.getProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _totalProducts = products.length;
          _lowStockCount = products.where((p) {
            final s = (p['stock'] as num?)?.toInt() ?? 0;
            return s > 0 && s < 5;
          }).length;
          _outOfStockCount = products.where((p) => (p['stock'] ?? 0) == 0).length;
          _totalStockValue = products.fold(0.0, (sum, p) {
            final price = (p['price'] as num?)?.toDouble() ?? 0.0;
            final stock = (p['stock'] as num?)?.toInt() ?? 0;
            return sum + price * stock;
          });
          _lowStockProducts = products.where((p) {
            final s = (p['stock'] as num?)?.toInt() ?? 0;
            return s > 0 && s < 5;
          }).take(5).toList();

          final categories = <String, double>{};
          for (var p in products) {
            final cat = p['category'] ?? 'Iba pa';
            final stock = (p['stock'] ?? 0).toDouble();
            categories[cat] = (categories[cat] ?? 0) + stock;
          }

          final colors = [const Color(0xFF1B6B5A), const Color(0xFF2E8B72), const Color(0xFFE8A838), const Color(0xFFE65100), const Color(0xFF1565C0)];

          _categoryData = categories.entries.map((e) {
            final index = categories.keys.toList().indexOf(e.key);
            return {'label': e.key, 'value': e.value, 'color': colors[index % colors.length]};
          }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await _loadDashboard();
  }

  void _onNavSelected(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    if (index == 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.barcodeScannerScreen);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.productManagementScreen);
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, AppRoutes.profileScreen);
    }
  }

  void _showEditSheet(Map<String, dynamic> product) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductBottomSheetWidget(product: product),
    );
    if (result == true) _loadDashboard();
  }

  static Map<String, dynamic> _getCategoryStyle(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('canned') || cat.contains('rice') || cat.contains('bigas')) {
      return {'icon': Icons.fastfood_rounded, 'color': const Color(0xFFFFA000)};
    }
    if (cat.contains('beverage') || cat.contains('drink') || cat.contains('juice')) {
      return {'icon': Icons.local_drink_rounded, 'color': const Color(0xFF1565C0)};
    }
    if (cat.contains('snack') || cat.contains('instant') || cat.contains('noodle')) {
      return {'icon': Icons.cookie_rounded, 'color': const Color(0xFFE65100)};
    }
    if (cat.contains('personal') || cat.contains('care') || cat.contains('hygiene')) {
      return {'icon': Icons.soap_rounded, 'color': const Color(0xFF7C4DFF)};
    }
    if (cat.contains('condiment') || cat.contains('linis') || cat.contains('cleaning')) {
      return {'icon': Icons.cleaning_services_rounded, 'color': const Color(0xFF00897B)};
    }
    if (cat.contains('dairy') || cat.contains('frozen') || cat.contains('frozen')) {
      return {'icon': Icons.ac_unit_rounded, 'color': const Color(0xFF1565C0)};
    }
    if (cat.contains('tobacco')) {
      return {'icon': Icons.smoke_free_rounded, 'color': const Color(0xFF795548)};
    }
    return {'icon': Icons.inventory_2_rounded, 'color': AppTheme.primary};
  }

  void _showAddProductSheet() async {
    final result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddProductBottomSheetWidget());

    if (result == true) {
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: isTablet ? _buildTabletLayout() : _buildPhoneLayout()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductSheet,
        icon: const Icon(Icons.add_rounded),
        label: Text('Dagdag Produkto', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: isTablet ? null : AppNavigation(currentIndex: _selectedNavIndex, onDestinationSelected: _onNavSelected),
    );
  }

  Widget _buildPhoneLayout() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primary,
      child: _isLoading
          ? const DashboardSkeletonWidget()
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _animateIn(0, _buildFilterChips()),
                      const SizedBox(height: 16),
                      _animateIn(1, DashboardKpiGridWidget(
                        totalProducts: _totalProducts,
                        lowStockCount: _lowStockCount,
                        outOfStockCount: _outOfStockCount,
                        totalStockValue: _totalStockValue,
                      )),
                      const SizedBox(height: 24),
                      if (_totalProducts == 0) ...[
                        _animateIn(2, _buildEmptyProductsBanner()),
                      ] else ...[
                        _animateIn(2, _buildSectionHeader(_sectionTitle, 'Tingnan Lahat')),
                        const SizedBox(height: 12),
                        _animateIn(3, DashboardLowStockWidget(products: _filteredSectionProducts, onProductTap: _showEditSheet)),
                        const SizedBox(height: 24),
                        _animateIn(4, _buildSectionHeader('Stock sa Kategorya', null)),
                        const SizedBox(height: 12),
                        _animateIn(5, DashboardChartWidget(categoryData: _categoryData)),
                        const SizedBox(height: 24),
                        _animateIn(6, _buildSectionHeader('Mga Bagong Produkto', null)),
                        const SizedBox(height: 12),
                        _animateIn(7, _buildRecentlyAdded()),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _animateIn(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        AppNavigation(currentIndex: _selectedNavIndex, onDestinationSelected: _onNavSelected),
        const VerticalDivider(width: 1),
        Expanded(
          child: _isLoading
              ? const DashboardSkeletonWidget()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppTheme.primary,
                  child: CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildFilterChips(),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      DashboardKpiGridWidget(
                                        tabletMode: true,
                                        totalProducts: _totalProducts,
                                        lowStockCount: _lowStockCount,
                                        outOfStockCount: _outOfStockCount,
                                        totalStockValue: _totalStockValue,
                                      ),
                                      SizedBox(height: 20),
                                      DashboardChartWidget(categoryData: _categoryData),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader('⚠️ Mababa na', 'Tingnan Lahat'),
                                      const SizedBox(height: 10),
                                      DashboardLowStockWidget(compact: true, products: _filteredSectionProducts, onProductTap: _showEditSheet),
                                      const SizedBox(height: 20),
                                      _buildSectionHeader('Stock sa Kategorya', null),
                                      const SizedBox(height: 10),
                                      DashboardChartWidget(categoryData: _categoryData),
                                      const SizedBox(height: 20),
                                      _buildSectionHeader('Mga Bagong Produkto', null),
                                      const SizedBox(height: 10),
                                      _buildRecentlyAdded(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      expandedHeight: 80,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      scrolledUnderElevation: 4,
      shadowColor: AppTheme.primary.withAlpha(50),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SariStock',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 12, color: Colors.white.withAlpha(180)),
              const SizedBox(width: 4),
              Text(
                '$_storeName • ${_formatDate(DateTime.now())}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withAlpha(180)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: Colors.white.withAlpha(220)),
              onPressed: () {},
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF155E4E), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
            ),
            child: Center(
              child: Text(
                _ownerInitials,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.outlineVariant),
              ),
              child: Text(
                filter,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.white : AppTheme.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
        ),
        if (action != null)
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.productManagementScreen),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(action, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildEmptyProductsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primary.withAlpha(15), shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Wala pang mga produkto',
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Magdagdag ng produkto para masimulan\nang iyong SariStock dashboard.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.onSurfaceVariant.withAlpha(150), height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _showAddProductSheet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Dagdag Produkto', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyAdded() {
    final recent = _allProducts.reversed.take(5).toList();
    if (recent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Wala pang mga produkto.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.outline),
          ),
        ),
      );
    }
    return Column(
      children: recent.asMap().entries.map((entry) {
        final index = entry.key;
        final p = entry.value;
        final stock = (p['stock'] ?? 0) as int;
        final isOut = stock == 0;
        final isLow = stock > 0 && stock < 5;
        final statusColor = isOut
            ? AppTheme.cardRose.colors.first
            : isLow
                ? AppTheme.cardAmber.colors.first
                : AppTheme.success;
        final catStyle = _getCategoryStyle(p['category'] as String? ?? '');
        final catIcon = catStyle['icon'] as IconData;
        final catColor = catStyle['color'] as Color;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + index * 60),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(catIcon, color: catColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] as String? ?? 'Produkto',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p['category'] as String? ?? 'General',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${p['price']}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                    ),
                    Text(
                      '$stock units',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
