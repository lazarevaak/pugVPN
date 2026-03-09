import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/src/app_store.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(provider<AppStore>((_) => AppStore.instance));
}
