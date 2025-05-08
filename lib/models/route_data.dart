import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'lokomotif.dart';
import 'vagon.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'vehicle_type.dart';

class VehiclePosition {
  final VehicleType type;
  final LatLng position;

  VehiclePosition({
    required this.type,
    required this.position,
  });
}

class RouteData {
  final String routeText;
  final List<LatLng> polylinePoints;
  final List<Lokomotif> lokomotifler;
  final List<Vagon> vagonlar;
  final List<String> markerIds = [];
  final StreamController<List<LatLng>> _positionController =
      StreamController<List<LatLng>>.broadcast();
  Stream<List<LatLng>> get positionStream => _positionController.stream;

  // VehiclePositionController hatası için
  final StreamController<List<VehiclePosition>> vehiclePositionController =
      StreamController<List<VehiclePosition>>.broadcast();

  final StreamController<bool> _stateController =
      StreamController<bool>.broadcast();
  Stream<bool> get stateStream => _stateController.stream;
  // Değişken tanımları
  List<LatLng> lokoPositions = [];
  List<LatLng> vagonPositions = [];

  List<LatLng> trainPositions;
  List<double> trainProgress;
  List<int> trainPolylineIndex;
  DateTime startTime;
  Timer? _animationTimer;

  List<LatLng> _lastKnownPositions = []; // Son bilinen pozisyonlar

  bool isActive = false; // Yeni eklenen aktiflik durumu
  bool _isTrainMoving = false;
  bool get isTrainMoving => _isTrainMoving;
  AnimationController? animationController;
  bool _isAnimationInitialized = false;
  bool isCoinAnimationActive = false;
  bool isTreeAnimationActive = false;
  bool isStationAnimationActive = false;
  bool wasStarted = false;
  bool isCompleted;
  int currentStationIndex = 0;
  double speed = 1.0;
  final VoidCallback? onUpdate;
  String? currentTime;
  final ValueNotifier<int> currentStationNotifier = ValueNotifier(0);

  static const double vehicleSpacing = 0.003; // Vagonlar arası mesafe
  static const double lokoSpacing = 0.005;
  static const double initialDelay = 0.02;

  // Getter'lar
  Timer? get animationTimer => _animationTimer;
  set animationTimer(Timer? timer) {
    _animationTimer?.cancel();
    _animationTimer = timer;
  }

  bool get isLastStation => currentStationIndex >= polylinePoints.length - 1;

  double progressIncrement = 0.0; // Eklendi

  List<VehiclePosition> get vehiclePositions {
    final List<VehiclePosition> vehicles = [];

    // Lokomotifleri ekle
    for (int i = 0; i < lokoAdet; i++) {
      if (i < trainPositions.length) {
        vehicles.add(VehiclePosition(
          type: VehicleType.lokomotif,
          position: trainPositions[i],
        ));
      }
    }

    // Vagonları ekle
    for (int i = lokoAdet; i < trainPositions.length; i++) {
      vehicles.add(VehiclePosition(
        type: VehicleType.vagon,
        position: trainPositions[i],
      ));
    }

    return vehicles;
  }

  // Sabitler
  static const double meterToLatLng = 0.00001;
  static const double spacingMeters = 50;

  RouteData({
    required this.routeText,
    required this.polylinePoints,
    required List<Lokomotif> lokomotifler,
    required List<Vagon> vagonlar,
    required this.trainPositions,
    required this.trainProgress,
    required this.trainPolylineIndex,
    required this.onUpdate,
    required this.isCompleted,
    // animationTimer parametresini kaldır
  })  : lokomotifler = lokomotifler.map((l) => l.copyWith()).toList(),
        vagonlar = vagonlar.map((v) => v.copyWith()).toList(),
        startTime = DateTime.now(),
        _isTrainMoving = false;

