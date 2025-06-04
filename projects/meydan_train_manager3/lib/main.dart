import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tren/models/inventory_manager.dart';
import 'package:tren/models/lokomotif.dart';
import 'package:tren/models/vagon.dart';
import 'package:tren/animations/ray_animation.dart';
import 'package:tren/widget/dialogs/market_dialog.dart';
import 'package:tren/widget/floating_youtube_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/route_data.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:rxdart/rxdart.dart';
import 'package:tren/animations/tree_animation.dart';
import 'animations/coin_animate.dart';
import 'widget/dialogs/train_request_dialog.dart';
import 'screens/map_screen.dart';
import 'services/route_services.dart';
import 'models/station.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:tren/widget/dialogs/depo_dialog.dart';

// main.dart ve diğer dosyaların başına ekle:

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => InventoryManager(
        List<Lokomotif>.from(lokoListesi),
        List<Vagon>.from(vagonListesi),
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

  final int _activeRouteId = -1;
  int lokoAdet = 0; // Lokomotif sayısı
  int vagonAdet = 0; // Vagon sayısı
  //int kasa = 100000; // Başlangıç kasası
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
    ).map((listOfLists) =>
        listOfLists.expand((x) => x as Iterable<LatLng>).toList());
  }

  void _onCoinCollected(int amount) {
    final inventoryManager =
        Provider.of<InventoryManager>(context, listen: false);
    inventoryManager.addKasa(amount);
  }

  void showTrainRequestDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => const TrainRequestDialog(),
    );

    // Dialog'dan dönen veriyi doğru şekilde işle
    if (result != null && result is Map<String, dynamic>) {
      // Anahtarları doğru isimlerle al
      final List<Lokomotif> selectedLokomotifler =
          result['lokomotifler'] as List<Lokomotif>;
      final List<Vagon> selectedVagonlar = result['vagonlar'] as List<Vagon>;
      final Station? startStation = result['startStation'] as Station?;
      final Station? endStation = result['endStation'] as Station?;

      // Gerekli kontrolleri yap
      if (startStation == null || endStation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen istasyon seçin!')),
        );
        return;
      }

      // Rota oluşturma işlemini başlat
      setState(() {
        _calculateRoute(
          startStation: startStation,
          endStation: endStation,
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
    // _treeController = AnimationController(
    //   // ✅ Var olan kodu koruyun
    //   vsync: this,
    //   duration: const Duration(seconds: 1),
    // )..repeat();
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
    final inventoryManager =
        Provider.of<InventoryManager>(context, listen: false);
    inventoryManager.addKasa(amount);
    // REMOVE setState here - handled by notifyListeners()
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

  void _openYouTubePlayer(BuildContext context) {
    if (kIsWeb) {
      // Web için farklı bir çözüm
      launchUrl(Uri.parse(
          "https://www.youtube.com/watch?v=EPJlpufuog8&list=PL9o-TYYDeFV0zyxn-aRwuU94QMkuXAPej&index=10"));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.6,
              child: FloatingYoutubePlayer(
                videoUrl:
                    "https://www.youtube.com/watch?v=EPJlpufuog8&list=PL9o-TYYDeFV0zyxn-aRwuU94QMkuXAPej&index=10",
                onClose: () => Navigator.pop(context),
              ),
            ),
          );
        },
      );
    }
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

    // Yeni değişken tanımları ekleyin
    final double initialDelay = 0.002;
    final double vehicleSpacing = 0.0003;
    final int totalVehicles =
        lokomotifler.fold(0, (sum, loko) => sum + loko.selectedCount) +
            vagonlar.fold(0, (sum, vagon) => sum + vagon.selectedCount);

    _routes[routeId] = RouteData(
      inventoryManager: InventoryManager(lokomotifler,
          vagonlar), // Pass appropriate arguments for InventoryManager
      routeText: route.map((s) => s.name).join(' --> '),
      polylinePoints:
          route.map((s) => LatLng(s.latitude, s.longitude)).toList(),
      lokomotifler: lokomotifler,
      vagonlar: vagonlar,
      isCompleted: false,
      trainPositions: List.generate(
        totalVehicles,
        (_) => LatLng(route[0].latitude, route[0].longitude),
      ),
      trainProgress: List.generate(
        totalVehicles,
        (i) => i == 0 ? -initialDelay : -i * vehicleSpacing - initialDelay,
      ),
      trainPolylineIndex: List.generate(totalVehicles, (_) => 0),
      onUpdate: () => setState(() {}),
      onEarningsCalculated: (earnings) {
        // Kazancı kasa'ya ekle
        updateKasa(earnings);
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

    setState(() {
      _currentRouteId = routeId;
    });
  }

  void startTrainAnimation(int routeId) {
    debugPrint("Animasyon başlatılıyor: $routeId");
    final routeData = _routes[routeId];
    if (routeData == null || routeData.isTrainMoving) return;

    // Speed değerini RouteData'dan alın
    double speed = routeData.speedKmh * 1000 / 3600;
    double totalDistance = routeData.totalDistance;
    double totalTime = totalDistance / speed;

    routeData.progressIncrement = (1 / totalTime) * 0.05;

    routeData.positionStream.listen((positions) {
      if (routeData.isTrainMoving) {
        setState(() => routeData.trainPositions = positions);
      }
    });
    routeData.startAnimation();
    if (routeData.isTrainMoving) return;
    if (!routeData.isTrainMoving) {
      routeData.startAnimation();
      routeData.currentTime = DateFormat('HH:mm').format(DateTime.now());
      routeData.startRouteAnimations();
      setState(() {});
    }

    routeData.currentTime = DateFormat('HH:mm').format(DateTime.now());
    routeData.startRouteAnimations();

    routeData.animationTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      bool allCompleted = true;

      for (int i = 0; i < routeData.trainPositions.length; i++) {
        if (routeData.trainProgress[i] < 1.0) {
          routeData.trainProgress[i] += routeData.progressIncrement *
              (i < routeData.lokoAdet ? 1.0 : 0.98);
          routeData.trainProgress[i] =
              routeData.trainProgress[i].clamp(0.0, 1.0);
          allCompleted = false;
        }
        routeData.trainPositions[i] = trainPositions[i] =
            routeData.getPositionAlongRoute(routeData.trainProgress[i]);
      }

      routeData.updatePositions();
      routeData.updatePositionStream(routeData.trainPositions);
      void pauseTrainAnimation(int routeId) {
        _routes[routeId]?.pauseAnimation();
        setState(() {});
      }
    });
  }

  void _toggleRouteAnimation(int routeId) {
    final route = _routes[routeId];
    if (route == null) return;

    setState(() {
      if (route.isTrainMoving) {
        route.pauseAnimation();
      } else {
        final now = DateTime.now();
        route.currentTime = DateFormat('HH:mm').format(now);
        route.startAnimation();
      }
      _currentRouteId = routeId;
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

  void _deleteRoute(int routeId) {
    final routeData = _routes[routeId];
    if (routeData == null) return;

    if (routeData.isTrainMoving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce treni durdurun!')),
      );
      return;
    }

    // Get inventory manager instance
    final inventoryManager =
        Provider.of<InventoryManager>(context, listen: false);

    // Return locomotives to inventory
    for (var loko in routeData.lokomotifler) {
      inventoryManager.returnLokomotif(loko.tip, loko.selectedCount);
    }

    // Return wagons to inventory
    for (var vagon in routeData.vagonlar) {
      inventoryManager.returnVagon(vagon.tip, vagon.selectedCount);
    }

    setState(() {
      routeData.dispose();
      _routes.remove(routeId);
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
                                  'Kasa: ${Provider.of<InventoryManager>(context).kasa} TL', // Kasa buradan alınıyor
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
                      showMarketDialog(context);
                      debugPrint("market tıklandı");
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
                      showDepoDialog(context);
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
                      final routeId = entry.key;
                      final routeData = entry.value;

                      return ValueListenableBuilder<int>(
                        valueListenable: routeData.currentStationNotifier,
                        builder: (context, currentIndex, _) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _currentRouteId = routeId),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: _currentRouteId == routeId
                                  ? Colors.blue[200]
                                  : Colors.grey[400],
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // Zaman bilgisi
                                  IntrinsicWidth(
                                    child: Text(
                                      routeData.currentTime ?? "00:00",
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
                                  // İstasyon listesi
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: routeData.routeText
                                            .split(' --> ')
                                            .asMap()
                                            .entries
                                            .map((e) {
                                          bool isPassed = e.key < currentIndex;
                                          bool isCurrent =
                                              e.key == currentIndex;

                                          return Row(
                                            children: [
                                              Text(
                                                e.value,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: isCurrent
                                                      ? Colors.red
                                                      : isPassed
                                                          ? Colors.green
                                                          : Colors.black,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              if (e.key <
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
                                  // Kontrol butonları
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Play/Pause butonlarını güncelleyin
                                      ElevatedButton(
                                        onPressed: () =>
                                            _toggleRouteAnimation(routeId),
                                        child: Icon(routeData.isTrainMoving
                                            ? Icons.pause
                                            : Icons.play_arrow),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _deleteRoute(routeId),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: SafeArea(
              child: SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Sabit arka plan (her zaman görünür)
                    Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            'lib/assets/arkaplan/manzara.jpg',
                            fit: BoxFit.values[0],
                            width: double.infinity,
                          ),
                        ),
                        Image.asset(
                          'lib/assets/ray.png',
                          fit: BoxFit.fitWidth,
                          repeat: ImageRepeat.repeatX,
                          width: double.infinity,
                        ),
                      ],
                    ),

                    // Animasyonlar (arka planın üzerinde)
                    if (_routes.containsKey(_currentRouteId)) ...[
                      Positioned.fill(
                        bottom: 9,
                        child: RayAnimationWidget(
                          routeId: _currentRouteId,
                          isActive: _routes[_currentRouteId]!.isTrainMoving,
                          speed: _routes[_currentRouteId]!.speedKmh,
                        ),
                      ),
                      Positioned(
                        bottom: -25,
                        child: SizedBox(
                          height: 140,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
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
                                                width: 200,
                                                height: 150,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
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
                              'max Hız: ${_routes[_currentRouteId]!.formattedSpeed}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TreeAnimationWidget(
                        routeId: _currentRouteId,
                        isActive: _routes[_currentRouteId]!.isTrainMoving,
                        speed: _routes[_currentRouteId]!.speedKmh,
                      ),
                      CoinAnimateScreen(
                        isActive:
                            _routes[_currentRouteId]?.isTrainMoving ?? false,
                        onCoinCollected: (amount) {
                          debugPrint('Coin collected: $amount');
                          _onCoinCollected(amount);
                        },
                      ),
                    ],
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
                  backgroundColor: Colors.red,
                  onPressed: () => _openYouTubePlayer(context),
                  child: const Icon(Icons.play_arrow),
                ),
                // Ana ekrandaki harita butonunu güncelleyin
                FloatingActionButton(
                  onPressed: () {
                    // This should now match the updated constructor
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          activeRouteId: _activeRouteId,
                          combinedPositionStream: combinedPositionStream,
                          routePolylines: routePolylines,
                          routes: _routes,
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
