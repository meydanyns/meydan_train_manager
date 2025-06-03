import 'package:flutter/material.dart';
import 'package:tren/models/lokomotif.dart';
import 'package:tren/models/vagon.dart';

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
                  child: TabBarView(
                    children: [
                      _buildLokomotifList(),
                      _buildVagonList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'startStation': null,
                  'endStation': null,
                  'lokomotifler': [],
                  'vagonlar': [],
                });
              },
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildLokomotifList() {
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
                debugPrint('${lokomotif.tip} satın alındı');
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

Widget _buildVagonList() {
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
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                debugPrint('${vagon.tip} satın alındı');
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
