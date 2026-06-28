import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/product.dart';
import '../../provider/cart_provider.dart';
import '../../widgets/price_text.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFFE5EFEA),
                  child: SizedBox(
                    height: 320,
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 56),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            product.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          PriceText(
            product.price,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text('库存 ${product.stock} 件'),
          const SizedBox(height: 12),
          Text(product.description),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: product.stock <= 0
                ? null
                : () async {
                    await context.read<CartProvider>().add(product);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已加入购物车')));
                  },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('加入购物车'),
          ),
          const SizedBox(height: 24),
          Text(
            '商品评价',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const ListTile(
            leading: Icon(Icons.star_rate_rounded),
            title: Text('课程设计演示评价'),
            subtitle: Text('后端 /reviews 接口会保存评分、文字内容和审核状态。'),
          ),
        ],
      ),
    );
  }
}