  void resetPositions() {
    final totalVehicles = lokoAdet + vagonAdet;
    trainPositions = List.generate(totalVehicles, (_) => polylinePoints[0]);
    trainProgress = List.filled(totalVehicles, 0.0);
    trainPolylineIndex = List.filled(totalVehicles, 0);
    currentStationIndex = 0;
    isCoinAnimationActive = false;
    currentTime = "00:00";
    onUpdate?.call();
  }

  void updatePositionStream(List<LatLng> positions) {
    if (_positionController.isClosed) return;
    _positionController.add(positions);
  }

  // Eksik metodların eklenmesi
  void updateStartTime() => startTime = DateTime.now();

  void updateCurrentStation(int newIndex) {
    if (newIndex != currentStationIndex && newIndex < polylinePoints.length) {
      currentStationIndex = newIndex;
      if (onUpdate != null) onUpdate!(); // UI'ı yenile
    }
  }

  Set<Polyline> get polylines {
    return {
      Polyline(
        polylineId: PolylineId(routeText),
        points: polylinePoints,
        color: Colors.blue,
        width: 3,
      )
    };
  }

  Set<Marker> get markers {
    return trainPositions
        .map((pos) => Marker(
              markerId: MarkerId(pos.toString()),
              position: pos,
            ))
        .toSet();
  }

  void startRouteAnimations() {
    isTreeAnimationActive = true;
    isCoinAnimationActive = true;
    isStationAnimationActive = true;
    if (onUpdate != null) onUpdate!();
  }

  void stopRouteAnimations() {
    isTreeAnimationActive = false;
    isCoinAnimationActive = false;
    isStationAnimationActive = false;
    if (onUpdate != null) onUpdate!();
  }

// route_data.dart dosyasına ekleyin
  void updatePositions() {
    if (!isActive) return;

    // Konum güncelleme mantığı
    for (int i = 0; i < trainProgress.length; i++) {
      trainPositions[i] = getPositionAlongRoute(trainProgress[i]);
    }
    _positionController.add(trainPositions);
  }

  // Private yerine public method yapın (alt çizgiyi kaldırın)
// Güncellenmiş getPositionAlongRoute metodu
  LatLng getPositionAlongRoute(double progress) {
    final path = polylinePoints;
    if (path.isEmpty) return const LatLng(0, 0);

    progress = progress.clamp(0.0, 1.0);
    final double length = path.length.toDouble();
    final double target = progress * (length - 1);

    final int index = target.floor().clamp(0, path.length - 2);
    final double segmentProgress = target - index;

    final start = path[index];
    final end = path[index + 1];

    return LatLng(
      start.latitude + (end.latitude - start.latitude) * segmentProgress,
      start.longitude + (end.longitude - start.longitude) * segmentProgress,
    );
  }

// Kullanılmayan metodlar KALDIRILDI

// RouteData sınıfına bu metodu ekleyin
  LatLng getPositionForVehicle(int vehicleIndex) {
    const double spacing = 50.0; // 50 metre ara
    return getPositionAlongRoute(
      trainProgress[0], // İlk lokomotifin progresi
    );
  }

  Timer? get currentAnimationTimer => _animationTimer;
  set currentAnimationTimer(Timer? timer) {
    _animationTimer?.cancel(); // Eski timer'ı temizle
    _animationTimer = timer;
  }

  void resumeAnimations() {
    // Diğer animasyon kontrolleri
  }

  void resetWithAnimation() {
    trainProgress = List.filled(trainProgress.length, 0.0);
    trainPolylineIndex = List.filled(trainPolylineIndex.length, 0);
    trainPositions = List.generate(
      trainPositions.length,
      (_) => polylinePoints.first,
    );
    currentStationIndex = 0;
    startAnimations(); // Reset sırasında animasyonları yeniden başlat
  }

