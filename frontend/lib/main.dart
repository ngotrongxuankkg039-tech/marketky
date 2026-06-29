import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'common/api_client.dart';
import 'common/app_constants.dart';
import 'common/app_theme.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/buyer/home_page.dart';
import 'pages/merchant/merchant_dashboard_page.dart';
import 'provider/admin_provider.dart';
import 'provider/address_provider.dart';
import 'provider/auth_provider.dart';
import 'provider/cart_provider.dart';
import 'provider/catalog_provider.dart';
import 'provider/merchant_provider.dart';
import 'provider/order_provider.dart';
import 'provider/review_provider.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient(AppConstants.apiBaseUrl);
  final authProvider = AuthProvider(apiClient);
  await authProvider.restore();
  runApp(MarketKyShopApp(apiClient: apiClient, authProvider: authProvider));
}

class MarketKyShopApp extends StatelessWidget {
  const MarketKyShopApp({
    super.key,
    required this.apiClient,
    required this.authProvider,
  });

  final ApiClient apiClient;
  final AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(apiClient)..load(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => AddressProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => MerchantProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => AdminProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ReviewProvider(apiClient)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.light(),
        routes: AppRoutes.routes,
        home: const RoleGate(),
      ),
    );
  }
}

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const LoginPage();
    }
    if (auth.hasRole(AppRoles.admin)) {
      return const AdminDashboardPage();
    }
    if (auth.hasRole(AppRoles.merchant)) {
      return const MerchantDashboardPage();
    }
    return const HomePage();
  }
}
