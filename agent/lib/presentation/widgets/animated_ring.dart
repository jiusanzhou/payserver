import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 带流动动画的圆环组件
class AnimatedRing extends StatefulWidget {
  final bool isRunning;
  final double size;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;
  final Widget? child;

  const AnimatedRing({
    super.key,
    required this.isRunning,
    this.size = 240,
    this.strokeWidth = 8,
    this.activeColor = const Color(0xFF4CAF50),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.child,
  });

  @override
  State<AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isRunning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RingBackgroundPainter(
              strokeWidth: widget.strokeWidth,
              color: widget.inactiveColor.withOpacity(0.3),
            ),
          ),
          // 动画圆环
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _FlowingRingPainter(
                  progress: _controller.value,
                  isRunning: widget.isRunning,
                  strokeWidth: widget.strokeWidth,
                  activeColor: widget.activeColor,
                  inactiveColor: widget.inactiveColor,
                ),
              );
            },
          ),
          // 中心内容
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _RingBackgroundPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;

  _RingBackgroundPainter({
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RingBackgroundPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class _FlowingRingPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;

  _FlowingRingPainter({
    required this.progress,
    required this.isRunning,
    required this.strokeWidth,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (isRunning) {
      // 流动效果：渐变圆弧旋转
      final startAngle = progress * 2 * math.pi - math.pi / 2;
      
      // 绘制多段渐变弧
      for (int i = 0; i < 3; i++) {
        final segmentStart = startAngle + i * (2 * math.pi / 3);
        final sweepAngle = math.pi / 2;
        
        final gradient = SweepGradient(
          startAngle: segmentStart,
          endAngle: segmentStart + sweepAngle,
          colors: [
            activeColor.withOpacity(0.0),
            activeColor.withOpacity(0.8),
            activeColor,
            activeColor.withOpacity(0.8),
            activeColor.withOpacity(0.0),
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        );

        final paint = Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(rect, segmentStart, sweepAngle, false, paint);
      }
      
      // 发光效果
      final glowPaint = Paint()
        ..color = activeColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(center, radius, glowPaint);
    } else {
      // 停止状态：静态圆环
      final paint = Paint()
        ..color = inactiveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowingRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.activeColor != activeColor;
  }
}