  int get lokoAdet => lokomotifler.fold(0, (sum, l) => sum + l.selectedCount);
  int get vagonAdet => vagonlar.fold(0, (sum, v) => sum + v.selectedCount);

// RouteData içinde speed hesaplaması
// Lokomotif bazlı hız hesaplama (km/h cinsinden)
  // RouteData içinde hız hesaplamasını iyileştirme
  double get speedKmh {
    if (lokomotifler.isEmpty) return 0.0;

    double totalWeight = vagonlar.fold(0.0, (sum, v) => sum + v.kapasite);
    double speedReduction =
        totalWeight * 0.0005; // Her 1000 ton için %0.5 hız kaybı

    return lokomotifler.map((l) => l.hiz).reduce(max) * (1 - speedReduction);
  }

// Gerçek zamanlı hız bilgisi için
  String get formattedSpeed => '${speedKmh.toStringAsFixed(1)} km/h';

// Lokomotiflerin toplam ağırlığını hesapla ve sefer sonunda kazanılacak parayı hesapla
  int calculateEarnings() {
    final totalLoad = vagonlar.fold(
        0, (sum, vagon) => sum + (vagon.kapasite * vagon.selectedCount));
    final distanceKm = totalDistance / 1000;

    // Mesafe x Yük x Sabit çarpan (0.1 gibi)
    return (distanceKm * totalLoad * 0.1).round();
  }

  List<LatLng> get visiblePositions {
    return _isTrainMoving ? trainPositions : _lastKnownPositions;
  }

//sadece bir rotanın animasyonunu başlatmak için
  void startAnimation() {
    if (_isTrainMoving) return;

    _isTrainMoving = true;
    _stateController.add(true);

    final totalDistance = this.totalDistance;
    final speed = speedKmh * 1000 / 3600;
    final totalTime = totalDistance / speed;

    // Hız çarpanını
    progressIncrement = (1 / totalTime) * 0.20;

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      bool allCompleted = true;

      // İlk lokomotifin hareketi
      if (trainProgress[0] < 1.0) {
        trainProgress[0] += progressIncrement;
        trainProgress[0] = trainProgress[0].clamp(0.0, 1.0);
        allCompleted = false;
      }

      // Diğer araçların kademeli hareketi
      for (int i = 1; i < trainProgress.length; i++) {
        double targetProgress = trainProgress[i - 1] - _getSpacingForVehicle(i);
        if (targetProgress > trainProgress[i]) {
          trainProgress[i] = targetProgress.clamp(0.0, 1.0);
          allCompleted = false;
        }
      }

      // Konumları güncelle
      for (int i = 0; i < trainPositions.length; i++) {
        trainPositions[i] = getPositionAlongRoute(trainProgress[i]);
      }

      _positionController.add([...trainPositions]);
      updateCurrentStationIndex();

      if (allCompleted) {
        timer.cancel();
        completeRoute();
      }
    });
  }

  double _getSpacingForVehicle(int index) {
    if (index < lokoAdet) {
      return lokoSpacing; // Lokomotifler arası daha fazla mesafe
    }
    return vehicleSpacing; // Vagonlar arası normal mesafe
  }

  void pauseAnimation() {
    if (!_isTrainMoving) return;

    // Son pozisyonları kaydet
    _lastKnownPositions = List.from(trainPositions);

    _isTrainMoving = false;
    _stateController.add(false);
    _animationTimer?.cancel();
    pauseAnimations();
  }

// RouteData içinde animationTimer'ı başlatma ve durdurma
  void checkArrival() {
    if (isLastStation) {
      stopAnimations();
      _isTrainMoving = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationTimer?.cancel();
      });
    }
  }

  Timer? _clockTimer;

  void dispose() {
    _stateController.close();
    _positionController.close();
    _animationTimer?.cancel();
  }

  void startAnimations() {
    if (_isTrainMoving) return;
    _isTrainMoving = true;
    _stateController.add(true);
  }

  void stopAnimations() {
    isCoinAnimationActive = false;
    isTreeAnimationActive = false;
    isStationAnimationActive = false;
    onUpdate?.call(); // State'i güncelle
  }

  void toggleAnimation() {
    if (_isTrainMoving) {
      pauseAnimation();
    } else {
      startAnimation();
    }
    // Durum değişikliğini tüm dinleyicilere bildir
    _stateController.add(_isTrainMoving);
    if (onUpdate != null) onUpdate!();
  }

  void initializeAnimation(TickerProvider vsync) {
    if (!_isAnimationInitialized) {
      animationController = AnimationController(
        vsync: vsync, // HomePage'den gelen TickerProvider
        duration: const Duration(seconds: 5),
      )..repeat();
      _isAnimationInitialized = true;
    }
  }

  void disposeAnimation() {
    _clockTimer?.cancel();
    animationController?.dispose();
    _animationTimer?.cancel();
    _positionController.close();
    _isAnimationInitialized = false;
    _isAnimationInitialized = false;
  }

