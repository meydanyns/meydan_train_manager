import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tren/models/lokomotif.dart';
import 'package:tren/models/vagon.dart';
import 'package:tren/request.dart';
import 'package:tren/screens/map_screen.dart';
import 'package:tren/services/route_services.dart';

import 'models/station.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tren Oyunu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Station? startStation;
  Station? endStation;
  List<Station> route = [];
  String routeText = '';

  Set<Marker> markers = {};

  Set<Polyline> polylines = {};
  LatLng trainPosition = const LatLng(39.9334, 32.8597);

  int lokoAdet = 0; // Lokomotif sayısı
  int vagonAdet = 0; // Vagon sayısı
  int kasa = 1000;

  int _currentRouteId = 0; // Seçilen rota ID'si

  final Completer<GoogleMapController> _controller = Completer();

  List<BitmapDescriptor> lokoIcons = []; // Lokomotif ikonları
  List<BitmapDescriptor> vagonIcons = []; // Vagon ikonları

  List<String> routeTexts = [];
  List<List<LatLng>> routePolylinePoints = [];
  List<Set<Polyline>> routePolylines = [];
  List<Set<Marker>> routeMarkers = [];

  final int _currentPolylineIndex = 0;
  final double _progress = 0.0;
  List<LatLng> polylinePoints = [];
  late Timer _animationTimer;

  List<double> trainProgress = [];
  List<int> trainPolylineIndex = [];
  List<LatLng> trainPositions = [];
  List<Marker> trainMarkers = [];

  String? selectedLoko;
  String? selectedVagon;

  List<bool> isTrainMovingList = [];
  bool isTrainMoving = false;

  List<Color> stationColors = [];

  AnimationController?
      animationController; // Nullable yapın // Animasyon kontrolü için
  late Animation<double> _animation; // Animasyon değeri için

  // Trenin geçtiği istasyonun indeksini takip etmek için
  final int _currentStationIndex = 0;

  // Her rota için ayrı bir kimlik (routeId) oluşturun
  int _nextRouteId = 0;

  // Rota bilgilerini tutan yapı
  final Map<int, RouteData> _routes = {};

  final List<Map<String, dynamic>> locomotives = [
    {"name": "Lokomotif 1", "icon": 'lib/assets/train_icon.png'},
    {"name": "Lokomotif 2", "icon": Icons.directions_railway_filled},
  ];

  final List<Map<String, dynamic>> wagons = [
    {"name": "Vagon 1", "icon": Icons.directions_transit},
    {"name": "Vagon 2", "icon": Icons.luggage},
  ];

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
  final _trainPositionStreamController =
      StreamController<List<LatLng>>.broadcast();

  StreamSubscription<List<LatLng>>? _trainPositionSubscription;

  List<List<LatLng>> trainPositionsList = [];
  List<List<double>> trainProgressList = [];
  List<List<int>> trainPolylineIndexList = [];

  void showTrainRequestDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const TrainRequestDialog();
      },
    );

    if (result != null) {
      setState(() {
        startStation = result['startStation'];
        endStation = result['endStation'];
        selectedLoko = result['selectedLoko'];
        selectedVagon = result['selectedVagon'];
        lokoAdet = result['lokoAdet'];
        vagonAdet = result['vagonAdet'];
      });

      _calculateRoute();
    }
  }

  @override
  void initState() {
    super.initState();
    RouteService.initializeGraph();
    _loadIcons(); // İkonları yükle
    final throttledStream = _trainPositionStreamController.stream
        .throttleTime(const Duration(milliseconds: 50));

    // Stream'i dinleyin
    throttledStream.listen((trainPositions) {
      print("Train Positions: $trainPositions");
    });
  }

  @override
  void dispose() {
    for (var routeData in _routes.values) {
      if (routeData != null) {
        routeData.disposeAnimation(); // Tüm rotaların animasyonlarını temizle
      }
    }
    _trainPositionSubscription?.cancel();
    _trainPositionStreamController.close();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    lokoIcons.clear();
    vagonIcons.clear();

    for (int i = 0; i < lokoAdet; i++) {
      BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(10, 10)),
        'lib/assets/lokomotifler/loko.png',
      );
      lokoIcons.add(icon);
    }

    for (int i = 0; i < vagonAdet; i++) {
      BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(10, 10)),
        'lib/assets/vagonlar/vagon1.png',
      );
      vagonIcons.add(icon);
    }

    setState(() {});
  }

  Future<BitmapDescriptor> _getTrainIcon(String assetPath) async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(10, 10)),
        assetPath,
      );
    } catch (e) {
      print("Error loading train icon: $e");
      // Fallback ikon döndür
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(10, 10)),
        'lib/assets/lokomotifler/loko.png', // Varsayılan ikon
      );
    }
  }

  void _showDepoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2, // İki tab olacak
          child: AlertDialog(
            title: const Text('DEPPO'),
            content: SizedBox(
              height: 400, // Dialog yüksekliği
              width: 600, // Dialog genişliği
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
                        // Lokomotifler Tab'ı
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: lokoListesi.length,
                          itemBuilder: (context, index) {
                            Lokomotif lokomotif = lokoListesi[index];
                            return ListTile(
                              leading: Image.asset(
                                lokomotif.resim, // Lokomotif resmi
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                              title:
                                  Text(lokomotif.tip), // Lokomotif özellikleri
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Metinleri sola hizala
                                children: [
                                  Text('Loko Tipi: ${lokomotif.tip}'),
                                  Text('Adet: ${lokomotif.adet}'),
                                  Text('Hız: ${lokomotif.hiz} KM'),
                                  Text('Bakım: ${lokomotif.guc} %'),
                                ],
                              ),
                            );
                          },
                        ),
                        // Vagonlar Tab'ı
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: vagonListesi.length,
                          itemBuilder: (context, index) {
                            Vagon vagon = vagonListesi[index];
                            return ListTile(
                              leading: Image.asset(
                                vagon.resim,
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                              title: Text(vagon.tip), // Lokomotif özellikleri
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Metinleri sola hizala
                                children: [
                                  Text('Vagon Tipi: ${vagon.tip}'),
                                  Text('Adet: ${vagon.adet}'),
                                  Text('Kapasite: ${vagon.kapasite} TON'),
                                  Text('Bakım: ${vagon.bakim} %'),
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
    if (_routes[routeId] != null) {
      _routes[routeId]!.animationController?.stop(); // Null kontrolü ile çağır
    }
  }

  void _onEndStationSelected(Station? station) {
    setState(() {
      endStation = station;
    });
  }

  LatLng _calculateOffsetPosition(
      LatLng start, LatLng end, double distanceMeters) {
    double totalDistance = _haversineDistance(start, end);

    if (totalDistance < distanceMeters || totalDistance == 0) {
      return start; // Burada LatLng tipinde bir değer döndürülüyor.
    }

    double ratio = distanceMeters / totalDistance;

    double lat = start.latitude + (end.latitude - start.latitude) * ratio;
    double lng = start.longitude + (end.longitude - start.longitude) * ratio;

    return LatLng(lat, lng); // Burada da LatLng tipinde bir değer döndürülüyor.
  }

  void _calculateRoute() async {
    if (startStation != null && endStation != null) {
      List<Station> route =
          RouteService.findShortestRoute(startStation!, endStation!);
      String routeText = route.map((station) => station.name).join(' --> ');

      int routeId = _nextRouteId++;
      _routes[routeId] = RouteData(
        routeText: routeText,
        polylinePoints: route
            .map((station) => LatLng(station.latitude, station.longitude))
            .toList(),
        isTrainMoving: false,
        trainPositions: List.generate(lokoAdet + vagonAdet,
            (_) => LatLng(route[0].latitude, route[0].longitude)),
        trainProgress: List.generate(lokoAdet + vagonAdet, (_) => 0.0),
        trainPolylineIndex: List.generate(lokoAdet + vagonAdet, (_) => 0),
        selectedLoko: selectedLoko, // Seçilen lokomotif
        selectedVagon: selectedVagon, // Seçilen vagon
        lokoAdet: lokoAdet, // Lokomotif sayısı
        vagonAdet: vagonAdet, // Vagon sayısı
      );

      // Trenlerin başlangıç konumlarını ayarla
      double offsetDistance = 40.0;
      for (int i = 0; i < lokoAdet + vagonAdet; i++) {
        if (i == 0) {
          _routes[routeId]!.trainPolylineIndex[i] = 0;
          _routes[routeId]!.trainProgress[i] = 0.0;
        } else {
          _routes[routeId]!.trainPolylineIndex[i] = 0;
          _routes[routeId]!.trainProgress[i] = -i *
              (offsetDistance /
                  _haversineDistance(
                    _routes[routeId]!.polylinePoints[0],
                    _routes[routeId]!.polylinePoints[1],
                  ));
        }
      }

      setState(() {
        routePolylinePoints.add(_routes[routeId]!.polylinePoints);
        routePolylines.add({
          Polyline(
            polylineId: PolylineId('route_$routeId'),
            points: _routes[routeId]!.polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        });
      });

      if (route.isNotEmpty) {
        await _updateMap();
      }
    }
  }

  Future<void> _updateMap() async {
    polylines.clear();
    markers.clear();

    for (var polylineSet in routePolylines) {
      polylines.addAll(polylineSet);
    }
    for (var markerSet in routeMarkers) {
      markers.addAll(markerSet);
    }

    final GoogleMapController controller = await _controller.future;
    final bounds = _boundsFromLatLngList(polylinePoints);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20.0));
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  double _haversineDistance(LatLng pos1, LatLng pos2) {
    const double R = 6371000;
    double lat1 = pos1.latitude * pi / 180;
    double lat2 = pos2.latitude * pi / 180;
    double dLat = lat2 - lat1;
    double dLng = (pos2.longitude - pos1.longitude) * pi / 180;

    double a =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLng / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  void _startTrainAnimation(int routeId) {
    if (_routes[routeId] != null &&
        _routes[routeId]!.polylinePoints.isNotEmpty) {
      setState(() {
        _routes[routeId]!.isTrainMoving = true;
      });

      if (!_routes[routeId]!._isAnimationInitialized) {
        _routes[routeId]!.initializeAnimation(this);
      }

      _routes[routeId]!.animationTimer = Timer.periodic(
        const Duration(milliseconds: 30),
        (timer) {
          bool allTrainsArrived = true;

          for (int i = 0; i < lokoAdet + vagonAdet; i++) {
            if (_routes[routeId]!.trainPolylineIndex[i] <
                _routes[routeId]!.polylinePoints.length - 1) {
              double speed = 0.003;
              _routes[routeId]!.trainProgress[i] += speed;

              if (_routes[routeId]!.trainProgress[i] >= 1.0) {
                _routes[routeId]!.trainPolylineIndex[i]++;
                _routes[routeId]!.trainProgress[i] = 0.0;
              }

              LatLng start = _routes[routeId]!
                  .polylinePoints[_routes[routeId]!.trainPolylineIndex[i]];
              LatLng end = _routes[routeId]!
                  .polylinePoints[_routes[routeId]!.trainPolylineIndex[i] + 1];

              _routes[routeId]!.trainPositions[i] = LatLng(
                start.latitude +
                    (end.latitude - start.latitude) *
                        _routes[routeId]!.trainProgress[i],
                start.longitude +
                    (end.longitude - start.longitude) *
                        _routes[routeId]!.trainProgress[i],
              );

              if (_routes[routeId]!.trainPolylineIndex[i] >
                  _routes[routeId]!.currentStationIndex) {
                _routes[routeId]!.currentStationIndex =
                    _routes[routeId]!.trainPolylineIndex[i];
              }

              allTrainsArrived = false;
            } else if (_routes[routeId]!.trainPolylineIndex[i] ==
                _routes[routeId]!.polylinePoints.length - 1) {
              _routes[routeId]!.currentStationIndex =
                  _routes[routeId]!.polylinePoints.length - 1;
            }
          }

          if (allTrainsArrived) {
            timer.cancel();
            setState(() {
              _routes[routeId]!.isTrainMoving = false;
            });
          }

          _trainPositionStreamController.add(_routes[routeId]!.trainPositions);
          setState(() {});
        },
      );
    }
  }
  // void _pauseTrainAnimation() {
  //   _animationController.stop(); // Animasyonu durdur
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Meydan Train Manager')),
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
                        fit: BoxFit.scaleDown, // metni ölçeklendirir
                        child: Text(
                          'Kasa: $kasa',
                          style: const TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                      print("deppo tıklandı");
                    },
                    child: Container(
                      margin: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.amber,
                      ),
                      child: const Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown, //  metni ölçeklendirir
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
            flex: 8,
            child: Container(
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
                              _currentRouteId =
                                  routeId; // Seçilen rota ID'sini güncelle
                            });
                            print("seçilen tren");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.grey[400],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IntrinsicWidth(
                                  child: Text(routeData.currentTime),
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
                                          return Row(
                                            children: [
                                              Text(
                                                station,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: index ==
                                                          routeData
                                                              .currentStationIndex
                                                      ? Colors.red
                                                      : Colors.black,
                                                ),
                                              ),
                                              if (index <
                                                  routeData.routeText
                                                          .split(' --> ')
                                                          .length -
                                                      1)
                                                const Text(
                                                  ' --> ',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
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
                                        if (_routes[routeId] != null) {
                                          if (_routes[routeId]!.isTrainMoving) {
                                            // Tren hareket halindeyse duraklat
                                            setState(() {
                                              _routes[routeId]!.isTrainMoving =
                                                  false;
                                            });
                                            _pauseTrainAnimation(
                                                routeId); // Tren animasyonunu duraklat
                                          } else {
                                            // Tren duraklatılmışsa hareket ettir
                                            setState(() {
                                              DateTime now = DateTime.now();
                                              String formattedTime =
                                                  "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
                                              _routes[routeId]!.currentTime =
                                                  formattedTime;
                                              _routes[routeId]!.isTrainMoving =
                                                  true;
                                            });
                                            _startTrainAnimation(
                                                routeId); // Tren animasyonunu başlat
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _routes[routeId]!.isTrainMoving
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: Colors.white,
                                          ),
                                        ],
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
                                            routeData
                                                .disposeAnimation(); // Animasyonu temizle
                                            _routes.remove(routeId);
                                            routePolylinePoints
                                                .removeAt(routeId);
                                            routePolylines.removeAt(routeId);
                                            if (_currentRouteId == routeId) {
                                              _currentRouteId =
                                                  -1; // Seçilen rota silinirse sıfırla
                                            }
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
          ),
          Expanded(
            flex: 1,
            child: Container(
              height: 200, // Container yüksekliğini ayarlayın
              width: 1800,
              child: Center(
                child: ClipRRect(
                  child: Stack(
                    children: [
                      // Arka plan animasyonu (ağaç ikonları)
                      ClipRect(
                        child: Builder(
                          builder: (context) {
                            // Rota yoksa veya _currentRouteId geçersizse boş widget döndür
                            if (_currentRouteId == -1 ||
                                !_routes.containsKey(_currentRouteId)) {
                              return const SizedBox();
                            }

                            // animationController null ise boş widget döndür
                            if (_routes[_currentRouteId]!.animationController ==
                                null) {
                              return const SizedBox();
                            }

                            return AnimatedBuilder(
                              animation: _routes[_currentRouteId]!
                                  .animationController!,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    -_routes[_currentRouteId]!
                                            .animationController!
                                            .value *
                                        MediaQuery.of(context).size.width,
                                    0,
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: List.generate(25, (index) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 100),
                                          child: Icon(
                                            Icons.park,
                                            size: 20,
                                            color: Colors.green,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // GridView.builder
                      if (_currentRouteId != -1 &&
                          _routes[_currentRouteId] != null)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 35,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _routes[_currentRouteId]!.lokoAdet +
                              _routes[_currentRouteId]!.vagonAdet,
                          itemBuilder: (context, index) {
                            final routeData = _routes[_currentRouteId]!;
                            return SizedBox(
                              width: 100,
                              height: 100, // Sabit yükseklik
                              child: index < routeData.vagonAdet
                                  ? (routeData.selectedVagon != null
                                      ? Image.asset(
                                          routeData.selectedVagon!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.contain,
                                        )
                                      : const Icon(Icons.train,
                                          size: 24, color: Colors.blue))
                                  : (routeData.selectedLoko != null
                                      ? Image.asset(
                                          routeData.selectedLoko!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.contain,
                                        )
                                      : const Icon(Icons.train,
                                          size: 24, color: Colors.blue)),
                            );
                          },
                        )
                      else
                        const Center(
                          child: Text('Lütfen bir rota seçin.'),
                        ),
                    ],
                  ),
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
                    print("tren ekleme butonu tıklandı");
                  },
                  child: const Icon(Icons.add),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.amber,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          routePolylines: routePolylines,
                          routePolylinePoints: routePolylinePoints,
                          lokoIcons: lokoIcons,
                          vagonIcons: vagonIcons,
                          trainPositionStream:
                              _trainPositionStreamController.stream,
                          routeMarkers: routeMarkers,
                          lokoAdet: lokoAdet,
                          vagonAdet: vagonAdet,
                          markers: markers,
                          getTrainIcon: _getTrainIcon,
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

class RouteData {
  final String routeText;
  final List<LatLng> polylinePoints;
  bool isTrainMoving;
  List<LatLng> trainPositions;
  List<double> trainProgress;
  List<int> trainPolylineIndex;
  int currentStationIndex;
  String currentTime;
  String? selectedLoko;
  String? selectedVagon;
  int lokoAdet;
  int vagonAdet;
  AnimationController? animationController; // Nullable yapın
  late Timer animationTimer;
  bool _isAnimationInitialized = false;

  RouteData({
    required this.routeText,
    required this.polylinePoints,
    required this.isTrainMoving,
    required this.trainPositions,
    required this.trainProgress,
    required this.trainPolylineIndex,
    this.currentStationIndex = 0,
    this.currentTime = "00:00",
    this.selectedLoko,
    this.selectedVagon,
    this.lokoAdet = 0,
    this.vagonAdet = 0,
  });

  void initializeAnimation(TickerProvider vsync) {
    if (!_isAnimationInitialized) {
      animationController = AnimationController(
        vsync: vsync,
        duration: const Duration(seconds: 5),
      )..repeat();
      _isAnimationInitialized = true;
    }
  }

  void disposeAnimation() {
    if (_isAnimationInitialized) {
      animationController?.dispose(); // Null kontrolü ile dispose et
      _isAnimationInitialized = false;
    }
    if (animationTimer.isActive) {
      animationTimer.cancel();
    }
  }
}
