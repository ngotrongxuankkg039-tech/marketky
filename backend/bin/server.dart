import 'dart:io';

import 'package:marketky_shop_backend/server.dart';
import 'package:shelf/shelf_io.dart';

Future<void> main(List<String> args) async {
  final handler = buildHandler();
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('MarketKy Shop API listening on http://localhost:${server.port}');
}
