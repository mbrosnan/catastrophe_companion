import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final iconExporter = IconExporter();
  await iconExporter.exportAllIcons();

  print('All icons exported successfully!');
  exit(0);
}

class IconExporter {
  final int iconSize = 1024; // Highest resolution
  final String outputDir = 'exported_icons';

  Future<void> exportAllIcons() async {
    // Create output directory
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    print('Exporting icons to: ${dir.absolute.path}');

    // Export storm type icons
    await _exportStormIcons();

    // Export property type icons
    await _exportPropertyIcons();
  }

  Future<void> _exportStormIcons() async {
    print('\nExporting storm type icons...');

    final stormIcons = {
      'snow': Icons.ac_unit,
      'earthquake': Icons.landscape,
      'hurricane': Icons.cyclone,
      'flood': Icons.water,
      'fire': Icons.local_fire_department,
      'hail': Icons.grain,
      'tornado': Icons.air,
    };

    final stormColors = {
      'snow': Colors.lightBlue,
      'earthquake': Colors.brown,
      'hurricane': Colors.purple,
      'flood': Colors.blue,
      'fire': Colors.red,
      'hail': Colors.orange.shade800,
      'tornado': Colors.grey,
    };

    for (final entry in stormIcons.entries) {
      final name = entry.key;
      final icon = entry.value;
      final color = stormColors[name] ?? Colors.black;

      await _exportIcon(
        icon: icon,
        color: color,
        fileName: 'storm_$name.png',
      );
      print('  ✓ Exported storm_$name.png');
    }
  }

  Future<void> _exportPropertyIcons() async {
    print('\nExporting property type icons...');

    final propertyIcons = {
      'mobile_home': Icons.rv_hookup,
      'house': Icons.home,
      'mansion': Icons.villa,
    };

    for (final entry in propertyIcons.entries) {
      final name = entry.key;
      final icon = entry.value;

      await _exportIcon(
        icon: icon,
        color: Colors.blue.shade700,
        fileName: 'property_$name.png',
      );
      print('  ✓ Exported property_$name.png');
    }
  }

  Future<void> _exportIcon({
    required IconData icon,
    required Color color,
    required String fileName,
  }) async {
    // Create a picture recorder to capture the drawing
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw transparent background
    final paint = Paint()..color = Colors.transparent;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, iconSize.toDouble(), iconSize.toDouble()),
      paint,
    );

    // Create text painter for the icon
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: iconSize * 0.8, // 80% of canvas size for padding
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );

    textPainter.layout();

    // Center the icon on the canvas
    final offsetX = (iconSize - textPainter.width) / 2;
    final offsetY = (iconSize - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(offsetX, offsetY));

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(iconSize, iconSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Save to file
    final file = File('$outputDir/$fileName');
    await file.writeAsBytes(buffer);
  }
}
