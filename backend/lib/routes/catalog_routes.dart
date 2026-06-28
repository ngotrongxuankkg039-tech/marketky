import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/mysql_database.dart';
import '../utils/json_response.dart';

class CatalogRoutes {
  CatalogRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..get('/categories', _categories)
    ..get('/products', _products)
    ..get('/products/<id|[0-9]+>', _productDetail);

  Future<Response> _categories(Request request) {
    return _database.withConnection((connection) async {
      final results = await connection.query(
        'SELECT id, name, parent_id FROM categories WHERE status = "ENABLED" ORDER BY sort_order, id',
      );
      return jsonResponse(
        results.map((row) {
          final data = row.fields;
          return {
            'id': data['id'],
            'name': data['name'],
            'parentId': data['parent_id'],
          };
        }).toList(),
      );
    });
  }

  Future<Response> _products(Request request) {
    final keyword = request.url.queryParameters['keyword'];
    final categoryId = request.url.queryParameters['categoryId'];
    final where = <String>['p.deleted_at IS NULL', 'p.status = "ON_SALE"'];
    final values = <Object?>[];
    if (keyword != null && keyword.isNotEmpty) {
      where.add('p.name LIKE ?');
      values.add('%$keyword%');
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      where.add('p.category_id = ?');
      values.add(int.parse(categoryId));
    }
    return _database.withConnection((connection) async {
      final results = await connection.query('''
        SELECT p.id, p.shop_id, p.category_id, p.name, p.description, p.price, p.stock, p.status,
               COALESCE(MIN(pi.url), '') AS image_url
        FROM products p
        LEFT JOIN product_images pi ON pi.product_id = p.id
        WHERE ${where.join(' AND ')}
        GROUP BY p.id
        ORDER BY p.created_at DESC
        ''', values);
      return jsonResponse(results.map(_productJson).toList());
    });
  }

  Future<Response> _productDetail(Request request, String id) {
    return _database.withConnection((connection) async {
      final results = await connection.query(
        '''
        SELECT p.id, p.shop_id, p.category_id, p.name, p.description, p.price, p.stock, p.status,
               COALESCE(MIN(pi.url), '') AS image_url
        FROM products p
        LEFT JOIN product_images pi ON pi.product_id = p.id
        WHERE p.id = ? AND p.deleted_at IS NULL
        GROUP BY p.id
        ''',
        [int.parse(id)],
      );
      if (results.isEmpty) {
        return jsonResponse({'message': 'Product not found'}, statusCode: 404);
      }
      return jsonResponse(_productJson(results.first));
    });
  }

  Map<String, dynamic> _productJson(dynamic row) {
    final data = row.fields;
    return {
      'id': data['id'],
      'shopId': data['shop_id'],
      'categoryId': data['category_id'],
      'name': data['name'],
      'description': data['description'],
      'price': data['price'].toString(),
      'stock': data['stock'],
      'status': data['status'],
      'imageUrl': data['image_url'],
    };
  }
}
