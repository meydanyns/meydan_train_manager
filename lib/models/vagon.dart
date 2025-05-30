// vagon.dart
class Vagon {
  final String id;
  final String tip;
  final int adet; // Stok adedi (sabit)
  final int kapasite;
  final String resim;
  int selectedCount; // Seçilen adet

  Vagon({
    required this.id,
    required this.tip,
    required this.adet,
    required this.kapasite,
    required this.resim,
    this.selectedCount = 0,
  });

  Vagon copyWith({int? selectedCount}) {
    return Vagon(
      id: id,
      tip: tip,
      adet: adet,
      kapasite: kapasite,
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
    kapasite: 20,
    resim: 'lib/assets/vagonlar/Eamnoss.png',
  ),
  Vagon(
    id: '3',
    tip: 'Ksw',
    adet: 44,
    kapasite: 20,
    resim: 'lib/assets/vagonlar/Ksw.png',
  ),
  Vagon(
    id: '4',
    tip: 'Zacess',
    adet: 54,
    kapasite: 20,
    resim: 'lib/assets/vagonlar/Zacess.png',
  ),
  Vagon(
    id: '4',
    tip: 'Fals',
    adet: 44,
    kapasite: 20,
    resim: 'lib/assets/vagonlar/Fals.png',
  ),
  Vagon(
    id: '5',
    tip: 'Elswz',
    adet: 54,
    kapasite: 20,
    resim: 'lib/assets/vagonlar/Elswz.png',
  ),
];
