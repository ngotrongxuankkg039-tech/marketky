import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../common/api_client.dart';
import '../model/address.dart';

class AddressProvider extends ChangeNotifier {
  AddressProvider(this._apiClient);

  final ApiClient _apiClient;
  final List<Address> addresses = [];
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _apiClient.get('/addresses/') as List<dynamic>;
      addresses
        ..clear()
        ..addAll(
          data.map((item) => Address.fromJson(item as Map<String, dynamic>)),
        );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({
    Address? address,
    required String receiver,
    required String phone,
    required String province,
    required String city,
    required String detail,
    required bool isDefault,
  }) async {
    final body = {
      'receiver': receiver,
      'phone': phone,
      'province': province,
      'city': city,
      'detail': detail,
      'isDefault': isDefault,
    };
    if (address == null) {
      await _apiClient.post('/addresses/', body: body);
    } else {
      await _apiClient.put('/addresses/${address.id}', body: body);
    }
    await load();
  }

  Future<void> delete(Address address) async {
    await _apiClient.delete('/addresses/${address.id}');
    await load();
  }
}
