import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ClientBpmnViewerScreen extends StatefulWidget {
  const ClientBpmnViewerScreen({super.key, required this.xmlBpmn, this.title = 'Diagrama'});

  final String xmlBpmn;
  final String title;

  @override
  State<ClientBpmnViewerScreen> createState() => _ClientBpmnViewerScreenState();
}

class _ClientBpmnViewerScreenState extends State<ClientBpmnViewerScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF07111F))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _loading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_buildHtml(widget.xmlBpmn));
  }

  String _buildHtml(String xmlBpmn) {
    final encodedXml = jsonEncode(xmlBpmn);
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body {
      width: 100%;
      height: 100%;
      margin: 0;
      background: #07111F;
      overflow: hidden;
      font-family: Arial, sans-serif;
    }
    #canvas {
      width: 100vw;
      height: 100vh;
      background: linear-gradient(180deg, rgba(12,18,36,0.96), rgba(7,17,31,0.98));
    }
    .hint {
      position: fixed;
      left: 16px;
      top: 16px;
      z-index: 3;
      color: #dbeafe;
      background: rgba(15, 23, 42, 0.8);
      border: 1px solid rgba(255,255,255,0.08);
      border-radius: 999px;
      padding: 8px 12px;
      font-size: 12px;
      letter-spacing: 1px;
      text-transform: uppercase;
    }
  </style>
  <link rel="stylesheet" href="https://unpkg.com/bpmn-js@18.3.1/dist/assets/diagram-js.css">
  <link rel="stylesheet" href="https://unpkg.com/bpmn-js@18.3.1/dist/assets/bpmn-font/css/bpmn-embedded.css">
  <script src="https://unpkg.com/bpmn-js@18.3.1/dist/bpmn-viewer.development.js"></script>
</head>
<body>
  <div class="hint">Diagrama BPMN</div>
  <div id="canvas"></div>
  <script>
    const xml = $encodedXml;
    const viewer = new BpmnJS({ container: '#canvas' });

    viewer.importXML(xml)
      .then(() => {
        const canvas = viewer.get('canvas');
        canvas.zoom('fit-viewport', 'auto');
      })
      .catch((error) => {
        document.body.innerHTML = '<pre style="color:#fff;padding:16px;white-space:pre-wrap;">No se pudo cargar el diagrama\\n' + error + '</pre>';
      });
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
