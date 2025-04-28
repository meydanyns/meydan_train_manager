import 'package:flutter/material.dart';
import '../models/route_data.dart';

class StationAnimationWidget extends StatefulWidget {
  final String stationName;
  final bool isActive;
  final RouteData routeData;

  const StationAnimationWidget({
    super.key,
    required this.stationName,
    required this.isActive,
    required this.routeData,
  });

  @override
  _StationAnimationWidgetState createState() => _StationAnimationWidgetState();
}

class _StationAnimationWidgetState extends State<StationAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _currentStation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Daha yavaş animasyon
    );

    _animation = Tween<double>(begin: 1.2, end: -0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    if (widget.isActive && widget.stationName.isNotEmpty) {
      _startAnimation(widget.stationName);
    }
  }

  void _startAnimation(String stationName) {
    if (stationName != _currentStation) {
      _currentStation = stationName;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StationAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stationName != oldWidget.stationName &&
        widget.stationName.isNotEmpty) {
      _startAnimation(widget.stationName);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive || _currentStation == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _animation.value,
          bottom: 50, // Ray çizgisine göre konumlandırma
          child: Image.asset(
            'lib/assets/station.png',
            width: 224,
            height: 324,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
