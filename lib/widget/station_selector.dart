import 'package:flutter/material.dart';
import '../models/station.dart';

class StationSelector extends StatelessWidget {
  final List<Station> stations;
  final Function(Station?) onStationSelected;
  final String hint;
  final Station? selectedStation;

  const StationSelector({
    super.key,
    required this.stations,
    required this.onStationSelected,
    required this.hint,
    this.selectedStation,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Station>(
      hint: Text(hint),
      value: selectedStation,
      onChanged: onStationSelected,
      items: stations.map((Station station) {
        return DropdownMenuItem<Station>(
          value: station,
          child: Text(station.name),
        );
      }).toList(),
    );
  }
}
