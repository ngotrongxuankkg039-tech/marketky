import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';
import '../../provider/catalog_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_tile.dart';

class MerchantDashboardPage extends StatelessWidget {
  const MerchantDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<CatalogProvider>().products;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('商家管理后台'),
          actions: [
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
        body: TabBarView(
          children: [
            _StatsTab(productCount: products.length),
            _ProductsTab(products: products),
            const _MerchantOrdersTab(),
            const _ShopInfoTab(),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.productCount});

  final int productCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        StatTile(
          label: '在售商品',
          value: productCount.toString(),
          icon: Icons.inventory_2_outlined,
        ),
        const StatTile(
          label: '今日订单',
          value: '24',
          icon: Icons.receipt_long_outlined,
        ),
        const StatTile(
          label: '待发货',
          value: '6',
          icon: Icons.local_shipping_outlined,
        ),
        const StatTile(
          label: '销售额',
          value: '¥12,680',
          icon: Icons.payments_outlined,
        ),
      ],
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.products});

  final List<dynamic> products;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          title: '商品库存与上下架',
          trailing: FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('调用 POST /merchant/products 新增商品')),
            ),
            icon: const Icon(Icons.add),
            label: const Text('新增商品'),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('商品')),
                DataColumn(label: Text('价格')),
                DataColumn(label: Text('库存')),
                DataColumn(label: Text('状态')),
                DataColumn(label: Text('操作')),
              ],
              rows: [
                for (final product in products)
                  DataRow(
                    cells: [
                      DataCell(Text(product.name)),
                      DataCell(Text('¥${product.price.toStringAsFixed(2)}')),
                      DataCell(Text(product.stock.toString())),
                      DataCell(Text(product.status)),
                      DataCell(
                        Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: '修改库存',
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '调用 PUT /merchant/products/${product.id}/stock',
                                      ),
                                    ),
                                  ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: product.status == 'ON_SALE'
                                  ? '下架'
                                  : '上架',
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '调用 PUT /merchant/products/${product.id}/status',
                                      ),
                                    ),
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
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MerchantOrdersTab extends StatelessWidget {
  const _MerchantOrdersTab();

  @override
  Widget build(BuildContext context) {
    const orders = [
      {'orderNo': 'MK202606280001', 'status': 'PAID', 'amount': '¥458.00'},
      {'orderNo': 'MK202606280002', 'status': 'REFUNDING', 'amount': '¥159.00'},
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          title: '订单发货/退款',
          child: Column(
            children: [
              for (final order in orders)
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(order['orderNo']!),
                  subtitle: Text(order['status']!),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '调用 PUT /merchant/orders/{id}/ship',
                                ),
                              ),
                            ),
                        child: const Text('发货'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '调用 PUT /merchant/refunds/{id}/audit',
                                ),
                              ),
                            ),
                        child: const Text('退款'),
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

class _ShopInfoTab extends StatelessWidget {
  const _ShopInfoTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SectionCard(
          title: '店铺信息维护',
          child: Column(
            children: [
              TextField(decoration: InputDecoration(labelText: '店铺名称')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: '店铺公告')),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: null, child: Text('保存')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
