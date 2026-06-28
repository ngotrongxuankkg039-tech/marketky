import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  const port = '18080';
  const host = 'http://localhost:$port';
  late Process process;

  setUp(() async {
    process = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'PORT': port},
    );
    await process.stdout.first;
  });

  tearDown(() {
    process.kill();
  });

  test('health endpoint returns ok', () async {
    final response = await get(Uri.parse('$host/health'));
    expect(response.statusCode, 200);
    expect(jsonDecode(response.body), {'status': 'ok'});
  });

  test('unknown endpoint returns 404 json', () async {
    final response = await get(Uri.parse('$host/unknown'));
    expect(response.statusCode, 404);
  });
}
