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
import 'provider/auth_provider.dart';
import 'provider/cart_provider.dart';
import 'provider/catalog_provider.dart';
import 'provider/order_provider.dart';
import 'routes/app_routes.dart';

void main() {
  final apiClient = ApiClient(AppConstants.apiBaseUrl);
  runApp(MarketKyShopApp(apiClient: apiClient));
}

class MarketKyShopApp extends StatelessWidget {
  const MarketKyShopApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiClient)..restore(),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(apiClient)..load(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => AdminProvider(apiClient)),
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
    if (auth.isRestoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
