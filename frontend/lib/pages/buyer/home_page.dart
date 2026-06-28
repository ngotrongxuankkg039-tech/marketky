import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';
import '../../provider/cart_provider.dart';
import '../../provider/catalog_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/product_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketKy 商城'),
        actions: [
          IconButton(
            tooltip: '我的订单',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.orders),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: '个人资料',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: '购物车',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.cart),
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (cart.totalQuantity > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Badge(label: Text(cart.totalQuantity.toString())),
                ),
            ],
          ),
          IconButton(
            tooltip: '退出登录',
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CatalogProvider>().load(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索商品名称',
              ),
              onChanged: context.read<CatalogProvider>().search,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('全部'),
                      selected: catalog.selectedCategoryId == null,
                      onSelected: (_) => catalog.selectCategory(null),
                    ),
                  ),
                  for (final category in catalog.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: catalog.selectedCategoryId == category.id,
                        onSelected: (_) => catalog.selectCategory(category.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (catalog.isLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1100
                      ? 4
                      : width > 760
                      ? 3
                      : width > 520
                      ? 2
                      : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: catalog.filteredProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (_, index) =>
                        ProductCard(product: catalog.filteredProducts[index]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
