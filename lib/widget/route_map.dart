import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteMap extends StatefulWidget {
  const RouteMap({super.key});

  @override
  RouteMapState createState() => RouteMapState();
}

class RouteMapState extends State<RouteMap> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(39.9334, 32.8597); // Ankara
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harita'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 6.0,
        ),
        markers: markers,
        polylines: polylines,
      ),
    );
  }
}
