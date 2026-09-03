import 'package:flutter/material.dart';
import '../core/api.dart';

class OvertrainingPage extends StatefulWidget {
  const OvertrainingPage({super.key});

  @override
  State<OvertrainingPage> createState() => _OvertrainingPageState();
}

class _OvertrainingPageState extends State<OvertrainingPage> {
  bool loading = true;
  Map<String, dynamic>? overtrainingData;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => loading = true);
    try {
      final data = await Api.getOvertraining();
      if (mounted) {
        setState(() {
          overtrainingData = data;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    final cargaAguda = double.tryParse(overtrainingData?["carga_aguda"]?.toString() ?? "0") ?? 0.0;
    final cargaCronica = double.tryParse(overtrainingData?["carga_cronica"]?.toString() ?? "0") ?? 0.0;
    final acwr = double.tryParse(overtrainingData?["acwr"]?.toString() ?? "0") ?? 0.0;
    final mensagens = (overtrainingData?["mensagem"] as List? ?? []);
    final recomendacoes = (overtrainingData?["recomendacoes"] as List? ?? []);

    // Determinação do Estado Clínico / Fisiológico
    String estadoGeral = "Evoluindo Bem (Zona Ideal)";
    String estadoSub = "Sua carga de treino está equilibrada, promovendo ganho de condicionamento com baixo risco de lesão.";
    Color corEstado = const Color(0xFF10B981); // Verde
    IconData iconeEstado = Icons.check_circle_rounded;

    if (acwr > 1.5) {
      estadoGeral = "Treinando Demais (Alto Risco de Overtraining)";
      estadoSub = "Você aumentou o volume ou intensidade rápido demais nos últimos 7 dias. Alto risco de lesão e fadiga crônica.";
      corEstado = const Color(0xFFEF4444); // Vermelho
      iconeEstado = Icons.warning_rounded;
    } else if (acwr < 0.8 && cargaCronica > 0) {
      estadoGeral = "Treinando Pouco (Sub-treinamento)";
      estadoSub = "A carga dos últimos 7 dias está abaixo da sua capacidade crônica. É seguro progredir o volume gradualmente.";
      corEstado = const Color(0xFF3B82F6); // Azul
      iconeEstado = Icons.info_outline_rounded;
    } else if (acwr >= 1.3 && acwr <= 1.5) {
      estadoGeral = "Zona de Alerta (Atenção ao Aumento de Carga)";
      estadoSub = "Carga em fase de crescimento acelerado. Mantenha os dias de descanso programados para recuperar a musculatura.";
      corEstado = const Color(0xFFF59E0B); // Amarelo/Laranja
      iconeEstado = Icons.warning_amber_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Carga & Overtraining",
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
                  // Card Principal de Diagnóstico
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: corEstado.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: corEstado.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: corEstado.withValues(alpha: 0.2),
                              child: Icon(iconeEstado, color: corEstado, size: 30),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Diagnóstico de Carga",
                                    style: TextStyle(fontSize: 13, color: corEstado, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    estadoGeral,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: txtColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          estadoSub,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Gauge / Barra do Índice ACWR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Índice ACWR (Agudo : Crônico)",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: txtColor),
                            ),
                            Text(
                              "${acwr.toStringAsFixed(2)}x",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corEstado),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (acwr / 2.0).clamp(0.0, 1.0),
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(corEstado),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("< 0.8: Pouco", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text("0.8 - 1.3: Ideal", style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                            Text("> 1.5: Perigo", style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Cards Carga Aguda vs Carga Crônica
                  Row(
                    children: [
                      Expanded(
                        child: _cardCarga(
                          "Carga Aguda",
                          "Últimos 7 dias",
                          cargaAguda.toStringAsFixed(0),
                          Icons.bolt_rounded,
                          const Color(0xFF0066FF),
                          cardBg,
                          txtColor,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _cardCarga(
                          "Carga Crônica",
                          "Média 28 dias",
                          cargaCronica.toStringAsFixed(0),
                          Icons.timeline_rounded,
                          const Color(0xFF8B5CF6),
                          cardBg,
                          txtColor,
                          isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Recomendações Práticas
                  Text(
                    "Recomendações do Treinador",
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
                        if (mensagens.isNotEmpty) ...[
                          const Text(
                            "Pontos de Atenção:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          ...mensagens.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 8, color: Color(0xFF0066FF)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(m.toString(), style: TextStyle(color: txtColor, fontSize: 13.5)),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 12),
                        ],
                        const Text(
                          "O que fazer agora:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        if (recomendacoes.isNotEmpty)
                          ...recomendacoes.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(r.toString(), style: TextStyle(color: txtColor, fontSize: 13.5)),
                                    ),
                                  ],
                                ),
                              ))
                        else ...[
                          _itemRecomendacao("Mantenha 1 a 2 dias de descanso total na semana para regeneração muscular.", txtColor),
                          _itemRecomendacao("80% do volume deve ser em Zona 1 e Zona 2 (rodagens leves).", txtColor),
                          _itemRecomendacao("Durma pelo menos 7 a 8 horas por noite para absorver a carga de treino.", txtColor),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Explicação didática do ACWR
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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
                            Icon(Icons.school_rounded, color: Color(0xFF0066FF), size: 22),
                            SizedBox(width: 10),
                            Text(
                              "Como funciona o cálculo?",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "O método ACWR (Acute:Chronic Workload Ratio) compara o que você treinou na última semana (fadiga) com o que treinou no último mês (preparo físico). Se a fadiga superar demais o preparo (> 1.5x), o risco de lesão aumenta exponencialmente.",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            height: 1.4,
                          ),
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

  Widget _cardCarga(
    String titulo,
    String subtitulo,
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
          Text(
            valor,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: txtColor),
          ),
          Text(titulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cor)),
          Text(subtitulo, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _itemRecomendacao(String texto, Color txtColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: TextStyle(color: txtColor, fontSize: 13.5))),
        ],
      ),
    );
  }
}
