import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/api_client.dart';
import '../../provider/auth_provider.dart';
import '../../provider/cart_provider.dart';
import '../../provider/order_provider.dart';
import '../../widgets/price_text.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CartProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('购物车')),
      body: cart.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
          ? const Center(child: Text('购物车为空'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final item in cart.items)
                  Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.product.imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.shopping_bag_outlined),
                        ),
                      ),
                      title: Text(item.product.name),
                      subtitle: PriceText(item.subtotal),
                      trailing: SizedBox(
                        width: 132,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: '减少',
                              onPressed: () {
                                cart.changeQuantity(
                                  item.product,
                                  item.quantity - 1,
                                );
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(item.quantity.toString()),
                            IconButton(
                              tooltip: '增加',
                              onPressed: () {
                                cart.changeQuantity(
                                  item.product,
                                  item.quantity + 1,
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          '合计',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        PriceText(
                          cart.totalAmount,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: _isCheckingOut
                              ? null
                              : () => _checkout(context),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(_isCheckingOut ? '提交中' : '模拟支付下单'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty || _isCheckingOut) return;
    setState(() => _isCheckingOut = true);
    try {
      await context.read<OrderProvider>().createOrder(
        items: List.of(cart.items),
        payMethod: 'MOCK',
      );
      cart.clearLocal();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('订单创建成功，库存已由后端事务扣减')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      if (error is ApiException && error.statusCode == 401) {
        await context.read<AuthProvider>().logout();
        if (!context.mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }
}
