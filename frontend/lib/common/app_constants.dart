class AppConstants {
  static const appName = 'MarketKy Shop';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );
}

class AppRoles {
  static const buyer = 'BUYER';
  static const merchant = 'MERCHANT_ADMIN';
  static const admin = 'SUPER_ADMIN';
}
