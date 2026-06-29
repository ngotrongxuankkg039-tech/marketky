import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marketky_shop_frontend/common/api_client.dart';
import 'package:marketky_shop_frontend/main.dart';
import 'package:marketky_shop_frontend/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login page before authentication', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async => http.Response('[]', 200));
    final apiClient = ApiClient('http://localhost:8080/api', client: client);
    final authProvider = AuthProvider(apiClient);

    await tester.pumpWidget(
      MarketKyShopApp(apiClient: apiClient, authProvider: authProvider),
    );
    await tester.pumpAndSettle();

    expect(find.text('MarketKy Shop'), findsOneWidget);
    expect(find.text('账号登录'), findsOneWidget);
  });
}
