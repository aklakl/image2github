// Stub implementation for dart:html on non-web platforms
// This file is only used when running on mobile/desktop platforms

class Window {
  final Location location = Location();
  final History history = History();
}

class Location {
  String href = '';
}

class History {
  void replaceState(dynamic data, String title, String url) {
    // No-op on non-web platforms
  }
}

final window = Window();
