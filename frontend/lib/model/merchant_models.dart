class MerchantStats {
  const MerchantStats({
    required this.products,
    required this.orders,
    required this.pendingShipments,
    required this.refundRequests,
    required this.sales,
  });

  final int products;
  final int orders;
  final int pendingShipments;
  final int refundRequests;
  final double sales;

  factory MerchantStats.fromJson(Map<String, dynamic> json) {
    return MerchantStats(
      products: int.tryParse(json['products'].toString()) ?? 0,
      orders: int.tryParse(json['orders'].toString()) ?? 0,
      pendingShipments: int.tryParse(json['pendingShipments'].toString()) ?? 0,
      refundRequests: int.tryParse(json['refundRequests'].toString()) ?? 0,
      sales: double.tryParse(json['sales'].toString()) ?? 0,
    );
  }
}

class MerchantShop {
  const MerchantShop({
    required this.id,
    required this.name,
    required this.description,
    required this.contactPhone,
    required this.status,
  });

  final int id;
  final String name;
  final String description;
  final String contactPhone;
  final String status;

  factory MerchantShop.fromJson(Map<String, dynamic> json) {
    return MerchantShop(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class MerchantOrder {
  const MerchantOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.totalAmount,
    required this.buyerName,
    required this.itemCount,
    required this.createdAt,
  });

  final int id;
  final String orderNo;
  final String status;
  final double totalAmount;
  final String buyerName;
  final int itemCount;
  final DateTime createdAt;

  factory MerchantOrder.fromJson(Map<String, dynamic> json) {
    return MerchantOrder(
      id: json['id'] as int? ?? 0,
      orderNo: json['orderNo']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0,
      buyerName: json['buyerName']?.toString() ?? '',
      itemCount: int.tryParse(json['itemCount'].toString()) ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class MerchantRefund {
  const MerchantRefund({
    required this.id,
    required this.orderId,
    required this.orderNo,
    required this.buyerName,
    required this.reason,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int orderId;
  final String orderNo;
  final String buyerName;
  final String reason;
  final double amount;
  final String status;
  final DateTime createdAt;

  factory MerchantRefund.fromJson(Map<String, dynamic> json) {
    return MerchantRefund(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      orderNo: json['orderNo']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      status: json['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
