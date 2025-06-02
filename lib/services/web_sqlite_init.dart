import 'package:flutter/foundation.dart';

// This file contains a stub implementation for web platforms
// It helps avoid the "databaseFactory not initialized" error

class WebSqliteInit {
  // This method is a no-op on web platforms
  static void initialize() {
    if (kDebugMode) {
      debugPrint('Web platform detected - using alternative storage implementation');
    }
  }
} 