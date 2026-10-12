import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class PythonRunner extends StatefulWidget {
  const PythonRunner({super.key, required this.config, required this.onMessage});
  final Map<String, dynamic> config;
  final void Function(Map<String, dynamic>) onMessage;
  @override State<PythonRunner> createState() => _PythonRunnerState();
}
class _PythonRunnerState extends State<PythonRunner> {
  static int serial = 0;
  late final String view = 'academy-python-${serial++}';
  late final web.HTMLIFrameElement frame;
  late final JSFunction listener;
  @override void initState() {
    super.initState();
    frame = web.HTMLIFrameElement()..src = Uri.base.resolve('assets/assets/runner/runner.html?v=0.7.1').toString()..title = 'Python code runner';
    frame.style..border = '0'..width = '100%'..height = '100%';
    listener = ((web.MessageEvent event) {
      if (event.source != frame.contentWindow || event.origin != web.window.location.origin) return;
      try {
        final message = Map<String, dynamic>.from(jsonDecode((event.data as JSString).toDart));
        if (message['type'] == 'ready') { send(); } else { widget.onMessage(message); }
      } catch (_) { /* Ignore messages outside the runner contract. */ }
    }).toJS;
    web.window.addEventListener('message', listener);
    ui.platformViewRegistry.registerViewFactory(view, (_) => frame);
  }
  void send() => frame.contentWindow?.postMessage(jsonEncode({'type':'academy-init','config':widget.config}).toJS, web.window.location.origin.toJS);
  @override void didUpdateWidget(covariant PythonRunner oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.config['dark'] != widget.config['dark'] || oldWidget.config['revision'] != widget.config['revision']) send(); }
  @override void dispose() { web.window.removeEventListener('message', listener); super.dispose(); }
  @override Widget build(BuildContext context) => HtmlElementView(viewType: view);
}
