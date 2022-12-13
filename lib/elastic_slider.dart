import 'dart:ui';

import 'package:bezier/bezier.dart';
import 'package:flutter/material.dart';
import "package:vector_math/vector_math.dart" as math;

class ElasticSlider extends StatefulWidget {
  const ElasticSlider({super.key});

  @override
  State<ElasticSlider> createState() => _ElasticSliderState();
}

class _ElasticSliderState extends State<ElasticSlider>
    with SingleTickerProviderStateMixin {
  ValueNotifier<Offset> dragPosition = ValueNotifier(Offset(50, 0));
  double estabilishedHeight = 0;
  late AnimationController animationController;
  late Animation<double> animation;
  final double ballSize = 25;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    animation =
        Tween<double>(begin: 1.0, end: 0.0).animate(animationController);

    animation.addListener(() {
      if (animationController.status == AnimationStatus.forward) {
        dragPosition.value = Offset(dragPosition.value.dx,
            estabilishedHeight * Curves.elasticIn.transform(animation.value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return AnimatedBuilder(
          animation: dragPosition,
          builder: (context, _) {
            return CustomPaint(
              painter: SliderPainter(
                  [dragPosition.value.translate(ballSize / 2, 0)]),
              child: Stack(
                fit: StackFit.loose,
                children: [
                  Positioned(
                      left: dragPosition.value.dx,
                      top: 30 + dragPosition.value.dy,
                      child: buildBall()),
                ],
              ),
            );
          });
    });
  }

  Widget buildBall() {
    return GestureDetector(
      onPanUpdate: (details) {
        animationController.value = animationController.lowerBound;
        dragPosition.value =
            dragPosition.value.translate(details.delta.dx, details.delta.dy);
        estabilishedHeight = dragPosition.value.dy;
      },
      onPanEnd: (details) {
        animationController.forward().then((value) {
          animationController.value = animationController.lowerBound;
          estabilishedHeight = 0.0;
        });
        // dragPosition.value = Offset(dragPosition.value.dx, 0);
      },
      child: Container(
        width: ballSize,
        height: ballSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
      ),
    );
  }
}

class SliderPainter extends CustomPainter {
  final List<Offset> hitPoints;

  SliderPainter(this.hitPoints);
  final lineDeformationWidth = 0.2;
  final lineHeight = 43.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    final points = <Offset>[];
    points.add(Offset(0, lineHeight));
    final curvePoints = computeLineDeformationBasedOnPoint(
      segmentStartPoint: Offset(0, lineHeight),
      nodePoint: Offset(hitPoints.first.dx, lineHeight + hitPoints.first.dy),
      segmentEndPoint: Offset(size.width, lineHeight + 0),
      canvas: canvas,
    );
    points.addAll(curvePoints);
    points.add(Offset(size.width, lineHeight + 0));
    canvas.drawPoints(PointMode.polygon, points, paint);

    // for (final point in points) {
    //   canvas.drawCircle(point, 5, paint);
    // }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  List<Offset> computeLineDeformationBasedOnPoint({
    required Offset segmentStartPoint,
    required Offset nodePoint,
    required Offset segmentEndPoint,
    required Canvas canvas,
  }) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;
    // final points = <Offset>[];
    final firstAnchor = Offset(nodePoint.translate(-150, 0).dx, lineHeight);

    final firstControlPoint =
        Offset(nodePoint.translate(-90, 0).dx, lineHeight + ((lineHeight - nodePoint.dy)*0.3));
    final secondAnchor = Offset(nodePoint.translate(-40, 0).dx,
        lineHeight + ((nodePoint.dy - lineHeight) * 0.75));

    final firstCurve = computeBezierCurve(
      startPoint: firstAnchor,
      controlPoint: firstControlPoint,
      endPoint: secondAnchor,
    );

    final secondControlPoint = Offset(nodePoint.translate(-20, 0).dx, lineHeight + ((nodePoint.dy - lineHeight) * 1.1));

    final secondCurve = computeBezierCurve(
      startPoint: secondAnchor,
      controlPoint: secondControlPoint,
      endPoint: nodePoint,
    );
    // canvas.drawCircle(firstAnchor, 5, paint);
    // canvas.drawCircle(firstControlPoint, 5, paint);
    // canvas.drawCircle(secondAnchor, 5, paint);
    // canvas.drawCircle(secondControlPoint, 5, paint);

    return [...firstCurve, ...secondCurve];
  }

  List<Offset> computeBezierCurve({
    required Offset startPoint,
    required Offset controlPoint,
    required Offset endPoint,
  }) {
    final quadraticCurve = QuadraticBezier([
      math.Vector2(startPoint.dx, startPoint.dy),
      math.Vector2(controlPoint.dx, controlPoint.dy),
      math.Vector2(endPoint.dx, endPoint.dy)
    ]);

    double time = 0.0;
    final points = <Offset>[];
    while (time <= 1.0) {
      final math.Vector2 point = quadraticCurve.pointAt(time);
      final splitted =
          point.toString().replaceAll('[', '').replaceAll(']', '').split(',');
      points.add(
          Offset(double.parse(splitted.first), double.parse(splitted.last)));
      time += 0.1;
    }
    return points;
  }
}

// final quadraticCurve = QuadraticBezier([
//         math.Vector2(-40.0, -40.0),
//         math.Vector2(30.0, 10.0),
//         math.Vector2(55.0, 25.0)
//       ]);

//       double time = 0.0;
//       final points = <Offset>[];
//       while (time <= 1.0) {
//         final math.Vector2 point = quadraticCurve.pointAt(time);
//         final splitted = point
//             .toString()
//             .replaceAll('[', '')
//             .replaceAll(']', '')
//             .split(',');
//         points.add(Offset(
//             double.parse(splitted.first), double.parse(splitted.last)));
//         time += 0.1;
//       }

// final paint = Paint()
//   ..color = Colors.black
//   ..strokeWidth = 2;
// final points = <Offset>[];
// points.add(Offset(0, lineHeight));
// final hitPoint =
//     Offset(hitPoints.first.dx, lineHeight + hitPoints.first.dy);
// final firstCurveP2 = hitPoint.translate(
//     (hitPoint.dx * lineDeformationWidth) * -1,
//     lineHeight + ((hitPoint.dy * 0.9) * -1));
// final firstCurveP1 = Offset(firstCurveP2.dx * 0.9, lineHeight + 0);
// points.add(firstCurveP1);
// points.add(firstCurveP2);

// points.add(hitPoint);
// final thirdCurveP1 = hitPoint.translate(
//     (hitPoint.dx * lineDeformationWidth),
//     lineHeight + ((hitPoint.dy * 0.9) * -1));
// points.add(thirdCurveP1);
// final thirdCurveP2 = Offset(thirdCurveP1.dx * 1.1, lineHeight + 0);
// points.add(thirdCurveP2);
// // points.add(endCurve);
// points.add(Offset(size.width, lineHeight + 0));
// canvas.drawPoints(PointMode.polygon, points, paint);
