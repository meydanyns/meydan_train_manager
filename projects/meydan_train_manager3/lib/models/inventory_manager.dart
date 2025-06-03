import 'package:flutter/foundation.dart';
import 'lokomotif.dart';
import 'vagon.dart';

class InventoryManager extends ChangeNotifier {
  List<Lokomotif> _lokomotifler;
  List<Vagon> _vagonlar;
  void updateState() => notifyListeners();

  InventoryManager(this._lokomotifler, this._vagonlar);

  List<Lokomotif> get lokomotifler => _lokomotifler;
  List<Vagon> get vagonlar => _vagonlar;

  void consumeLokomotif(String tip, int count) {
    final index = lokomotifler.indexWhere((l) => l.tip == tip);
    if (index != -1) {
      lokomotifler[index] = lokomotifler[index].copyWith(
        adet: lokomotifler[index].adet - count,
      );
      notifyListeners();
    }
  }

  void consumeVagon(String tip, int count) {
    final index = vagonlar.indexWhere((v) => v.tip == tip);
    if (index != -1) {
      vagonlar[index] = vagonlar[index].copyWith(
        adet: vagonlar[index].adet - count,
      );
      notifyListeners();
    }
  }

  void returnLokomotif(String tip, int count) {
    final index = lokomotifler.indexWhere((l) => l.tip == tip);
    if (index != -1) {
      lokomotifler[index] = lokomotifler[index].copyWith(
        adet: lokomotifler[index].adet + count,
      );
      notifyListeners();
    }
  }

  void returnVagon(String tip, int count) {
    final index = vagonlar.indexWhere((v) => v.tip == tip);
    if (index != -1) {
      vagonlar[index] = vagonlar[index].copyWith(
        adet: vagonlar[index].adet + count,
      );
      notifyListeners();
    }
  }
}
