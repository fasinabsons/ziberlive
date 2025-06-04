import 'package:intl/intl.dart';
import 'user_model.dart'; // Assuming SubscriptionType might be used indirectly or was planned
// If SubscriptionType is from app_models.dart, that should be imported instead.
// For now, user_model.dart is kept as per original file.
// import 'app_models.dart'; // if SubscriptionType is defined there

class Bill {
  final String id;
  String name; // Serves as title
  String? description;
  double amount;
  DateTime dueDate;
  BillType type;
  List<String> userIds; // IDs of users who need to pay the bill
  Map<String, PaymentStatus> paymentStatus; // User ID to payment status
  String? apartmentId; // For apartment-specific bills
  double incomePoolRewardOffset;

  Bill({
    required this.id,
    required this.name,
    this.description,
    required this.amount,
    required this.dueDate,
    required this.type,
    required this.userIds,
    this.paymentStatus = const {},
    this.apartmentId,
    this.incomePoolRewardOffset = 0.0,
  });

  // Create a bill from JSON map
  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      name: json['name'],
      description: json['description'] as String?,
      amount: json['amount']?.toDouble() ?? 0.0,
      dueDate: DateTime.parse(json['dueDate']),
      type: BillType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BillType.utility, // Default type
      ),
      userIds: List<String>.from(json['userIds'] ?? []),
      paymentStatus: (json['paymentStatus'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              PaymentStatus.values.firstWhere(
                (e) => e.toString() == value,
                orElse: () => PaymentStatus.unpaid, // Default status
              ),
            ),
          ) ??
          {},
      apartmentId: json['apartmentId'],
      incomePoolRewardOffset: json['incomePoolRewardOffset']?.toDouble() ?? 0.0,
    );
  }

  // Convert bill to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'type': type.toString(),
      'userIds': userIds,
      'paymentStatus':
          paymentStatus.map((key, value) => MapEntry(key, value.toString())),
      'apartmentId': apartmentId,
      'incomePoolRewardOffset': incomePoolRewardOffset,
    };
  }

  // Calculate amount per user
  double getAmountPerUser() {
    if (userIds.isEmpty) return 0;
    // This calculation might need adjustment based on how exemptions are truly handled now.
    // For now, it's a simple division.
    return amount / userIds.length;
  }

  // Format the due date
  String getFormattedDueDate() {
    return DateFormat('MMM dd, yyyy').format(dueDate);
  }

  // Check if the bill is overdue
  bool isOverdue() {
    // Consider timezones if backend and frontend are in different TZs.
    return dueDate.isBefore(DateTime.now());
  }

  // Check if bill is relevant for a specific subscription type
  // This method might need an import for SubscriptionType if it's not defined locally
  // For now, assuming SubscriptionType is accessible.
  // bool isRelevantForSubscription(SubscriptionType subscriptionType) {
  //   switch (type) {
  //     case BillType.rent:
  //       return subscriptionType == SubscriptionType.rent;
  //     case BillType.utility:
  //       return subscriptionType == SubscriptionType.utilities;
  //     case BillType.communityMeals:
  //       return subscriptionType == SubscriptionType.communityMeals;
  //     case BillType.drinkingWater:
  //       return subscriptionType == SubscriptionType.drinkingWater;
  //     case BillType.other:
  //       return true; // Other bills are relevant for all
  //   }
  // }
  // Commenting out isRelevantForSubscription as SubscriptionType is not in scope here.
  // It was in the original file but referred to a type not defined in bill_model.dart.
  // This will be resolved when checking imports and dependencies.

  // Set payment status for a user
  void markAsPaid(String userId) {
    paymentStatus[userId] = PaymentStatus.paid;
  }

  // Get payment count
  int getPaidCount() {
    return paymentStatus.values
        .where((status) => status == PaymentStatus.paid)
        .length;
  }

  // Get payment progress percentage
  double getPaymentProgress() {
    if (userIds.isEmpty) return 0.0;
    return getPaidCount() / userIds.length;
  }
}

enum BillType {
  rent,
  utility,
  communityMeals,
  drinkingWater,
  other,
}

enum PaymentStatus {
  paid,
  unpaid,
  pending,
}
