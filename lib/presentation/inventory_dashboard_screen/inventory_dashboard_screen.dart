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
import './widgets/dashboard_recent_transactions_widget.dart';

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
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
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _categoryData = [];
  String _storeName = 'Aking Tindahan';

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
      });
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final products = await _supabaseService.getProducts();
      if (mounted) {
        setState(() {
          _totalProducts = products.length;
          _lowStockProducts = products
              .where((p) => (p['stock'] ?? 0) < 5)
              .take(5) // Limit to top 5 for dashboard
              .toList();
          _lowStockCount = products.where((p) => (p['stock'] ?? 0) < 5).length;
          
          // Calculate category data
          final categories = <String, double>{};
          for (var p in products) {
            final cat = p['category'] ?? 'Iba pa';
            final stock = (p['stock'] ?? 0).toDouble();
            categories[cat] = (categories[cat] ?? 0) + stock;
          }
          
          final colors = [
            const Color(0xFF1B6B5A),
            const Color(0xFF2E8B72),
            const Color(0xFFE8A838),
            const Color(0xFFE65100),
            const Color(0xFF1565C0),
          ];
          
          _categoryData = categories.entries.map((e) {
            final index = categories.keys.toList().indexOf(e.key);
            return {
              'label': e.key,
              'value': e.value,
              'color': colors[index % colors.length],
            };
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
      Navigator.pushNamed(context, AppRoutes.barcodeScannerScreen);
    } else if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.productManagementScreen);
    } else if (index == 3) {
      Navigator.pushNamed(context, AppRoutes.profileScreen);
    }
  }

  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProductBottomSheetWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductSheet,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Dagdag Produkto',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: isTablet
          ? null
          : AppNavigation(
              currentIndex: _selectedNavIndex,
              onDestinationSelected: _onNavSelected,
            ),
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
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                      DashboardKpiGridWidget(
                        totalProducts: _totalProducts,
                        lowStockCount: _lowStockCount,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        '⚠️ Mababa na ang Stock',
                        'Tingnan Lahat',
                      ),
                      const SizedBox(height: 10),
                      DashboardLowStockWidget(
                        products: _lowStockProducts,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('Stock sa Kategorya', null),
                      const SizedBox(height: 10),
                      DashboardChartWidget(categoryData: _categoryData),
                      const SizedBox(height: 20),
                      _buildSectionHeader('Mga Transaksyon Ngayon', 'Lahat'),
                      const SizedBox(height: 10),
                      const DashboardRecentTransactionsWidget(
                        transactions: [],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        AppNavigation(
          currentIndex: _selectedNavIndex,
          onDestinationSelected: _onNavSelected,
        ),
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
                                      ),
                                      SizedBox(height: 20),
                                      DashboardChartWidget(
                                        categoryData: _categoryData,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader(
                                        '⚠️ Mababa na',
                                        'Tingnan Lahat',
                                      ),
                                      const SizedBox(height: 10),
                                      DashboardLowStockWidget(
                                        compact: true,
                                        products: _lowStockProducts,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildSectionHeader(
                                        'Stock sa Kategorya',
                                        null,
                                      ),
                                      const SizedBox(height: 10),
                                      DashboardChartWidget(
                                        categoryData: _categoryData,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildSectionHeader(
                                        'Transaksyon',
                                        'Lahat',
                                      ),
                                      const SizedBox(height: 10),
                                      const DashboardRecentTransactionsWidget(
                                        transactions: [],
                                      ),
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
      backgroundColor: AppTheme.surface,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SariStock',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          Text(
            '$_storeName • ${_formatDate(DateTime.now())}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppTheme.outline,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.onSurface,
              ),
              onPressed: () {},
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withAlpha(77),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  'AN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
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
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.outlineVariant,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                ),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo',
      'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
