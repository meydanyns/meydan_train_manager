class Vagon {
  final String tip;
  final int adet;
  final int kapasite;
  final int bakim;
  final String resim;

  Vagon({
    required this.tip,
    required this.adet,
    required this.kapasite,
    required this.bakim,
    required this.resim,
  });
}

List<Vagon> vagonListesi = [
  Vagon(
    tip: 'E',
    adet: 4,
    kapasite: 20,
    bakim: 100,
    resim: 'lib/assets/vagonlar/vagon1.png',
  ),
  Vagon(
    tip: 'F',
    adet: 4,
    kapasite: 20,
    bakim: 100,
    resim: 'lib/assets/vagonlar/vagon2.png',
  ),
  Vagon(
    tip: 'S',
    adet: 4,
    kapasite: 20,
    bakim: 100,
    resim: 'lib/assets/vagonlar/vagon3.png',
  ),
  Vagon(
    tip: 'Z',
    adet: 4,
    kapasite: 20,
    bakim: 100,
    resim: 'lib/assets/vagonlar/vagon1.png',
  ),
];
