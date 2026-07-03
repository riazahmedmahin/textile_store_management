import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/section_provider.dart';
import 'providers/product_provider.dart';
import 'providers/stock_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wywesvarpqblppobooga.supabase.co',
    anonKey: 'sb_publishable_jAeXThn_7S0ig_CsdAeygQ_lGEJFSCM',
  );

  runApp(const TextileStoreApp());
}

class TextileStoreApp extends StatelessWidget {
  const TextileStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SectionProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
      ],
      child: MaterialApp(
        title: 'KTL Store Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (!auth.isAuthenticated) {
              return const LoginScreen();
            }
            return const MainShell();
          },
        ),
      ),
    );
  }
}
