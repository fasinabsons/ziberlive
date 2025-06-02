// import 'package:flutter/foundation.dart';

// Global configuration settings for the Ziberlive app.
// Centralizes feature flags and environment-specific settings.

// Debug mode flag (normally imported from Flutter foundation)
const bool kDebugMode = false; // Set to false for production

// App information
const String kAppName = "Ziberlive";
const String kAppVersion = "1.0.0";
const String kBuildNumber = "1";

// Feature flags
const bool kUseFirebase = true;  // Set to true to enable premium features
const bool kUseAds = true;       // Set to true to show ads
const bool kUseMockP2P = false;  // Set to false to use real P2P connections
const bool kAllowMultiAdmin = true; // Allow multiple admins in the same instance
const bool kEnableAnalytics = true; // Enable usage analytics

// Free vs. Premium features
const bool kEnableCloudBackup = false;  // Premium: Set to true to enable
const bool kEnableAdvancedAnalytics = false; // Premium: Set to true to enable
const bool kEnableUserPhotos = false;   // Premium: Set to true to enable
const bool kEnablePublicVacancyListings = false; // Premium: Set to true to enable
const bool kEnablePushNotifications = false; // Premium: Set to true to enable
const bool kEnableWebDashboard = false; // Premium: Set to true to enable

// Premium thresholds
const int kCreditsPremiumThreshold = 1000; // Credits needed for "premium" status
const int kPremiumBasicFeeCents = 500; // $5.00 for basic premium
const int kPremiumProFeeCents = 1000;  // $10.00 for pro premium
const int kPremiumEnterpriseFeeCents = 2000; // $20.00 for enterprise premium

// P2P Sync Configuration
const String kServiceId = "com.Ziberlive.sync";
const Duration kSyncInterval = Duration(minutes: 30);
const Duration kConnectionTimeout = Duration(seconds: 30);
const int kMaxSyncRetries = 3;
const int kMaxPeers = 8;

// Database Configuration
const String kDatabaseName = "Ziberlive.db";
const int kDatabaseVersion = 1;
const bool kUseEncryption = false;

// UI Configuration
const Duration kAnimationDuration = Duration(milliseconds: 300);
const bool kUseAnimations = true;
const double kCardBorderRadius = 12.0;
const double kCommunityTreeSize = 200.0;

// Paths and URLs
const String kPrivacyPolicyUrl = "https://example.com/privacy";
const String kTermsOfServiceUrl = "https://example.com/terms";
const String kSupportEmail = "support@Ziberlive.example.com";

// Debug settings (using our custom kDebugMode)
const bool kVerboseLogging = kDebugMode;
const bool kShowDebugBanner = kDebugMode;

// Environment-specific settings
enum Environment { development, staging, production }

// Current environment
const Environment kEnvironment = Environment.production;

// Multi-language support
const List<String> kSupportedLanguages = ["en", "ar", "hi"];
const String kDefaultLanguage = "en";

// Misc
const int kTreeLevelMax = 5; // Maximum level for the community tree 