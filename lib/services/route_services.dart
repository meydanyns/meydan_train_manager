import '../models/station.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class RouteService {
  // İstasyonlar arasındaki bağlantıları temsil eden graf
  static Map<Station, List<Station>> graph = {};

  // Tüm hatlar
  static List<List<Station>> routes = [
    // Hat1: Ankara -> Elmadağ -> Kırıkkale -> Yerköy -> Kayseri
    [
      Station(name: 'Ankara', latitude: 39.935913, longitude: 32.843087),
      Station(name: 'Mamak', latitude: 39.931543, longitude: 32.911814),
      Station(name: 'Kayaş', latitude: 39.913458, longitude: 32.965430),
      Station(name: 'Lalahan', latitude: 39.970639, longitude: 33.117394),
      Station(name: 'Lalabel', latitude: 39.958773, longitude: 33.190856),
      Station(name: 'Elmadağ', latitude: 39.923602, longitude: 33.227082),
      Station(name: 'Kurbağalı', latitude: 39.944146, longitude: 33.297462),
      Station(name: 'Kılıçlar', latitude: 39.900025, longitude: 33.321871),
      Station(name: 'Irmak', latitude: 39.932176, longitude: 33.390066),
      Station(name: 'Yahşihan', latitude: 39.845620, longitude: 33.447170),
      Station(name: 'Kırıkkale', latitude: 39.8468, longitude: 33.5153),
      Station(name: 'Mahmutlar', latitude: 39.859390, longitude: 33.605176),
      Station(name: 'Balışıh', latitude: 39.909650, longitude: 33.718703),
      Station(name: 'İzzettin', latitude: 39.910153, longitude: 33.839005),
      Station(name: 'Çerikli', latitude: 39.894057, longitude: 34.000020),
      Station(name: 'Yerköy', latitude: 39.6381, longitude: 34.4672),
      Station(name: 'Şefaatlı', latitude: 39.498176, longitude: 34.750182),
      Station(name: 'Yenifakılı', latitude: 39.213219, longitude: 35.002146),
      Station(name: 'Boğazköprü', latitude: 38.755541, longitude: 35.323168),
      Station(name: 'Kayseri', latitude: 38.7227, longitude: 35.4875),
    ],
// ırmak zonguldak hattı
    [
      Station(name: 'Irmak', latitude: 39.932176, longitude: 33.390066),
      Station(name: 'kalecik', latitude: 40.076937, longitude: 33.445308),
      Station(name: 'Alibey', latitude: 40.193444, longitude: 33.568764),
      Station(name: 'Tüney', latitude: 40.355882, longitude: 33.529197),
      Station(name: 'Germece', latitude: 40.405165, longitude: 33.677511),
      Station(name: 'Çankırı', latitude: 40.596688, longitude: 33.613588),
      Station(name: 'Güllüce', latitude: 40.814777, longitude: 33.407231),
      Station(name: 'Kurşunlu', latitude: 40.844297, longitude: 33.261692),
      Station(name: 'Çerkeş', latitude: 40.811154, longitude: 32.884729),
      Station(name: 'ismetpaşa', latitude: 40.877024, longitude: 32.610454),
      Station(name: 'Karabük', latitude: 41.195139, longitude: 32.614644),
      Station(name: 'Bolkuş', latitude: 41.160668, longitude: 32.517103),
      Station(name: 'Kayadibi', latitude: 41.236262, longitude: 32.202398),
      Station(name: 'Gökçebey', latitude: 41.306737, longitude: 32.139270),
      Station(name: 'Çaycuma', latitude: 41.423603, longitude: 32.095513),
      Station(name: 'Filyos', latitude: 41.560591, longitude: 32.022957),
      Station(name: 'Zonguldak', latitude: 41.448350, longitude: 31.793598),
    ],
    // Hat2: Kayseri -> Niğde -> Ulukışla -> Yenice -> Adana
    [
      Station(name: 'Kayseri', latitude: 38.7227, longitude: 35.4875),
      Station(name: 'Boğazköprü', latitude: 38.755541, longitude: 35.323168),
      Station(name: 'İncasu', latitude: 38.629169, longitude: 35.196711),
      Station(name: 'Akköy', latitude: 38.338022, longitude: 35.035953),
      Station(name: 'Araplı', latitude: 38.257759, longitude: 35.105827),
      Station(name: 'Niğde', latitude: 37.9667, longitude: 34.6833),
      Station(name: 'Bor', latitude: 37.9667, longitude: 34.6833),
      Station(name: 'Altay', latitude: 37.667062, longitude: 34.463712),
      Station(name: 'Ulukışla', latitude: 37.5458, longitude: 34.4814),
    ],
    // ulukışla  yenice hattı
    [
      Station(name: 'Ulukışla', latitude: 37.5458, longitude: 34.4814),
      Station(name: 'Çiftehan', latitude: 37.511764, longitude: 34.772988),
      Station(name: 'Pozantı', latitude: 37.434096, longitude: 34.875823),
      Station(name: 'Belemedik', latitude: 37.354927, longitude: 34.910560),
      Station(name: 'Hacıkırı', latitude: 37.252374, longitude: 34.980812),
      Station(name: 'Durak', latitude: 37.154200, longitude: 34.976418),
      Station(name: 'Yenice', latitude: 36.974851, longitude: 35.056166),
    ],
    //   yenice- toprakkale hattı
    [
      Station(name: 'Yenice', latitude: 36.974851, longitude: 35.056166),
      Station(name: 'Şehitlik', latitude: 36.997665, longitude: 35.241685),
      Station(name: 'Şakirpaşa', latitude: 36.996222, longitude: 35.290073),
      Station(name: 'Adana', latitude: 37.005864, longitude: 35.327816),
      Station(name: 'İncirlik', latitude: 36.983804, longitude: 35.437142),
      Station(name: 'Yakapınar', latitude: 36.967896, longitude: 35.612699),
      Station(name: 'Ceyhan', latitude: 37.018240, longitude: 35.817877),
      Station(name: 'Günyazı', latitude: 37.057455, longitude: 35.952719),
      Station(name: 'Toprakkale', latitude: 37.066547, longitude: 36.145709),
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
      Station(name: 'Yeşilyurt', latitude: 40.007734, longitude: 36.219490),
      Station(name: 'Artova', latitude: 40.113522, longitude: 36.300422),
      Station(name: 'Yıldıztepe', latitude: 40.161917, longitude: 35.930900),
      Station(name: 'Zile', latitude: 40.281907, longitude: 35.931507),
      Station(name: 'Turhal', latitude: 40.388996, longitude: 36.078212),
      Station(name: 'Kızılca', latitude: 40.515884, longitude: 35.761050),
      Station(name: 'Amasya', latitude: 40.664820, longitude: 35.832671),
      Station(name: 'Havza', latitude: 40.9667, longitude: 35.6667),
      Station(name: 'Samsun', latitude: 41.2867, longitude: 36.3300),
    ],
    // Hat5: Kalın - Çetinkaya Hattı
    [
      Station(name: 'Kalın', latitude: 39.691856, longitude: 36.759933),
      Station(name: 'Sivas', latitude: 39.7500, longitude: 37.0167),
      Station(name: 'Bostankaya', latitude: 39.513992, longitude: 37.008492),
      Station(name: 'Kangal', latitude: 39.246117, longitude: 37.385248),
      Station(name: 'Çetinkaya', latitude: 39.248143, longitude: 37.603290),
    ],
    // Çetinkaya-Malatya
    [
      Station(name: 'Çetinkaya', latitude: 39.248143, longitude: 37.603290),
      Station(name: 'Demiriz', latitude: 39.159911, longitude: 37.693466),
      Station(name: 'Akçamağara', latitude: 39.099788, longitude: 37.734980),
      Station(name: 'Akgedik', latitude: 39.050251, longitude: 37.716262),
      Station(name: 'Ulugüney', latitude: 39.049543, longitude: 37.717367),
      Station(name: 'Hasançelebi', latitude: 38.953102, longitude: 37.891710),
      Station(name: 'Hekimhan', latitude: 38.814712, longitude: 37.932057),
      Station(name: 'Kesikköprü', latitude: 38.710769, longitude: 38.011108),
      Station(name: 'Kesikköprü', latitude: 38.710769, longitude: 38.011108),
      Station(name: 'Sarsap', latitude: 38.668379, longitude: 38.134948),
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
      Station(name: 'Gemici D.', latitude: 38.457912, longitude: 38.599458),
      Station(name: 'Kuşsarayı', latitude: 38.452646, longitude: 38.682229),
      Station(name: 'Pınarlı', latitude: 38.472427, longitude: 38.775734),
      Station(name: 'Baskil', latitude: 38.565293, longitude: 38.821961),
      Station(name: 'Şefkat', latitude: 38.573350, longitude: 38.899928),
      Station(name: 'Yolçatı', latitude: 38.542425, longitude: 39.035854),
    ],

    // Hat7:  Yolçatı-Diyarbakır Hattı
    [
      Station(name: 'Yolçatı', latitude: 38.542425, longitude: 39.035854),
      Station(name: 'Uluova', latitude: 38.492251, longitude: 39.200514),
      Station(name: 'Kürk', latitude: 38.462477, longitude: 39.273505),
      Station(name: 'Sivrice', latitude: 38.447684, longitude: 39.308336),
      Station(name: 'Gölcük', latitude: 38.462395, longitude: 39.391419),
      Station(name: 'Gezin', latitude: 38.494556, longitude: 39.520681),
      Station(name: 'Maden', latitude: 38.401386, longitude: 39.670002),
      Station(name: 'Sallar', latitude: 38.275725, longitude: 39.678257),
      Station(name: 'Ergani', latitude: 38.231549, longitude: 39.756625),
      Station(name: 'Geyik', latitude: 38.143899, longitude: 39.936359),
      Station(name: 'Leylek', latitude: 38.021235, longitude: 40.084260),
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
      Station(name: 'Ankara', latitude: 39.935913, longitude: 32.843087),
      Station(name: 'Hipodrom', latitude: 39.945721, longitude: 32.825070),
      Station(name: 'Marşandiz', latitude: 39.932125, longitude: 32.769071),
      Station(name: 'Etimesgut', latitude: 39.949086, longitude: 32.663447),
      Station(name: 'Sincan', latitude: 39.968395, longitude: 32.574392),
      Station(name: 'Malıköy', latitude: 39.784650, longitude: 32.386977),
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
    //  balıkesir -İzmir
    [
      Station(name: 'Balıkesir', latitude: 39.646883, longitude: 27.889984),
      Station(name: 'Soma', latitude: 39.195541, longitude: 27.629509),
      Station(name: 'Akhisar', latitude: 38.908251, longitude: 27.790766),
      Station(name: 'Manisa', latitude: 38.621469, longitude: 27.435501),
      Station(name: 'Menemen', latitude: 38.603168, longitude: 27.076219),
      Station(name: 'İzmir', latitude: 38.438025, longitude: 27.149003),
    ],
// alayunt-afyon
    [
      Station(name: 'Alayunt', latitude: 39.394175, longitude: 30.104651),
      Station(name: 'Çöğürler', latitude: 39.267675, longitude: 30.178262),
      Station(name: 'İhsaniye', latitude: 39.206892, longitude: 30.296695),
      Station(name: 'Döğer', latitude: 39.130064, longitude: 30.382092),
      Station(name: 'İhsaniye', latitude: 39.012500, longitude: 30.403168),
      Station(name: 'Gazlıgöl', latitude: 38.933407, longitude: 30.501379),
      Station(name: 'Afyon', latitude: 38.763163, longitude: 30.553595),
    ],
    // afyon-dinar
    [
      Station(name: 'Afyon', latitude: 38.763163, longitude: 30.553595),
      Station(name: 'Tınaztepe', latitude: 38.744793, longitude: 30.384943),
      Station(name: 'Kocatepe', latitude: 38.673658, longitude: 30.324952),
      Station(name: 'Çiğiltepe', latitude: 38.596180, longitude: 30.265687),
      Station(name: 'Sandıklı', latitude: 38.458021, longitude: 30.260927),
      Station(name: 'Kazanpınar', latitude: 38.193134, longitude: 30.196677),
      Station(name: 'Dinar', latitude: 38.062272, longitude: 30.155311),
    ],
    // Hat8:  Yolçatı-Tatvan Hattı
    [
      Station(name: 'Yolçatı', latitude: 38.542425, longitude: 39.035854),
      Station(name: 'Elazığ', latitude: 38.665103, longitude: 39.222883),
      Station(name: 'Yurt', latitude: 38.636423, longitude: 39.357111),
      Station(name: 'Çağlar', latitude: 38.587752, longitude: 39.362924),
      Station(name: 'Muratbağı', latitude: 38.654485, longitude: 39.781094),
      Station(name: 'Palu', latitude: 38.690948, longitude: 39.926142),
      Station(name: 'Genç', latitude: 38.751475, longitude: 40.556416),
      Station(name: 'Oymapınar', latitude: 38.858741, longitude: 40.970740),
      Station(name: 'kurt', latitude: 38.834572, longitude: 41.269777),
      Station(name: 'Muş', latitude: 38.761917, longitude: 41.510827),
      Station(name: 'Sıcaksu', latitude: 38.649758, longitude: 42.144171),
      Station(name: 'Tatvan', latitude: 38.507060, longitude: 42.276269),
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

class RouteServiceHelper {
  static double calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371e3; // Dünya yarıçapı (metre)
    double phi1 = p1.latitude * pi / 180;
    double phi2 = p2.latitude * pi / 180;
    double deltaPhi = (p2.latitude - p1.latitude) * pi / 180;
    double deltaLambda = (p2.longitude - p1.longitude) * pi / 180;

    double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }
}
