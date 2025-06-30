import 'package:flutter/material.dart';
import '../models/map_configuration.dart';

class StateChip extends StatelessWidget {
  final String stateCode;
  final int count;
  final List<StormType> stormTypes;

  const StateChip({
    super.key,
    required this.stateCode,
    required this.count,
    required this.stormTypes,
  });

  @override
  Widget build(BuildContext context) {
    if (stormTypes.length == 1) {
      // Single storm type - simple colored chip
      return Chip(
        label: Text(
          '$stateCode: $count',
          style: TextStyle(
            color: _getTextColor(stormColors[stormTypes.first]!),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: stormColors[stormTypes.first],
      );
    } else {
      // Multi-storm state - custom painted chip with hard split
      return Container(
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _SplitColorPainter(
              leftColor: stormColors[stormTypes[0]]!,
              rightColor: stormColors[stormTypes[1]]!,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '$stateCode: $count',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate luminance to determine if text should be black or white
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class _SplitColorPainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;

  _SplitColorPainter({
    required this.leftColor,
    required this.rightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw left half
    paint.color = leftColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      paint,
    );
    
    // Draw right half
    paint.color = rightColor;
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SplitColorPainter oldDelegate) {
    return oldDelegate.leftColor != leftColor || oldDelegate.rightColor != rightColor;
  }
}