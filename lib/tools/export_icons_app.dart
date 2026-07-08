import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

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

      await _exportStormIcons();
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
    // Material icon storms
    final iconStorms = {
      'snow': (Icons.ac_unit, const Color(0xFF02A9F4)),
      'flood': (Icons.water, const Color(0xFF1A4784)),
      'hail': (Icons.grain, const Color(0xFFFFEB3B)),
      'hurricane_other': (Icons.cyclone, Colors.purple.shade300),
      'fire': (Icons.local_fire_department, Colors.red),
      'hurricane_florida': (Icons.cyclone, Colors.purple),
      'fire_california': (Icons.local_fire_department, const Color(0xFFB71C1C)),
    };

    for (final entry in iconStorms.entries) {
      setState(() => status = 'Exporting storm_${entry.key}.png...');
      await _captureIcon(entry.value.$1, entry.value.$2, 'storm_${entry.key}.png');
    }

    // Tornado SVG path storms — draw the twister shape directly
    final tornadoStorms = {
      'tornado': Colors.grey,
      'tornado_texas': const Color(0xFF424242),
    };

    for (final entry in tornadoStorms.entries) {
      setState(() => status = 'Exporting storm_${entry.key}.png...');
      await _captureTornadoIcon(entry.value, 'storm_${entry.key}.png');
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
      await _captureIcon(entry.value, Colors.teal.shade700, 'property_${entry.key}.png');
    }
  }

  Future<void> _captureIcon(IconData icon, Color color, String fileName) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 1024.0;

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()..color = Colors.transparent,
    );

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

  Future<void> _captureTornadoIcon(Color color, String fileName) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 1024.0;

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()..color = Colors.transparent,
    );

    // Scale from 24x24 SVG viewbox to 1024 canvas (with 75% fill)
    final scale = size * 0.75 / 24.0;
    final offset = size * 0.125;

    canvas.save();
    canvas.translate(offset, offset);
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Tornado SVG paths (from tornado.svg, 24x24 viewbox)
    // Each horizontal bar of the twister shape
    final paths = [
      // Top bar: x=3..20, y=2..4
      Path()..addRRect(RRect.fromLTRBR(3, 2, 20, 4, const Radius.circular(1))),
      // Second bar: x=7..21, y=5..7
      Path()..addRRect(RRect.fromLTRBR(7, 5, 21, 7, const Radius.circular(1))),
      // Third bar: x=9..20, y=8..10
      Path()..addRRect(RRect.fromLTRBR(9, 8, 20, 10, const Radius.circular(1))),
      // Fourth bar: x=6..16, y=11..13
      Path()..addRRect(RRect.fromLTRBR(6, 11, 16, 13, const Radius.circular(1))),
      // Fifth bar: x=6..14, y=14..16
      Path()..addRRect(RRect.fromLTRBR(6, 14, 14, 16, const Radius.circular(1))),
      // Sixth bar: x=9..16, y=17..19
      Path()..addRRect(RRect.fromLTRBR(9, 17, 16, 19, const Radius.circular(1))),
      // Bottom bar: x=13..17, y=20..22
      Path()..addRRect(RRect.fromLTRBR(13, 20, 17, 22, const Radius.circular(1))),
    ];

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    await File('exported_icons/$fileName').writeAsBytes(buffer);
  }
}
