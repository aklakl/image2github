class GitHubFile {
  final String name;
  final String path;
  final String sha;
  final String type; // 'file' or 'dir'
  final int size;
  final String? downloadUrl;

  GitHubFile({
    required this.name,
    required this.path,
    required this.sha,
    required this.type,
    required this.size,
    this.downloadUrl,
  });

  factory GitHubFile.fromJson(Map<String, dynamic> json) {
    return GitHubFile(
      name: json['name'] as String,
      path: json['path'] as String,
      sha: json['sha'] as String,
      type: json['type'] as String,
      size: json['size'] as int,
      downloadUrl: json['download_url'] as String?,
    );
  }

  bool get isDirectory => type == 'dir';
}
