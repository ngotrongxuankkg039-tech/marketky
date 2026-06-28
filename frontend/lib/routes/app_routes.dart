import 'package:flutter/material.dart';

import '../pages/auth/register_page.dart';
import '../pages/buyer/cart_page.dart';
import '../pages/buyer/orders_page.dart';
import '../pages/buyer/profile_page.dart';

class AppRoutes {
  static const register = '/register';
  static const cart = '/cart';
  static const orders = '/orders';
  static const profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
    register: (_) => const RegisterPage(),
    cart: (_) => const CartPage(),
    orders: (_) => const OrdersPage(),
    profile: (_) => const ProfilePage(),
  };
}
