import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Consumer için gerekli import
import 'package:tren/models/inventory_manager.dart'; // InventoryManager için
import 'package:tren/models/lokomotif.dart'; // Lokomotif modeli için
import 'package:tren/models/vagon.dart'; // Vagon modeli için

void showDepoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Consumer<InventoryManager>(
        builder: (context, inventoryManager, child) {
          return DefaultTabController(
            length: 2,
            child: AlertDialog(
              title: const Text('DEPPO'),
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
                          // Lokomotifler
                          ListView.builder(
                            itemCount: inventoryManager.lokomotifler.length,
                            itemBuilder: (context, index) {
                              Lokomotif lokomotif =
                                  inventoryManager.lokomotifler[index];
                              return _buildInventoryItem(
                                image: lokomotif.resim,
                                name: lokomotif.tip,
                                stock: lokomotif.adet,
                                detail: 'Hız: ${lokomotif.hiz} KM',
                              );
                            },
                          ),
                          // Vagonlar
                          ListView.builder(
                            itemCount: inventoryManager.vagonlar.length,
                            itemBuilder: (context, index) {
                              Vagon vagon = inventoryManager.vagonlar[index];
                              return _buildInventoryItem(
                                image: vagon.resim,
                                name: vagon.tip,
                                stock: vagon.adet,
                                detail: 'Kapasite: ${vagon.kapasite} TON',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildInventoryItem({
  required String image,
  required String name,
  required int stock,
  required String detail,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Image.asset(image, width: 60, height: 60),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Stok: $stock'),
              Text(detail),
            ],
          ),
        ),
      ],
    ),
  );
}
