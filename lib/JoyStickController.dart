import 'package:flutter/material.dart';
import 'dart:math' as math;

class JoystickController extends StatefulWidget {
  final double size;
  final Color baseColor;
  final Color knobColor;
  final Function(double x, double y)? onChanged;
  final double sensitivity;

  const JoystickController({
    Key? key,
    this.size = 200.0,
    this.baseColor = Colors.grey,
    this.knobColor = Colors.blue,
    this.onChanged,
    this.sensitivity = 1.0,
  }) : super(key: key);

  @override
  State<JoystickController> createState() => _JoystickControllerState();
}

class _JoystickControllerState extends State<JoystickController> {
  Offset _knobPosition = Offset.zero;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: JoystickPainter(
            knobPosition: _knobPosition,
            baseColor: widget.baseColor,
            knobColor: widget.knobColor,
            isDragging: _isDragging,
          ),
          size: Size(widget.size, widget.size),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _updateKnobPosition(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updateKnobPosition(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _knobPosition = Offset.zero;
      _isDragging = false;
    });
    widget.onChanged?.call(0, 0);
  }

  void _updateKnobPosition(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final offset = localPosition - center;
    final distance = offset.distance;
    final maxDistance = widget.size / 2 - 30; // 30 is knob radius + padding

    if (distance <= maxDistance) {
      setState(() {
        _knobPosition = offset;
      });
    } else {
      // Clamp to circle boundary
      final angle = math.atan2(offset.dy, offset.dx);
      setState(() {
        _knobPosition = Offset(
          math.cos(angle) * maxDistance,
          math.sin(angle) * maxDistance,
        );
      });
    }

    // Normalize values to -1.0 to 1.0 range
    final normalizedX = (_knobPosition.dx / maxDistance) * widget.sensitivity;
    final normalizedY = (_knobPosition.dy / maxDistance) * widget.sensitivity;

    widget.onChanged?.call(normalizedX, normalizedY);
  }
}

class JoystickPainter extends CustomPainter {
  final Offset knobPosition;
  final Color baseColor;
  final Color knobColor;
  final bool isDragging;

  JoystickPainter({
    required this.knobPosition,
    required this.baseColor,
    required this.knobColor,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;
    final knobRadius = 25.0;

    // Draw base circle
    final basePaint = Paint()
      ..color = baseColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, baseRadius, basePaint);

    // Draw base border
    final baseBorderPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, baseRadius, baseBorderPaint);

    // Draw center cross for reference
    final crossPaint = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      crossPaint,
    );

    // Draw knob
    final knobCenter = center + knobPosition;
    final knobPaint = Paint()
      ..color = knobColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(knobCenter, knobRadius, knobPaint);

    // Draw knob border
    final knobBorderPaint = Paint()
      ..color = knobColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(knobCenter, knobRadius, knobBorderPaint);

    // Add shadow effect when dragging
    if (isDragging) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawCircle(knobCenter + const Offset(2, 2), knobRadius, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}