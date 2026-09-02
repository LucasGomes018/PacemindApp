import 'package:flutter/material.dart';
import 'stat_card.dart';

class DashboardStats extends StatelessWidget {
  final double kmSemana;
  final int tempo;
  final int carga;
  final int treinos;

  const DashboardStats({
    super.key,
    required this.kmSemana,
    required this.tempo,
    required this.carga,
    required this.treinos,
  });

  String _formatarTempo(int totalSegundos) {
    final horas = totalSegundos ~/ 3600;
    final minutos = (totalSegundos % 3600) ~/ 60;
    final segundos = totalSegundos % 60;

    if (horas > 0) {
      return "${horas}h ${minutos}m";
    }

    if (minutos > 0) {
      return "${minutos}m ${segundos}s";
    }

    return "${segundos}s";
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      children: [
        StatCard(
          icon: Icons.route,
          title: "KM",
          value: kmSemana.toStringAsFixed(1),
          color: const Color(0xFF0066FF),
        ),
        StatCard(
          icon: Icons.timer,
          title: "Tempo",
          value: _formatarTempo(tempo),
          color: Colors.orange,
        ),
        StatCard(
          icon: Icons.local_fire_department,
          title: "Carga",
          value: "$carga",
          color: Colors.red,
        ),
        StatCard(
          icon: Icons.fitness_center,
          title: "Treinos",
          value: "$treinos",
          color: Colors.green,
        ),
      ],
    );
  }
}