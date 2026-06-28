class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.payStatus,
    required this.payMethod,
    required this.totalAmount,
    required this.createdAt,
    this.items = const [],
    this.refund,
  });

  final int id;
  final String orderNo;
  final String status;
  final String payStatus;
  final String payMethod;
  final double totalAmount;
  final DateTime createdAt;
  final List<ShopOrderItem> items;
  final OrderRefund? refund;

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
      payStatus: json['payStatus']?.toString() ?? 'PENDING',
      payMethod: json['payMethod']?.toString() ?? 'MOCK',
      items: (json['items'] as List? ?? const [])
          .map((item) => ShopOrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      refund: json['refund'] == null
          ? null
          : OrderRefund.fromJson(json['refund'] as Map<String, dynamic>),
    );
  }
}

class ShopOrderItem {
  const ShopOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  final int id;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  factory ShopOrderItem.fromJson(Map<String, dynamic> json) {
    return ShopOrderItem(
      id: json['id'] as int? ?? 0,
      productId: json['productId'] as int? ?? json['product_id'] as int? ?? 0,
      productName:
          json['productName']?.toString() ??
          json['product_name']?.toString() ??
          '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
    );
  }
}

class OrderRefund {
  const OrderRefund({
    required this.id,
    required this.reason,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String reason;
  final double amount;
  final String status;
  final DateTime createdAt;

  factory OrderRefund.fromJson(Map<String, dynamic> json) {
    return OrderRefund(
      id: json['id'] as int? ?? 0,
      reason: json['reason']?.toString() ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      status: json['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
