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

// --- Ad Reward Constants ---
// These values are granted for *each* rewarded ad successfully watched.
// Trust Score
const int kRewardTrustScorePoints = 5;
// Community Tree
const int kRewardCommunityTreePoints = 10;
// Income Pool (placeholder, assuming this is a general "points" pool)
const int kRewardIncomePoolPoints = 2; // Could be cents or abstract points
// Amazon Coupon Points
const int kRewardAmazonCouponPoints = 1; // e.g., 1 point towards a coupon
// PayPal Points (similar to Amazon, points towards a PayPal reward)
const int kRewardPayPalPoints = 1;

// Community Tree Configuration
const int kPointsPerCommunityTreeVisualLevel = 100; // Points needed to advance one visual stage of the tree

// --- Settings Ad Reward Constants ---
const int kRewardSettingsAdCoins = 10;
const int kRewardSettingsAdAmazonCouponPoints = 1;
const int kRewardSettingsAdPayPalPoints = 1; // Simplified to 1 integer point instead of 0.5
const int kSettingsAdsDailyCap = 5;

// --- Amazon Coupon Tiers ---
class AmazonCouponTier {
  final int pointsRequired;
  final int dollarValue; // USD
  final String description;

  const AmazonCouponTier({
    required this.pointsRequired,
    required this.dollarValue,
    required this.description,
  });
}

const List<AmazonCouponTier> kAmazonCouponTiers = [
  AmazonCouponTier(pointsRequired: 100, dollarValue: 5, description: "\$5 Amazon Coupon"),
  AmazonCouponTier(pointsRequired: 450, dollarValue: 25, description: "\$25 Amazon Coupon (10% off points)"), // Example with a slight "discount"
  AmazonCouponTier(pointsRequired: 800, dollarValue: 50, description: "\$50 Amazon Coupon (20% off points)"),
];

// --- PayPal Cash Reward Tiers ---
class PayPalCashTier {
  final int pointsRequired;
  final int dollarValue; // USD
  final String description;

  const PayPalCashTier({
    required this.pointsRequired,
    required this.dollarValue,
    required this.description,
  });
}

const List<PayPalCashTier> kPayPalCashTiers = [
  PayPalCashTier(pointsRequired: 200, dollarValue: 2, description: "\$2 PayPal Cash"),
  PayPalCashTier(pointsRequired: 900, dollarValue: 10, description: "\$10 PayPal Cash (10% off points)"),
  PayPalCashTier(pointsRequired: 1600, dollarValue: 20, description: "\$20 PayPal Cash (20% off points)"),
];

// --- Income Pool Collective Goals ---
enum IncomePoolRewardType { payPal, amazonCoupon, other }

class IncomePoolGoal {
  final int pointsRequired;
  final String description; // e.g., "$10 PayPal for the house", "Pizza Night Fund"
  final IncomePoolRewardType rewardType;
  final int rewardValue; // e.g., 10 (for $10), or an ID for a specific coupon/item

  const IncomePoolGoal({
    required this.pointsRequired,
    required this.description,
    required this.rewardType,
    required this.rewardValue,
  });
}

const List<IncomePoolGoal> kIncomePoolGoals = [
  IncomePoolGoal(pointsRequired: 1000, description: "\$10 PayPal for household supplies", rewardType: IncomePoolRewardType.payPal, rewardValue: 10),
  IncomePoolGoal(pointsRequired: 2500, description: "\$25 Amazon Coupon for common goods", rewardType: IncomePoolRewardType.amazonCoupon, rewardValue: 25),
  IncomePoolGoal(pointsRequired: 5000, description: "Fund for a Community Pizza Night", rewardType: IncomePoolRewardType.other, rewardValue: 50), // rewardValue could be target fund amount
];

// --- Microtransaction Products ---
enum ProductType { coins, treeSkin, featureUnlock }

class MicrotransactionProduct {
  final String id; // e.g., "coins_50", "tree_skin_cherry_blossom"
  final String name;
  final String description;
  final double priceUSD;
  final ProductType type;
  final int? coinAmount; // Only if type is coins
  final String? cosmeticId; // Only if type is cosmetic (e.g., "cherry_blossom_skin")

  const MicrotransactionProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.priceUSD,
    required this.type,
    this.coinAmount,
    this.cosmeticId,
  });
}

const List<MicrotransactionProduct> kMicrotransactionProducts = [
  MicrotransactionProduct(id: "coins_50", name: "50 Credits", description: "Get 50 in-app credits.", priceUSD: 0.99, type: ProductType.coins, coinAmount: 50),
  MicrotransactionProduct(id: "coins_250", name: "250 Credits", description: "Get 250 in-app credits (Best Value!).", priceUSD: 3.99, type: ProductType.coins, coinAmount: 250),
  MicrotransactionProduct(id: "tree_skin_gold", name: "Golden Tree Skin", description: "A dazzling golden skin for your community tree!", priceUSD: 1.99, type: ProductType.treeSkin, cosmeticId: "golden_tree"),
  MicrotransactionProduct(id: "tree_skin_sakura", name: "Sakura Tree Skin", description: "Beautiful cherry blossom skin for the community tree.", priceUSD: 1.99, type: ProductType.treeSkin, cosmeticId: "sakura_tree"),
  // Example for a feature unlock, though not fully implemented in this subtask
  // MicrotransactionProduct(id: "unlock_advanced_stats", name: "Advanced Statistics", description: "Unlock detailed personal and community statistics.", priceUSD: 2.99, type: ProductType.featureUnlock),
];

