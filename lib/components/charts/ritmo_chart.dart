import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RitmoChart extends StatelessWidget {
  final List<dynamic> dados;

  const RitmoChart({super.key, required this.dados});

  // ⏱️ converte segundos → mm:ss
  String formatarRitmo(double segundos) {
    final min = (segundos ~/ 60);
    final seg = (segundos % 60).toInt();
    return "$min:${seg.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) {
      return const Center(child: Text("Sem dados de ritmo"));
    }

    // 🔥 transforma dados em pontos do gráfico
    final spots = dados.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      final ritmo = (item["ritmo_medio"] is num)
          ? (item["ritmo_medio"] as num).toDouble()
          : 0.0;

      return FlSpot(index.toDouble(), ritmo);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  formatarRitmo(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text("${value.toInt() + 1}");
              },
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true),
          ),
        ],

        // 🧠 TOOLTIP (quando toca/clica)
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final ritmo = spot.y;
                return LineTooltipItem(
                  formatarRitmo(ritmo),
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}