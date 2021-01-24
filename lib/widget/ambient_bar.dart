import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'dart:math' as math;

class AmbientBarValue extends Equatable {
  const AmbientBarValue({
    @required this.progress,
    @required this.progressColor,
    @required this.backgroundColor,
    @required this.gapSize,
    @required this.stepCount,
    @required this.reverse,
    this.radius,
  });
  final double progress;
  final double gapSize;
  final int stepCount;
  final Color backgroundColor;
  final Color progressColor;
  final bool reverse;
  final double radius;

  @override
  List<Object> get props =>
      [progress, gapSize, stepCount, backgroundColor, progressColor];
}

class AmbientBar extends StatelessWidget {
  const AmbientBar({
    Key key,
    @required this.value,
  }) : super(key: key);
  final AmbientBarValue value;

  @override
  Widget build(BuildContext context) {
    Widget child = CustomPaint(painter: AmbientBarPainer(value));

    if (value.reverse) {
      child = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: child,
      );
    }

    if (value.radius != null) {
      child = ClipRRect(
        child: child,
        borderRadius: BorderRadius.circular(value.radius),
      );
    }

    return child;
  }
}

class AmbientBarPainer extends CustomPainter {
  AmbientBarPainer(this.value);
  final AmbientBarValue value;
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = value.backgroundColor;
    final progressPaint = Paint()..color = value.progressColor;
    final sectionWidth =
        (size.width - value.gapSize * (value.stepCount - 1)) / value.stepCount;

    for (var i = 0; i < value.stepCount; i++) {
      final xStart = (sectionWidth + value.gapSize) * i;
      final xEnd = xStart + sectionWidth;
      final xStartProgress = xStart / size.width;
      final xEndProgress = xEnd / size.width;

      void drawRect(Paint paint) {
        canvas.drawRect(
          Rect.fromLTRB(xStart, 0, xEnd, size.height),
          paint,
        );
      }

      drawRect(
        bgPaint,
      );

      if (value.progress >= xEndProgress) {
        drawRect(
          progressPaint,
        );
      } else if (value.progress > xStartProgress) {
        final relativeProgress =
            (value.progress - xStartProgress) / (xEndProgress - xStartProgress);
        progressPaint.color = progressPaint.color.withOpacity(relativeProgress);
        drawRect(
          progressPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(AmbientBarPainer oldDelegate) {
    return oldDelegate.value != value;
  }
}
