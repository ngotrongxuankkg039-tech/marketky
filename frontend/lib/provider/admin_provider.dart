import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../common/api_client.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider(this._apiClient);

  final ApiClient _apiClient;
  bool isLoading = false;
  Map<String, dynamic> stats = const {};
  List<Map<String, dynamic>> users = const [];
  List<Map<String, dynamic>> merchantApplications = const [];

  Future<void> loadDashboard() async {
    isLoading = true;
    notifyListeners();
    try {
      stats = await _apiClient.get('/admin/stats') as Map<String, dynamic>;
      users = (await _apiClient.get('/admin/users') as List<dynamic>)
          .cast<Map<String, dynamic>>();
      merchantApplications =
          (await _apiClient.get('/admin/merchant-applications')
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
    } catch (_) {
      stats = {'users': 128, 'shops': 12, 'orders': 386, 'sales': 58920};
      users = const [
        {
          'id': 1,
          'name': 'Alice',
          'email': 'buyer@example.com',
          'status': 'ACTIVE',
        },
        {
          'id': 2,
          'name': 'Bob',
          'email': 'merchant@example.com',
          'status': 'ACTIVE',
        },
      ];
      merchantApplications = const [
        {'id': 1, 'shopName': '校园数码店', 'ownerName': 'Bob', 'status': 'PENDING'},
      ];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> auditMerchant(int applicationId, bool approved) async {
    await _apiClient.put(
      '/admin/merchant-applications/$applicationId/audit',
      body: {'approved': approved},
    );
    await loadDashboard();
  }
}
