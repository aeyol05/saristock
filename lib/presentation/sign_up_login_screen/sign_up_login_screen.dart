import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/auth_header_widget.dart';
import './widgets/demo_credentials_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/register_form_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc AuthProvider for production
  late TabController _tabController;
  bool _isLoading = false;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final SupabaseService _supabaseService = SupabaseService();

  void _handleLogin(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      if (!_supabaseService.isInitialized) {
        // Demo Mode login fallback
        if (email == 'marites@saristock.ph' && password == 'Tindahan2024!') {
          _navigateToDashboard();
        } else {
          Fluttertoast.showToast(
            msg: 'Invalid credentials — use the demo accounts below',
            backgroundColor: AppTheme.error,
          );
        }
        return;
      }
      
      await _supabaseService.signIn(email, password);
      _navigateToDashboard();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: AppTheme.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.inventoryDashboardScreen,
        (route) => false,
      );
    }
  }

  void _handleRegister(Map<String, String> data) async {
    setState(() => _isLoading = true);
    try {
      final email = data['email'] ?? '';
      final password = data['password'] ?? '';

      if (!_supabaseService.isInitialized) {
        Fluttertoast.showToast(msg: 'Demo: Account created locally');
        _navigateToDashboard();
        return;
      }

      final response = await _supabaseService.signUp(email, password);
      
      if (response.user != null) {
        await _supabaseService.createProfile(
          response.user!.id,
          data['storeName'] ?? '',
          data['ownerName'] ?? '',
        );
      }
      
      Fluttertoast.showToast(
        msg: 'Store registered! Redirecting to your dashboard...',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: AppTheme.success,
      );
      _navigateToDashboard();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: AppTheme.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              AuthHeaderWidget(screenHeight: screenHeight),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 0 : 20,
                  vertical: 0,
                ),
                child: isTablet
                    ? Center(
                        child: SizedBox(
                          width: 480,
                          child: _buildFormCard(context),
                        ),
                      )
                    : _buildFormCard(context),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 0 : 20),
                child: isTablet
                    ? Center(
                        child: SizedBox(
                          width: 480,
                          child: const DemoCredentialsWidget(),
                        ),
                      )
                    : const DemoCredentialsWidget(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Mag-login'),
                Tab(text: 'Mag-register'),
              ],
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.outline,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
            ),
          ),
          SizedBox(
            height: _currentTab == 0 ? 320 : 460,
            child: TabBarView(
              controller: _tabController,
              children: [
                LoginFormWidget(isLoading: _isLoading, onLogin: _handleLogin),
                RegisterFormWidget(
                  isLoading: _isLoading,
                  onRegister: _handleRegister,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
