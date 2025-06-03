import 'package:flutter/material.dart';

class RayAnimationWidget extends StatefulWidget {
  final int routeId;
  final bool isActive; // Bu parametre artık kullanılacak
  final double speed;
  const RayAnimationWidget({
    super.key,
    required this.routeId,
    required this.isActive,
    required this.speed,
  });

  @override
  _RayAnimationWidgetState createState() => _RayAnimationWidgetState();
}

class _RayAnimationWidgetState extends State<RayAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    // Sadece aktifse animasyonu başlat
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RayAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Aktiflik durumu değiştiğinde animasyonu güncelle
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }

    // Hız değiştiğinde animasyon süresini güncelle
    if (widget.speed != oldWidget.speed) {
      final newSpeed = widget.speed.clamp(0.5, 5.0);
      _controller.duration = Duration(
        milliseconds: (4000 / newSpeed).toInt(),
      );
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
              child: Container(height: 10, color: Colors.black),
            ),
            // Hareketli ray katmanı (sadece aktifse görünür)
            if (widget.isActive)
              Positioned(
                bottom: 0,
                left: -(_controller.value * 1000),
                right: 0,
                child: SizedBox(
                  height: 10,
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
