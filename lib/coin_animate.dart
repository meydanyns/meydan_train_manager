import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
// coin_animate.dart başına ekleyin:
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Coin {
  double x;
  double y;
  double speed;

  Coin({required this.x, required this.y, required this.speed});
}

class CoinAnimateScreen extends StatefulWidget {
  final bool isActive;
  final Function(int) onCoinCollected;

  const CoinAnimateScreen({
    super.key,
    required this.isActive,
    required this.onCoinCollected,
  });

  @override
  _CoinAnimateScreenState createState() => _CoinAnimateScreenState();
}

class _CoinAnimateScreenState extends State<CoinAnimateScreen>
    with SingleTickerProviderStateMixin {
  final List<Coin> _coins = [];
  Timer? _spawnTimer;
  late final Ticker _ticker;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startSpawning();

    _ticker = Ticker(_updateCoins)..start();
  }

  void _startSpawning() {
    _spawnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _coins.add(
          Coin(
            x: _random.nextDouble() * 4200,
            y: 0,
            speed: 100 + _random.nextDouble() * 80, // 100-200 px/sn
          ),
        );
      });
    });
  }

  void _updateCoins(Duration elapsed) {
    setState(() {
      final double deltaTime = 1 / 60; // 60 FPS tahmini
      for (var coin in _coins) {
        coin.y += coin.speed * deltaTime;
      }
      _coins.removeWhere((coin) => coin.y > MediaQuery.of(context).size.height);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _coins.map((coin) {
        return Positioned(
          left: coin.x,
          top: coin.y,
          child: GestureDetector(
            onTap: () {
              widget.onCoinCollected(10);
              setState(() {
                _coins.remove(coin);
              });
            },
            child: const Icon(
              Icons.monetization_on,
              color: Colors.amber,
              size: 30,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }
}
