import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  final List<Set<Polyline>> routePolylines;
  final List<List<LatLng>> routePolylinePoints;
  final List<BitmapDescriptor> lokoIcons;
  final List<BitmapDescriptor> vagonIcons;
  final Stream<List<LatLng>> trainPositionStream;
  final List<Set<Marker>> routeMarkers;
  final int lokoAdet;
  final int vagonAdet;
  final Set<Marker> markers;
  final Future<BitmapDescriptor> Function(String) getTrainIcon;

  const MapScreen({
    super.key,
    required this.routePolylines,
    required this.routePolylinePoints,
    required this.lokoIcons,
    required this.vagonIcons,
    required this.trainPositionStream,
    required this.routeMarkers,
    required this.lokoAdet,
    required this.vagonAdet,
    required this.markers,
    required this.getTrainIcon,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Harita')),
      body: StreamBuilder<List<LatLng>>(
        stream: widget.trainPositionStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Set<Marker> newMarkers = {};
            for (int i = 0; i < snapshot.data!.length; i++) {
              newMarkers.add(
                Marker(
                  markerId: MarkerId('train_$i'),
                  position: snapshot.data![i],
                  icon: i < widget.lokoAdet
                      ? widget.lokoIcons[i]
                      : widget.vagonIcons[i - widget.lokoAdet],
                ),
              );
            }

            return GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(39.9334, 32.8597), // Başlangıç konumu
                zoom: 7,
              ),
              markers: newMarkers,
              polylines: widget.routePolylines
                  .expand((polylineSet) => polylineSet)
                  .toSet(),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
