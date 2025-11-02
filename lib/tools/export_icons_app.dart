import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const IconExporterApp());
}

class IconExporterApp extends StatefulWidget {
  const IconExporterApp({super.key});

  @override
  State<IconExporterApp> createState() => _IconExporterAppState();
}

class _IconExporterAppState extends State<IconExporterApp> {
  String status = 'Ready to export icons...';
  bool isExporting = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Icon Exporter')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(status, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              if (!isExporting)
                ElevatedButton(
                  onPressed: _exportIcons,
                  child: const Text('Export Icons'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportIcons() async {
    setState(() {
      isExporting = true;
      status = 'Starting export...';
    });

    try {
      final dir = Directory('exported_icons');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Storm icons
      await _exportStormIcons();

      // Property icons
      await _exportPropertyIcons();

      setState(() {
        status = 'Export complete! Check the exported_icons folder.';
      });
    } catch (e) {
      setState(() {
        status = 'Error: $e';
      });
    }
  }

  Future<void> _exportStormIcons() async {
    final storms = {
      'snow': (Icons.ac_unit, Colors.lightBlue),
      'earthquake': (Icons.landscape, Colors.brown),
      'hurricane_other': (Icons.cyclone, const Color(0xFFE6E6FA)),
      'hurricane_florida': (Icons.cyclone, Colors.purple),
      'flood': (Icons.water, Colors.blue),
      'fire': (Icons.local_fire_department, Colors.red),
      'hail': (Icons.grain, Colors.yellow),
      'tornado': (Icons.air, Colors.grey),
    };

    for (final entry in storms.entries) {
      setState(() => status = 'Exporting storm_${entry.key}.png...');
      await _captureIcon(entry.value.$1, entry.value.$2, 'storm_${entry.key}.png');
    }
  }

  Future<void> _exportPropertyIcons() async {
    final properties = {
      'mobile_home': Icons.rv_hookup,
      'house': Icons.home,
      'mansion': Icons.villa,
    };

    for (final entry in properties.entries) {
      setState(() => status = 'Exporting property_${entry.key}.png...');
      await _captureIcon(entry.value, Colors.blue.shade700, 'property_${entry.key}.png');
    }
  }

  Future<void> _captureIcon(IconData icon, Color color, String fileName) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 1024.0;

    // Transparent background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()..color = Colors.transparent,
    );

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.75,
          fontFamily: icon.fontFamily,
          color: color,
        ),
      )
      ..layout();

    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    await File('exported_icons/$fileName').writeAsBytes(buffer);
  }
}
