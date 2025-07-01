class UserPaymentModel {
  final int userId;
  final String planName;
  final String paymentStatus;
  final double amount;
  final String transactionId;

  UserPaymentModel({
    required this.userId,
    required this.planName,
    required this.paymentStatus,
    required this.amount,
    required this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "planName": planName,
      "paymentStatus": paymentStatus,
      "amount": amount,
      "transactionId": transactionId,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
