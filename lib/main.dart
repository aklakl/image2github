import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';

import 'services/auth_service.dart';

import 'screens/main_screen.dart';

void main() {
  // Enable browser context menu for right-click copy/paste on web
  if (kIsWeb) {
    BrowserContextMenu.enableContextMenu();
  }
  runApp(const Image2GitHubApp());
}

class Image2GitHubApp extends StatefulWidget {
  const Image2GitHubApp({super.key});

  @override
  State<Image2GitHubApp> createState() => _Image2GitHubAppState();
}

class _Image2GitHubAppState extends State<Image2GitHubApp> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _authService.getToken();
    setState(() {
      _isLoggedIn = token != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image2GitHub',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: _isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _isLoggedIn
              ? const MainScreen()
              : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
