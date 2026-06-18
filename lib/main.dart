import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/server_provider.dart';
import 'providers/vpn_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SlagCloneApp());
}

class SlagCloneApp extends StatelessWidget {
  const SlagCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => VpnProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Slag Clone VPN',
        debugShowCheckedModeBanner: false,
        theme: buildDarkTheme(),
        home: const _Gate(),
      ),
    );
  }
}

/// Quyết định hiển thị Login hay màn chính dựa trên trạng thái đăng nhập.
class _Gate extends StatelessWidget {
  const _Gate();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.loggedIn ? const MainNavigation() : const LoginScreen();
  }
}
