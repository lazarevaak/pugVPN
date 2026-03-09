import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {'ok': true, 'time': DateTime.now().toUtc().toIso8601String()},
  );
}
