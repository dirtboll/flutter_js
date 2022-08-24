import 'package:flutter/services.dart';

import '../javascript_runtime.dart';

extension JavascriptRuntimeWebSocketExtension on JavascriptRuntime {
  enableBase64() async {
    final base64js =
        await rootBundle.loadString('packages/flutter_js/assets/js/base64.js');
    evaluate(base64js);
  }
}
