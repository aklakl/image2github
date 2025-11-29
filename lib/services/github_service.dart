import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/repository.dart';
import '../config/constants.dart';
import 'auth_service.dart';

class GitHubService {
  final String _baseUrl = AppConfig.githubApiBaseUrl;
  final AuthService _authService = AuthService();
  String? _token;
  String? _username;
  
  GitHubService({String? token, String? username}) {
    _token = token;
    _username = username;
  }
  
  Future<void> _ensureCredentials() async {
    if (_token == null) {
      _token = await _authService.getToken();
    }
    if (_username == null) {
      _username = await _authService.getUsername();
    }
    if (_token == null) {
      throw Exception('Authentication required');
    }
  }
  
  // Get authorization headers
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/vnd.github.v3+json',
    'Content-Type': 'application/json',
  };
  
  /// Fetch all repositories for the authenticated user
  Future<List<Repository>> fetchRepositories() async {
    await _ensureCredentials();
    try {
      // Use /user/repos for authenticated user
      final url = Uri.parse('$_baseUrl/user/repos?per_page=100&sort=updated');
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Repository.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch repositories: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching repositories: $e');
    }
  }
  
  /// Get file information from repository to check if it exists
  Future<String?> _getFileSha(String owner, String repo, String path, String branch) async {
    await _ensureCredentials();
    try {
      final url = Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path?ref=$branch');
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sha'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Upload or update a file in a GitHub repository
  Future<bool> uploadFile({
    required Repository repository,
    required String filePath,
    required List<int> fileBytes,
    String? commitMessage,
    String? branch,
  }) async {
    await _ensureCredentials();
    try {
      // Encode file to base64
      final base64Content = base64Encode(fileBytes);
      
      final targetBranch = branch ?? repository.defaultBranch;

      // Check if file already exists to get SHA
      final existingSha = await _getFileSha(
        repository.ownerLogin,
        repository.name,
        filePath,
        targetBranch,
      );
      
      final url = Uri.parse(
        '$_baseUrl/repos/${repository.ownerLogin}/${repository.name}/contents/$filePath'
      );
      
      final body = {
        'message': commitMessage ?? 'Upload image via Image2GitHub app',
        'content': base64Content,
        'branch': targetBranch,
      };
      
      // Include SHA if file exists (for update)
      if (existingSha != null) {
        body['sha'] = existingSha;
      }
      
      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Upload failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  /// Fetch contents of a repository path
  Future<List<Map<String, dynamic>>> fetchRepoContents(String owner, String repo, String path, String branch) async {
    await _ensureCredentials();
    try {
      final url = Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path?ref=$branch');
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch contents: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching contents: $e');
    }
  }

  /// Fetch all branches for a repository
  Future<List<String>> fetchBranches(String owner, String repo) async {
    await _ensureCredentials();
    try {
      final url = Uri.parse('$_baseUrl/repos/$owner/$repo/branches');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((branch) => branch['name'] as String).toList();
      } else {
        throw Exception('Failed to fetch branches: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching branches: $e');
    }
  }
}
