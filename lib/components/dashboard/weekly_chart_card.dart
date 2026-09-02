import 'package:flutter/material.dart';
import '../../components/charts/km_chart.dart';

class WeeklyChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> dados;

  const WeeklyChartCard({
    super.key,
    required this.dados,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Color(0xFF0066FF),
              ),

              SizedBox(width: 8),

              Text(
                "Evolução semanal",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Color(0xFF0066FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 220,
            child: KmChart(
              dados: dados,
            ),
          ),
        ],
      ),
    );
  }
}