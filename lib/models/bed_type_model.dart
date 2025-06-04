class BedType {
  final String typeName; // Primary key
  final double price; // Monthly price
  final String? customLabel;
  final double? premiumPercentage; // e.g., 0.20 for 20%
  final double? premiumFixedAmount;

  BedType({
    required this.typeName,
    required this.price,
    this.customLabel,
    this.premiumPercentage,
    this.premiumFixedAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'typeName': typeName,
      'price': price,
      'customLabel': customLabel,
      'premiumPercentage': premiumPercentage,
      'premiumFixedAmount': premiumFixedAmount,
    };
  }

  factory BedType.fromJson(Map<String, dynamic> json) {
    return BedType(
      typeName: json['typeName'] as String,
      price: json['price'] as double,
      customLabel: json['customLabel'] as String?,
      premiumPercentage: json['premiumPercentage'] as double?,
      premiumFixedAmount: json['premiumFixedAmount'] as double?,
    );
  }

  BedType copyWith({
    String? typeName,
    double? price,
    String? customLabel,
    double? premiumPercentage,
    double? premiumFixedAmount,
  }) {
    return BedType(
      typeName: typeName ?? this.typeName,
      price: price ?? this.price,
      customLabel: customLabel ?? this.customLabel,
      premiumPercentage: premiumPercentage ?? this.premiumPercentage,
      premiumFixedAmount: premiumFixedAmount ?? this.premiumFixedAmount,
    );
  }
}
