import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Export all icons as PNG files', (WidgetTester tester) async {
    final exporter = IconExporter();
    await exporter.exportAllIcons();

    print('\n✓ All icons exported successfully!');
  });
}

class IconExporter {
  final int iconSize = 2048; // Very high resolution
  final String outputDir = 'exported_icons';

  Future<void> exportAllIcons() async {
    // Create output directory
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    print('\nExporting icons to: ${dir.absolute.path}\n');

    // Export storm type icons
    await _exportStormIcons();

    // Export property type icons
    await _exportPropertyIcons();
  }

  Future<void> _exportStormIcons() async {
    print('Storm Type Icons:');
    print('─' * 50);

    final stormIcons = {
      'snow': Icons.ac_unit,
      'earthquake': Icons.landscape,
      'hurricane_other': Icons.cyclone,
      'hurricane_florida': Icons.cyclone,
      'flood': Icons.water,
      'fire': Icons.local_fire_department,
      'hail': Icons.grain,
      'tornado': Icons.air,
    };

    final stormColors = {
      'snow': Colors.lightBlue,
      'earthquake': Colors.brown,
      'hurricane_other': const Color(0xFFE6E6FA), // Lavender
      'hurricane_florida': Colors.purple,
      'flood': Colors.blue,
      'fire': Colors.red,
      'hail': Colors.yellow,
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
      print('  ✓ storm_$name.png');
    }
  }

  Future<void> _exportPropertyIcons() async {
    print('\nProperty Type Icons:');
    print('─' * 50);

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
      print('  ✓ property_$name.png');
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
    final size = iconSize.toDouble();

    // Draw transparent background
    final bgPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size, size),
      bgPaint,
    );

    // Create text painter for the icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.75, // 75% of canvas size for padding
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
        fontFamilyFallback: const ['MaterialIcons'],
      ),
    );

    textPainter.layout();

    // Center the icon on the canvas
    final offsetX = (size - textPainter.width) / 2;
    final offsetY = (size - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(offsetX, offsetY));

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(iconSize, iconSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to encode image for $fileName');
    }

    final buffer = byteData.buffer.asUint8List();

    // Save to file
    final file = File('$outputDir/$fileName');
    await file.writeAsBytes(buffer);
  }
}
