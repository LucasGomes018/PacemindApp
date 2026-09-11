import 'package:flutter/material.dart';
import 'stat_card.dart';

class SummaryGrid extends StatelessWidget {
  final String km;
  final String tempo;
  final String treinos;
  final String carga;

  const SummaryGrid({
    super.key,
    required this.km,
    required this.tempo,
    required this.treinos,
    required this.carga,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.route,
                title: "KM",
                value: km,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: StatCard(
                icon: Icons.timer,
                title: "Tempo",
                value: tempo,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.fitness_center,
                title: "Treinos",
                value: treinos,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: StatCard(
                icon: Icons.bolt,
                title: "Carga",
                value: carga,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}