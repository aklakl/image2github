import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/repository.dart';
import '../config/constants.dart';

class GitHubService {
  final String _baseUrl = AppConfig.githubApiBaseUrl;
  final String _token = AppConfig.githubToken;
  final String _username = AppConfig.githubUsername;
  
  // Get authorization headers
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/vnd.github.v3+json',
    'Content-Type': 'application/json',
  };
  
  /// Fetch all repositories for the configured user
  Future<List<Repository>> fetchRepositories() async {
    try {
      final url = Uri.parse('$_baseUrl/users/$_username/repos?per_page=100');
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
  /// 
  /// [repository] - The repository to upload to
  /// [filePath] - Path in repository where file should be stored (e.g., 'images/logo.png')
  /// [fileBytes] - The image file bytes
  /// [commitMessage] - Optional commit message
  Future<bool> uploadFile({
    required Repository repository,
    required String filePath,
    required List<int> fileBytes,
    String? commitMessage,
  }) async {
    try {
      // Encode file to base64
      final base64Content = base64Encode(fileBytes);
      
      // Check if file already exists to get SHA
      final existingSha = await _getFileSha(
        repository.ownerLogin,
        repository.name,
        filePath,
        repository.defaultBranch,
      );
      
      final url = Uri.parse(
        '$_baseUrl/repos/${repository.ownerLogin}/${repository.name}/contents/$filePath'
      );
      
      final body = {
        'message': commitMessage ?? 'Upload image via Image2GitHub app',
        'content': base64Content,
        'branch': repository.defaultBranch,
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
}
