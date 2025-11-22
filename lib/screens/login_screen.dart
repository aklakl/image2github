import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html show window;
import '../services/auth_service.dart';
import '../services/github_service.dart';
import 'repository_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _tokenController = TextEditingController();
  StreamSubscription? _sub;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showTokenInput = false;
  bool _rememberMe = true; // Default to true

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkWebUrlForCode();
      _showTokenInput = true; // Show token input by default on web
    } else {
      _initDeepLinkListener();
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _checkWebUrlForCode() async {
    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];
    
    if (code != null) {
      // Clear the code from URL
      html.window.history.replaceState(null, '', '/');
      await _handleAuthCode(code);
    }
  }

  Future<void> _initDeepLinkListener() async {
    _sub = _authService.deepLinkStream.listen((String? link) {
      if (link != null) {
        _handleDeepLink(link);
      }
    }, onError: (err) {
      setState(() {
        _errorMessage = 'Deep link error: $err';
      });
    });
  }

  Future<void> _handleDeepLink(String link) async {
    final uri = Uri.parse(link);
    final code = uri.queryParameters['code'];
    
    if (code != null) {
      await _handleAuthCode(code);
    }
  }

  Future<void> _handleAuthCode(String code) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.exchangeCodeForToken(code);
      if (token != null) {
        final user = await _authService.getUser(token);
        if (user != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RepositoryListScreen()),
            );
          }
        } else {
          throw Exception('Failed to get user profile');
        }
      } else {
        throw Exception('Failed to get access token');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithOAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _authService.login();
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not launch login: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithToken() async {
    final token = _tokenController.text.trim();
    
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Personal Access Token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Only save the token if "Remember me" is checked
      if (_rememberMe) {
        await _authService.saveToken(token);
      }
      
      // Get user info
      final user = await _authService.getUser(token);
      if (user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RepositoryListScreen()),
          );
        }
      } else {
        throw Exception('Invalid token or failed to get user profile');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_upload,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Image2GitHub',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload images to your repositories',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Token input (shown on web or when user chooses)
                if (_showTokenInput) ...[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        hintText: 'Enter GitHub Personal Access Token',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.key),
                      ),
                      obscureText: true,
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    ElevatedButton.icon(
                      onPressed: _loginWithToken,
                      icon: const Icon(Icons.login),
                      label: const Text('Login with Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Remember Me Checkbox
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: CheckboxListTile(
                      title: const Text(
                        'Remember me',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? true;
                        });
                      },
                      activeColor: Colors.white,
                      checkColor: Colors.deepPurple,
                      tileColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showTokenInput = false;
                      });
                    },
                    child: const Text(
                      'Or login with OAuth',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ] else ...[
                  // OAuth login button
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    ElevatedButton.icon(
                      onPressed: _loginWithOAuth,
                      icon: const Icon(Icons.login),
                      label: const Text('Login with GitHub'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Remember Me Checkbox
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: CheckboxListTile(
                      title: const Text(
                        'Remember me',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? true;
                        });
                      },
                      activeColor: Colors.white,
                      checkColor: Colors.deepPurple,
                      tileColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showTokenInput = true;
                      });
                    },
                    child: const Text(
                      'Or use Personal Access Token',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
                
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to get Personal Access Token:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Go to GitHub Settings\n'
                        '2. Developer settings → Personal access tokens → Tokens (classic)\n'
                        '3. Generate new token (classic)\n'
                        '4. Select scopes: repo, read:user\n'
                        '5. Copy and paste the token here',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
