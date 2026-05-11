import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './core/services/supabase_service.dart';
import './theme/app_theme.dart';
import './routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseService().initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'saristock',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.initial,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
