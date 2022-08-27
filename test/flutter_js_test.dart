import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('evaluate javascript', () {
    final result = jsRuntime.evaluate('Math.pow(5,3)');
    print('${result.rawResult}, ${result.stringResult}');
    print(
        '${result.rawResult.runtimeType}, ${result.stringResult.runtimeType}');
    expect(result.rawResult, equals(125));
    expect(result.stringResult, equals('125'));
  });

  test('setTimeout', () async {
    var called = false;
    jsRuntime.onMessage("setTimeoutCalled_aaa", (dynamic args) {
      called = true;
    });
    jsRuntime.evaluate("""
      setTimeout(() => {sendMessage('setTimeoutCalled_aaa', JSON.stringify([]))}, 500);
    """);
    await Future.delayed(Duration(milliseconds: 1000));
    expect(called, true);
  });

  test('setTimeout double', () async {
    var called = false;
    jsRuntime.onMessage("setTimeoutCalled_aaa", (dynamic args) {
      called = true;
    });
    jsRuntime.evaluate("""
      setTimeout(() => {sendMessage('setTimeoutCalled_aaa', JSON.stringify([]))}, 500.2);
    """);
    await Future.delayed(Duration(milliseconds: 1000));
    expect(called, true);
  });

  test('setTimeout with args', () async {
    List<dynamic> called = [];
    jsRuntime.onMessage("setTimeoutCalled_aaa", (dynamic args) {
      called = args;
    });
    jsRuntime.evaluate("""
      setTimeout((a,b,c) => {sendMessage('setTimeoutCalled_aaa', JSON.stringify([a,b,c]))}, 500, 1, 2, 3);
    """);
    await Future.delayed(Duration(milliseconds: 1000));
    expect(called, [1, 2, 3]);
  });

  test('setTimeout just callback', () async {
    var called = false;
    jsRuntime.onMessage("setTimeoutCalled_aaa", (dynamic args) {
      called = true;
    });
    jsRuntime.evaluate("""
      setTimeout(() => {sendMessage('setTimeoutCalled_aaa', JSON.stringify([]))});
    """);
    await Future.delayed(Duration(milliseconds: 1000));
    expect(called, true);
  });

  test('clearTimeout', () async {
    var called = false;
    jsRuntime.onMessage("setTimeoutCalled_aaa", (dynamic args) {
      called = true;
    });
    jsRuntime.evaluate("""
      var t = setTimeout(() => {sendMessage('setTimeoutCalled_aaa', JSON.stringify([]))}, 500);
      clearTimeout(t);
    """);
    await Future.delayed(Duration(milliseconds: 1000));
    expect(called, false);
  });
}
