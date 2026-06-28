class Address {
  const Address({
    required this.id,
    required this.receiver,
    required this.phone,
    required this.province,
    required this.city,
    required this.detail,
    this.isDefault = false,
  });

  final int id;
  final String receiver;
  final String phone;
  final String province;
  final String city;
  final String detail;
  final bool isDefault;

  String get fullText => '$province$city $detail';

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int,
      receiver: json['receiver']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      isDefault: json['isDefault'] as bool? ?? json['is_default'] == 1,
    );
  }
}
