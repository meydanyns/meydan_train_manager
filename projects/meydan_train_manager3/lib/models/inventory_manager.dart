import 'package:flutter/foundation.dart';
import 'lokomotif.dart';
import 'vagon.dart';

class InventoryManager extends ChangeNotifier {
  List<Lokomotif> _lokomotifler;
  List<Vagon> _vagonlar;
  int kasa = 100000;

  InventoryManager(this._lokomotifler, this._vagonlar);

  List<Lokomotif> get lokomotifler => _lokomotifler;
  List<Vagon> get vagonlar => _vagonlar;

  void addKasa(int amount) {
    kasa += amount;
    notifyListeners();
  }

  void addLokomotifStock(String tip, int count) {
    final index = _lokomotifler.indexWhere((l) => l.tip == tip);
    if (index != -1) {
      _lokomotifler[index] = _lokomotifler[index].copyWith(
        adet: _lokomotifler[index].adet + count,
      );
      notifyListeners();
    }
  }

  void addVagonStock(String tip, int count) {
    final index = _vagonlar.indexWhere((v) => v.tip == tip);
    if (index != -1) {
      _vagonlar[index] = _vagonlar[index].copyWith(
        adet: _vagonlar[index].adet + count,
      );
      notifyListeners();
    }
  }

  void consumeLokomotif(String tip, int count) {
    final index = _lokomotifler.indexWhere((l) => l.tip == tip);
    if (index != -1) {
      _lokomotifler[index] = _lokomotifler[index].copyWith(
        adet: _lokomotifler[index].adet - count,
      );
      notifyListeners();
    }
  }

  void consumeVagon(String tip, int count) {
    final index = _vagonlar.indexWhere((v) => v.tip == tip);
    if (index != -1) {
      _vagonlar[index] = _vagonlar[index].copyWith(
        adet: _vagonlar[index].adet - count,
      );
      notifyListeners();
    }
  }

  // Eksik metodları ekleyelim
  void returnLokomotif(String tip, int count) {
    addLokomotifStock(tip, count);
  }

  void returnVagon(String tip, int count) {
    addVagonStock(tip, count);
  }
}
