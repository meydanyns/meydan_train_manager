import 'dart:async';
import 'dart:math'; // Import dart:math to use the pi constant
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'lokomotif.dart';
import 'vagon.dart';

class RouteData {
  final String routeText;
  final List<LatLng> polylinePoints;
  final List<Lokomotif> lokomotifler;
  final List<Vagon> vagonlar;
  bool isTrainMoving;
  List<LatLng> trainPositions;
  List<double> trainProgress;
  List<int> trainPolylineIndex;
  DateTime startTime;
  Timer? _animationTimer;
  set animationTimer(Timer? timer) => _animationTimer = timer;

  AnimationController? animationController;
  bool _isAnimationInitialized = false;
  bool isCoinAnimationActive = false;
  bool isTreeAnimationActive = false;
  bool isStationAnimationActive = false; // Bu satırı ekleyin
  bool wasStarted = false;
  bool isCompleted;
  bool get isLastStation => currentStationIndex >= polylinePoints.length - 1;
  String? currentTime;
  bool _isAnimating = false;

  // Removed redundant declaration of _animationTimer
  // Nullable ama başlangıç değeri var
  int currentStationIndex = 0;
  double speed = 1.0;
  double get scaledSpeed => speed * 0.001; // Hızı 0-1 aralığına ölçekle
  final VoidCallback? onUpdate;

  Stream<List<LatLng>> get positionStream => _positionController.stream;
  final StreamController<List<LatLng>> _positionController =
      StreamController<List<LatLng>>.broadcast(); // Broadcast yapın

  bool shouldShowAnimations = false;

  void resetPositions() {
    final totalVehicles = lokoAdet + vagonAdet;
    trainPositions = List.generate(totalVehicles, (_) => polylinePoints[0]);
    trainProgress = List.filled(totalVehicles, 0.0);
    trainPolylineIndex = List.filled(totalVehicles, 0);
    currentStationIndex = 0;
    isCoinAnimationActive = false;
    currentTime = "00:00"; // Saati sıfırla

    onUpdate?.call();
  }

  RouteData({
    required this.routeText,
    required this.polylinePoints,
    required List<Lokomotif> lokomotifler,
    required List<Vagon> vagonlar,
    this.isTrainMoving = false,
    required this.trainPositions,
    required this.trainProgress,
    required this.trainPolylineIndex,
    required this.onUpdate,
    required this.isCompleted,
    Timer? animationTimer,
  })  : lokomotifler = lokomotifler.map((l) => l.copyWith()).toList(),
        vagonlar = vagonlar.map((v) => v.copyWith()).toList(),
        startTime = DateTime.now(),
        _animationTimer = animationTimer; // <<< BURASI EKLENDİ

  // Removed redundant initialization of _positionController

  // Eksik metodların eklenmesi
  void updateStartTime() => startTime = DateTime.now();

