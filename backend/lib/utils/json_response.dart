import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(Object body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

Middleware errorMiddleware() {
  return (innerHandler) {
    return (request) async {
      try {
        return await innerHandler(request);
      } on FormatException catch (error) {
        return jsonResponse({'message': error.message}, statusCode: 400);
      } on StateError catch (error) {
        return jsonResponse({'message': error.message}, statusCode: 409);
      } catch (error) {
        return jsonResponse({
          'message': 'Server error',
          'detail': error.toString(),
        }, statusCode: 500);
      }
    };
  };
}
