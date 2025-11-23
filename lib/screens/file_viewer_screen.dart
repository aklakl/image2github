import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dark.dart';
import '../models/github_file.dart';
import '../models/repository.dart';
import '../services/auth_service.dart';

class FileViewerScreen extends StatefulWidget {
  final GitHubFile file;
  final Repository repository;
  final VoidCallback? onCopyPathForUpload;

  const FileViewerScreen({
    super.key,
    required this.file,
    required this.repository,
    this.onCopyPathForUpload,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}
class _FileViewerScreenState extends State<FileViewerScreen> {
  final AuthService _authService = AuthService();
  String? _fileContent;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDarkMode = true;
  bool _isRawMode = false;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  Future<void> _loadFileContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For image files, we don't need to fetch and decode content
      // Just mark as loaded and use download_url for display
      if (_isImageFile) {
        setState(() {
          _fileContent = 'IMAGE'; // Just a marker, not actually used for display
          _isLoading = false;
        });
        return;
      }

      // For text/code files, use GitHub API to avoid CORS issues on web
      final token = await _authService.getToken();
      final apiUrl = 'https://api.github.com/repos/${widget.repository.ownerLogin}/${widget.repository.name}/contents/${widget.file.path}';
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // GitHub API returns content as base64 for files
        if (data['encoding'] == 'base64' && data['content'] != null) {
          // Decode base64 content
          String base64Content = data['content'].toString().replaceAll('\n', '');
          final decodedBytes = base64.decode(base64Content);
          
          try {
            // Try to decode as UTF-8 text
            final decodedContent = utf8.decode(decodedBytes);
            setState(() {
              _fileContent = decodedContent;
              _isLoading = false;
            });
          } catch (e) {
            throw Exception('Unable to decode file as text. This might be a binary file.');
          }
        } else {
          throw Exception('Unexpected content encoding');
        }
      } else {
        throw Exception('Failed to load file: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _isImageFile {
    final extension = widget.file.name.toLowerCase().split('.').last;
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].contains(extension);
  }

  String _getLanguage() {
    final extension = widget.file.name.toLowerCase().split('.').last;
    final languageMap = {
      'dart': 'dart',
      'java': 'java',
      'kt': 'kotlin',
      'swift': 'swift',
      'js': 'javascript',
      'ts': 'typescript',
      'jsx': 'javascript',
      'tsx': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'go': 'go',
      'rs': 'rust',
      'c': 'c',
      'cpp': 'cpp',
      'h': 'c',
      'hpp': 'cpp',
      'cs': 'csharp',
      'php': 'php',
      'html': 'xml',
      'xml': 'xml',
      'css': 'css',
      'scss': 'scss',
      'json': 'json',
      'yaml': 'yaml',
      'yml': 'yaml',
      'md': 'markdown',
      'sh': 'bash',
      'sql': 'sql',
      'gradle': 'gradle',
    };
    return languageMap[extension] ?? 'plaintext';
  }

  void _copyPath() {
    Clipboard.setData(ClipboardData(text: widget.file.path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File path copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyContent() {
    if (_fileContent != null) {
      Clipboard.setData(ClipboardData(text: _fileContent!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File content copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyPathAndNavigateBack() {
    if (widget.onCopyPathForUpload != null) {
      widget.onCopyPathForUpload!();
      // Navigation is now handled by the callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: widget.file.path,
          child: SelectableText(
            widget.file.name,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          if (!_isImageFile)
            IconButton(
              icon: Icon(_isRawMode ? Icons.code : Icons.text_fields, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isRawMode = !_isRawMode;
                });
              },
              tooltip: _isRawMode ? 'Show highlighted' : 'Show raw text',
            ),
          if (!_isImageFile)
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              tooltip: _isDarkMode ? 'Light mode' : 'Dark mode',
            ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: _copyPath,
            tooltip: 'Copy file path',
          ),
          if (widget.onCopyPathForUpload != null)
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              onPressed: _copyPathAndNavigateBack,
              tooltip: 'Use this path for upload',
            ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading file',
                style: TextStyle(fontSize: 18, color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFileContent,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_fileContent == null) {
      return const Center(child: Text('No content available'));
    }

    if (_isImageFile) {
      return _buildImageViewer();
    } else {
      return _buildCodeViewer();
    }
  }

  Widget _buildImageViewer() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  widget.file.downloadUrl!,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Failed to load image', style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Text('Error: $error', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    'Size: ${(widget.file.size / 1024).toStringAsFixed(2)} KB',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pinch to zoom • Double tap to reset',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeViewer() {
    final language = _getLanguage();
    final theme = _isDarkMode ? darkTheme : githubTheme;
    final backgroundColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  language.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_all, size: 20),
                  onPressed: _copyContent,
                  tooltip: 'Copy all code',
                  color: Colors.grey.shade700,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_fileContent!.split('\n').length} lines',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isRawMode
                  ? SelectableText(
                      _fileContent!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    )
                  : SelectionArea(
                      child: HighlightView(
                        _fileContent!,
                        language: language,
                        theme: theme,
                        padding: const EdgeInsets.all(12),
                        textStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