  void updateCurrentStation(int newIndex) {
    // Son indeksi de dahil etmek için koşulu değiştir
    if (newIndex != currentStationIndex &&
        newIndex >= 0 &&
        newIndex < polylinePoints.length) {
      // <= length-1 yerine length
      currentStationIndex = newIndex;
      if (onUpdate != null) onUpdate!();
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

// RouteData sınıfında
  void updatePosition(int index) {
    final currentIndex = trainPolylineIndex[index];
    if (currentIndex >= polylinePoints.length - 1) return;

    final start = polylinePoints[currentIndex];
    final end = polylinePoints[currentIndex + 1];

    trainPositions[index] = LatLng(
      start.latitude + (end.latitude - start.latitude) * trainProgress[index],
      start.longitude +
          (end.longitude - start.longitude) * trainProgress[index],
    );

    // Tüm pozisyonları tek seferde gönder
    _positionController.add(List<LatLng>.from(trainPositions));
  }

  Timer? get currentAnimationTimer => _animationTimer;
  set currentAnimationTimer(Timer? timer) {
    _animationTimer?.cancel(); // Eski timer'ı temizle
    _animationTimer = timer;
  }

  void pauseAnimation() {
    _isAnimating = false;
    _animationTimer?.cancel();
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
  double get speedKmh {
    if (lokomotifler.isEmpty) return 0.0;

    double maxHiz = lokomotifler
        .map((loko) => loko.hiz)
        .fold(0.0, (max, hiz) => hiz > max ? hiz : max);

    // Yük etkisi (örnek: her 1000 TON için %5 yavaşlama)
    double totalLoad =
        vagonlar.fold(0, (sum, v) => sum + (v.kapasite * v.selectedCount));
    double loadFactor = (totalLoad / 1000) * 0.05;

    return maxHiz * (1 - loadFactor.clamp(0.0, 0.3)); // Max %30 yavaşlama
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

// RouteData içinde animationTimer'ı başlatma ve durdurma
  void checkArrival() {
    if (isLastStation) {
      stopAnimations();
      isTrainMoving = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationTimer?.cancel();
      });
    }
  }

  Timer? _clockTimer;

  void dispose() {
    _positionController.close();
  }

  void startAnimations({double speedKmh = 150.0}) {
    isCoinAnimationActive = true;
    isTreeAnimationActive = true;
    isStationAnimationActive = true;
    onUpdate?.call(); // State'i güncelle
    if (_isAnimating) return;
    _isAnimating = true;
  }

  void stopAnimations() {
    isCoinAnimationActive = false;
    isTreeAnimationActive = false;
    isStationAnimationActive = false;
    onUpdate?.call(); // State'i güncelle
  }

  void toggleAnimations(bool isMoving) =>
      isMoving ? startAnimations() : stopAnimations();

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
    isTrainMoving = false;
  }

  void completeRoute() {
    isCompleted = true;
    isTrainMoving = false;
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
    isTrainMoving = true;
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
    const double simulationSpeedMultiplier = 100.0;
    double totalDistance = 0;
    for (int i = 0; i < polylinePoints.length - 1; i++) {
      totalDistance +=
          calculateDistance(polylinePoints[i], polylinePoints[i + 1]);
    }

    double adjustedSpeed = speedKmh * simulationSpeedMultiplier;
    double speedMps = adjustedSpeed * 1000 / 3600;
    double totalTime = totalDistance / speedMps;

    _animationTimer?.cancel(); // Önceki timer'ı iptal et
    _animationTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      bool allTrainsArrived = true;
      double progressIncrement = (1 / totalTime) * 0.15;

      for (int i = 0; i < trainPositions.length; i++) {
        final currentIndex = trainPolylineIndex[i];
        final isLastSegment = currentIndex >= polylinePoints.length - 1;

        if (!isLastSegment) {
          trainProgress[i] += progressIncrement;
          allTrainsArrived = false;

          if (trainProgress[i] >= 1.0) {
            trainPolylineIndex[i]++;
            updateCurrentStation(trainPolylineIndex[i]);
            trainProgress[i] = 0.0;
          }
          updatePosition(i);
        } else {
          if (trainProgress[i] < 1.0) {
            trainProgress[i] += progressIncrement;
            allTrainsArrived = false;
          }
          trainPositions[i] = polylinePoints.last;
        }
      }

      if (allTrainsArrived) {
        timer.cancel();
        completeRoute();
        _positionController.add(trainPositions); // Son pozisyonu gönder
      }
    });
  }

  void resetRoute() {
    _animationTimer?.cancel();
    resetPositions();
    isCompleted = false;
    isTrainMoving = false;
    wasStarted = false;
    currentStationIndex = 0;
    startTime = DateTime.now();
    _positionController.add(trainPositions); // Resetlenmiş pozisyonları gönder
  }

  // Mesafe hesaplama fonksiyonunu buraya taşı
  static double calculateDistance(LatLng p1, LatLng p2) {
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
