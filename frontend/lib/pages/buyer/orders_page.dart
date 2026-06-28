import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/order.dart';
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
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.orders.isEmpty
          ? const Center(child: Text('暂无订单'))
          : RefreshIndicator(
              onRefresh: () => context.read<OrderProvider>().load(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: orderProvider.orders.length,
                itemBuilder: (_, index) {
                  final order = orderProvider.orders[index];
                  return Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(order.orderNo),
                      subtitle: Text(
                        '${_statusText(order.status)} · ${_payText(order.payStatus)} · ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}',
                      ),
                      trailing: PriceText(order.totalAmount),
                      children: [
                        for (final item in order.items)
                          ListTile(
                            dense: true,
                            title: Text(item.productName),
                            subtitle: Text(
                              '数量 ${item.quantity} · 单价 ¥${item.price.toStringAsFixed(2)}',
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                PriceText(item.subtotal),
                                TextButton.icon(
                                  onPressed: _canReview(order)
                                      ? () => _showReviewDialog(context, item)
                                      : null,
                                  icon: const Icon(Icons.rate_review_outlined),
                                  label: const Text('评价'),
                                ),
                              ],
                            ),
                          ),
                        if (order.refund != null)
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.assignment_return_outlined,
                            ),
                            title: Text(
                              '退款：${_refundText(order.refund!.status)}',
                            ),
                            subtitle: Text(order.refund!.reason),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: _canRefund(order)
                                  ? () => _showRefundDialog(context, order)
                                  : null,
                              icon: const Icon(Icons.undo_outlined),
                              label: const Text('申请退款'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  bool _canRefund(ShopOrder order) {
    return order.refund == null &&
        {'PAID', 'SHIPPED', 'COMPLETED'}.contains(order.status);
  }

  bool _canReview(ShopOrder order) {
    return {'PAID', 'SHIPPED', 'COMPLETED'}.contains(order.status);
  }

  Future<void> _showRefundDialog(BuildContext context, ShopOrder order) async {
    final controller = TextEditingController(text: '商品不符合预期，申请课程设计演示退款');
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('申请退款 - ${order.orderNo}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '退款原因'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('提交'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty || !context.mounted) return;
    await _runOrderAction(
      context,
      () => context.read<OrderProvider>().requestRefund(order, reason),
      success: '退款申请已提交',
    );
  }

  Future<void> _showReviewDialog(
    BuildContext context,
    ShopOrderItem item,
  ) async {
    final controller = TextEditingController(text: '商品质量不错，数据库课程设计流程已跑通。');
    var rating = 5;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('评价 ${item.productName}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: rating,
                  decoration: const InputDecoration(labelText: '评分'),
                  items: [
                    for (var value = 1; value <= 5; value++)
                      DropdownMenuItem(value: value, child: Text('$value 星')),
                  ],
                  onChanged: (value) =>
                      setState(() => rating = value ?? rating),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: '评价内容'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
    final content = controller.text.trim();
    controller.dispose();
    if (saved != true || content.isEmpty || !context.mounted) return;
    await _runOrderAction(
      context,
      () => context.read<OrderProvider>().submitReview(
        item: item,
        rating: rating,
        content: content,
      ),
      success: '评价已提交',
    );
  }

  Future<void> _runOrderAction(
    BuildContext context,
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

String _statusText(String status) {
  return switch (status) {
    'CREATED' => '待支付',
    'PAID' => '待发货',
    'SHIPPED' => '已发货',
    'COMPLETED' => '已完成',
    'CANCELLED' => '已取消',
    'REFUNDING' => '退款中',
    'REFUNDED' => '已退款',
    _ => status,
  };
}

String _payText(String status) {
  return switch (status) {
    'SUCCESS' => '已支付',
    'PENDING' => '待支付',
    'FAILED' => '支付失败',
    'REFUNDED' => '已退款',
    _ => status,
  };
}

String _refundText(String status) {
  return switch (status) {
    'REQUESTED' => '待审核',
    'APPROVED' => '已通过',
    'REJECTED' => '已驳回',
    'DONE' => '已完成',
    _ => status,
  };
}
