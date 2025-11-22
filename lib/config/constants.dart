class AppConfig {
  // GitHub OAuth Configuration
  // TODO: Replace with your Client ID and Client Secret
  static const String githubClientId = 'Ov23li451NheLOJ5n6Oq';
  static const String githubClientSecret = 'cee7f1444a75753590d1ab8b8c9c1740d634d280';
  static const String githubRedirectUri = 'image2github://callback';
  static const String githubApiBaseUrl = 'https://api.github.com';
  
  // Scopes required for the app
  static const String githubScopes = 'repo read:user';
}
