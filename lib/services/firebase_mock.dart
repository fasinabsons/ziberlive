// Mock Firebase implementation for when Firebase is not enabled.
// This allows the app to compile and run without actual Firebase dependencies.

import 'package:flutter/foundation.dart';

/// Mock Firebase class
class Firebase {
  /// Mock initialization function that does nothing but returns a Future
  static Future<FirebaseApp> initializeApp({FirebaseOptions? options}) async {
    if (kDebugMode) {
      debugPrint('Using mock Firebase implementation');
    }
    return FirebaseApp();
  }
}

/// Mock FirebaseApp class
class FirebaseApp {
  final String name = 'mock-app';
  final FirebaseOptions options = FirebaseOptions();
}

/// Mock FirebaseOptions class
class FirebaseOptions {
  final String apiKey = 'mock-api-key';
  final String appId = 'mock-app-id';
  final String messagingSenderId = 'mock-sender-id';
  final String projectId = 'mock-project-id';
}

/// Mock FirebaseAuth implementation
class FirebaseAuth {
  static FirebaseAuth instance = FirebaseAuth();
  
  Stream<User?> authStateChanges() {
    return Stream.value(null);
  }
  
  User? get currentUser => null;
  
  Future<UserCredential> signInAnonymously() async {
    return UserCredential();
  }
  
  Future<void> signOut() async {}
}

/// Mock User class
class User {
  final String uid = 'mock-user-id';
  final String? email = null;
  final String? displayName = null;
}

/// Mock UserCredential class
class UserCredential {
  final User? user = User();
}

/// Mock FirebaseStorage implementation
class FirebaseStorage {
  static FirebaseStorage instance = FirebaseStorage();
  
  Reference ref([String? path]) {
    return Reference();
  }
}

/// Mock Reference class
class Reference {
  Future<String> getDownloadURL() async {
    return 'https://example.com/mock-image.jpg';
  }
  
  UploadTask putFile(dynamic file) {
    return UploadTask();
  }
  
  Reference child(String path) {
    return Reference();
  }
}

/// Mock UploadTask class
class UploadTask {
  Future<TaskSnapshot> get future async {
    return TaskSnapshot();
  }
}

/// Mock TaskSnapshot class
class TaskSnapshot {
  final String ref = 'mock-ref';
}

/// Mock FirebaseMessaging implementation
class FirebaseMessaging {
  static FirebaseMessaging instance = FirebaseMessaging();
  
  Future<String?> getToken() async {
    return 'mock-fcm-token';
  }
  
  Future<void> subscribeToTopic(String topic) async {}
  
  Future<void> unsubscribeFromTopic(String topic) async {}
}

/// Mock FirebaseAnalytics implementation
class FirebaseAnalytics {
  static FirebaseAnalytics instance = FirebaseAnalytics();
  
  Future<void> logEvent({required String name, Map<String, dynamic>? parameters}) async {}
} 