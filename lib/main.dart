import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tren/models/lokomotif.dart';
import 'package:tren/models/vagon.dart';
import 'package:tren/ray_animation.dart';
import 'models/route_data.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:rxdart/rxdart.dart';
import 'package:tren/tree_animation.dart';
import 'coin_animate.dart';
import 'request.dart';
import 'screens/map_screen.dart';
import 'services/route_services.dart';
import 'models/station.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 🔇 Debug yazısı kapalı
      title: 'Tren Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final RouteData? routeData; // Nullable olarak tanımlayın
  const HomePage({super.key, this.routeData});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Station? startStation;
  Station? endStation;
  List<Station> route = [];
  String routeText = '';
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  LatLng trainPosition = const LatLng(39.9334, 32.8597);

  int lokoAdet = 0; // Lokomotif sayısı
  int vagonAdet = 0; // Vagon sayısı
  int kasa = 1000; // Başlangıç kasası
  int level = 1; // Oyun seviyesi
  int bitirilenSefer = 0; // Bitirilen sefer sayısı
  int iptalSefer = 0; // İptal edilen sefer sayısı
  int _currentRouteId = 0; // Seçilen rota ID'si

  List<BitmapDescriptor> lokoIcons = []; // Lokomotif ikonları
  List<BitmapDescriptor> vagonIcons = []; // Vagon ikonları

  List<String> routeTexts = [];
  List<List<LatLng>> routePolylinePoints = [];
  List<Set<Polyline>> routePolylines = [];
  List<Set<Marker>> routeMarkers = [];

  List<LatLng> polylinePoints = [];

  List<double> trainProgress = [];
  List<int> trainPolylineIndex = [];
  List<LatLng> trainPositions = [];
  List<Marker> trainMarkers = [];

  Lokomotif? selectedLoko;
  Vagon? selectedVagon;
  List<bool> isTrainMovingList = [];
  bool isTrainMoving = false;

  List<Color> stationColors = [];
  final Map<int, StreamController<List<LatLng>>> _routeStreamControllers = {};
  AnimationController? animationController;

  int _nextRouteId = 0;

  final Map<int, RouteData> _routes = {};

  bool isSoundOn = true; // Ses açık mı?
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isEditingTitle = false;
  String titleText = 'şirket ismini yazınız';
  final TextEditingController _controller = TextEditingController();

  Stream<List<LatLng>> get combinedPositionStream {
    return CombineLatestStream.list(
      _routes.values.map((route) => route.positionStream),
    ).map((listOfLists) => listOfLists.expand((x) => x).toList());
  }

  List<String> lokoResimler = [
    'lib/assets/lokomotifler/loko.png',
    'lib/assets/lokomotifler/star_icon.png',
    'lib/assets/lokomotifler/train4.png',
    'lib/assets/lokomotifler/lde11000.png',
    'lib/assets/lokomotifler/lde18000.png',
    'lib/assets/lokomotifler/lde22000.png',
    'lib/assets/lokomotifler/lde24000.png',
    'lib/assets/lokomotifler/lde33000.png',
    'lib/assets/lokomotifler/lde36000.png',
    'lib/assets/lokomotifler/le68000.png',
  ];

  List<String> vagonResimler = [
    'lib/assets/vagonlar/vagon1.png',
    'lib/assets/vagonlar/vagon2.png',
    'lib/assets/vagonlar/vagon3.png',
    'lib/assets/vagonlar/vagon4.png',
  ];

  void _onCoinCollected(int amount) {
    setState(() {
      kasa += amount;
      // Eski hatalı kodlar silindi
    });
  }

  void showTrainRequestDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => const TrainRequestDialog(),
    );

    if (result != null) {
      final selectedLokomotifler = result['lokomotifler'] as List<Lokomotif>;
      final selectedVagonlar = result['vagonlar'] as List<Vagon>;

      setState(() {
        startStation = result['startStation'] as Station?;
        endStation = result['endStation'] as Station?;

        // Seçilen lokomotif ve vagon listelerini işle
        _calculateRoute(
          startStation: startStation!,
          endStation: endStation!,
          lokomotifler: selectedLokomotifler,
          vagonlar: selectedVagonlar,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    RouteService.initializeGraph();
    _loadIcons();
    final throttledStream = CombineLatestStream.list(
      _routeStreamControllers.values.map((c) => c.stream),
    ).throttleTime(const Duration(milliseconds: 100));

    throttledStream.listen((trainPositions) {
      debugPrint("Train Positions: $trainPositions");
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    for (var routeData in _routes.values) {
      routeData.disposeAnimation();
    }
    for (var controller in _routeStreamControllers.values) {
      controller.close();
    }
    super.dispose();
  }

  void updateKasa(int amount) {
    setState(() {
      kasa += amount;
    });
  }

  Future<void> _loadIcons() async {
    lokoIcons.clear();
    vagonIcons.clear();

    for (int i = 0; i < lokoAdet; i++) {
      BitmapDescriptor icon = await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(2, 2)),
        'lib/assets/circle_red.png',
      );
      lokoIcons.add(icon);
    }

    for (int i = 0; i < vagonAdet; i++) {
      BitmapDescriptor icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(2, 2)), // İkon boyutunu küçültün
        'lib/assets/circle_black.png',
      );
      vagonIcons.add(icon);
    }

    setState(() {});
  }

  // Mevcut kodunuzu bu şekilde güncelleyin:
  Future<BitmapDescriptor> createCustomIcon() async {
    // Asset yükleme
    final ByteData data = await rootBundle.load('assets/icons/red_circle.png');
    final Uint8List bytes = data.buffer.asUint8List();

    // Resmi yeniden boyutlandırma
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 24,
      targetHeight: 24,
    );

    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final Uint8List resizedBytes = resizedData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(resizedBytes);
  }

  void _showDepoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: const Text('DEPPO'),
            content: SizedBox(
              height: 400,
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Lokomotifler'),
                      Tab(text: 'Vagonlar'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: lokoListesi.length,
                          itemBuilder: (context, index) {
                            Lokomotif lokomotif = lokoListesi[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        lokomotif.tip,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Image.asset(
                                        lokomotif.resim,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Loko Tipi: ${lokomotif.tip}'),
                                        Text('Adet: ${lokomotif.adet}'),
                                        Text('Hız: ${lokomotif.hiz} KM'),
                                        Text('Bakım: ${lokomotif.guc} %'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: vagonListesi.length,
                          itemBuilder: (context, index) {
                            Vagon vagon = vagonListesi[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        vagon.tip,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Image.asset(
                                        vagon.resim,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Adet: ${vagon.adet}'),
                                        Text(
                                            'Kapasite: ${vagon.kapasite.toString()} TON'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pauseTrainAnimation(int routeId) {
    final routeData = _routes[routeId];
    routeData?.pause();
    routeData?.pauseAnimations();
    setState(() {});
  }

// gerçek uzaklık hesaplama fonksiyonu
  static double calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371e3; // Earth radius in meters
    double phi1 = p1.latitude * pi / 180;
    double phi2 = p2.latitude * pi / 180;
    double deltaPhi = (p2.latitude - p1.latitude) * pi / 180;
    double deltaLambda = (p2.longitude - p1.longitude) * pi / 180;

    double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // metre cinsinden mesafe
  }

  Future<BitmapDescriptor> createCircleIcon(
      {int size = 20, Color color = Colors.red}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color; // Daire rengi

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    final ui.Image img =
        await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData =
        await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(pngBytes);
  }

  void _calculateRoute({
    required Station startStation,
    required Station endStation,
    required List<Lokomotif> lokomotifler,
    required List<Vagon> vagonlar,
  }) async {
    List<Station> route =
        RouteService.findShortestRoute(startStation, endStation);

    int routeId = _nextRouteId++;
    _routes[routeId] = RouteData(
      routeText: route.map((s) => s.name).join(' --> '),
      polylinePoints:
          route.map((s) => LatLng(s.latitude, s.longitude)).toList(),
      lokomotifler: lokomotifler,
      vagonlar: vagonlar,
      isTrainMoving: false,
      isCompleted: false, // Added the required parameter
      trainPositions: List.generate(
        lokomotifler.fold(0, (sum, loko) => sum + loko.selectedCount) +
            vagonlar.fold(0, (sum, vagon) => sum + vagon.selectedCount),
        (_) => LatLng(route[0].latitude, route[0].longitude),
      ),
      trainProgress: List.generate(
        lokomotifler.fold(0, (sum, loko) => sum + loko.selectedCount) +
            vagonlar.fold(0, (sum, vagon) => sum + vagon.selectedCount),
        (_) => 0.0,
      ),
      trainPolylineIndex: List.generate(
        lokomotifler.fold(0, (sum, loko) => sum + loko.selectedCount) +
            vagonlar.fold(0, (sum, vagon) => sum + vagon.selectedCount),
        (_) => 0,
      ),
      onUpdate: () {
        setState(() {
          // Kazancı kasa'ya ekle
          if (_routes[routeId]?.isCompleted == true) {
            final earnings = _routes[routeId]!.calculateEarnings();
            kasa += earnings;
            _routes[routeId]!.isCompleted = false; // Tekrar eklenmemesi için
          }
        });
      },
    );

    routePolylinePoints.add(_routes[routeId]!.polylinePoints);
    routePolylines.add({
      Polyline(
        polylineId: PolylineId('route_$routeId'),
        points: _routes[routeId]!.polylinePoints,
        color: Colors.blue,
        width: 5,
      ),
    });

    debugPrint("Rota uzunluğu: ${_routes[routeId]!.formattedDistance}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text("Rota oluşturuldu: ${_routes[routeId]!.formattedDistance}")),
    );

    setState(() {});
  }

  void _startTrainAnimation(int routeId, {double speedKmh = 250.0}) {
    final routeData = _routes[routeId];
    if (routeData == null) return;

    // SADECE SEÇİLEN ROTANIN ANİMASYONUNU KONTROL ET
    routeData.initializeAnimation(this);
    if (routeData.isTrainMoving) {
      routeData.pause();
    } else {
      routeData.resume(speedKmh: speedKmh);
    }

    // Play butonuna basıldığı andaki saati al
    final now = DateTime.now();
    setState(() {
      routeData.currentTime = "${now.hour.toString().padLeft(2, '0')}:";
      "${now.minute.toString().padLeft(2, '0')}";
    });
    routeData.resumeAnimations();
    debugPrint(
      'Tren ${routeId + 1} başlatıldı:\n'
      'Lokomotifler: ${routeData.lokomotifler.map((l) => l.tip).join(", ")}\n'
      'Hesaplanan Hız: ${routeData.formattedSpeed}\n'
      'Toplam Yük: ${routeData.vagonlar.fold(0, (sum, v) => sum + (v.kapasite * v.selectedCount))} ton',
    );

    if (routeData.isCompleted) {
      routeData.resetRoute();
    }

    if (routeData.isTrainMoving) {
      routeData.pause();
    } else {
      routeData.initializeAnimation(this);
      routeData.resume(speedKmh: routeData.speedKmh);
    }

    setState(() {
      if (routeData.isCompleted || !routeData.wasStarted) {
        routeData.resetPositions();

        routeData.isCompleted = false;
      }

      if (routeData.isTrainMoving) {
        _pauseTrainAnimation(routeId);
      } else {
        routeData.resume(speedKmh: speedKmh);
      }
    });

    const double simulationSpeedMultiplier = 100.0;
    double totalDistance = 0;
    for (int i = 0; i < routeData.polylinePoints.length - 1; i++) {
      totalDistance += _HomePageState.calculateDistance(
          routeData.polylinePoints[i], routeData.polylinePoints[i + 1]);
    }

    double adjustedSpeed = speedKmh * simulationSpeedMultiplier;
    double speedMps = adjustedSpeed * 1000 / 3600;
    double totalTime = totalDistance / speedMps;

    double progressIncrement = (1 / totalTime) * 0.15;

    routeData.wasStarted = true;
    routeData.isCompleted = false; // Bu satırı ekleyin
    routeData.isTrainMoving = true;
    routeData.startAnimations();

    Timer timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Timer logic here
    });
    routeData.animationTimer = timer;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      bool allTrainsArrived = true;

      for (int i = 0; i < routeData.trainPositions.length; i++) {
        final currentIndex = routeData.trainPolylineIndex[i];
        final isLastSegment = currentIndex >=
            routeData.polylinePoints.length - 1; // ← Bu satırı ekleyin

        if (!isLastSegment) {
          routeData.trainProgress[i] += progressIncrement;
          allTrainsArrived = false;

          if (routeData.trainProgress[i] >= 1.0) {
            routeData.trainPolylineIndex[i]++;
            routeData.updateCurrentStation(routeData.trainPolylineIndex[i]);
            routeData.trainProgress[i] = 0.0;
          }

          final start = routeData.polylinePoints[currentIndex];
          final end = routeData.polylinePoints[currentIndex + 1];
          routeData.trainPositions[i] = LatLng(
            start.latitude +
                (end.latitude - start.latitude) * routeData.trainProgress[i],
            start.longitude +
                (end.longitude - start.longitude) * routeData.trainProgress[i],
          );
        } else {
          if (routeData.trainProgress[i] < 1.0) {
            routeData.trainProgress[i] += progressIncrement;
            allTrainsArrived = false;
          }
          routeData.trainPositions[i] = routeData.polylinePoints.last;
        }
      }

      if (allTrainsArrived) {
        timer.cancel();
        routeData.pauseAnimations();
        setState(() {
          routeData.completeRoute();
          kasa += 100;
          bitirilenSefer++;
          if (bitirilenSefer % 25 == 0) level++;
        });
        Future.delayed(const Duration(milliseconds: 5), () {
          if (mounted) setState(() => routeData.resetPositions());
        });
      }
      _routeStreamControllers[routeId]!.add(routeData.trainPositions);
      if (mounted) setState(() {});
    });

    setState(() {
      routeData.currentTime =
          "${DateTime.now().hour.toString().padLeft(2, '0')}:"
          "${DateTime.now().minute.toString().padLeft(2, '0')}";
    });
  }

// İndeks geçerliliğini kontrol eden yardımcı fonksiyon
  bool isIndexValid(int index, List<dynamic> list) {
    return index >= 0 && index < list.length;
  }

  Future<void> _toggleSound() async {
    setState(() {
      isSoundOn = !isSoundOn;
    });

    if (isSoundOn) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // 🔁 Sürekli tekrar
      await _audioPlayer.play(AssetSource('sounds/trenses.mp3'));
    } else {
      await _audioPlayer.stop(); // 🔇 Durdur
    }
  }

  void _startEditing() {
    setState(() {
      isEditingTitle = true;
      _controller.text = titleText;
    });
  }

  void _saveTitle() {
    setState(() {
      titleText = _controller.text;
      isEditingTitle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: GestureDetector(
            onTap: _startEditing,
            child: isEditingTitle
                ? SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onSubmitted: (_) => _saveTitle(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 156, 21, 21),
                        fontSize: 20,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  )
                : Text(
                    titleText,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 168, 17, 17),
                      fontSize: 20,
                    ),
                  ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 20),
            icon: Icon(isSoundOn ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleSound,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.amber,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              children: [
                                Text(
                                  ' level: $level',
                                  style: TextStyle(
                                    fontSize: 100,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Kasa: $kasa ',
                                  style: const TextStyle(
                                    fontSize: 100,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const Icon(
                                  Icons.monetization_on,
                                  size: 100,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _showDepoDialog(context);
                      debugPrint("deppo tıklandı");
                    },
                    child: Container(
                      margin: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.amber,
                      ),
                      child: const Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "MARKETİNG",
                            style: TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _showDepoDialog(context);
                      debugPrint("deppo tıklandı");
                    },
                    child: Container(
                      margin: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.amber,
                      ),
                      child: const Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "DEPPO",
                            style: TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ..._routes.entries.map(
                    (entry) {
                      int routeId = entry.key;
                      RouteData routeData = entry.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentRouteId = routeId;
                          });
                          debugPrint("seçilen tren");
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey[400],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IntrinsicWidth(
                                child: Text(
                                  (routeData.currentTime ??
                                      "00:00"), // Null-aware operatör eklendi
                                  style: TextStyle(
                                    color: routeData.isTrainMoving
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: routeData.routeText
                                          .split(' --> ')
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        String station = entry.value;
                                        bool isPassed = index <
                                            routeData.currentStationIndex;
                                        bool isCurrent = index ==
                                            routeData.currentStationIndex;

                                        return Row(
                                          children: [
                                            Text(
                                              station,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isCurrent
                                                    ? Colors.red
                                                    : isPassed
                                                        ? Colors.green
                                                        : Colors.black,
                                              ),
                                            ),
                                            if (index <
                                                routeData.routeText
                                                        .split(' --> ')
                                                        .length -
                                                    1)
                                              const Text(' --> '),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      final routeData = _routes[routeId]!;
                                      if (routeData.isCompleted ||
                                          !routeData.isTrainMoving) {
                                        _startTrainAnimation(routeId);
                                      } else {
                                        _pauseTrainAnimation(routeId);
                                      }
                                    },
                                    child: Icon(
                                      _routes[routeId]!.isCompleted ||
                                              !_routes[routeId]!.isTrainMoving
                                          ? Icons.play_arrow
                                          : Icons.pause,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (routeData.isTrainMoving) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Tren hareket halindeyken rota silinemez!'),
                                          ),
                                        );
                                      } else {
                                        setState(() {
                                          routeData.disposeAnimation();
                                          _routes.remove(routeId);
                                          routePolylinePoints.removeAt(routeId);
                                          routePolylines.removeAt(routeId);
                                          if (_currentRouteId == routeId) {
                                            _currentRouteId = -1;
                                          }
                                          kasa -= 20;
                                          if (kasa < 0) kasa = 0;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Expanded(
              flex: 4,
              child: SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            'lib/assets/manzara.jpg',
                            fit: BoxFit.cover,
                            width: double.infinity, // Genişliği tam yap
                          ),
                        ),
                        Image.asset(
                          'lib/assets/ray.png',
                          fit: BoxFit.fitWidth,
                          repeat: ImageRepeat.repeatX,
                          width: double.infinity, // Genişliği tam yap
                        ),
                      ],
                    ),

                    // 1. RAY ANİMASYONU (En alt katman)
                    if (_routes[_currentRouteId]?.isTreeAnimationActive ??
                        false)
                      Positioned.fill(
                        bottom: 8, // Siyah çizgi üzerinde
                        child: RayAnimationWidget(
                          routeId: _currentRouteId,
                          isActive:
                              _routes[_currentRouteId]?.shouldShowAnimations ??
                                  false,
                          speed: _currentRouteId != -1
                              ? _routes[_currentRouteId]!.speed
                              : 1.0,
                        ),
                      ),

                    // 3. İSTASYON ANİMASYONU (şimdilik kaldırıldı)
                    // if (_routes[_currentRouteId]?.isStationAnimationActive ??
                    //     false)
                    //   Positioned(
                    //     bottom: -300, // Siyah çizgi üzerinde
                    //     left: 0,
                    //     right: 0,
                    //     height: 200,
                    //     child: StationAnimationWidget(
                    //       stationName: _getCurrentStationName(_currentRouteId),
                    //       isActive: _routes[_currentRouteId]!.isTrainMoving,
                    //       routeData: _routes[_currentRouteId]!,
                    //     ),
                    //   ),

                    // 4. TREN VE VAGONLAR
                    if (_currentRouteId != -1 &&
                        _routes[_currentRouteId] != null)
                      Positioned(
                        bottom: -30, // Siyah çizgi üzerinde
                        child: SizedBox(
                          height: 140,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // VAGONLAR
                                Row(
                                  children: _routes[_currentRouteId]!
                                      .vagonlar
                                      .expand((vagon) => List.generate(
                                            vagon.selectedCount,
                                            (index) => Container(
                                              margin: const EdgeInsets.only(
                                                  right: 5),
                                              child: Image.asset(
                                                vagon.resim,
                                                width: 100,
                                                height: 120,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),

                                // LOKOMOTİFLER
                                Row(
                                  children: _routes[_currentRouteId]!
                                      .lokomotifler
                                      .expand((loko) => List.generate(
                                            loko.selectedCount,
                                            (index) => Image.asset(
                                              loko.resim,
                                              width: 200,
                                              height: 150,
                                              fit: BoxFit.contain,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // 2. AĞAÇ ANİMASYONU
                    // if (_routes[_currentRouteId]?.isTreeAnimationActive ??
                    //     false)
                    if (_routes[_currentRouteId] != null)
                      Positioned(
                        bottom: 2, // Siyah çizgi üzerinde
                        left: 0,
                        right: 0,
                        height: 200,
                        child: TreeAnimationWidget(
                          routeId: _currentRouteId,
                          isActive:
                              _routes[_currentRouteId]?.isTreeAnimationActive ??
                                  false,
                          speed: _routes[_currentRouteId]!.speed,
                          baseOffset: 50,
                        ),
                      ),

                    // COİN ANİMASYONU (En üst katman)
                    // if (_routes[_currentRouteId]?.isCoinAnimationActive ??
                    //     false)
                    if (_routes[_currentRouteId] != null)
                      Positioned.fill(
                        child: CoinAnimateScreen(
                          isActive: _routes[_currentRouteId]!.isTrainMoving,
                          onCoinCollected: _onCoinCollected,
                        ),
                      ),

                    // HIZ GÖSTERGESİ
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.speed, color: Colors.blue),
                          const SizedBox(width: 5),
                          Text(
                            'max Hız: ${_routes[_currentRouteId]?.formattedSpeed ?? 'N/A'} ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: () {
                    showTrainRequestDialog(context);
                    debugPrint("tren ekleme butonu tıklandı");
                  },
                  child: const Icon(Icons.add),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.amber,
                  onPressed: () {
                    // Ana ekranda MapScreen çağrısı:
                    // main.dart içinde MapScreen çağrısını düzeltin
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          combinedPositionStream: combinedPositionStream,
                          routePolylines: routePolylines,
                          routes: _routes,
                          // Removed trainPositionStream as it is not defined
                        ),
                      ),
                    );
                  },
                  child: const Text('Harita'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
