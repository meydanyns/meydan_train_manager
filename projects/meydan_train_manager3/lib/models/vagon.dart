// vagon.dart
class Vagon {
  final String id;
  final String tip;
  final int adet; // Stok adedi (sabit)
  final int kapasite;
  final int fiyat; // Fiyat opsiyonel, varsayılan 0
  final String resim;
  int selectedCount; // Seçilen adet

  Vagon({
    required this.id,
    required this.tip,
    required this.adet,
    required this.kapasite,
    this.fiyat = 0, // Fiyat opsiyonel, varsayılan 0
    required this.resim,
    this.selectedCount = 0,
  });

  Vagon copyWith({int? adet, int? selectedCount}) {
    return Vagon(
      id: id,
      tip: tip,
      adet: adet ?? this.adet,
      kapasite: kapasite,
      fiyat: fiyat,
      resim: resim,
      selectedCount: selectedCount ?? this.selectedCount,
    );
  }
}

List<Vagon> vagonListesi = [
  Vagon(
    id: '1',
    tip: 'Eamnoss',
    adet: 14,
    kapasite: 40,
    fiyat: 100000, // Fiyatı ekledik
    resim: 'lib/assets/vagonlar/Eamnoss.png',
  ),
  Vagon(
    id: '3',
    tip: 'Ksw',
    adet: 44,
    kapasite: 50,
    fiyat: 100000, // Fiyatı ekledik
    resim: 'lib/assets/vagonlar/Ksw.png',
  ),
  Vagon(
    id: '3',
    tip: 'Kswd',
    adet: 44,
    kapasite: 60,
    fiyat: 100000, // Fiyatı ekledik
    resim: 'lib/assets/vagonlar/Kswd.png',
  ),
  Vagon(
    id: '4',
    tip: 'Zacess',
    adet: 54,
    kapasite: 90,
    fiyat: 100000, // Fiyatı ekledik
    resim: 'lib/assets/vagonlar/Zacess.png',
  ),
  Vagon(
    id: '4',
    tip: 'Fals',
    adet: 44,
    kapasite: 80,
    fiyat: 100000, // Fiyatı ekledik
    resim: 'lib/assets/vagonlar/Fals.png',
  ),
  Vagon(
    id: '5',
    tip: 'Elswz',
    adet: 54,
    kapasite: 90,
    fiyat: 100000, // Fiyatı ekledik

    resim: 'lib/assets/vagonlar/Elswz.png',
  ),
  Vagon(
    id: '4',
    tip: 'Daswu',
    adet: 54,
    kapasite: 90,
    fiyat: 100000, // Fiyatı ekledik
    resim: 'lib/assets/vagonlar/Daswu.png',
  ),
  Vagon(
    id: '4',
    tip: 'Gbs',
    adet: 44,
    kapasite: 80,
    fiyat: 100000, // Fiyatı ekledik
    resim: 'lib/assets/vagonlar/Gbs.png',
  ),
  Vagon(
    id: '5',
    tip: 'Wlalm',
    adet: 54,
    kapasite: 80,
    fiyat: 100000, // Fiyatı ekledik
    resim: 'lib/assets/vagonlar/Wlalm.png',
  ),
];
