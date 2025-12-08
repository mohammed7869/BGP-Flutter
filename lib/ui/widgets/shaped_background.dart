import 'package:flutter/material.dart';

class ShapedBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color shapeColor;

  const ShapedBackground({
    Key? key,
    required this.child,
    this.backgroundColor = const Color(0xFFF7EFE8),
    this.shapeColor = const Color(0xFFFFFFFF),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ShapedBackgroundPainter(shapeColor: shapeColor),
          ),
          child,
        ],
      ),
    );
  }
}

class ShapedBackgroundPainter extends CustomPainter {
  final Color shapeColor;

  ShapedBackgroundPainter({required this.shapeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = shapeColor
      ..style = PaintingStyle.fill;

    // Top curved shape
    // final topPath = Path();
    // topPath.moveTo(0, 0);
    // topPath.lineTo(0, size.height * 0.25);
    // topPath.quadraticBezierTo(
    //   size.width * 0.5,
    //   size.height * 0.50,
    //   size.width,
    //   size.height * 0.25,
    // );
    // topPath.lineTo(size.width, 0);
    // topPath.close();
    // canvas.drawPath(topPath, paint);

    // Bottom curved shape
    final bottomPath = Path();
    bottomPath.moveTo(0, size.height);
    bottomPath.lineTo(0, size.height * 0.8); // moved up slightly

// left slope up
    bottomPath.lineTo(size.width * 0.4, size.height * 0.65);

// small smooth peak (not too sharp)
    bottomPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.6, // moved up slightly
      size.width * 0.6,
      size.height * 0.65,
    );

// right slope down
    bottomPath.lineTo(size.width, size.height * 0.8);
    bottomPath.lineTo(size.width, size.height);
    bottomPath.close();

    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
