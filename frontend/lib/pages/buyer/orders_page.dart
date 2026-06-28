import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider/order_provider.dart';
import '../../widgets/price_text.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OrderProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('我的订单')),
      body: orderProvider.orders.isEmpty
          ? const Center(child: Text('暂无订单'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orderProvider.orders.length,
              itemBuilder: (_, index) {
                final order = orderProvider.orders[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(order.orderNo),
                    subtitle: Text(
                      '${order.status} · ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}',
                    ),
                    trailing: PriceText(order.totalAmount),
                  ),
                );
              },
            ),
    );
  }
}
