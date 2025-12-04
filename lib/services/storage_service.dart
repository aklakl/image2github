import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _pinnedReposKey = 'pinned_repos';
  static const String _targetPathPrefix = 'target_path_';
  
  // Default pinned repo
  static const String _defaultPinnedRepo = 'PCC';
  
  late SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize default pinned repo if no pinned repos exist
    if (!_prefs.containsKey(_pinnedReposKey)) {
      await _pinRepo(_defaultPinnedRepo);
    }
  }
  
  // Get list of pinned repositories
  List<String> getPinnedRepos() {
    return _prefs.getStringList(_pinnedReposKey) ?? [];
  }
  
  // Check if a repo is pinned
  bool isRepoPinned(String repoName) {
    final pinnedRepos = getPinnedRepos();
    return pinnedRepos.contains(repoName);
  }
  
  // Toggle pin status for a repo
  Future<void> togglePinRepo(String repoName) async {
    if (isRepoPinned(repoName)) {
      await _unpinRepo(repoName);
    } else {
      await _pinRepo(repoName);
    }
  }
  
  Future<void> _pinRepo(String repoName) async {
    final pinnedRepos = getPinnedRepos();
    if (!pinnedRepos.contains(repoName)) {
      pinnedRepos.add(repoName);
      await _prefs.setStringList(_pinnedReposKey, pinnedRepos);
    }
  }
  
  Future<void> _unpinRepo(String repoName) async {
    final pinnedRepos = getPinnedRepos();
    if (pinnedRepos.contains(repoName)) {
      pinnedRepos.remove(repoName);
      await _prefs.setStringList(_pinnedReposKey, pinnedRepos);
    }
  }
  
  // Get target path for a repo
  String getTargetPath(String repoName) {
    return _prefs.getString('$_targetPathPrefix$repoName') ?? '';
  }
  
  // Set target path for a repo
  Future<void> setTargetPath(String repoName, String path) async {
    await _prefs.setString('$_targetPathPrefix$repoName', path);
  }
}
