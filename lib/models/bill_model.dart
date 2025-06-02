import 'package:intl/intl.dart';
import 'user_model.dart';

class Bill {
  final String id;
  String name;
  double amount;
  DateTime dueDate;
  BillType type;
  List<String> userIds; // IDs of users who need to pay the bill
  Map<String, PaymentStatus> paymentStatus; // User ID to payment status
  String? apartmentId; // For apartment-specific bills

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.type,
    required this.userIds,
    this.paymentStatus = const {},
    this.apartmentId,
  });

  // Create a bill from JSON map
  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      name: json['name'],
      amount: json['amount']?.toDouble() ?? 0.0,
      dueDate: DateTime.parse(json['dueDate']),
      type: BillType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BillType.utility,
      ),
      userIds: List<String>.from(json['userIds'] ?? []),
      paymentStatus: (json['paymentStatus'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              PaymentStatus.values.firstWhere(
                (e) => e.toString() == value,
                orElse: () => PaymentStatus.unpaid,
              ),
            ),
          ) ??
          {},
      apartmentId: json['apartmentId'],
    );
  }

  // Convert bill to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'type': type.toString(),
      'userIds': userIds,
      'paymentStatus':
          paymentStatus.map((key, value) => MapEntry(key, value.toString())),
      'apartmentId': apartmentId,
    };
  }

  // Calculate amount per user
  double getAmountPerUser() {
    if (userIds.isEmpty) return 0;
    return amount / userIds.length;
  }

  // Format the due date
  String getFormattedDueDate() {
    return DateFormat('MMM dd, yyyy').format(dueDate);
  }

  // Check if the bill is overdue
  bool isOverdue() {
    return dueDate.isBefore(DateTime.now());
  }

  // Check if bill is relevant for a specific subscription type
  bool isRelevantForSubscription(SubscriptionType subscriptionType) {
    switch (type) {
      case BillType.rent:
        return subscriptionType == SubscriptionType.rent;
      case BillType.utility:
        return subscriptionType == SubscriptionType.utilities;
      case BillType.communityMeals:
        return subscriptionType == SubscriptionType.communityMeals;
      case BillType.drinkingWater:
        return subscriptionType == SubscriptionType.drinkingWater;
      case BillType.other:
        return true; // Other bills are relevant for all
    }
  }

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