// RouteData sınıfına ekleyin
  void pauseAnimations() {
    isCoinAnimationActive = false;
    isTreeAnimationActive = false;
    isStationAnimationActive = false;
    onUpdate?.call();
  }

  // Yeni eklenen pause/resume fonksiyonları
  void pause() {
    _animationTimer?.cancel();
    _isTrainMoving = false;
  }

  // route_data.dart içinde

  // RouteData içinde updateCurrentStationIndex metodunu güncelleyin
  void updateCurrentStationIndex() {
    if (trainProgress.isEmpty) return;

    double progress = trainProgress[0];
    int newIndex = (progress * (polylinePoints.length - 1)).floor();
    newIndex = newIndex.clamp(0, polylinePoints.length - 1);

    if (newIndex != currentStationIndex) {
      currentStationIndex = newIndex;
      currentStationNotifier.value = newIndex;
      if (onUpdate != null) onUpdate!();
    }
  }

  void completeRoute() {
    isCompleted = true;
    _isTrainMoving = false;
    stopAnimations();

    final earnings = calculateEarnings();
    debugPrint('Kazanç: $earnings TL');

    // Kasa güncellemesi için callback
    if (onUpdate != null) {
      onUpdate!(); // Bu, main.dart'daki setState'i tetikleyecek
    }

    // 5 saniye bekleme süresi
    Timer(const Duration(seconds: 5), () {
      resetRoute();
      if (onUpdate != null) onUpdate!();
    });
  }

  void resume({double speedKmh = 250.0}) {
    if (isCompleted || isTrainMoving) return;

    // Yeni animasyon timer'ı oluştur
    _startAnimationTimer(speedKmh: speedKmh);
    _isTrainMoving = true;
  }

  double get totalDistance {
    double distance = 0;
    for (int i = 0; i < polylinePoints.length - 1; i++) {
      distance += calculateDistance(polylinePoints[i], polylinePoints[i + 1]);
    }
    return distance;
  }

  String get formattedDistance {
    return '${(totalDistance / 1000).toStringAsFixed(1)} km';
  }

  void _startAnimationTimer({double speedKmh = 250.0}) {
    const double simulationSpeedMultiplier = 150.0; // 100'den 150'ye çıkar
    double totalDistance = this.totalDistance;

    double adjustedSpeed = speedKmh * simulationSpeedMultiplier;
    double speedMps = adjustedSpeed * 1000 / 3600;
    double totalTime = totalDistance / speedMps;

    _animationTimer?.cancel();
    // Timer süresini 50ms'den 30ms'ye düşür
    _animationTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      // Kalan kodlar aynı...
    });
  }

  void resetRoute() {
    _animationTimer?.cancel();
    resetPositions();
    isCompleted = false;
    _isTrainMoving = false;
    wasStarted = false;
    currentStationIndex = 0;
    startTime = DateTime.now();
    _positionController.add(trainPositions);
  }

  double calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371e3;
    double phi1 = p1.latitude * pi / 180;
    double phi2 = p2.latitude * pi / 180;
    double deltaPhi = (p2.latitude - p1.latitude) * pi / 180;
    double deltaLambda = (p2.longitude - p1.longitude) * pi / 180;

    double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }
}
