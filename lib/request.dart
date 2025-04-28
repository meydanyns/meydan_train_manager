import 'package:flutter/material.dart';
import 'package:tren/models/lokomotif.dart';
import 'package:tren/models/station.dart';
import 'package:tren/models/vagon.dart';
import 'package:tren/services/route_services.dart';
import 'package:dropdown_search/dropdown_search.dart';

class TrainRequestDialog extends StatefulWidget {
  const TrainRequestDialog({super.key});

  @override
  _TrainRequestDialogState createState() => _TrainRequestDialogState();
}

class _TrainRequestDialogState extends State<TrainRequestDialog> {
  Station? startStation;
  Station? endStation;
  List<LokomotifSelection> lokomotifSelections = [];
  List<VagonSelection> vagonSelections = [];

  @override
  void initState() {
    super.initState();
    // Mevcut listelerin kopyalarını oluştur
    lokomotifSelections = lokoListesi
        .map((loko) => LokomotifSelection(
            loko: loko.copyWith(), selectedCount: 0)) // ✅ copyWith
        .toList();
    vagonSelections = vagonListesi
        .map((vagon) => VagonSelection(
            vagon: vagon.copyWith(), selectedCount: 0)) // ✅ copyWith
        .toList();
  }

  int get totalGuc => lokomotifSelections.fold(0,
      (sum, selection) => sum + (selection.selectedCount * selection.loko.guc));

  int get totalKapasite => vagonSelections.fold(
      0,
      (sum, selection) =>
          sum + (selection.selectedCount * selection.vagon.kapasite));

  Widget buildStationSelector({
    required String hint,
    required Station? selectedStation,
    required Function(Station?) onStationSelected,
  }) {
    return DropdownSearch<Station>(
      items: RouteService.graph.keys.toList(),
      selectedItem: selectedStation,
      onChanged: onStationSelected,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(hintText: "İstasyon Ara..."),
        ),
        itemBuilder: (context, item, isSelected) => ListTile(
          title: Text(item.name),
        ),
      ),
      compareFn: (item1, item2) => item1.name == item2.name,
      itemAsString: (station) => station.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tren Talep'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // StationSelector(
            //   stations: RouteService.graph.keys.toList(),
            //   onStationSelected: (station) =>
            //       setState(() => startStation = station),
            //   hint: 'Çıkış İstasyonu Seçin',
            //   selectedStation: startStation,
            // ),
            // StationSelector(
            //   stations: RouteService.graph.keys.toList(),
            //   onStationSelected: (station) =>
            //       setState(() => endStation = station),
            //   hint: 'Varış İstasyonu Seçin',
            //   selectedStation: endStation,
            // ),
            buildStationSelector(
              hint: 'Çıkış İstasyonu Seçin',
              onStationSelected: (station) =>
                  setState(() => startStation = station),
              selectedStation: startStation,
            ),
            SizedBox(height: 20),
            buildStationSelector(
              hint: 'Varış İstasyonu Seçin',
              selectedStation: endStation,
              onStationSelected: (station) =>
                  setState(() => endStation = station),
            ),
            const SizedBox(height: 20),
            const Text('Lokomotif Seçimi', style: TextStyle(fontSize: 18)),
            ...lokomotifSelections.map(_buildLokomotifRow),
            Text('Toplam Güç: $totalGuc HP',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Vagon Seçimi', style: TextStyle(fontSize: 18)),
            ...vagonSelections.map(_buildVagonRow),
            Text('Toplam Kapasite: $totalKapasite TON',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () => _onSubmit(),
          child: const Text('Tamam'),
        )
      ],
    );
  }

  Widget _buildLokomotifRow(LokomotifSelection selection) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Image.asset(selection.loko.resim, width: 60, height: 60),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(selection.loko.tip,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Stok: ${selection.loko.adet}'),
              Text('Güç: ${selection.loko.guc} HP'),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _updateLokomotifCount(selection, -1),
          ),
          Text('${selection.selectedCount}',
              style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _updateLokomotifCount(selection, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildVagonRow(VagonSelection selection) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Image.asset(selection.vagon.resim, width: 60, height: 60),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(selection.vagon.tip,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Stok: ${selection.vagon.adet}'),
              Text('Kapasite: ${selection.vagon.kapasite} TON'),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _updateVagonCount(selection, -1),
          ),
          Text('${selection.selectedCount}',
              style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _updateVagonCount(selection, 1),
          ),
        ],
      ),
    );
  }

  void _updateLokomotifCount(LokomotifSelection selection, int delta) {
    final newCount = selection.selectedCount + delta;

    // Stok kontrolü (adet değişmez!)
    if (newCount >= 0 && newCount <= selection.loko.adet) {
      setState(() {
        selection.selectedCount = newCount; // Sadece selectedCount güncellenir
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stokta yeterli lokomotif yok!")),
      );
    }
  }

  void _updateVagonCount(VagonSelection selection, int delta) {
    final newCount = selection.selectedCount + delta;

    // Stok kontrolü (adet değişmez!)
    if (newCount >= 0 && newCount <= selection.vagon.adet) {
      setState(() {
        selection.selectedCount = newCount; // Sadece selectedCount güncellenir
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stokta yeterli vagon yok!")),
      );
    }
  }

  void _onSubmit() {
    final selectedLokomotifler = lokomotifSelections
        .where((s) => s.selectedCount > 0)
        .map((s) => s.loko.copyWith(selectedCount: s.selectedCount))
        .toList();
    // Lokomotif stok kontrolü
    for (var lokoSelection in lokomotifSelections) {
      if (lokoSelection.selectedCount > lokoSelection.loko.adet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${lokoSelection.loko.tip} stok yetersiz!")),
        );
        return;
      }
    }
    final selectedVagonlar = vagonSelections
        .where((s) => s.selectedCount > 0)
        .map((s) => s.vagon.copyWith(selectedCount: s.selectedCount))
        .toList();

    // Vagon stok kontrolü
    for (var vagonSelection in vagonSelections) {
      if (vagonSelection.selectedCount > vagonSelection.vagon.adet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${vagonSelection.vagon.tip} stok yetersiz!")),
        );
        return;
      }
    }

    if (selectedLokomotifler.isEmpty || selectedVagonlar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('En az 1 lokomotif ve 1 vagon seçmelisiniz!')),
      );
      return;
    }

    Navigator.pop(context, {
      'startStation': startStation,
      'endStation': endStation,
      'lokomotifler': selectedLokomotifler,
      'vagonlar': selectedVagonlar,
    });
  }
}

class LokomotifSelection {
  Lokomotif loko;
  int selectedCount;

  LokomotifSelection({
    required this.loko,
    this.selectedCount = 0,
  });
}

class VagonSelection {
  Vagon vagon;
  int selectedCount;

  VagonSelection({
    required this.vagon,
    this.selectedCount = 0,
  });
}
