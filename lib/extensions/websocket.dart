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
    // debugPrint("Loaded WebSocket");
    this.onMessage("ws:construct", this._onMsgConstruct);
    this.onMessage("ws:send", this._onMsgSend);
    this.onMessage("ws:close", this._onMsgClose);
    return this;
  }

  void _onMsgConstruct(args) {
    final id = args["id"];
    assert(id is int);
    final url = args["url"].toString();
    Iterable<String> prot = [];
    try {
      prot = args["protocol"];
    } catch (e) {}
    try {
      WebSocket.connect(url, protocols: prot).then((sock) {
        var ws = IOWebSocketChannel(sock);
        ws.stream.listen(_onWsMessage(id),
            onError: _onWsError(id), onDone: _onWsClose(id));
        dartContext[WEBSOCKET_IDS_KEY][id] = ws;
        // debugPrint("Created WebSocket $id to $url with protocols $prot");
        _onWsOpen(id)();
      }).onError((error, stackTrace) => _onWsError(id)(error, stackTrace));
    } catch (e) {
      // debugPrint("Failed to create websocket $id, cause: ${e.toString()}");
      _onWsClose(id)();
    }
  }

  void Function() _onWsOpen(int id) {
    return () async {
      evaluate("""
        WebSocket._dispatchEvent($id, "open");
      """);
    };
  }

  void Function(dynamic) _onWsMessage(int id) {
    return (data) async {
      // Sanitize input
      evaluate("""
        WebSocket._dispatchEvent($id, "message", ${jsonEncode(data)});
      """);
    };
  }

  Function _onWsError(int id) {
    return (Object err, StackTrace stackTrace) async {
      // debugPrint("Got WebSocket error $id, cause: ${err.toString()}");
      evaluate("""
        WebSocket._dispatchEvent($id, "error");
      """);
      _onMsgClose({id: id});
    };
  }

  void Function() _onWsClose(int id) {
    return () async {
      evaluate("""
        WebSocket._dispatchEvent($id, "close");
      """);
    };
  }

  void _onMsgSend(args) {
    var id = args["id"];
    if (id.runtimeType != int || dartContext[WEBSOCKET_IDS_KEY][id] == null)
      return;
    final IOWebSocketChannel ws = dartContext[WEBSOCKET_IDS_KEY][id];
    final data = args["data"];
    ws.sink.add(data);
  }

  void _onMsgClose(args) {
    var id = args["id"];
    if (!(id is int) || !dartContext[WEBSOCKET_IDS_KEY].containsKey(id)) return;
    final IOWebSocketChannel ws = dartContext[WEBSOCKET_IDS_KEY][id];
    final code = args["code"] is int ? args[1] : null;
    final reason = args["reason"] is String ? args[2] : null;
    try {
      ws.sink.close(code, reason);
    } catch (e) {
      debugPrint("Failed to close WebSocket $id, cause: ${e.toString()}");
    } finally {
      dartContext[WEBSOCKET_IDS_KEY].remove(id);
    }
    // debugPrint("Closed WebSocket $id");
  }
}
