
import 'package:flutter/material.dart';
import 'package:tren/models/station.dart';
import 'package:tren/services/route_services.dart';
import 'package:tren/widget/station_selector.dart';

class TrainRequestDialog extends StatefulWidget {
  const TrainRequestDialog({super.key});

  @override
  _TrainRequestDialogState createState() => _TrainRequestDialogState();
}

class _TrainRequestDialogState extends State<TrainRequestDialog> {
  Station? startStation;
  Station? endStation;
  String? selectedLoko;
  String? selectedVagon;
  int lokoAdet = 0;
  int vagonAdet = 0;

  final List<String> lokoResimler = [
    'lib/assets/lokomotifler/loko.png',
    'lib/assets/lokomotifler/train4.png',
    'lib/assets/lokomotifler/lde11000.png',
    'lib/assets/lokomotifler/lde18000.png',
    'lib/assets/lokomotifler/lde22000.png',
    'lib/assets/lokomotifler/lde24000.png',
    'lib/assets/lokomotifler/lde33000.png',
    'lib/assets/lokomotifler/lde36000.png',
    'lib/assets/lokomotifler/le68000.png',
  ];

  final List<String> vagonResimler = [
    'lib/assets/vagonlar/vagon1.png',
    'lib/assets/vagonlar/vagon2.png',
    'lib/assets/vagonlar/vagon3.png',
    'lib/assets/vagonlar/vagon4.png',
  ];

  void _onStartStationSelected(Station? station) {
    setState(() {
      startStation = station;
    });
  }

  void _onEndStationSelected(Station? station) {
    setState(() {
      endStation = station;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tren Talep'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            StationSelector(
              stations: RouteService.graph.keys.toList(),
              onStationSelected: _onStartStationSelected,
              hint: 'Çıkış İstasyonu Seçin',
              selectedStation: startStation,
            ),
            const SizedBox(height: 10),
            StationSelector(
              stations: RouteService.graph.keys.toList(),
              onStationSelected: _onEndStationSelected,
              hint: 'Varış İstasyonu Seçin',
              selectedStation: endStation,
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              hint: const Text("Lokomotif Seç"),
              value: selectedLoko,
              isExpanded: true,
              items: lokoResimler.map((String filePath) {
                return DropdownMenuItem<String>(
                  value: filePath,
                  child: Row(
                    children: [
                      Image.asset(
                        filePath,
                        width: 100,
                        height: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        filePath.split('/').last.split('.').first,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedLoko = value;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              hint: const Text("Vagon Seç"),
              value: selectedVagon,
              isExpanded: true,
              items: vagonResimler.map((String filePath) {
                return DropdownMenuItem<String>(
                  value: filePath,
                  child: Row(
                    children: [
                      Image.asset(
                        filePath,
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        filePath.split('/').last.split('.').first,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedVagon = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Column(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          lokoAdet++;
                        });
                      },
                      child: const Icon(Icons.plus_one),
                    ),
                    Text("$lokoAdet"),
                    const Text("Lokomotif"),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          if (lokoAdet > 0) {
                            lokoAdet--;
                          }
                        });
                      },
                      child: const Icon(Icons.exposure_minus_1),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          vagonAdet++;
                        });
                      },
                      child: const Icon(Icons.plus_one),
                    ),
                    Text("$vagonAdet"),
                    const Text("Vagon"),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          if (vagonAdet > 0) {
                            vagonAdet--;
                          }
                        });
                      },
                      child: const Icon(Icons.exposure_minus_1),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            if (startStation != null &&
                endStation != null &&
                selectedLoko != null &&
                selectedVagon != null) {
              Navigator.of(context).pop({
                'startStation': startStation,
                'endStation': endStation,
                'selectedLoko': selectedLoko,
                'selectedVagon': selectedVagon,
                'lokoAdet': lokoAdet,
                'vagonAdet': vagonAdet,
              });
              print(
                "Vagon Resmi Boyutu: ${Image.asset(selectedVagon!).width} x ${Image.asset(selectedVagon!).height}",
              );
              print(
                "Lokomotif Resmi Boyutu: ${Image.asset(selectedLoko!).width} x ${Image.asset(selectedLoko!).height}",
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
              );
            }
          },
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}
