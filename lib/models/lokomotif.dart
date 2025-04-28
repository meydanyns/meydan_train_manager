// lokomotif.dart
class Lokomotif {
  final String id;
  final String tip;
  final int adet; // Stok adedi (sabit)
  final double hiz;
  final int guc;
  final String resim;
  int selectedCount; // Seçilen adet

  Lokomotif({
    required this.id,
    required this.tip,
    required this.adet,
    required this.hiz,
    required this.guc,
    required this.resim,
    this.selectedCount = 0,
  });

  Lokomotif copyWith({int? selectedCount}) {
    return Lokomotif(
      id: id,
      tip: tip,
      adet: adet,
      hiz: hiz,
      guc: guc,
      resim: resim,
      selectedCount: selectedCount ?? this.selectedCount,
    );
  }
}

List<Lokomotif> lokoListesi = [
  Lokomotif(
    id: '1',
    tip: "DH7000",
    adet: 13,
    hiz: 40,
    guc: 900,
    resim: 'lib/assets/lokomotifler/DH7000.png',
  ),
  Lokomotif(
    id: '1',
    tip: "lde11000",
    adet: 23,
    hiz: 50,
    guc: 1100,
    resim: 'lib/assets/lokomotifler/lde11000.png',
  ),
  Lokomotif(
    id: '2',
    tip: "lde18000",
    adet: 22,
    hiz: 60,
    guc: 1800,
    resim: 'lib/assets/lokomotifler/lde18000.png',
  ),
  Lokomotif(
    id: '2',
    tip: "lde22000",
    adet: 42,
    hiz: 75,
    guc: 2200,
    resim: 'lib/assets/lokomotifler/lde22000.png',
  ),
  Lokomotif(
    id: '3',
    tip: "lde33000",
    adet: 42,
    hiz: 80,
    guc: 3300,
    resim: 'lib/assets/lokomotifler/lde33000.png',
  ),
  Lokomotif(
    id: '4',
    tip: "lde24000",
    adet: 43,
    hiz: 70,
    guc: 2400,
    resim: 'lib/assets/lokomotifler/lde24000.png',
  ),
  Lokomotif(
    id: '5',
    tip: "lde36000",
    adet: 43,
    hiz: 90,
    guc: 3600,
    resim: 'lib/assets/lokomotifler/lde36000.png',
  ),
  Lokomotif(
    id: '5',
    tip: "le68000",
    adet: 20,
    hiz: 100,
    guc: 6800,
    resim: 'lib/assets/lokomotifler/le68000.png',
  ),
  // Diğer lokomotifler...
];
