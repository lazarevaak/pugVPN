import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/system/health_check_use_case.dart';

Future<Response> onRequest(RequestContext context) async {
  final healthCheckUseCase = context.read<HealthCheckUseCase>();
  await healthCheckUseCase.execute();
  return Response.json(
    body: {'ok': true, 'time': DateTime.now().toUtc().toIso8601String()},
  );
}
