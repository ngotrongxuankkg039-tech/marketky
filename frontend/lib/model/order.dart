class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  final int id;
  final String orderNo;
  final String status;
  final double totalAmount;
  final DateTime createdAt;

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    return ShopOrder(
      id: json['id'] as int,
      orderNo:
          json['orderNo']?.toString() ?? json['order_no']?.toString() ?? '',
      status: json['status']?.toString() ?? 'CREATED',
      totalAmount:
          double.tryParse(
            json['totalAmount']?.toString() ??
                json['total_amount']?.toString() ??
                '0',
          ) ??
          0,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }
}
