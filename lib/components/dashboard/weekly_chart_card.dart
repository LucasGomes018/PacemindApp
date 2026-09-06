import 'package:flutter/material.dart';
import '../../components/charts/km_chart.dart';

class WeeklyChartCard extends StatefulWidget {
  final List<Map<String, dynamic>> dados;

  const WeeklyChartCard({super.key, required this.dados});

  @override
  State<WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends State<WeeklyChartCard> {
  bool isBarChart = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;

    final kmList = widget.dados.map((e) {
      final v = e["km"];
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }).toList();

    final totalKm = kmList.fold(0.0, (a, b) => a + b);
    final maxKm = kmList.fold(0.0, (a, b) => a > b ? a : b);
    final diasComTreino = kmList.where((km) => km > 0).length;
    final mediaKm = kmList.isEmpty ? 0.0 : totalKm / kmList.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF0066FF).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Título, Total e Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Evolução Semanal",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "Quilometragem (km)",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Badge de Total
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${totalKm.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Botão seletor de gráfico (Linha / Barras)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _chartTypeButton(
                      icon: Icons.show_chart_rounded,
                      isActive: !isBarChart,
                      onTap: () {
                        if (isBarChart) setState(() => isBarChart = false);
                      },
                    ),
                    _chartTypeButton(
                      icon: Icons.bar_chart_rounded,
                      isActive: isBarChart,
                      onTap: () {
                        if (!isBarChart) setState(() => isBarChart = true);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico
          SizedBox(
            height: 200,
            child: KmChart(
              dados: widget.dados,
              isBarChart: isBarChart,
            ),
          ),

          if (widget.dados.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 16),

            // Mini Estatísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(
                  icon: Icons.emoji_events_outlined,
                  label: "Maior Treino",
                  valor: "${maxKm.toStringAsFixed(1)} km",
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _miniStat(
                  icon: Icons.speed_rounded,
                  label: "Média Diária",
                  valor: "${mediaKm.toStringAsFixed(1)} km",
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _miniStat(
                  icon: Icons.calendar_today_rounded,
                  label: "Dias Ativos",
                  valor: "$diasComTreino/${widget.dados.length}",
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chartTypeButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0066FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String valor,
    required bool isDark,
  }) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF0066FF),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
