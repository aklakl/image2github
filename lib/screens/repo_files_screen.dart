import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/repository.dart';
import '../models/github_file.dart';
import '../services/github_service.dart';
import 'file_viewer_screen.dart';
import 'image_upload_screen.dart';

class RepoFilesScreen extends StatefulWidget {
  final Repository repository;
  final String path;
  final bool fromUploadScreen;
  final Function(String)? onPathSelected;
  final String? branch;

  const RepoFilesScreen({
    super.key,
    required this.repository,
    this.path = '',
    this.fromUploadScreen = false,
    this.onPathSelected,
    this.branch,
  });

  @override
  State<RepoFilesScreen> createState() => _RepoFilesScreenState();
}

class _RepoFilesScreenState extends State<RepoFilesScreen> {
  final GitHubService _githubService = GitHubService();
  List<GitHubFile> _files = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<String> _branches = [];
  String? _selectedBranch;
  bool _isLoadingBranches = true;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.branch ?? widget.repository.defaultBranch;
    _loadBranches();
    _loadFiles();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoadingBranches = true;
    });
    try {
      final branches = await _githubService.fetchBranches(
        widget.repository.ownerLogin,
        widget.repository.name,
      );
      setState(() {
        _branches = branches;
        _isLoadingBranches = false;
      });
    } catch (e) {
      // Handle error silently for now
      setState(() {
        _isLoadingBranches = false;
      });
    }
  }

  Future<void> _loadFiles() async {
    if (_selectedBranch == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contents = await _githubService.fetchRepoContents(
        widget.repository.ownerLogin,
        widget.repository.name,
        widget.path,
        _selectedBranch!,
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
          settings: const RouteSettings(name: 'repo_files'),
          builder: (context) => RepoFilesScreen(
            repository: widget.repository,
            path: file.path,
            fromUploadScreen: widget.fromUploadScreen,
            onPathSelected: widget.onPathSelected,
            branch: _selectedBranch,
          ),
        ),
      );
    } else {
      // Open file viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'repo_files'), // Also mark viewer as part of file browsing
          builder: (context) => FileViewerScreen(
            file: file,
            repository: widget.repository,
            onCopyPathForUpload: () => _selectPathForUpload(file.path),
          ),
        ),
      );
    }
  }

  void _selectPathForUpload(String path) {
    if (widget.onPathSelected != null) {
      // Case 1: Came from Upload Screen
      widget.onPathSelected!(path);
      // Pop until we find a route that is NOT 'repo_files'
      Navigator.of(context).popUntil((route) {
        return route.settings.name != 'repo_files';
      });
    } else {
      // Case 2: Came from Repository List (Browse mode)
      // Navigate to ImageUploadScreen with the selected path
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageUploadScreen(
            repository: widget.repository,
            initialPath: path,
            branch: _selectedBranch,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              widget.path.isEmpty ? widget.repository.name : widget.path.split('/').last,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
            ),
            if (_selectedBranch != null)
              Text(
                'Branch: $_selectedBranch',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          _buildBranchSelector(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.of(context).popUntil((route) {
                return route.settings.name != 'repo_files';
              });
            },
            tooltip: 'Close',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SelectionArea(child: _buildBody()),
    );
  }

  Widget _buildBranchSelector() {
    if (_isLoadingBranches) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (_branches.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButton<String>(
      value: _selectedBranch,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedBranch = newValue;
          });
          _loadFiles();
        }
      },
      items: _branches.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(color: Colors.black)),
        );
      }).toList(),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      underline: Container(),
      dropdownColor: Colors.white,
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
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _onFileTapped(file),
                  tooltip: 'View file',
                  color: Colors.blue,
                ),
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
              if (!file.isDirectory)
                IconButton(
                  icon: const Icon(Icons.upload_file, size: 20),
                  onPressed: () => _selectPathForUpload(file.path),
                  tooltip: 'Use for upload',
                  color: Colors.green,
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
