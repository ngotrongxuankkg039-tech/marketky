import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/api_client.dart';
import '../../model/product.dart';
import '../../provider/auth_provider.dart';
import '../../provider/cart_provider.dart';
import '../../provider/review_provider.dart';
import '../../widgets/price_text.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReviewProvider>().loadProductReviews(product.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final reviews = reviewProvider.reviewsFor(product.id);
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
                    try {
                      await context.read<CartProvider>().add(product);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('已加入购物车')));
                    } catch (error) {
                      if (!context.mounted) return;
                      if (error is ApiException && error.statusCode == 401) {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
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
          if (reviewProvider.isLoading(product.id))
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (reviews.isEmpty)
            const ListTile(
              leading: Icon(Icons.rate_review_outlined),
              title: Text('暂无评价'),
              subtitle: Text('买家可在订单页提交购买评价。'),
            )
          else
            for (final review in reviews)
              ListTile(
                leading: const Icon(Icons.star_rate_rounded),
                title: Text('${review.userName} · ${review.rating} 星'),
                subtitle: Text(review.content),
              ),
        ],
      ),
    );
  }
}
