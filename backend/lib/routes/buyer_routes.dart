import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/mysql_database.dart';
import '../middleware/auth_middleware.dart';
import '../utils/json_response.dart';
import '../utils/request_body.dart';

class FavoriteRoutes {
  FavoriteRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..post('/<productId|[0-9]+>', _add)
    ..delete('/<productId|[0-9]+>', _remove);

  Future<Response> _add(Request request, String productId) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      await connection.query(
        'INSERT IGNORE INTO favorites(user_id, product_id) VALUES (?, ?)',
        [user.id, int.parse(productId)],
      );
      return jsonResponse({'message': 'Favorite saved'});
    });
  }

  Future<Response> _remove(Request request, String productId) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      await connection.query(
        'DELETE FROM favorites WHERE user_id = ? AND product_id = ?',
        [user.id, int.parse(productId)],
      );
      return jsonResponse({'message': 'Favorite removed'});
    });
  }
}

class AddressRoutes {
  AddressRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..get('/', _list)
    ..post('/', _create);

  Future<Response> _list(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final results = await connection.query(
        'SELECT id, receiver, phone, province, city, detail, is_default FROM addresses WHERE user_id = ? ORDER BY is_default DESC, id DESC',
        [user.id],
      );
      return jsonResponse(results.map((row) => row.fields).toList());
    });
  }

  Future<Response> _create(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    return _database.withConnection((connection) async {
      final result = await connection.query(
        '''
        INSERT INTO addresses(user_id, receiver, phone, province, city, detail, is_default)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          user.id,
          body['receiver'],
          body['phone'],
          body['province'],
          body['city'],
          body['detail'],
          body['isDefault'] == true ? 1 : 0,
        ],
      );
      return jsonResponse({'id': result.insertId}, statusCode: 201);
    });
  }
}

class ReviewRoutes {
  ReviewRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()..post('/', _create);

  Future<Response> _create(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    return _database.withConnection((connection) async {
      final result = await connection.query(
        '''
        INSERT INTO reviews(user_id, product_id, order_item_id, rating, content, status)
        VALUES (?, ?, ?, ?, ?, "VISIBLE")
        ''',
        [
          user.id,
          body['productId'],
          body['orderItemId'],
          body['rating'],
          body['content'],
        ],
      );
      return jsonResponse({'id': result.insertId}, statusCode: 201);
    });
  }
}
