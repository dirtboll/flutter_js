import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/javascript_runtime.dart';
import 'package:web_socket_channel/io.dart';

const WEBSOCKET_IDS_KEY = 'webSocketIds';

extension JavascriptRuntimeWebSocketExtension on JavascriptRuntime {
  Future<JavascriptRuntime> enableWebSocket() async {
    dartContext[WEBSOCKET_IDS_KEY] = HashMap<int, IOWebSocketChannel>();
    final wsJs = await rootBundle
        .loadString('packages/flutter_js/assets/js/websocket.js');
    evaluate(wsJs);
    debugPrint("Loaded WebSocket");
    this.onMessage("ws:construct", (args) {
      final id = args[0];
      assert(id is int);
      final url = Uri.parse(args[1].toString());
      Iterable<String> prot = [];
      try {
        prot = args[2];
      } catch (e) {}
      final ws = IOWebSocketChannel.connect(url, protocols: prot);
      ws.stream.listen((data) {
        this.evaluate("""
          WebSocket._dispatchEvent(${id}, "message", "${data.toString()}");
        """);
      });
      dartContext[WEBSOCKET_IDS_KEY][id] = ws;

      debugPrint("Created WebSocket (${id}) to ${url} with protocols ${prot}");
    });
    this.onMessage("ws:send", (args) {
      final id = args[0];
      assert(id is int);
      final data = args[1];
      final IOWebSocketChannel ws = dartContext[WEBSOCKET_IDS_KEY][id];
      ws.sink.add(data);
    });
    this.onMessage("ws:close", (args) {
      final id = args[0];
      assert(id is int);
      final code = args[1] is int ? args[1] : null;
      final reason = args[2] is String ? args[2] : null;
      final IOWebSocketChannel ws = dartContext[WEBSOCKET_IDS_KEY][id];
      ws.sink.close(code, reason);
    });

    return this;
  }

  Map<int, IOWebSocketChannel> getActiveWebSockets() {
    return dartContext[WEBSOCKET_IDS_KEY];
  }
}
