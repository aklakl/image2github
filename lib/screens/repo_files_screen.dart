import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image2github/models/repository.dart';
import 'package:image2github/models/github_file.dart';
import 'package:image2github/services/github_service.dart';
import 'package:image2github/screens/file_viewer_screen.dart';
import 'package:image2github/screens/image_upload_screen.dart';

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

  // New state for multi-selection
  final Set<GitHubFile> _selectedFiles = {};
  bool _isSelectionMode = false;

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
    if (_isSelectionMode) {
      _toggleFileSelection(file);
      return;
    }

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
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'repo_files'),
          builder: (context) => FileViewerScreen(
            file: file,
            repository: widget.repository,
            onCopyPathForUpload: () => _selectPathForUpload(file.path),
          ),
        ),
      );
    }
  }
  
  void _onFileLongPressed(GitHubFile file) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
      });
    }
    _toggleFileSelection(file);
  }

  void _toggleFileSelection(GitHubFile file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
      if (_selectedFiles.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });
  }
  
  void _selectPathForUpload(String path) {
    if (widget.onPathSelected != null) {
      widget.onPathSelected!(path);
      Navigator.of(context).popUntil((route) => route.settings.name != 'repo_files');
    } else {
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

  Future<void> _deleteSelectedFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Files'),
        content: Text('Are you sure you want to delete ${_selectedFiles.length} file(s)? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _githubService.deleteFiles(
        owner: widget.repository.ownerLogin,
        repo: widget.repository.name,
        files: _selectedFiles.toList(),
        branch: _selectedBranch!,
      );
      
      setState(() {
        _isSelectionMode = false;
        _selectedFiles.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Files deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadFiles();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _cancelSelectionMode();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildDefaultAppBar(),
      body: SelectionArea(child: _buildBody()),
    );
  }
  
  AppBar _buildDefaultAppBar() {
    return AppBar(
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
    );
  }
  
  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _cancelSelectionMode,
        tooltip: 'Cancel',
      ),
      title: Text('${_selectedFiles.length} selected', style: const TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _selectedFiles.isNotEmpty ? _deleteSelectedFiles : null,
          tooltip: 'Delete Selected Files',
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
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
        final isSelected = _selectedFiles.contains(file);
        
        return ListTile(
          onTap: () => _onFileTapped(file),
          onLongPress: () => _onFileLongPressed(file),
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) => _toggleFileSelection(file),
                )
              : Icon(
                  file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                  color: file.isDirectory ? Colors.amber : Colors.grey,
                ),
          title: Text(file.name),
          selected: isSelected,
          trailing: _isSelectionMode
              ? null
              : Row(
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
                    if (file.isDirectory) const Icon(Icons.chevron_right),
                  ],
                ),
        );
      },
    );
  }
}
