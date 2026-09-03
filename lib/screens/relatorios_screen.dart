import 'package:flutter/material.dart';
import '../core/api.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  bool loading = true;
  Map<String, dynamic>? dashboard;
  Map<String, dynamic>? overtraining;
  List<dynamic> questionarios = [];
  List<dynamic> testes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => loading = true);
    try {
      final d = await Api.getDashboard();
      final o = await Api.getOvertraining();
      final q = await Api.listarQuestionarios();
      final t = await Api.listarTestes();

      if (mounted) {
        setState(() {
          dashboard = d;
          overtraining = o;
          questionarios = q;
          testes = t;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    final resumo = dashboard?["resumo"] ?? {};
    final kmTotal = double.tryParse(resumo["total_km"]?.toString() ?? "0") ?? 0.0;
    final ritmoMedio = int.tryParse(resumo["ritmo_medio"]?.toString() ?? "0") ?? 0;
    final totalTreinos = int.tryParse(resumo["total_treinos"]?.toString() ?? "0") ?? 0;
    final acwr = double.tryParse(overtraining?["acwr"]?.toString() ?? "0") ?? 1.0;

    // Último ACQ-5
    dynamic ultimoACQ5;
    for (var q in questionarios) {
      if (q["tipo"] == "acq5") {
        ultimoACQ5 = q;
        break;
      }
    }

    // Último MiniAQLQ
    dynamic ultimoMiniAQLQ;
    for (var q in questionarios) {
      if (q["tipo"] == "miniaqlq") {
        ultimoMiniAQLQ = q;
        break;
      }
    }

    // Último teste 3km
    dynamic ultimo3km;
    for (var t in testes) {
      if (t["tipo_teste"] == "3km") {
        ultimo3km = t;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Relatórios & Desempenho",
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
                  // Banner Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                            : [const Color(0xFF0066FF), const Color(0xFF3B82F6)],
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Relatório Integrado PaceMind",
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Performance na corrida alinhada ao controle respiratório.",
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
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

                  // 1. Resumo de Corrida & Carga
                  _cardSecao(
                    titulo: "1. Performance de Corrida",
                    icone: Icons.directions_run_rounded,
                    cor: const Color(0xFF0066FF),
                    cardBg: cardBg,
                    txtColor: txtColor,
                    isDark: isDark,
                    conteudo: [
                      _linhaDado("Quilometragem Total", "${kmTotal.toStringAsFixed(1)} km"),
                      _linhaDado("Treinos Concluídos", "$totalTreinos treinos"),
                      _linhaDado("Pace Médio Geral", _formatarPace(ritmoMedio)),
                      _linhaDado("Índice de Carga (ACWR)", "${acwr.toStringAsFixed(2)}x (${acwr > 1.5 ? 'Alto Risco' : 'Equilibrado'})"),
                      if (ultimo3km != null)
                        _linhaDado("vVO2max (Teste 3km)", "${ultimo3km['vvo2max_kmh'] ?? '-'} km/h"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Controle de Asma e Saúde Respiratória
                  _cardSecao(
                    titulo: "2. Saúde Respiratória (ACQ-5 & MiniAQLQ)",
                    icone: Icons.health_and_safety_rounded,
                    cor: const Color(0xFF10B981),
                    cardBg: cardBg,
                    txtColor: txtColor,
                    isDark: isDark,
                    conteudo: [
                      if (ultimoACQ5 != null) ...[
                        _linhaDado(
                          "Score ACQ-5 (Controle)",
                          "${ultimoACQ5['pontuacao_media']} pts - ${ultimoACQ5['classificacao'] ?? 'Controlada'}",
                        ),
                        _linhaDado("Última Avaliação ACQ-5", ultimoACQ5['criado_em']?.toString().split("T")[0] ?? "-"),
                      ] else
                        _linhaDado("ACQ-5", "Nenhum questionário respondido recentemente"),
                      const SizedBox(height: 8),
                      if (ultimoMiniAQLQ != null) ...[
                        _linhaDado(
                          "Score MiniAQLQ (Qualidade de Vida)",
                          "${ultimoMiniAQLQ['pontuacao_media']} / 7.0 pts - ${ultimoMiniAQLQ['classificacao'] ?? 'Excelente'}",
                        ),
                        _linhaDado("Última Avaliação MiniAQLQ", ultimoMiniAQLQ['criado_em']?.toString().split("T")[0] ?? "-"),
                      ] else
                        _linhaDado("MiniAQLQ", "Nenhum questionário respondido recentemente"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Parecer para o Treinador e Médico
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
                            Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF8B5CF6), size: 22),
                            SizedBox(width: 8),
                            Text(
                              "3. Parecer de Prescrição",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "O atleta apresenta um índice de carga de ${acwr.toStringAsFixed(2)}x com sintomas respiratórios avaliados. Recomenda-se manter treinos predominantemente em Zona 1 e Zona 2 (80%) e progredir os estímulos de alta intensidade apenas em semanas com ACQ-5 < 1.0.",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botão Compartilhar / Exportar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            content: Text("Relatório pronto para envio ao treinador/médico!"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text(
                        "Exportar / Compartilhar Relatório",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _cardSecao({
    required String titulo,
    required IconData icone,
    required Color cor,
    required Color cardBg,
    required Color txtColor,
    required bool isDark,
    required List<Widget> conteudo,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icone, color: cor, size: 22),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: txtColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...conteudo,
        ],
      ),
    );
  }

  Widget _linhaDado(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(valor, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
