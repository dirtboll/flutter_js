import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/javascript_runtime.dart';
import 'package:web_socket_channel/io.dart';

const WEBSOCKET_IDS_KEY = 'webSocketIds';

extension JavascriptRuntimeWebSocketExtension on JavascriptRuntime {
  Map<int, IOWebSocketChannel> getActiveWebSockets() {
    return dartContext[WEBSOCKET_IDS_KEY];
  }

  Future<JavascriptRuntime> enableWebSocket() async {
    dartContext[WEBSOCKET_IDS_KEY] = HashMap<int, IOWebSocketChannel>();
    final wsJs = await rootBundle
        .loadString('packages/flutter_js/assets/js/websocket.js');
    evaluate(wsJs);
    debugPrint("Loaded WebSocket");
    this.onMessage("ws:construct", this._onMsgConstruct);
    this.onMessage("ws:send", this._onMsgSend);
    this.onMessage("ws:close", this._onMsgClose);
    return this;
  }

  void _onMsgConstruct(args) {
    final id = args[0];
    assert(id is int);
    final url = Uri.parse(args[1].toString());
    Iterable<String> prot = [];
    try {
      prot = args[2];
    } catch (e) {}

    WebSocket.connect(args[1], protocols: prot).then((sock) {
      var ws = IOWebSocketChannel(sock);
      _onWsOpen(id)();
      ws.stream.listen(_onWsMessage(id),
          onError: _onWsError(id), onDone: _onWsClose(id));
      dartContext[WEBSOCKET_IDS_KEY][id] = ws;
      debugPrint("Created WebSocket (${id}) to ${url} with protocols ${prot}");
    });
  }

  void Function() _onWsOpen(int id) {
    return () async {
      evaluate("""
        WebSocket._dispatchEvent(${id}, "open");
      """);
    };
  }

  void Function(dynamic) _onWsMessage(int id) {
    return (data) async {
      final msgb64 = base64.encode(utf8.encode(data.toString()));
      evaluate("""
        WebSocket._dispatchEvent(${id}, "message", Base64.decode("${msgb64}"));
      """);
    };
  }

  Function _onWsError(int id) {
    return (Object err, StackTrace stackTrace) async {
      evaluate("""
        WebSocket._dispatchEvent(${id}, "error");
      """);
    };
  }

  void Function() _onWsClose(int id) {
    return () async {
      evaluate("""
        WebSocket._dispatchEvent(${id}, "close");
      """);
    };
  }

  void _onMsgSend(args) {
    final id = args[0];
    assert(id is int);
    final data = args[1];
    final IOWebSocketChannel ws = dartContext[WEBSOCKET_IDS_KEY][id];
    ws.sink.add(data);
  }

  void _onMsgClose(args) {
    final id = args[0];
    assert(id is int);
    final code = args[1] is int ? args[1] : null;
    final reason = args[2] is String ? args[2] : null;
    final IOWebSocketChannel ws = dartContext[WEBSOCKET_IDS_KEY][id];
    ws.sink.close(code, reason);
  }
}
