import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../config/constants.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AppLinks _appLinks = AppLinks();
  static const String _tokenKey = 'github_token';
  static const String _usernameKey = 'github_username';

  // Initialize deep link listener
  Stream<Uri> get deepLinkStream => _appLinks.uriLinkStream;

  // Get platform-specific redirect URI
  String get _redirectUri {
    return kIsWeb ? AppConfig.githubRedirectUriWeb : AppConfig.githubRedirectUri;
  }

  // Launch GitHub OAuth login
  Future<void> login() async {
    final url = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': AppConfig.githubClientId,
      'redirect_uri': _redirectUri,
      'scope': AppConfig.githubScopes,
    });

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $url');
    }
  }

  // Exchange authorization code for access token
  Future<String?> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.https('github.com', '/login/oauth/access_token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': AppConfig.githubClientId,
          'client_secret': AppConfig.githubClientSecret,
          'code': code,
          'redirect_uri': _redirectUri,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          await _storage.write(key: _tokenKey, value: accessToken);
          return accessToken;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to exchange code for token: $e');
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.githubApiBaseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final username = data['login'] as String;
        await _storage.write(key: _usernameKey, value: username);
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get stored username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // Save token directly (for Personal Access Token login)
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }
}
