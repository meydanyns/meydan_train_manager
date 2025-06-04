import 'package:flutter/material.dart';
import 'package:tren/models/inventory_manager.dart';
import 'package:tren/models/lokomotif.dart';
import 'package:tren/models/vagon.dart';
import 'package:provider/provider.dart';

void showMarketDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: const Text('MARKET'),
          content: SizedBox(
            height: 400,
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Lokomotifler'),
                    Tab(text: 'Vagonlar'),
                  ],
                ),
                Expanded(
                  child: Consumer<InventoryManager>(
                    builder: (context, inventoryManager, child) {
                      return TabBarView(
                        children: [
                          _buildLokomotifList(context, inventoryManager),
                          _buildVagonList(context, inventoryManager),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    },
  );
}

// Satınalma Onay iletişim kutusu fonksiyonu
Future<void> _showConfirmationDialog(
  BuildContext context,
  String message,
  VoidCallback onConfirm,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Onay'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Hayır'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Evet'),
            onPressed: () {
              Navigator.of(context).pop(); // İletişim kutusunu kapat
              onConfirm(); // Onaylandığında asıl işlemi çalıştır
            },
          ),
        ],
      );
    },
  );
}

Widget _buildLokomotifList(
    BuildContext context, InventoryManager inventoryManager) {
  return ListView.separated(
    shrinkWrap: true,
    itemCount: lokoListesi.length,
    itemBuilder: (context, index) {
      Lokomotif lokomotif = lokoListesi[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(
                  lokomotif.tip,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Image.asset(
                  lokomotif.resim,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Loko Tipi: ${lokomotif.tip}'),
                  Text('Hız: ${lokomotif.hiz} KM'),
                  Text('Güç: ${lokomotif.guc} HP'),
                  Text('Fiyat: ${lokomotif.fiyat} TL'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // DEĞİŞTİ: Direk satın alma yerine onay iletişim kutusu göster
                _showConfirmationDialog(
                  context,
                  '${lokomotif.fiyat} değerindeki ${lokomotif.tip} lokomotifi satın almak istediğinizden emin misiniz?',
                  () => _buyLokomotif(context, lokomotif, inventoryManager),
                );
              },
              child: const Text('SATIN AL'),
            ),
          ],
        ),
      );
    },
    separatorBuilder: (context, index) =>
        const Divider(thickness: 1, color: Colors.black),
  );
}

Widget _buildVagonList(
    BuildContext context, InventoryManager inventoryManager) {
  return ListView.separated(
    shrinkWrap: true,
    itemCount: vagonListesi.length,
    itemBuilder: (context, index) {
      Vagon vagon = vagonListesi[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(
                  vagon.tip,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Image.asset(
                  vagon.resim,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kapasite: ${vagon.kapasite.toString()} TON'),
                  Text('Fiyat: ${vagon.fiyat} TL'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // DEĞİŞTİ: Direk satın alma yerine onay iletişim kutusu göster
                _showConfirmationDialog(
                  context,
                  '${vagon.fiyat} değerindeki ${vagon.tip} vagonu satın almak istediğinizden emin misiniz?',
                  () => _buyVagon(context, vagon, inventoryManager),
                );
              },
              child: const Text('SATIN AL'),
            ),
          ],
        ),
      );
    },
    separatorBuilder: (context, index) =>
        const Divider(thickness: 1, color: Colors.black),
  );
}

void _buyLokomotif(BuildContext context, Lokomotif lokomotif,
    InventoryManager inventoryManager) {
  if (inventoryManager.kasa >= lokomotif.fiyat) {
    inventoryManager.addKasa(-lokomotif.fiyat);
    inventoryManager.addLokomotifStock(lokomotif.tip, 1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${lokomotif.tip} satın alındı!')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Yetersiz bakiye! ${lokomotif.fiyat - inventoryManager.kasa} TL eksiğiniz var.')),
    );
  }
}

void _buyVagon(
    BuildContext context, Vagon vagon, InventoryManager inventoryManager) {
  if (inventoryManager.kasa >= vagon.fiyat) {
    inventoryManager.addKasa(-vagon.fiyat);
    inventoryManager.addVagonStock(vagon.tip, 1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vagon.tip} satın alındı!')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Yetersiz bakiye! ${vagon.fiyat - inventoryManager.kasa} TL eksiğiniz var.')),
    );
  }
}
