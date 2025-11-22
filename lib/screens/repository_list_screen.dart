import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../services/auth_service.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../widgets/repository_card.dart';
import 'image_upload_screen.dart';
import 'login_screen.dart';
import 'repo_files_screen.dart';

class RepositoryListScreen extends StatefulWidget {
  const RepositoryListScreen({super.key});
  
  @override
  State<RepositoryListScreen> createState() => _RepositoryListScreenState();
}

class _RepositoryListScreenState extends State<RepositoryListScreen> {
  final GitHubService _githubService = GitHubService();
  final StorageService _storageService = StorageService();
  
  List<Repository> _allRepositories = [];
  List<Repository> _filteredRepositories = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _initData() async {
    await _storageService.init();
    await _loadRepositories();
  }
  
  Future<void> _loadRepositories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final repos = await _githubService.fetchRepositories();
      setState(() {
        _allRepositories = repos;
        _filterAndSortRepositories();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _filterAndSortRepositories() {
    final query = _searchController.text.toLowerCase();
    final pinnedRepos = _storageService.getPinnedRepos();
    
    List<Repository> filtered = _allRepositories.where((repo) {
      return repo.name.toLowerCase().contains(query);
    }).toList();
    
    // Sort: Pinned first, then alphabetical
    filtered.sort((a, b) {
      final aPinned = pinnedRepos.contains(a.name);
      final bPinned = pinnedRepos.contains(b.name);
      
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    
    setState(() {
      _filteredRepositories = filtered;
    });
  }
  
  void _onSearchChanged(String query) {
    _filterAndSortRepositories();
  }
  
  void _onRepositoryTapped(Repository repository) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageUploadScreen(repository: repository),
      ),
    );
  }
  
  void _onBrowseTapped(Repository repository) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepoFilesScreen(repository: repository),
      ),
    );
  }
  
  Future<void> _onPinToggle(Repository repository) async {
    await _storageService.togglePinRepo(repository.name);
    _filterAndSortRepositories();
  }

  Future<void> _logout() async {
    final authService = AuthService();
    await authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SelectableText(
          'My Repositories',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search repositories...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: SelectionArea(
        child: RefreshIndicator(
          onRefresh: _loadRepositories,
          child: _buildBody(),
        ),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            SizedBox(height: 16),
            Text(
              'Loading repositories...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading repositories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadRepositories,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_filteredRepositories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                  ? 'No repositories found' 
                  : 'No matching repositories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredRepositories.length,
      itemBuilder: (context, index) {
        final repo = _filteredRepositories[index];
        return RepositoryCard(
          repository: repo,
          isPinned: _storageService.isRepoPinned(repo.name),
          onTap: () => _onRepositoryTapped(repo),
          onPinToggle: () => _onPinToggle(repo),
          onBrowse: () => _onBrowseTapped(repo),
        );
      },
    );
  }
}
