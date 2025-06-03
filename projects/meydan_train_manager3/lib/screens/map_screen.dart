import 'dart:async';
import 'dart:math';

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_data.dart';
// Ensure this file contains the definition of VehicleType

class MapScreen extends StatefulWidget {
  final int activeRouteId;
  final Stream<List<LatLng>> combinedPositionStream;
  final List<Set<Polyline>> routePolylines;
  final Map<int, RouteData> routes;

  const MapScreen({
    super.key,
    required this.activeRouteId,
    required this.combinedPositionStream,
    required this.routePolylines,
    required this.routes,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late BitmapDescriptor _redCircleIcon;
  late BitmapDescriptor _blackCircleIcon;
  final Completer<GoogleMapController> _mapController = Completer();
  final Map<int, StreamSubscription<List<LatLng>>> _routeSubscriptions = {};

  final Map<int, List<LatLng>> _routePositions = {};

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _initRouteSubscriptions();
  }

  @override
  void dispose() {
    _routeSubscriptions.forEach((_, sub) => sub.cancel());
    super.dispose();
  }

  void _initRouteSubscriptions() {
    widget.routes.forEach((routeId, route) {
      // Her rota için ayrı subscription
      _routeSubscriptions[routeId] = route.positionStream.listen((positions) {
        _routePositions[routeId] = positions;
        setState(() {});
      });

      // Başlangıç pozisyonlarını kaydet
      _routePositions[routeId] = route.visiblePositions;
    });
  }

  Future<void> _loadIcons() async {
    _redCircleIcon = await _createVehicleIcon(
        color: Colors.red, size: 10.0 // 15'ten 10'a düşürüldü
        );

    _blackCircleIcon = await _createVehicleIcon(
        color: Colors.black87, size: 8.0 // 12'den 8'e düşürüldü
        );

    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createVehicleIcon(
      {required Color color, required double size}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png) ?? ByteData(0);

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  Set<Polyline> _getAllPolylines() {
    return widget.routes.values
        .map((route) => Polyline(
              polylineId: PolylineId(route.routeText),
              points: route.polylinePoints,
              color: Colors.blue,
              width: 3,
            ))
        .toSet();
  }

// map_screen.dart
  Set<Marker> _getAllMarkers() {
    final markers = <Marker>{};

    widget.routes.forEach((routeId, route) {
      final positions = _routePositions[routeId] ?? [];
      final vehicles = route.vehiclePositions;

      for (int i = 0; i < positions.length; i++) {
        markers.add(Marker(
          markerId: MarkerId('vehicle_${routeId}_$i'),
          position: positions[i],
          icon: i < route.lokoAdet ? _redCircleIcon : _blackCircleIcon,
          rotation: _calculateRotation(route.trainPositions),
        ));
      }
    });

    return markers;
  }

  double _calculateRotation(List<LatLng> positions) {
    if (positions.length < 2) return 0;

    final LatLng last = positions.last;
    final LatLng prev = positions[positions.length - 2];

    return atan2(
          last.longitude - prev.longitude,
          last.latitude - prev.latitude,
        ) *
        180 /
        pi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canlı Tren Takibi')),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: const CameraPosition(
          target: LatLng(39.236809, 35.090478),
          zoom: 6.9,
        ),
        polylines: widget.routePolylines.expand((set) => set).toSet(),
        markers: _getAllMarkers(),
        onMapCreated: (controller) => _mapController.complete(controller),
        myLocationEnabled: true,
      ),
    );
  }
}

// import 'dart:math';
// import 'package:flutter/material.dart';
// import '../models/route_data.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'dart:async';
// import 'dart:ui' as ui;
// import 'dart:typed_data';

// class MapScreen extends StatefulWidget {
//   final Stream<List<LatLng>> combinedPositionStream;
//   final List<Set<Polyline>> routePolylines;
//   final Map<int, RouteData> routes;

//   const MapScreen({
//     Key? key,
//     required this.combinedPositionStream,
//     required this.routePolylines,
//     required this.routes,
//   }) : super(key: key);

//   @override
//   _MapScreenState createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   Completer<GoogleMapController> _controller = Completer();
//   BitmapDescriptor? _redCircleIcon;
//   BitmapDescriptor? _blackCircleIcon;
//   Set<Polyline> _polylines = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadIcons();
//     _initializePolylines();
//   }

//   Future<void> _loadIcons() async {
//     _redCircleIcon = await _createCustomIcon(Colors.red);
//     _blackCircleIcon = await _createCustomIcon(Colors.black);
//     if (mounted) setState(() {});
//   }

//   void _initializePolylines() {
//     _polylines = widget.routePolylines.expand((polySet) => polySet).toSet();
//   }

//   Set<Marker> _createRouteMarkers() {
//     final markers = <Marker>{};

