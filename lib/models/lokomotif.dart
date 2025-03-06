class Lokomotif {
  final String tip;
  final int adet;
  final int hiz;
  final int guc;
  final String resim;

  Lokomotif({
    required this.tip,
    required this.adet,
    required this.hiz,
    required this.guc,
    required this.resim,
  });
}

List<Lokomotif> lokoListesi = [
  Lokomotif(
    tip: "lde11000",
    adet: 3,
    hiz: 130,
    guc: 1100,
    resim: 'lib/assets/lokomotifler/lde11000.png',
  ),
  Lokomotif(
    tip: "lde18000",
    adet: 2,
    hiz: 140,
    guc: 1200,
    resim: 'lib/assets/lokomotifler/lde18000.png',
  ),
  Lokomotif(
    tip: "lde22000",
    adet: 2,
    hiz: 120,
    guc: 1000,
    resim: 'lib/assets/lokomotifler/lde22000.png',
  ),
  Lokomotif(
    tip: "lde24000",
    adet: 3,
    hiz: 130,
    guc: 1100,
    resim: 'lib/assets/lokomotifler/lde24000.png',
  ),
  Lokomotif(
    tip: "lde36000",
    adet: 3,
    hiz: 140,
    guc: 1200,
    resim: 'lib/assets/lokomotifler/lde36000.png',
  ),
  // Diğer lokomotifler...
];
