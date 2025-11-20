class Repository {
  final String name;
  final String? description;
  final String fullName;
  final String defaultBranch;
  final String ownerLogin;
  final bool isPrivate;
  
  Repository({
    required this.name,
    this.description,
    required this.fullName,
    required this.defaultBranch,
    required this.ownerLogin,
    required this.isPrivate,
  });
  
  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'] as String,
      description: json['description'] as String?,
      fullName: json['full_name'] as String,
      defaultBranch: json['default_branch'] as String? ?? 'main',
      ownerLogin: json['owner']['login'] as String,
      isPrivate: json['private'] as bool? ?? false,
    );
  }
  
  String get displayDescription => description ?? 'No description available';
  
  @override
  String toString() => 'Repository(name: $name, fullName: $fullName)';
}