//     widget.routes.forEach((routeId, route) {
//       if (route.isTrainMoving) {
//         route.trainPositions.asMap().forEach((index, position) {
//           markers.add(Marker(
//             markerId: MarkerId('train_${routeId}_$index'),
//             position: position,
//             icon: index < route.lokoAdet ? _redCircleIcon! : _blackCircleIcon!,
//           ));
//         });
//       }
//     });

//     return markers;
//   }

//   Set<Polyline> _createRoutePolylines() {
//     final polylines = <Polyline>{};

//     widget.routes.forEach((routeId, route) {
//       polylines.add(Polyline(
//         polylineId: PolylineId('route_$routeId'),
//         points: route.polylinePoints,
//         color: Colors.blue,
//         width: 3,
//       ));
//     });

//     return polylines;
//   }

//   Future<BitmapDescriptor> _createCustomIcon(Color color,
//       {double size = 24.0}) async {
//     final ui.PictureRecorder recorder = ui.PictureRecorder();
//     final Canvas canvas = Canvas(recorder);
//     final Paint paint = Paint()..color = color;

//     canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
//     final ui.Image image =
//         await recorder.endRecording().toImage(size.toInt(), size.toInt());
//     final ByteData? byteData =
//         await image.toByteData(format: ui.ImageByteFormat.png);

//     return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Canlı Tren Takibi')),
//       body: StreamBuilder<List<LatLng>>(
//         stream: widget.combinedPositionStream,
//         builder: (context, snapshot) {
//           return GoogleMap(
//             mapType: MapType.normal,
//             initialCameraPosition: const CameraPosition(
//               target: LatLng(39.236809, 35.090478),
//               zoom: 6.9,
//             ),
//             markers: _createRouteMarkers(),
//             polylines: _createRoutePolylines(),
//             onMapCreated: (controller) => _controller.complete(controller),
//             myLocationEnabled: true,
//           );
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
// import 'dart:math';
// import 'package:flutter/material.dart';
// import '../models/route_data.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'dart:async';
// import 'dart:ui' as ui;
// import 'dart:typed_data';

// class MapScreen extends StatefulWidget {
//   final Stream<List<LatLng>> combinedPositionStream;
//   final List<Set<Polyline>> routePolylines;
//   final Map<int, RouteData> routes;

//   const MapScreen({
//     Key? key,
//     required this.combinedPositionStream,
//     required this.routePolylines,
//     required this.routes,
//   }) : super(key: key);

//   @override
//   _MapScreenState createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   Completer<GoogleMapController> _controller = Completer();
//   BitmapDescriptor? _redCircleIcon;
//   BitmapDescriptor? _blackCircleIcon;
//   Set<Polyline> _polylines = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadIcons();
//     _initializePolylines();
//   }

//   Future<void> _loadIcons() async {
//     _redCircleIcon = await _createCustomIcon(Colors.red);
//     _blackCircleIcon = await _createCustomIcon(Colors.black);
//     if (mounted) setState(() {});
//   }

//   void _initializePolylines() {
//     _polylines = widget.routePolylines.expand((polySet) => polySet).toSet();
//   }

//   Set<Marker> _createRouteMarkers() {
//     final markers = <Marker>{};

//     widget.routes.forEach((routeId, route) {
//       if (route.isTrainMoving) {
//         route.trainPositions.asMap().forEach((index, position) {
//           markers.add(Marker(
//             markerId: MarkerId('train_${routeId}_$index'),
//             position: position,
//             icon: index < route.lokoAdet ? _redCircleIcon! : _blackCircleIcon!,
//           ));
//         });
//       }
//     });

//     return markers;
//   }

//   Set<Polyline> _createRoutePolylines() {
//     final polylines = <Polyline>{};

//     widget.routes.forEach((routeId, route) {
//       polylines.add(Polyline(
//         polylineId: PolylineId('route_$routeId'),
//         points: route.polylinePoints,
//         color: Colors.blue,
//         width: 3,
//       ));
//     });

//     return polylines;
//   }

//   Future<BitmapDescriptor> _createCustomIcon(Color color,
//       {double size = 24.0}) async {
//     final ui.PictureRecorder recorder = ui.PictureRecorder();
//     final Canvas canvas = Canvas(recorder);
//     final Paint paint = Paint()..color = color;

//     canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
//     final ui.Image image =
//         await recorder.endRecording().toImage(size.toInt(), size.toInt());
//     final ByteData? byteData =
//         await image.toByteData(format: ui.ImageByteFormat.png);

//     return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Canlı Tren Takibi')),
//       body: StreamBuilder<List<LatLng>>(
//         stream: widget.combinedPositionStream,
//         builder: (context, snapshot) {
//           return GoogleMap(
//             mapType: MapType.normal,
//             initialCameraPosition: const CameraPosition(
//               target: LatLng(39.236809, 35.090478),
//               zoom: 6.9,
//             ),
//             markers: _createRouteMarkers(),
//             polylines: _createRoutePolylines(),
//             onMapCreated: (controller) => _controller.complete(controller),
//             myLocationEnabled: true,
//           );
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
