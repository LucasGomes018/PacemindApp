import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api.dart';

class EvolucaoPage extends StatefulWidget {
  const EvolucaoPage({super.key});

  @override
  State<EvolucaoPage> createState() => _EvolucaoPageState();
}

class _EvolucaoPageState extends State<EvolucaoPage> {
  bool loading = true;
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? comparacaoData;
  List<dynamic> treinos = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => loading = true);
    try {
      final dash = await Api.getDashboard();
      Map<String, dynamic> comp = {};
      List<dynamic> trs = [];

      try {
        comp = await Api.getComparacaoSemanal();
      } catch (_) {}

      try {
        trs = await Api.listarTreinosConcluidos();
      } catch (_) {}

      if (mounted) {
        setState(() {
          dashboardData = dash;
          comparacaoData = comp;
          treinos = trs;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  String _formatarPace(dynamic segundos) {
    if (segundos == null) return "-";
    final total = int.tryParse(segundos.toString()) ?? 0;
    if (total <= 0) return "-";
    final min = total ~/ 60;
    final seg = total % 60;
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} /km";
  }

  String _formatarTempo(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    if (h > 0) return "${h}h ${m}m";
    return "${m}m";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    // Métricas
    final resumo = dashboardData?["resumo"] ?? {};
    final kmTotal = double.tryParse(resumo["total_km"]?.toString() ?? "0") ?? 0.0;
    final tempoTotal = int.tryParse(resumo["total_tempo"]?.toString() ?? "0") ?? 0;
    final ritmoMedio = int.tryParse(resumo["ritmo_medio"]?.toString() ?? "0") ?? 0;
    final totalTreinos = int.tryParse(resumo["total_treinos"]?.toString() ?? "0") ?? 0;

    // Comparação Semana Atual vs Anterior
    final semanaAtualKm = double.tryParse(
            comparacaoData?["semana_atual"]?.toString() ??
                dashboardData?["comparacao"]?["semana_atual"]?.toString() ??
                "0") ??
        0.0;
    final semanaAnteriorKm = double.tryParse(
            comparacaoData?["semana_anterior"]?.toString() ??
                dashboardData?["comparacao"]?["semana_anterior"]?.toString() ??
                "0") ??
        0.0;

    final diffKm = semanaAtualKm - semanaAnteriorKm;
    final pctEvolucaoSemana = semanaAnteriorKm > 0
        ? ((diffKm / semanaAnteriorKm) * 100).toStringAsFixed(1)
        : (semanaAtualKm > 0 ? "+100" : "0");

    // Longão da Semana (maior treino)
    double longaoKm = 0.0;
    for (var t in treinos) {
      final d = double.tryParse(t["distancia_km"]?.toString() ?? "0") ?? 0.0;
      if (d > longaoKm) longaoKm = d;
    }

    // Dias de descanso estimados na semana
    final diasTreinados = totalTreinos.clamp(0, 7);
    final diasDescanso = (7 - diasTreinados).clamp(0, 7);

    // Dados para gráficos semanais (km)
    final semanalList = (dashboardData?["semanal"] as List? ?? []);
    final cargaList = (dashboardData?["carga"] as List? ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Evolução & Comparações",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Banner Principal
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFF0066FF), const Color(0xFF00C6FF)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_graph_rounded, color: Colors.white, size: 26),
                            SizedBox(width: 10),
                            Text(
                              "Comparativo Semanal de Volume",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Esta Semana", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "${semanaAtualKm.toStringAsFixed(1)} km",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: diffKm >= 0
                                    ? Colors.greenAccent.withValues(alpha: 0.25)
                                    : Colors.orangeAccent.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    diffKm >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$pctEvolucaoSemana%",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("Semana Anterior", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "${semanaAnteriorKm.toStringAsFixed(1)} km",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Grid de Métricas de Volume e Intensidade
                  Row(
                    children: [
                      Expanded(
                        child: _cardMetrica(
                          "Longão da Semana",
                          "${longaoKm.toStringAsFixed(1)} km",
                          Icons.route_rounded,
                          const Color(0xFF0066FF),
                          cardBg,
                          txtColor,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _cardMetrica(
                          "Pace Médio Geral",
                          _formatarPace(ritmoMedio),
                          Icons.speed_rounded,
                          const Color(0xFF10B981),
                          cardBg,
                          txtColor,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _cardMetrica(
                          "Dias de Descanso",
                          "$diasDescanso dias",
                          Icons.bed_rounded,
                          const Color(0xFF8B5CF6),
                          cardBg,
                          txtColor,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _cardMetrica(
                          "Tempo Total",
                          _formatarTempo(tempoTotal),
                          Icons.timer_outlined,
                          const Color(0xFFF59E0B),
                          cardBg,
                          txtColor,
                          isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Gráfico de Volume Semanal (km)
                  Text(
                    "Evolução da Quilometragem Semanal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: semanalList.isEmpty
                        ? const Center(
                            child: Text(
                              "Registre treinos para visualizar o gráfico de volume semanal.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _buildGraficoSemanal(semanalList, isDark),
                  ),

                  const SizedBox(height: 26),

                  // Gráfico de Carga de Treino
                  Text(
                    "Evolução da Carga de Treino (RPE x Duração)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: cargaList.isEmpty
                        ? const Center(
                            child: Text(
                              "Adicione sensações de esforço nos treinos para acompanhar a carga.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _buildGraficoCarga(cargaList, isDark),
                  ),

                  const SizedBox(height: 26),

                  // Evolução de Ritmo e Frequência Cardíaca
                  Text(
                    "Intensidade & Frequência Cardíaca",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 24),
                            SizedBox(width: 10),
                            Text(
                              "Controle Cardíaco nos Treinos",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Ao registrar sua FC média e máxima em cada corrida, o app detecta se você está evoluindo a velocidade sem elevar a exigência cardíaca (ganho de eficiência aeróbica).",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _itemResumoIntensidade("Treinos Salvos", "$totalTreinos", Colors.blue),
                            _itemResumoIntensidade("Volume Total", "${kmTotal.toStringAsFixed(0)} km", Colors.green),
                            _itemResumoIntensidade("Pace Médio", _formatarPace(ritmoMedio), Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _cardMetrica(
    String titulo,
    String valor,
    IconData icon,
    Color cor,
    Color cardBg,
    Color txtColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cor.withValues(alpha: 0.15),
            child: Icon(icon, color: cor, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemResumoIntensidade(String titulo, String valor, Color cor) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valor,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildGraficoSemanal(List<dynamic> lista, bool isDark) {
    final spots = <FlSpot>[];
    for (int i = 0; i < lista.length; i++) {
      final km = double.tryParse(lista[i]["km"]?.toString() ?? "0") ?? 0.0;
      spots.add(FlSpot(i.toDouble(), km));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF0066FF),
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0066FF).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoCarga(List<dynamic> lista, bool isDark) {
    final spots = <FlSpot>[];
    for (int i = 0; i < lista.length; i++) {
      final c = double.tryParse(lista[i]["carga"]?.toString() ?? "0") ?? 0.0;
      spots.add(FlSpot(i.toDouble(), c));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFF59E0B),
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
