import 'package:flutter/material.dart';
import '../models/train.dart';

class TrainController extends StatelessWidget {
  final Train train;
  final Function() onStart;

  const TrainController({
    super.key,
    required this.train,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Tren: ${train.name}'),
        Text('Mevcut İstasyon: ${train.currentStation.name}'),
        ElevatedButton(onPressed: onStart, child: const Text('Başlat')),
      ],
    );
  }
}
