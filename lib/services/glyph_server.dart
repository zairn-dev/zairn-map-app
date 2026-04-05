import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class GlyphServer {
  HttpServer? _server;
  int? _port;
  late String _glyphDir;

  String get glyphsUrl => 'http://127.0.0.1:$_port/{fontstack}/{range}.pbf';

  Future<void> start() async {
    // Copy glyph PBFs from assets to filesystem for fast sync access
    await _extractGlyphs();

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;

    _server!.listen((request) {
      final path = Uri.decodeFull(request.uri.path);
      final file = File('$_glyphDir$path');

      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        request.response.headers
          ..contentType = ContentType.binary
          ..set('Access-Control-Allow-Origin', '*')
          ..set('Content-Length', '${bytes.length}');
        request.response.add(bytes);
      } else {
        request.response.statusCode = 404;
      }
      request.response.close();
    });
  }

  Future<void> _extractGlyphs() async {
    final appDir = await getApplicationSupportDirectory();
    _glyphDir = '${appDir.path}/glyphs';

    // Check if already extracted
    final marker = File('$_glyphDir/.extracted');
    if (marker.existsSync()) return;

    const fontNames = ['Zen Maru Gothic Regular', 'Zen Maru Gothic Bold'];

    // Ranges matching what was kept by trim_glyphs.sh
    final ranges = <int>[];
    // Latin (0-1279)
    for (int i = 0; i <= 1024; i += 256) {
      ranges.add(i);
    }
    // Symbols (8192-10239)
    for (int i = 8192; i <= 9984; i += 256) {
      ranges.add(i);
    }
    // CJK Symbols, Hiragana, Katakana (12288-13311)
    for (int i = 12288; i <= 13056; i += 256) {
      ranges.add(i);
    }
    // CJK Ideographs (19968-40959)
    for (int i = 19968; i <= 40704; i += 256) {
      ranges.add(i);
    }
    // CJK Compat + Halfwidth/Fullwidth
    ranges.addAll([63744, 64000, 65024, 65280]);

    for (final fontName in fontNames) {
      final fontDir = Directory('$_glyphDir/$fontName');
      fontDir.createSync(recursive: true);

      for (final start in ranges) {
        final end = start + 255;
        final assetPath = 'assets/glyphs/$fontName/$start-$end.pbf';
        try {
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();
          if (bytes.isNotEmpty) {
            File('${fontDir.path}/$start-$end.pbf').writeAsBytesSync(bytes);
          }
        } catch (_) {
          // Asset not found
        }
      }
    }

    marker.writeAsStringSync('ok');
  }

  Future<void> stop() async {
    await _server?.close();
  }
}
