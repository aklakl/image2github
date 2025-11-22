import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/repository.dart';
import '../models/github_file.dart';
import '../services/github_service.dart';

class RepoFilesScreen extends StatefulWidget {
  final Repository repository;
  final String path;

  const RepoFilesScreen({
    super.key,
    required this.repository,
    this.path = '',
  });

  @override
  State<RepoFilesScreen> createState() => _RepoFilesScreenState();
}

class _RepoFilesScreenState extends State<RepoFilesScreen> {
  final GitHubService _githubService = GitHubService();
  List<GitHubFile> _files = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contents = await _githubService.fetchRepoContents(
        widget.repository.ownerLogin,
        widget.repository.name,
        widget.path,
      );
      
      final files = contents.map((json) => GitHubFile.fromJson(json)).toList();
      
      // Sort: Directories first, then files
      files.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFileTapped(GitHubFile file) {
    if (file.isDirectory) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RepoFilesScreen(
            repository: widget.repository,
            path: file.path,
          ),
        ),
      );
    } else {
      // For now, just show a snackbar for files
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File: ${file.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SelectableText(
          widget.path.isEmpty ? widget.repository.name : widget.path.split('/').last,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
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
      body: SelectionArea(child: _buildBody()),
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
                'Error loading files',
                style: TextStyle(fontSize: 18, color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFiles,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(child: Text('No files found'));
    }

    return ListView.separated(
      itemCount: _files.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final file = _files[index];
        return ListTile(
          leading: Icon(
            file.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: file.isDirectory ? Colors.amber : Colors.grey,
          ),
          title: Text(file.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!file.isDirectory)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: file.path));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File path copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy file path',
                ),
              if (file.isDirectory)
                const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => _onFileTapped(file),
        );
      },
    );
  }
}
