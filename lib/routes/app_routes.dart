import 'package:flutter/material.dart';

import '../presentation/barcode_scanner_screen/barcode_scanner_screen.dart';
import '../presentation/inventory_dashboard_screen/inventory_dashboard_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/product_management_screen/product_management_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String inventoryDashboardScreen = '/inventory-dashboard-screen';
  static const String barcodeScannerScreen = '/barcode-scanner-screen';
  static const String productManagementScreen = '/product-management-screen';
  static const String profileScreen = '/profile-screen';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case initial:
      case signUpLoginScreen:
        page = const SignUpLoginScreen();
        break;
      case inventoryDashboardScreen:
        page = const InventoryDashboardScreen();
        break;
      case barcodeScannerScreen:
        page = const BarcodeScannerScreen();
        break;
      case productManagementScreen:
        page = const ProductManagementScreen();
        break;
      case profileScreen:
        page = const ProfileScreen();
        break;
      default:
        page = const SignUpLoginScreen();
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.05, 0.0); // Slight slide from right
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      settings: settings,
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
