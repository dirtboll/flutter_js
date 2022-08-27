import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_js/extensions/websocket.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_js');

  TestWidgetsFlutterBinding.ensureInitialized();

  late JavascriptRuntime jsRuntime;

  setUp(() async {
    jsRuntime = await getJavascriptRuntime();
  });

  tearDown(() {
    try {
      jsRuntime.dispose();
    } on Error catch (_) {}
  });

  test("WebSocket defined", () {
    print(jsRuntime.evaluate('WebSocket'));
  });

  test('construct WebSocket', () async {
    print(jsRuntime.evaluate('''
      var ws = new WebSocket("ws://localhost:8080");
      ws.addEventListener("message", (data) => {console.log(data)});
      ws.send("test2");
      ws.send("test3");
      ws.send("test4");
    '''));
    await Future.delayed(Duration(seconds: 2));
    print(jsRuntime.getActiveWebSockets());
  });
}
