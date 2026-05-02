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

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SignUpLoginScreen(),
    signUpLoginScreen: (context) => const SignUpLoginScreen(),
    inventoryDashboardScreen: (context) => const InventoryDashboardScreen(),
    barcodeScannerScreen: (context) => const BarcodeScannerScreen(),
    productManagementScreen: (context) => const ProductManagementScreen(),
    profileScreen: (context) => const ProfileScreen(),
  };
}
