import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/merchant_models.dart';
import '../../model/product.dart';
import '../../provider/auth_provider.dart';
import '../../provider/catalog_provider.dart';
import '../../provider/merchant_provider.dart';
import '../../widgets/price_text.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_tile.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MerchantProvider>().loadAll();
      context.read<CatalogProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final merchant = context.watch<MerchantProvider>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('商家管理后台'),
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: merchant.isLoading
                  ? null
                  : () => context.read<MerchantProvider>().loadAll(),
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: '退出登录',
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.insights_outlined), text: '统计'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: '商品'),
              Tab(icon: Icon(Icons.local_shipping_outlined), text: '订单'),
              Tab(icon: Icon(Icons.storefront_outlined), text: '店铺'),
            ],
          ),
        ),
        body: merchant.isLoading && merchant.products.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _StatsTab(
                    stats: merchant.stats,
                    errorMessage: merchant.errorMessage,
                  ),
                  _ProductsTab(products: merchant.products),
                  _MerchantOrdersTab(
                    orders: merchant.orders,
                    refunds: merchant.refunds,
                  ),
                  _ShopInfoTab(shop: merchant.shop),
                ],
              ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats, this.errorMessage});

  final MerchantStats? stats;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final data =
        stats ??
        const MerchantStats(
          products: 0,
          orders: 0,
          pendingShipments: 0,
          refundRequests: 0,
          sales: 0,
        );
    final width = MediaQuery.sizeOf(context).width;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: Text(errorMessage!),
              leading: const Icon(Icons.error_outline),
              actions: const [SizedBox.shrink()],
            ),
          ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: width > 900
              ? 5
              : width > 560
              ? 3
              : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: width > 760 ? 2.0 : 2.2,
          children: [
            StatTile(
              label: '在售商品',
              value: data.products.toString(),
              icon: Icons.inventory_2_outlined,
            ),
            StatTile(
              label: '订单数',
              value: data.orders.toString(),
              icon: Icons.receipt_long_outlined,
            ),
            StatTile(
              label: '待发货',
              value: data.pendingShipments.toString(),
              icon: Icons.local_shipping_outlined,
            ),
            StatTile(
              label: '退款申请',
              value: data.refundRequests.toString(),
              icon: Icons.assignment_return_outlined,
            ),
            StatTile(
              label: '销售额',
              value: NumberFormat.currency(
                locale: 'zh_CN',
                symbol: '¥',
              ).format(data.sales),
              icon: Icons.payments_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          title: '商品库存与上下架',
          trailing: FilledButton.icon(
            onPressed: () => _showProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('新增商品'),
          ),
          child: products.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('暂无商品')),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 980),
                    child: DataTable(
                      columnSpacing: 28,
                      columns: const [
                        DataColumn(label: Text('商品')),
                        DataColumn(label: Text('价格')),
                        DataColumn(label: Text('库存')),
                        DataColumn(label: Text('状态')),
                        DataColumn(
                          label: SizedBox(width: 176, child: Text('操作')),
                        ),
                      ],
                      rows: [
                        for (final product in products)
                          DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    product.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(PriceText(product.price)),
                              DataCell(Text(product.stock.toString())),
                              DataCell(_StatusChip(status: product.status)),
                              DataCell(
                                SizedBox(
                                  width: 176,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: '编辑商品',
                                        onPressed: () => _showProductDialog(
                                          context,
                                          product: product,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: '修改库存',
                                        onPressed: () =>
                                            _showStockDialog(context, product),
                                        icon: const Icon(
                                          Icons.inventory_outlined,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: product.status == 'ON_SALE'
                                            ? '下架'
                                            : '上架',
                                        onPressed: () => _runAction(
                                          context,
                                          () => context
                                              .read<MerchantProvider>()
                                              .toggleStatus(product),
                                          success: product.status == 'ON_SALE'
                                              ? '商品已下架'
                                              : '商品已上架',
                                        ),
                                        icon: Icon(
                                          product.status == 'ON_SALE'
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showStockDialog(BuildContext context, Product product) async {
    final controller = TextEditingController(text: product.stock.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('修改库存 - ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '库存数量'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(int.tryParse(controller.text)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result < 0 || !context.mounted) return;
    await _runAction(
      context,
      () => context.read<MerchantProvider>().updateStock(product, result),
      success: '库存已更新',
    );
  }

  Future<void> _showProductDialog(
    BuildContext context, {
    Product? product,
  }) async {
    final formKey = GlobalKey<FormState>();
    final categories = context.read<CatalogProvider>().categories;
    var categoryId =
        product?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : 1);
    final categoryItems = categories.isEmpty
        ? [DropdownMenuItem(value: categoryId, child: const Text('默认分类'))]
        : [
            for (final category in categories)
              DropdownMenuItem(value: category.id, child: Text(category.name)),
          ];
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final priceController = TextEditingController(
      text: product?.price.toStringAsFixed(2) ?? '',
    );
    final stockController = TextEditingController(
      text: product?.stock.toString() ?? '0',
    );
    final imageController = TextEditingController(
      text: product?.imageUrl ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(product == null ? '新增商品' : '编辑商品'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: '分类'),
                      items: categoryItems,
                      onChanged: (value) =>
                          setState(() => categoryId = value ?? categoryId),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '商品名称'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? '请输入商品名称'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: '商品描述'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '价格'),
                      validator: (value) => double.tryParse(value ?? '') == null
                          ? '请输入有效价格'
                          : null,
                    ),
                    if (product == null) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '初始库存'),
                        validator: (value) => int.tryParse(value ?? '') == null
                            ? '请输入有效库存'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: '图片 URL'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      final provider = context.read<MerchantProvider>();
      await _runAction(
        context,
        () => product == null
            ? provider.createProduct(
                categoryId: categoryId,
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                price: double.parse(priceController.text),
                stock: int.parse(stockController.text),
                imageUrl: imageController.text.trim(),
              )
            : provider.updateProduct(
                product: product,
                categoryId: categoryId,
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                price: double.parse(priceController.text),
                imageUrl: imageController.text.trim(),
              ),
        success: product == null ? '商品已新增' : '商品已保存',
      );
    }

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    imageController.dispose();
  }
}

class _MerchantOrdersTab extends StatelessWidget {
  const _MerchantOrdersTab({required this.orders, required this.refunds});

  final List<MerchantOrder> orders;
  final List<MerchantRefund> refunds;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          title: '订单发货',
          child: orders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无订单')),
                )
              : Column(
                  children: [
                    for (final order in orders)
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(order.orderNo),
                        subtitle: Text(
                          '${_statusText(order.status)} · ${order.buyerName} · ${order.itemCount} 件商品',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PriceText(order.totalAmount),
                            FilledButton.tonal(
                              onPressed: order.status == 'PAID'
                                  ? () => _runAction(
                                      context,
                                      () => context
                                          .read<MerchantProvider>()
                                          .shipOrder(order),
                                      success: '订单已发货',
                                    )
                                  : null,
                              child: const Text('发货'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '退款审核',
          child: refunds.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无退款申请')),
                )
              : Column(
                  children: [
                    for (final refund in refunds)
                      ListTile(
                        leading: const Icon(Icons.assignment_return_outlined),
                        title: Text(refund.orderNo),
                        subtitle: Text(
                          '${refund.buyerName} · ${refund.reason} · ${_statusText(refund.status)}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PriceText(refund.amount),
                            FilledButton.tonal(
                              onPressed: refund.status == 'REQUESTED'
                                  ? () => _runAction(
                                      context,
                                      () => context
                                          .read<MerchantProvider>()
                                          .auditRefund(refund, true),
                                      success: '退款已通过',
                                    )
                                  : null,
                              child: const Text('通过'),
                            ),
                            FilledButton.tonal(
                              onPressed: refund.status == 'REQUESTED'
                                  ? () => _runAction(
                                      context,
                                      () => context
                                          .read<MerchantProvider>()
                                          .auditRefund(refund, false),
                                      success: '退款已驳回',
                                    )
                                  : null,
                              child: const Text('驳回'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ShopInfoTab extends StatefulWidget {
  const _ShopInfoTab({required this.shop});

  final MerchantShop? shop;

  @override
  State<_ShopInfoTab> createState() => _ShopInfoTabState();
}

class _ShopInfoTabState extends State<_ShopInfoTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _ShopInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shop != null && widget.shop != oldWidget.shop) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    final shop = widget.shop;
    if (shop == null) return;
    _nameController.text = shop.name;
    _descriptionController.text = shop.description;
    _phoneController.text = shop.contactPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          title: '店铺信息维护',
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '店铺名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '店铺公告/描述'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: '联系电话'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _runAction(
                    context,
                    () => context.read<MerchantProvider>().saveShop(
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      contactPhone: _phoneController.text.trim(),
                    ),
                    success: '店铺信息已保存',
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive =
        status == 'ON_SALE' || status == 'PAID' || status == 'APPROVED';
    return Chip(
      label: Text(_statusText(status)),
      backgroundColor: isActive
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }
}

String _statusText(String status) {
  return switch (status) {
    'ON_SALE' => '在售',
    'OFF_SALE' => '已下架',
    'PAID' => '待发货',
    'SHIPPED' => '已发货',
    'COMPLETED' => '已完成',
    'REFUNDING' => '退款中',
    'REFUNDED' => '已退款',
    'REQUESTED' => '待审核',
    'APPROVED' => '已通过',
    'REJECTED' => '已驳回',
    _ => status,
  };
}

Future<void> _runAction(
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
