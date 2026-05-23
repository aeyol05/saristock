import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/loading_skeleton_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _hasError = false;
  int _productCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        _supabaseService.getProfile(),
        _supabaseService.getProductCount(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _productCount = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _supabaseService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signUpLoginScreen, (route) => false);
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'AN';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get _userEmail {
    if (!_supabaseService.isInitialized) return '';
    return _supabaseService.client.auth.currentUser?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    Widget content;
    if (_isLoading) {
      content = const ProfileSkeletonWidget();
    } else if (_hasError) {
      content = _buildErrorState();
    } else {
      content = _buildProfileContent();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverFillRemaining(hasScrollBody: false, child: content),
          ],
        ),
      ),
      bottomNavigationBar: isTablet
          ? null
          : AppNavigation(
              currentIndex: 3,
              onDestinationSelected: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(context, AppRoutes.inventoryDashboardScreen);
                }
                if (index == 1) {
                  Navigator.pushReplacementNamed(context, AppRoutes.barcodeScannerScreen);
                }
                if (index == 2) {
                  Navigator.pushReplacementNamed(context, AppRoutes.productManagementScreen);
                }
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
        background: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      title: Text(
        'Profile ng Tindahan',
        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileContent() {
    final ownerName = _profile?['owner_name'] as String?;
    final initials = _getInitials(ownerName);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildProfileHeader(initials),
          const SizedBox(height: 30),
          _buildProfileField('Pangalan ng Tindahan', _profile?['store_name'] ?? 'Wala pang pangalan', Icons.storefront_rounded, AppTheme.cardTeal.colors.first),
          const SizedBox(height: 16),
          _buildProfileField('Pangalan ng May-ari', ownerName ?? 'Wala pang pangalan', Icons.person_pin_rounded, AppTheme.cardViolet.colors.first),
          const SizedBox(height: 16),
          _buildProfileField('Email Address', _userEmail.isNotEmpty ? _userEmail : 'Wala pang email', Icons.email_outlined, AppTheme.cardAmber.colors.first),
          const SizedBox(height: 40),
          _buildLogoutButton(),
          const SizedBox(height: 20),
          Text('SariStock v1.0.0', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant.withAlpha(100))),
          const SizedBox(height: 16),
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
              'Hindi ma-load ang profile',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Suriin ang iyong internet connection at subukang muli.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.onSurfaceVariant.withAlpha(150)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Subukang Muli', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String initials) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primary.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))],
                border: Border.all(color: AppTheme.primary.withAlpha(20), width: 4),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showEditProfileSheet();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _profile?['store_name'] ?? 'Aking Tindahan',
          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_productCount produkto sa tindahan',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  void _showEditProfileSheet() {
    final storeNameCtrl = TextEditingController(text: _profile?['store_name'] as String? ?? '');
    final ownerNameCtrl = TextEditingController(text: _profile?['owner_name'] as String? ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: AppTheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: AppTheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'I-edit ang Profile',
                            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: storeNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Pangalan ng Tindahan *',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        validator: (v) => (v == null || v.isEmpty) ? 'Kailangan ng pangalan' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ownerNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Pangalan ng May-ari *',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        validator: (v) => (v == null || v.isEmpty) ? 'Kailangan ng pangalan' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: isSaving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isSaving = true);
                            try {
                              await _supabaseService.updateProfile(
                                storeNameCtrl.text.trim(),
                                ownerNameCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              Fluttertoast.showToast(msg: 'Profile na-update!', backgroundColor: AppTheme.success, textColor: Colors.white);
                              _loadProfile();
                            } catch (e) {
                              Fluttertoast.showToast(msg: 'Error: ${e.toString()}', backgroundColor: AppTheme.error);
                            } finally {
                              if (ctx.mounted) setSheetState(() => isSaving = false);
                            }
                          },
                          icon: isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            isSaving ? 'Nagse-save...' : 'I-save ang Pagbabago',
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant.withAlpha(150)),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: AppTheme.cardRose,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.cardRose.colors.first.withAlpha(50), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mag-logout sa App',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
