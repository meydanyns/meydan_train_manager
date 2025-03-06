import '../models/station.dart';

class RouteService {
  // İstasyonlar arasındaki bağlantıları temsil eden graf
  static Map<Station, List<Station>> graph = {};

  // Tüm hatlar
  static List<List<Station>> routes = [
    // Hat1: Ankara -> Elmadağ -> Kırıkkale -> Yerköy -> Kayseri
    [
      Station(name: 'Ankara', latitude: 39.9334, longitude: 32.8597),
      Station(name: 'Elmadağ', latitude: 39.923602, longitude: 33.227082),
      Station(name: 'Irmak', latitude: 39.932176, longitude: 33.390066),
      Station(name: 'Kırıkkale', latitude: 39.8468, longitude: 33.5153),
      Station(name: 'Çerikli', latitude: 39.894057, longitude: 34.000020),
      Station(name: 'Yerköy', latitude: 39.6381, longitude: 34.4672),
      Station(name: 'Şefaatlı', latitude: 39.498176, longitude: 34.750182),
      Station(name: 'Yenifakılı', latitude: 39.213219, longitude: 35.002146),
      Station(name: 'Boğazköprü', latitude: 38.755541, longitude: 35.323168),
      Station(name: 'Kayseri', latitude: 38.7227, longitude: 35.4875),
    ],

    [
      Station(name: 'Irmak', latitude: 39.932176, longitude: 33.390066),
      Station(name: 'kalecik', latitude: 40.076937, longitude: 33.445308),
      Station(name: 'Çankırı', latitude: 40.596688, longitude: 33.613588),
      Station(name: 'Güllüce', latitude: 40.814777, longitude: 33.407231),
      Station(name: 'ismetpaşa', latitude: 40.877024, longitude: 32.610454),
      Station(name: 'Karabük', latitude: 41.195139, longitude: 32.614644),
      Station(name: 'Gökçebey', latitude: 41.306737, longitude: 32.139270),
      Station(name: 'Çaycuma', latitude: 41.423603, longitude: 32.095513),
      Station(name: 'Filyos', latitude: 41.560591, longitude: 32.022957),
      Station(name: 'Zonguldak', latitude: 41.448350, longitude: 31.793598),
    ],
    // Hat2: Kayseri -> Niğde -> Ulukışla -> Yenice -> Adana
    [
      Station(name: 'Kayseri', latitude: 38.7227, longitude: 35.4875),
      Station(name: 'Boğazköprü', latitude: 38.755541, longitude: 35.323168),
      Station(name: 'Araplı', latitude: 38.257759, longitude: 35.105827),
      Station(name: 'Niğde', latitude: 37.9667, longitude: 34.6833),
      Station(name: 'Ulukışla', latitude: 37.5458, longitude: 34.4814),
      Station(name: 'Pozantı', latitude: 37.434096, longitude: 34.875823),
      Station(name: 'Yenice', latitude: 37.0000, longitude: 35.0000),
      Station(name: 'Adana', latitude: 37.0000, longitude: 35.3213),
    ],
    // Hat3: Kayseri -> Sarıoğlan -> Şarkışla -> Kalın -> Sivas
    [
      Station(name: 'Kayseri', latitude: 38.7227, longitude: 35.4875),
      Station(name: 'Sarıoğlan', latitude: 39.0778, longitude: 35.9667),
      Station(name: 'Şarkışla', latitude: 39.3514, longitude: 36.4097),
      Station(name: 'Hanlı', latitude: 39.455660, longitude: 36.627865),
      Station(name: 'Kalın', latitude: 39.691856, longitude: 36.759933),
    ],
    // Hat4: kalın -> Artova -> Amasya -> Havza -> Samsun
    [
      Station(name: 'Kalın', latitude: 39.691856, longitude: 36.759933),
      Station(name: 'Yıldızeli', latitude: 39.867235, longitude: 36.592980),
      Station(name: 'Artova', latitude: 40.113522, longitude: 36.300422),
      Station(name: 'Turhal', latitude: 40.388996, longitude: 36.078212),
      Station(name: 'Amasya', latitude: 40.664820, longitude: 35.832671),
      Station(name: 'Havza', latitude: 40.9667, longitude: 35.6667),
      Station(name: 'Samsun', latitude: 41.2867, longitude: 36.3300),
    ],
    // Hat5: Sivas - Malatya Hattı
    [
      Station(name: 'Kalın', latitude: 39.691856, longitude: 36.759933),
      Station(name: 'Sivas', latitude: 39.7500, longitude: 37.0167),
      Station(name: 'Bostankaya', latitude: 39.513992, longitude: 37.008492),
      Station(name: 'Kangal', latitude: 39.246117, longitude: 37.385248),
      Station(name: 'Çetinkaya', latitude: 39.248143, longitude: 37.603290),
    ],
    [
      Station(name: 'Çetinkaya', latitude: 39.248143, longitude: 37.603290),
      Station(name: 'Akgedik', latitude: 39.049543, longitude: 37.717367),
      Station(name: 'Hekimhan', latitude: 38.814712, longitude: 37.932057),
      Station(name: 'Yazıhan', latitude: 38.597574, longitude: 38.181731),
      Station(name: 'Dilek', latitude: 38.445432, longitude: 38.257564),
      Station(name: 'Malatya', latitude: 38.353104, longitude: 38.280001),
    ],
// çetinkaya kars
    [
      Station(name: 'Çetinkaya', latitude: 39.248143, longitude: 37.603290),
      Station(name: 'Güneş', latitude: 39.374150, longitude: 37.861892),
      Station(name: 'Cürek', latitude: 39.442784, longitude: 38.036778),
      Station(name: 'Divriği', latitude: 39.383150, longitude: 38.114908),
      Station(name: 'Çaltı', latitude: 39.368076, longitude: 38.350089),
      Station(name: 'İliç', latitude: 39.471655, longitude: 38.556127),
      Station(name: 'Eriç', latitude: 39.567682, longitude: 38.874512),
      Station(name: 'Kemah', latitude: 39.604772, longitude: 39.033716),
      Station(name: 'Cebesoy', latitude: 39.645615, longitude: 39.350528),
      Station(name: 'Erzincan', latitude: 39.734808, longitude: 39.497493),
      Station(name: 'Demirkapı', latitude: 39.579721, longitude: 40.164792),
      Station(name: 'Erbaş', latitude: 39.916103, longitude: 40.205971),
      Station(name: 'Aşkale', latitude: 39.921537, longitude: 40.683690),
      Station(name: 'Erzurum', latitude: 39.917053, longitude: 41.270692),
      Station(name: 'Horasan', latitude: 40.042272, longitude: 42.169321),
      Station(name: 'Topdağı', latitude: 40.312283, longitude: 42.302619),
      Station(name: 'Sarıkamış', latitude: 40.336985, longitude: 42.579146),
      Station(name: 'Selim', latitude: 40.464239, longitude: 42.781720),
      Station(name: 'Kars', latitude: 40.606313, longitude: 43.104559),
    ],
    // Hat6:  Malatya-Yolçatı Hattı
    [
      Station(name: 'Malatya', latitude: 38.353104, longitude: 38.280001),
      Station(name: 'Battalgazi', latitude: 38.433688, longitude: 38.373347),
      Station(name: 'Fırat', latitude: 38.439861, longitude: 38.517386),
      Station(name: 'Kuşsarayı', latitude: 38.452646, longitude: 38.682229),
      Station(name: 'Pınarlı', latitude: 38.472427, longitude: 38.775734),
      Station(name: 'Baskil', latitude: 38.565293, longitude: 38.821961),
      Station(name: 'Yolçatı', latitude: 38.542425, longitude: 39.035854),
    ],
    // Hat7:  Yolçatı-Diyarbakır Hattı
    [
      Station(name: 'Yolçatı', latitude: 38.542425, longitude: 39.035854),
      Station(name: 'Kürk', latitude: 38.462477, longitude: 39.273505),
      Station(name: 'Sivrice', latitude: 38.447684, longitude: 39.308336),
      Station(name: 'Gezin', latitude: 38.494556, longitude: 39.520681),
      Station(name: 'Maden', latitude: 38.401386, longitude: 39.670002),
      Station(name: 'Ergani', latitude: 38.231549, longitude: 39.756625),
      Station(name: 'Diyarbakır', latitude: 37.911923, longitude: 40.214684),
    ],

    //  Diyarbakır-Kurtalan Hattı
    [
      Station(name: 'Diyarbakır', latitude: 37.911923, longitude: 40.214684),
      Station(name: 'Bozdemir', latitude: 37.837168, longitude: 40.305257),
      Station(name: 'Bismil', latitude: 37.852702, longitude: 40.663464),
      Station(name: 'Çöltepe', latitude: 37.848216, longitude: 40.804242),
      Station(name: 'Soğuksu', latitude: 37.833121, longitude: 41.020105),
      Station(name: 'Batman', latitude: 37.878972, longitude: 41.123507),
      Station(name: 'Yaylıca', latitude: 38.007393, longitude: 41.232226),
      Station(name: 'Beşiri', latitude: 37.964503, longitude: 41.331801),
      Station(name: 'Demirkuyu', latitude: 37.962943, longitude: 41.507160),
      Station(name: 'Kurtalan', latitude: 37.928529, longitude: 41.696139),
    ],

    // Hat7:  Ankara-Eskişehir Hattı
    [
      Station(name: 'Ankara', latitude: 39.7500, longitude: 37.0167),
      Station(name: 'Sincan', latitude: 39.968395, longitude: 32.574392),
      Station(name: 'Polatlı', latitude: 39.582493, longitude: 32.134314),
      Station(name: 'Yunus Emre', latitude: 39.697339, longitude: 31.481758),
      Station(name: 'Alpu', latitude: 39.769238, longitude: 30.952086),
      Station(name: 'Eskişehir', latitude: 39.778953, longitude: 30.501373),
    ],
    [
      Station(name: 'Eskişehir', latitude: 39.778953, longitude: 30.501373),
      Station(name: 'Kızılinler', latitude: 39.704068, longitude: 30.417373),
      Station(name: 'Gökçeışık', latitude: 39.653753, longitude: 30.388485),
      Station(name: 'Sabuncupınarı', latitude: 39.562593, longitude: 30.190526),
      Station(name: 'Alayunt', latitude: 39.394175, longitude: 30.104651),
    ],
    // eskişehir  haydarpaşa
    [
      Station(name: 'Eskişehir', latitude: 39.778953, longitude: 30.501373),
      Station(name: 'Bozüyük', latitude: 39.903811, longitude: 30.049890),
      Station(name: 'Bilecik', latitude: 40.157293, longitude: 29.977936),
      Station(name: 'Pamukova', latitude: 40.504810, longitude: 30.166619),
      Station(name: 'Arifiye', latitude: 40.713022, longitude: 30.353846),
      Station(name: 'Gebze', latitude: 40.783276, longitude: 29.412287),
      Station(name: 'Pendik', latitude: 40.880313, longitude: 29.232235),
      Station(name: 'Maltepe', latitude: 40.920596, longitude: 29.133492),
      Station(name: 'Haydarpaşa', latitude: 40.998174, longitude: 29.022519),
    ],
// alayunt  balıkesir
    [
      Station(name: 'Alayunt', latitude: 39.394175, longitude: 30.104651),
      Station(name: 'Kütahya', latitude: 39.430362, longitude: 29.983325),
      Station(name: 'Tavşanlı', latitude: 39.540954, longitude: 29.510098),
      Station(name: 'Gökçedağ', latitude: 39.611161, longitude: 28.980278),
      Station(name: 'Dursunbey', latitude: 39.547927, longitude: 28.650858),
      Station(name: 'Mezitler', latitude: 39.549503, longitude: 28.306446),
      Station(name: 'Balıkesir', latitude: 39.646883, longitude: 27.889984),
    ],

    [
      Station(name: 'Alayunt', latitude: 39.394175, longitude: 30.104651),
      Station(name: 'Çöğürler', latitude: 39.267675, longitude: 30.178262),
      Station(name: 'İhsaniye', latitude: 39.206892, longitude: 30.296695),
      Station(name: 'Döğer', latitude: 39.130064, longitude: 30.382092),
      Station(name: 'İhsaniye', latitude: 39.012500, longitude: 30.403168),
      Station(name: 'Gazlıgöl', latitude: 38.933407, longitude: 30.501379),
      Station(name: 'Afyon', latitude: 38.763163, longitude: 30.553595),
    ],
    // Hat8:  Yolçatı-Tatvan Hattı
    [
      Station(name: 'Yolçatı', latitude: 38.542425, longitude: 39.035854),
      Station(name: 'Elazığ', latitude: 38.668751, longitude: 39.218168),
      Station(name: 'Çağlar', latitude: 38.588742, longitude: 39.391820),
      Station(name: 'Muratbağı', latitude: 38.651899, longitude: 39.774346),
      Station(name: 'Palu', latitude: 38.689091, longitude: 39.929666),
      Station(name: 'Genç', latitude: 38.750164, longitude: 40.560434),
      Station(name: 'Oymapınar', latitude: 38.866146, longitude: 40.966280),
      Station(name: 'Muş', latitude: 38.748488, longitude: 41.505457),
      Station(name: 'Tatvan', latitude: 38.512469, longitude: 42.277926),
    ],

    [
      Station(name: 'Afyon', latitude: 38.763163, longitude: 30.553595),
      Station(name: 'Çay', latitude: 38.628002, longitude: 31.036814),
      Station(name: 'Sultandağı', latitude: 38.549316, longitude: 31.267936),
      Station(name: 'Akşehir', latitude: 38.368571, longitude: 31.443843),
      Station(name: 'Ilgın', latitude: 38.286455, longitude: 31.919324),
      Station(name: 'Kadınhan', latitude: 38.317074, longitude: 32.184625),
      Station(name: 'Sarayönü', latitude: 38.255652, longitude: 32.406571),
      Station(name: 'Meydan', latitude: 38.237850, longitude: 32.528531),
      Station(name: 'Kayacak', latitude: 38.002108, longitude: 32.591927),
      Station(name: 'Konya', latitude: 37.865786, longitude: 32.475859),
      Station(name: 'Çumra', latitude: 37.568393, longitude: 32.786278),
      Station(name: 'Karaman', latitude: 37.190271, longitude: 33.220925),
      Station(name: 'Ereğli', latitude: 37.503086, longitude: 34.044511),
      Station(name: 'Ulukışla', latitude: 37.5458, longitude: 34.4814),
    ],
  ];

