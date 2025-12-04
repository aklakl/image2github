class AppConfig {
  // GitHub OAuth Configuration
  // TODO: Replace with your Client ID and Client Secret
  static const String githubClientId = 'Ov23li451NheLOJ5n6Oq';
  static const String githubClientSecret = 'cee7f1444a75753590d1ab8b8c9c1740d634d280';
  static const String githubRedirectUri = 'image2github://callback';
  static const String githubRedirectUriWeb = 'http://localhost:3000/';
  static const String githubApiBaseUrl = 'https://api.github.com';
/*
If you are running on Chrome (Web), the redirect URL works differently. image2github://callback is a custom scheme for mobile apps (Android/iOS).

Are you trying to run this on Chrome (Web) or Android Emulator?

If Android: The settings above are correct.
If Chrome (Web): You cannot use image2github:// scheme. You need to use http://localhost:port/ (where port is whatever flutter run uses, usually random, which makes it tricky).
*/
  
  // Scopes required for the app
  static const String githubScopes = 'repo read:user';
}
