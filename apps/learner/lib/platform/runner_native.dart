import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PythonRunner extends StatefulWidget {
  const PythonRunner({super.key, required this.config, required this.onMessage});
  final Map<String, dynamic> config;
  final void Function(Map<String, dynamic>) onMessage;
  @override State<PythonRunner> createState() => _PythonRunnerState();
}
class _PythonRunnerState extends State<PythonRunner> {
  WebViewController? controller;
  @override void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) return;
    controller = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('AcademyBridge', onMessageReceived: (message) {
        try {
          final data = Map<String, dynamic>.from(jsonDecode(message.message));
          if (data['type'] == 'ready') { send(); } else { widget.onMessage(data); }
        } catch (_) { /* Ignore messages outside the runner contract. */ }
      })
      ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: (request) => request.url.startsWith('file:') || request.url == 'about:blank' ? NavigationDecision.navigate : NavigationDecision.prevent))
      ..loadFlutterAsset('assets/runner/runner.html');
  }
  void send() => controller?.runJavaScript('window.academyInit(${jsonEncode(widget.config)})');
  @override void didUpdateWidget(covariant PythonRunner oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.config['dark'] != widget.config['dark'] || oldWidget.config['revision'] != widget.config['revision'] || oldWidget.config['fileSavedAt'] != widget.config['fileSavedAt']) send(); }
  @override Widget build(BuildContext context) => controller == null ? const Center(child: Text('The Python runner is available on web and Android.')) : WebViewWidget(controller: controller!);
}
