import 'dart:math';
import 'package:flutter/material.dart';

class RayAnimationWidget extends StatefulWidget {
  final bool isActive;
  final double speed;
  final int routeId;

  const RayAnimationWidget({
    super.key,
    required this.isActive,
    required this.speed,
    required this.routeId,
  });

  @override
  _RayAnimationWidgetState createState() => _RayAnimationWidgetState();
}

class _RayAnimationWidgetState extends State<RayAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final double _rayHeight = 10;
  double _baseSpeed = 1.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000 / _baseSpeed).toInt()),
    )..repeat();
  }

  @override
  void didUpdateWidget(RayAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.speed != oldWidget.speed) {
      _baseSpeed = widget.speed.clamp(0.5, 5.0);
      _controller.duration = Duration(seconds: (4 / _baseSpeed).toInt());
    }

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Sabit siyah çizgi
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _rayHeight,
                color: Colors.black,
              ),
            ),
            // Hareketli ray katmanı
            Positioned(
              bottom: 0,
              left: -(_controller.value * MediaQuery.of(context).size.width),
              right: 0,
              child: SizedBox(
                height: _rayHeight,
                child: Image.asset(
                  'lib/assets/ray.png',
                  fit: BoxFit.fitWidth,
                  repeat: ImageRepeat.repeatX,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