// --- Subscription Plans ---
enum SubscriptionBenefit { adFree, unlimitedFinanceCollaboration, cloudBackup, advancedAnalytics }

class SubscriptionPlan {
  final String id; // e.g., "premium_monthly", "premium_yearly"
  final String name;
  final String description;
  final double priceUSD;
  final Duration duration; // e.g., Duration(days: 30) for monthly
  final List<SubscriptionBenefit> benefits;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceUSD,
    required this.duration,
    required this.benefits,
  });
}

const List<SubscriptionPlan> kSubscriptionPlans = [
  SubscriptionPlan(
    id: "premium_monthly",
    name: "Premium Monthly",
    description: "Unlock all premium features with a monthly subscription.",
    priceUSD: 1.99,
    duration: Duration(days: 30),
    benefits: [SubscriptionBenefit.adFree, SubscriptionBenefit.cloudBackup, SubscriptionBenefit.advancedAnalytics],
  ),
  SubscriptionPlan(
    id: "premium_yearly",
    name: "Premium Yearly",
    description: "Get the best value with an annual subscription to all premium features.",
    priceUSD: 19.99, // Example: slight discount for yearly
    duration: Duration(days: 365),
    benefits: [SubscriptionBenefit.adFree, SubscriptionBenefit.cloudBackup, SubscriptionBenefit.advancedAnalytics, SubscriptionBenefit.unlimitedFinanceCollaboration],
  ),
];

const Duration kFreeTrialDuration = Duration(days: 7);

// --- Sync Interval Settings ---
enum SyncIntervalOption { manual, every15Minutes, everyHour, every4Hours }

const Map<SyncIntervalOption, Duration> kSyncIntervalDurations = {
  SyncIntervalOption.manual: Duration.zero, // Or a special marker like Duration(days: 999)
  SyncIntervalOption.every15Minutes: Duration(minutes: 15),
  SyncIntervalOption.everyHour: Duration(hours: 1),
  SyncIntervalOption.every4Hours: Duration(hours: 4),
};

const Map<SyncIntervalOption, String> kSyncIntervalLabels = {
  SyncIntervalOption.manual: "Manual Only",
  SyncIntervalOption.every15Minutes: "Every 15 minutes",
  SyncIntervalOption.everyHour: "Every hour",
  SyncIntervalOption.every4Hours: "Every 4 hours",
};

const String kPrefsSyncIntervalKey = 'syncIntervalPreference';

// --- Sync Method Priority Settings ---
enum SyncMethodPriority { wifiPreferred, bluetoothPreferred, systemChoice }

const Map<SyncMethodPriority, String> kSyncMethodPriorityLabels = {
  SyncMethodPriority.wifiPreferred: "Prefer Wi-Fi Direct / LAN",
  SyncMethodPriority.bluetoothPreferred: "Prefer Bluetooth",
  SyncMethodPriority.systemChoice: "Let System Decide",
};

const String kPrefsSyncMethodPriorityKey = 'syncMethodPriorityPreference';

// --- Sync Button Style Customization ---
const String kPrefsSyncButtonColorKey = 'syncButtonColorPreference';
const String kPrefsSyncButtonIconKey = 'syncButtonIconPreference';

// Define some color options (could be more extensive or a color picker)
// Storing ARGB value as int.
const Map<String, int> kSyncButtonColorOptions = {
  "Teal (Default)": 0xFF008080, // Colors.teal.value
  "Blue": 0xFF2196F3,       // Colors.blue.value
  "Green": 0xFF4CAF50,      // Colors.green.value
  "Orange": 0xFFFF9800,     // Colors.orange.value
};

// Define some icon options (using codepoints)
// Ensure these icons are available (e.g., MaterialIcons)
const Map<String, int> kSyncButtonIconOptions = {
  "Sync (Default)": 0xe627, // Icons.sync_rounded.codePoint
  "Refresh": 0xe514,      // Icons.refresh_rounded.codePoint
  "Loop": 0xe3ループ,        // Icons.loop_rounded.codePoint (Note: '루프' is Korean, likely a typo for loop's codepoint, using placeholder)
                                // Corrected: Icons.loop.codepoint is 0xe3a5
  "Cloud Sync": 0xe2c8,   // Icons.cloud_sync_rounded.codePoint
};
// Placeholder for loop icon if the above was a typo and meant to be a standard material icon
// const int kLoopIconCodePoint = 0xe3a5; // Actual Icons.loop.codePoint

// --- Backup Schedule Settings ---
enum BackupScheduleOption { manual, daily, weekly }
const Map<BackupScheduleOption, String> kBackupScheduleLabels = {
  BackupScheduleOption.manual: "Manual Only",
  BackupScheduleOption.daily: "Daily (Automatic)",
  BackupScheduleOption.weekly: "Weekly (Automatic)",
};
const String kPrefsBackupScheduleKey = 'backupSchedulePreference';

// --- Backup Scope Settings ---
enum BackupScopeOption { full } // Simplified for now
const Map<BackupScopeOption, String> kBackupScopeLabels = {
  BackupScopeOption.full: "Full Backup (Recommended)",
};
const String kPrefsBackupScopeKey = 'backupScopePreference';