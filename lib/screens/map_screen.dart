import 'dart:math';
import 'package:flutter/material.dart';
import '../models/route_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  final Stream<List<LatLng>> combinedPositionStream;
  final List<Set<Polyline>> routePolylines;
  final Map<int, RouteData> routes;
  const MapScreen({
    Key? key,
    required this.combinedPositionStream,
    required this.routePolylines,
    required this.routes,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor? _redCircleIcon;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadRedCircleIcon();
    _initializePolylines();
  }

  void _initializePolylines() {
    _polylines = widget.routePolylines.expand((polySet) => polySet).toSet();
  }

  Set<Marker> _createMarkers(List<LatLng> positions) {
    return positions
        .asMap()
        .map((i, pos) => MapEntry(
              i,
              Marker(
                markerId: MarkerId('train_$i'),
                position: pos,
                icon: _redCircleIcon ?? BitmapDescriptor.defaultMarker,
                rotation: _calculateRotation(positions, i),
              ),
            ))
        .values
        .toSet();
  }

  double _calculateRotation(List<LatLng> positions, int index) {
    if (index == 0 || index >= positions.length) return 0;
    final previous = positions[index - 1];
    final current = positions[index];
    final latDiff = current.latitude - previous.latitude;
    final lngDiff = current.longitude - previous.longitude;
    return (atan2(lngDiff, latDiff) * 180 / pi) + 90;
  }

  Future<void> _loadRedCircleIcon() async {
    final icon = await _createCustomIcon();
    if (mounted) {
      setState(() => _redCircleIcon = icon);
    }
  }

  Future<BitmapDescriptor> _createCustomIcon() async {
    const iconSize = 24.0;
    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, const Rect.fromLTRB(0, 0, iconSize, iconSize));

    canvas.drawCircle(
      Offset(iconSize / 2, iconSize / 2),
      iconSize / 2 - 1,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(iconSize.toInt(), iconSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canlı Tren Takibi')),
      body: StreamBuilder<List<LatLng>>(
        stream: widget.combinedPositionStream,
        builder: (context, snapshot) {
          final positions = snapshot.data ?? [];
          final initialPosition = positions.isNotEmpty
              ? positions.first
              : const LatLng(39.4334, 35.1997);

          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 6.8,
            ),
            markers: _createMarkers(positions), // Doğrudan burada oluşturun
            polylines: _polylines,
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
    );
  }
}
