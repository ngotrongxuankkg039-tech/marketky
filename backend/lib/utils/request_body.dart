import 'dart:convert';

import 'package:shelf/shelf.dart';

Future<Map<String, dynamic>> readJsonObject(Request request) async {
  final raw = await request.readAsString();
  if (raw.trim().isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('JSON body must be an object');
  }
  return decoded;
}