  // Grafı otomatik olarak oluştur
  static void initializeGraph() {
    for (var route in routes) {
      for (int i = 0; i < route.length; i++) {
        Station currentStation = route[i];
        if (!graph.containsKey(currentStation)) {
          graph[currentStation] = [];
        }

        // Bir sonraki istasyonu ekle
        if (i < route.length - 1) {
          Station nextStation = route[i + 1];
          graph[currentStation]!.add(nextStation);
        }

        // Bir önceki istasyonu ekle
        if (i > 0) {
          Station previousStation = route[i - 1];
          graph[currentStation]!.add(previousStation);
        }
      }
    }
  }

  // BFS algoritması ile en kısa rotayı bul
  static List<Station> findShortestRoute(Station start, Station end) {
    // Ziyaret edilen düğümleri takip etmek için bir küme
    Set<Station> visited = {};
    // BFS için kuyruk (queue) oluştur
    List<List<Station>> queue = [];
    // Başlangıç düğümünü kuyruğa ekle
    queue.add([start]);

    while (queue.isNotEmpty) {
      // Kuyruğun ilk rotasını al
      List<Station> path = queue.removeAt(0);
      // Son düğümü al
      Station node = path.last;

      // Eğer son düğüm varış istasyonu ise rotayı döndür
      if (node.name == end.name) {
        return path;
      }

      // Düğümü ziyaret edildi olarak işaretle
      if (!visited.contains(node)) {
        visited.add(node);

        // Komşu düğümleri kuyruğa ekle
        for (Station neighbor in graph[node]!) {
          List<Station> newPath = List.from(path);
          newPath.add(neighbor);
          queue.add(newPath);
        }
      }
    }

    // Rota bulunamazsa boş liste döndür
    return [];
  }
}
