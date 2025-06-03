import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TreeAnimationWidget extends StatefulWidget {
  final bool isActive;
  final double speed;
  final int routeId;
  final double baseOffset;

  const TreeAnimationWidget({
    super.key,
    required this.isActive,
    required this.speed,
    required this.routeId,
    this.baseOffset = 50,
  });

  @override
  _TreeAnimationWidgetState createState() => _TreeAnimationWidgetState();
}

class _TreeAnimationWidgetState extends State<TreeAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _treeController;
  late AnimationController _cloudController;
  late Random _random;
  List<Widget> _trees = [];
  List<CloudData> _clouds = [];
  late List<String> _treeAssets;
  late List<String> _cloudAssets;
  double _totalTreeWidth = 0.0;
  Timer? _treeSpawnTimer;
  double _treeSpeed = 1.0; // Sabit hız değeri

  @override
  void initState() {
    super.initState();
    _random = Random(widget.routeId);
    _treeSpeed = widget.speed.clamp(0.5, 5.0);
    _initializeAssets();
    _initializeCloudController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _generateRandomElements();
        _initializeCloudAnimations();
        _startTreeSpawning();
      }
    });
    _treeController = AnimationController(
      // ✅ initState'de başlatın
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();
  }

  void _startTreeSpawning() {
    _spawnNewTreeSet();
    _scheduleNextTreeSpawn();
  }

  void _spawnNewTreeSet() {
    if (!mounted) return;

    setState(() {
      final treeCount = _random.nextInt(5) + 4;
      _trees = List.generate(treeCount, (index) => _createTree());
      _calculateTotalWidth();

      _treeController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (10000 / _treeSpeed).round()),
      )..forward();
    });
  }

  void _scheduleNextTreeSpawn() {
    if (!mounted) return;

    final nextSpawnDelay = Duration(seconds: 3 + _random.nextInt(18));
    _treeSpawnTimer = Timer(nextSpawnDelay, () {
      _spawnNewTreeSet();
      _scheduleNextTreeSpawn();
    });
  }

  void _initializeAssets() {
    _treeAssets = [
      'lib/assets/trees/tree1.png',
      'lib/assets/trees/tree2.png',
      'lib/assets/trees/tree3.png',
      'lib/assets/trees/tree4.png',
      'lib/assets/trees/tree5.png',
    ];

    _cloudAssets = [
      'lib/assets/clouds/cloud1.png',
      'lib/assets/clouds/cloud2.png',
      'lib/assets/clouds/cloud3.png',
      'lib/assets/clouds/cloud4.png',
    ];
  }

  void _initializeCloudController() {
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  void _generateRandomElements() {
    final treeCount = _random.nextInt(5) + 4;
    _trees = List.generate(treeCount, (index) => _createTree());
    _calculateTotalWidth();
    _clouds = List.generate(5, (index) => _createCloudData());
  }

  Widget _createTree() {
    final sizeFactor = 0.8 + _random.nextDouble() * 0.4;
    final treeType = _treeAssets[_random.nextInt(_treeAssets.length)];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 30 + _random.nextInt(40).toDouble(),
      ),
      child: Image.asset(
        treeType,
        width: 80 * sizeFactor,
        height: 150 * sizeFactor,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      ),
    );
  }

  CloudData _createCloudData() {
    final screenWidth = MediaQuery.of(context).size.width;
    return CloudData(
      type: _cloudAssets[_random.nextInt(_cloudAssets.length)],
      startX: screenWidth + 200 + _random.nextDouble() * 300,
      endX: -200 - _random.nextDouble() * 300,
      y: 20.0 + _random.nextDouble() * 50,
      speed: 0.2 + _random.nextDouble(),
    );
  }

  void _initializeCloudAnimations() {
    _cloudController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _calculateTotalWidth() {
    _totalTreeWidth = _trees.fold(0.0, (sum, item) {
      final padding = (item as Padding).padding;
      final width = (item.child as Image).width!;
      return sum + width + padding.horizontal;
    });
  }

  @override
  void didUpdateWidget(TreeAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.speed != oldWidget.speed) {
      _treeSpeed = widget.speed.clamp(0.5, 5.0);
      if (_treeController.isAnimating) {
        _treeController.duration = Duration(
          milliseconds: (10000 / _treeSpeed).round(),
        );
      }
    }

    if (widget.routeId != oldWidget.routeId) {
      _random = Random(widget.routeId);
      _treeSpawnTimer?.cancel();
      if (widget.isActive) _startTreeSpawning();
    }

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _treeController.forward();
        _cloudController.repeat();
        _startTreeSpawning();
      } else {
        _treeController.stop();
        _cloudController.stop();
        _treeSpawnTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _treeSpawnTimer?.cancel();
    _treeController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink(); // Veya duraklatılmış durumda gösterilecek sabit bir görünüm
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._clouds.map((cloud) {
            final progress = _cloudController.value * cloud.speed;
            final currentX =
                cloud.startX + (cloud.endX - cloud.startX) * progress;

            return Positioned(
              left: currentX % (screenWidth + 400),
              top: cloud.y,
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(
                  cloud.type,
                  width: 150,
                  height: 75,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }),
          AnimatedBuilder(
            animation: _treeController,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(
                  screenWidth -
                      (screenWidth + _totalTreeWidth) * _treeController.value,
                  widget.baseOffset - 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children:
                      _trees.map((tree) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: tree,
                        );
                      }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CloudData {
  final String type;
  final double startX;
  final double endX;
  final double y;
  final double speed;

  CloudData({
    required this.type,
    required this.startX,
    required this.endX,
    required this.y,
    required this.speed,
  });
}
