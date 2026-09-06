import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class KmChart extends StatefulWidget {
  final List<dynamic> dados;
  final bool isBarChart;

  const KmChart({
    super.key,
    required this.dados,
    this.isBarChart = false,
  });

  @override
  State<KmChart> createState() => _KmChartState();
}

class _KmChartState extends State<KmChart> {
  int? touchedIndex;

  String _formatDiaLabel(dynamic raw, int index) {
    const fallbackDays = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"];
    if (widget.dados.isNotEmpty && index < widget.dados.length) {
      final item = widget.dados[index];
      if (item is Map) {
        if (item["dia"] != null && item["dia"].toString().trim().isNotEmpty) {
          return item["dia"].toString().trim();
        }
      }
    }
    if (raw != null && raw.toString().trim().isNotEmpty) {
      final s = raw.toString().trim();
      if (fallbackDays.contains(s) || s.length <= 4) return s;
    }
    return index < fallbackDays.length ? fallbackDays[index] : "${index + 1}";
  }

  String _getDiaCompleto(dynamic raw, int index) {
    const fallbackDays = [
      "Segunda-feira",
      "Terça-feira",
      "Quarta-feira",
      "Quinta-feira",
      "Sexta-feira",
      "Sábado",
      "Domingo"
    ];
    if (widget.dados.isNotEmpty && index < widget.dados.length) {
      final item = widget.dados[index];
      if (item is Map) {
        if (item["dia_completo"] != null && item["dia_completo"].toString().trim().isNotEmpty) {
          return item["dia_completo"].toString().trim();
        }
      }
    }
    return index < fallbackDays.length ? fallbackDays[index] : "Dia ${index + 1}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final axisTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (widget.dados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                color: Color(0xFF0066FF),
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Nenhum treino registrado",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Seus quilômetros semanais aparecerão aqui.",
              style: TextStyle(
                fontSize: 13,
                color: axisTextColor,
              ),
            ),
          ],
        ),
      );
    }

    final kmList = widget.dados.map((e) {
      final v = e["km"];
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }).toList();

    final maxKm = kmList.fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxKm <= 0 ? 5.0 : (maxKm * 1.25).ceilToDouble();
    final intervalY = maxY <= 5 ? 1.0 : (maxY / 4).ceilToDouble();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: widget.isBarChart
          ? _buildBarChart(kmList, maxY, intervalY, gridColor, axisTextColor, isDark)
          : _buildLineChart(kmList, maxY, intervalY, gridColor, axisTextColor, isDark),
    );
  }

  Widget _buildLineChart(
    List<double> kmList,
    double maxY,
    double intervalY,
    Color gridColor,
    Color axisTextColor,
    bool isDark,
  ) {
    final spots = kmList.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (kmList.length - 1).toDouble().clamp(1.0, double.infinity),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) => FlLine(
            color: gridColor,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value > maxY) return const SizedBox.shrink();
                return Text(
                  "${value.toInt()} km",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: axisTextColor,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.dados.length) {
                  return const SizedBox.shrink();
                }
                final raw = widget.dados[index]["dia"] ?? widget.dados[index]["semana"];
                final label = _formatDiaLabel(raw, index);
                final isSelected = touchedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF0066FF)
                          : axisTextColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
            ),
            barWidth: 3.5,
            isStrokeCapRound: true,
            shadow: Shadow(
              color: const Color(0xFF0066FF).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = touchedIndex == index;
                return FlDotCirclePainter(
                  radius: isSelected ? 6 : 4,
                  color: Colors.white,
                  strokeWidth: isSelected ? 3.5 : 2.5,
                  strokeColor: isSelected
                      ? const Color(0xFF00C6FF)
                      : const Color(0xFF0066FF),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0066FF).withValues(alpha: 0.32),
                  const Color(0xFF00C6FF).withValues(alpha: 0.03),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              setState(() {
                touchedIndex = response.lineBarSpots!.first.spotIndex;
              });
            } else {
              setState(() {
                touchedIndex = null;
              });
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFF0F172A),
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.spotIndex;
                final raw = widget.dados[index]["dia"] ?? widget.dados[index]["semana"];
                final dia = _getDiaCompleto(raw, index);
                return LineTooltipItem(
                  "$dia\n",
                  const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: "${spot.y.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(
    List<double> kmList,
    double maxY,
    double intervalY,
    Color gridColor,
    Color axisTextColor,
    bool isDark,
  ) {
    final barGroups = List.generate(kmList.length, (index) {
      final km = kmList[index];
      final isSelected = touchedIndex == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: km,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isSelected
                  ? const [Color(0xFF00C6FF), Color(0xFF38BDF8)]
                  : const [Color(0xFF0066FF), Color(0xFF00C6FF)],
            ),
            width: 18,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : const Color(0xFFF1F5F9),
            ),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) => FlLine(
            color: gridColor,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value > maxY) return const SizedBox.shrink();
                return Text(
                  "${value.toInt()} km",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: axisTextColor,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.dados.length) {
                  return const SizedBox.shrink();
                }
                final raw = widget.dados[index]["dia"] ?? widget.dados[index]["semana"];
                final label = _formatDiaLabel(raw, index);
                final isSelected = touchedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF0066FF)
                          : axisTextColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (response?.spot != null) {
              setState(() {
                touchedIndex = response!.spot!.touchedBarGroupIndex;
              });
            } else {
              setState(() {
                touchedIndex = null;
              });
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFF0F172A),
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final raw = widget.dados[groupIndex]["dia"] ?? widget.dados[groupIndex]["semana"];
              final dia = _getDiaCompleto(raw, groupIndex);
              return BarTooltipItem(
                "$dia\n",
                const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: "${rod.toY.toStringAsFixed(1)} km",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
