import 'package:flutter/material.dart';
import 'package:tren/models/lokomotif.dart';
import 'package:tren/models/station.dart';
import 'package:tren/models/vagon.dart';
import 'package:tren/services/route_services.dart';
import 'package:tren/models/inventory_manager.dart';
import 'package:provider/provider.dart';
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
  late InventoryManager _inventoryManager;

  @override
  void initState() {
    super.initState();
    _inventoryManager = Provider.of<InventoryManager>(context, listen: false);

    // Orijinal listelere referans ver
    lokomotifSelections = _inventoryManager.lokomotifler
        .map((loko) => LokomotifSelection(
              loko: loko,
              selectedCount: 0,
            ))
        .toList();

    vagonSelections = _inventoryManager.vagonlar
        .map((vagon) => VagonSelection(
              vagon: vagon,
              selectedCount: 0,
            ))
        .toList();
  }

  int get totalGuc => lokomotifSelections.fold(
        0,
        (sum, selection) =>
            sum + (selection.selectedCount * selection.loko.guc),
      );

  int get totalKapasite => vagonSelections.fold(
        0,
        (sum, selection) =>
            sum + (selection.selectedCount * selection.vagon.kapasite),
      );

  Widget buildStationSelector({
    required String hint,
    required Station? selectedStation,
    required ValueChanged<Station?> onStationSelected,
  }) {
    return DropdownSearch<Station>(
      items: RouteService.graph.keys.toList(),
      selectedItem: selectedStation,
      popupProps: PopupProps.dialog(
        showSearchBox: true,
        searchDelay: Duration.zero,
        itemBuilder: (context, Station? station, bool isSelected) {
          return ListTile(title: Text(station?.name ?? ""));
        },
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(),
        ),
      ),
      itemAsString: (station) => station.name,
      onChanged: onStationSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryManager>(
      builder: (context, inventoryManager, child) {
        lokomotifSelections = inventoryManager.lokomotifler
            .map((loko) => LokomotifSelection(
                  loko: loko,
                  selectedCount: lokomotifSelections
                          .firstWhere(
                            (s) => s.loko.tip == loko.tip,
                            orElse: () => LokomotifSelection(loko: loko),
                          )
                          .selectedCount ??
                      0,
                ))
            .toList();

        vagonSelections = inventoryManager.vagonlar
            .map((vagon) => VagonSelection(
                  vagon: vagon,
                  selectedCount: vagonSelections
                          .firstWhere(
                            (s) => s.vagon.tip == vagon.tip,
                            orElse: () => VagonSelection(vagon: vagon),
                          )
                          .selectedCount ??
                      0,
                ))
            .toList();

        return AlertDialog(
          title: const Text('Tren Talep'),
          content: SingleChildScrollView(
            child: Column(
              children: [
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
                Text(
                  'Toplam Güç: $totalGuc HP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        totalGuc >= totalKapasite ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Vagon Seçimi', style: TextStyle(fontSize: 18)),
                ...vagonSelections.map(_buildVagonRow),
                Text(
                  'Toplam Kapasite: $totalKapasite TON',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        totalGuc >= totalKapasite ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: (startStation == null || endStation == null)
                  ? null // Butonu devre dışı bırak
                  : () => _onSubmit(),
              child: const Text('Tamam'),
            )
          ],
        );
      },
    );
  }

  Widget _buildLokomotifRow(LokomotifSelection selection) {
    final available = selection.loko.adet - selection.selectedCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Image.asset(selection.loko.resim, width: 60, height: 60),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selection.loko.tip,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Stok: $available'),
              Text('Güç: ${selection.loko.guc} HP'),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _updateLokomotifCount(selection, -1),
          ),
          Text(
            '${selection.selectedCount}',
            style: const TextStyle(fontSize: 16),
          ),
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
              Text(
                selection.vagon.tip,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // Güncellenmiş stok gösterimi
              Text('Stok: ${selection.vagon.adet - selection.selectedCount}'),
              Text('Kapasite: ${selection.vagon.kapasite} TON'),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _updateVagonCount(selection, -1),
          ),
          Text(
            '${selection.selectedCount}',
            style: const TextStyle(fontSize: 16),
          ),
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
    // Düzeltme: Toplam stok kontrolü yapılmalı
    if (newCount >= 0 && newCount <= selection.loko.adet) {
      setState(() => selection.selectedCount = newCount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stokta yeterli ${selection.loko.tip} yok!")),
      );
    }
  }

  void _updateVagonCount(VagonSelection selection, int delta) {
    final newCount = selection.selectedCount + delta;
    // Düzeltme: Toplam stok kontrolü yapılmalı
    if (newCount >= 0 && newCount <= selection.vagon.adet) {
      setState(() => selection.selectedCount = newCount);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Stokta yeterli vagon yok!")));
    }
  }

  void _onSubmit() {
    final selectedLokomotifler = lokomotifSelections
        .where((s) => s.selectedCount > 0)
        .map((s) => s.loko.copyWith(selectedCount: s.selectedCount))
        .toList();

    final selectedVagonlar = vagonSelections
        .where((s) => s.selectedCount > 0)
        .map((s) => s.vagon.copyWith(selectedCount: s.selectedCount))
        .toList();

    // Stokları güncelle
    for (var loko in selectedLokomotifler) {
      _inventoryManager.consumeLokomotif(loko.tip, loko.selectedCount);
    }
    for (var vagon in selectedVagonlar) {
      _inventoryManager.consumeVagon(vagon.tip, vagon.selectedCount);
    }
    // Vagon stok kontrolü
    for (var vagonSelection in vagonSelections) {
      if (vagonSelection.selectedCount > vagonSelection.vagon.adet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${vagonSelection.vagon.tip} stok yetersiz!")),
        );
        return;
      }
    }

    // Yeni eklenen güç-kapasite kontrolü
    if (totalKapasite > totalGuc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Lokomotiflerin toplam gücü yetersiz!\nGerekli minimum güç: $totalKapasite HP\nMevcut güç: $totalGuc HP",
          ),
        ),
      );
      return;
    }

    if (selectedLokomotifler.isEmpty || selectedVagonlar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az 1 lokomotif ve 1 vagon seçmelisiniz!'),
        ),
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

  LokomotifSelection({required this.loko, this.selectedCount = 0});
}

class VagonSelection {
  Vagon vagon;
  int selectedCount;

  VagonSelection({required this.vagon, this.selectedCount = 0});
}
