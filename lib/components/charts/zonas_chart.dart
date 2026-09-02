import 'package:flutter/material.dart';

class ZonasChart extends StatelessWidget {
  final Map<String, dynamic> zonas;

  const ZonasChart({super.key, required this.zonas});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Z1: ${zonas["z1"] ?? 0}"),
    );
  }
}