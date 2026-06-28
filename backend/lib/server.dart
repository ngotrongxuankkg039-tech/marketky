import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config/env.dart';
import 'db/mysql_database.dart';
import 'middleware/auth_middleware.dart';
import 'middleware/cors_middleware.dart';
import 'routes/admin_routes.dart';
import 'routes/auth_routes.dart';
import 'routes/buyer_routes.dart';
import 'routes/cart_routes.dart';
import 'routes/catalog_routes.dart';
import 'routes/merchant_routes.dart';
import 'routes/order_routes.dart';
import 'utils/json_response.dart';

Handler buildHandler() {
  final database = MySqlDatabase(AppEnv.databaseConfig());
  final auth = AuthService(AppEnv.jwtSecret);

  final router = Router()
    ..get('/health', (_) => jsonResponse({'status': 'ok'}))
    ..mount('/api/auth/', AuthRoutes(database, auth).router.call)
    ..mount(
      '/api/favorites/',
      Pipeline()
          .addMiddleware(requireAuth(auth))
          .addMiddleware(requireRoles(const {'BUYER'}))
          .addHandler(FavoriteRoutes(database).router.call),
    )
    ..mount(
      '/api/addresses/',
      Pipeline()
          .addMiddleware(requireAuth(auth))
          .addMiddleware(requireRoles(const {'BUYER'}))
          .addHandler(AddressRoutes(database).router.call),
    )
    ..mount(
      '/api/reviews/',
      Pipeline()
          .addMiddleware(requireAuth(auth))
          .addMiddleware(requireRoles(const {'BUYER'}))
          .addHandler(ReviewRoutes(database).router.call),
    )
    ..mount('/api/', CatalogRoutes(database).router.call)
    ..mount(
      '/api/cart/',
      Pipeline()
          .addMiddleware(requireAuth(auth))
          .addMiddleware(requireRoles(const {'BUYER'}))
          .addHandler(CartRoutes(database).router.call),
    )
    ..mount(
      '/api/orders/',
      Pipeline()
          .addMiddleware(requireAuth(auth))
          .addMiddleware(requireRoles(const {'BUYER'}))
          .addHandler(OrderRoutes(database).router.call),
    )
    ..mount(
      '/api/merchant/',
      Pipeline()
          .addMiddleware(requireAuth(auth))
          .addMiddleware(requireRoles(const {'MERCHANT_ADMIN', 'SUPER_ADMIN'}))
          .addHandler(MerchantRoutes(database).router.call),
    )
    ..mount(
      '/api/admin/',
      Pipeline()
          .addMiddleware(requireAuth(auth))
          .addMiddleware(requireRoles(const {'SUPER_ADMIN'}))
          .addHandler(AdminRoutes(database).router.call),
    )
    ..all(
      '/<ignored|.*>',
      (_) => jsonResponse({'message': 'Not found'}, statusCode: 404),
    );

  return Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addMiddleware(errorMiddleware())
      .addHandler(router.call);
}
