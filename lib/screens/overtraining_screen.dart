import 'package:flutter/material.dart';
import '../core/api.dart';

class OvertrainingPage extends StatefulWidget {
  const OvertrainingPage({super.key});

  @override
  State<OvertrainingPage> createState() => _OvertrainingPageState();
}

class _OvertrainingPageState extends State<OvertrainingPage> {
  bool loading = true;
  String? erroCarregamento;
  Map<String, dynamic>? overtrainingData;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      loading = true;
      erroCarregamento = null;
    });

    try {
      final data = await Api.getOvertraining();
      if (!mounted) return;

      setState(() {
        overtrainingData = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar a análise de sobrecarga.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final cargaAguda = double.tryParse(overtrainingData?["carga_aguda"]?.toString() ?? "0") ?? 0.0;
    final cargaCronica = double.tryParse(overtrainingData?["carga_cronica"]?.toString() ?? "0") ?? 0.0;
    final acwr = double.tryParse(overtrainingData?["acwr"]?.toString() ?? "0") ?? 0.0;
    final mensagens = (overtrainingData?["mensagem"] as List? ?? []);
    final recomendacoes = (overtrainingData?["recomendacoes"] as List? ?? []);

    // Determinação do Estado Clínico / Fisiológico do Atleta
    String estadoGeral = "Zona Ideal (Sweet Spot)";
    String estadoDescricao =
        "Sua carga aguda está em equilíbrio ideal com o preparo acumulado no último mês. Baixo risco de lesão e alto ganho de condicionamento.";
    Color corEstado = const Color(0xFF10B981); // Verde
    IconData iconeEstado = Icons.verified_rounded;

    if (acwr > 1.5) {
      estadoGeral = "Alto Risco de Sobrecarga (Danger Zone)";
      estadoDescricao =
          "Você aumentou o volume ou a intensidade rápido demais nos últimos 7 dias. O risco de estiramentos, lesões articulares e fadiga crônica está elevado.";
      corEstado = const Color(0xFFEF4444); // Vermelho
      iconeEstado = Icons.warning_rounded;
    } else if (acwr >= 1.3 && acwr <= 1.5) {
      estadoGeral = "Zona de Alerta (Carga Acelerada)";
      estadoDescricao =
          "Carga em ritmo de crescimento acelerado. Priorize boas noites de sono, hidratação e cumpra os dias de descanso programados para recuperar o organismo.";
      corEstado = const Color(0xFFF59E0B); // Laranja
      iconeEstado = Icons.warning_amber_rounded;
    } else if (acwr < 0.8 && cargaCronica > 0) {
      estadoGeral = "Sub-Treinamento (Fase Regenerativa)";
      estadoDescricao =
          "A carga dos últimos 7 dias está abaixo da sua capacidade crônica habitual. Você está descansado e pode aumentar os treinos gradualmente.";
      corEstado = const Color(0xFF0066FF); // Azul
      iconeEstado = Icons.battery_charging_full_rounded;
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
          : RefreshIndicator(
              color: const Color(0xFF0066FF),
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Card Hero com Diagnóstico Fisiológico
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: corEstado.withValues(alpha: isDark ? 0.16 : 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: corEstado.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: corEstado.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconeEstado, color: corEstado, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DIAGNÓSTICO FISIOLÓGICO",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: corEstado,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    estadoGeral,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: txtColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          estadoDescricao,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Barra Espectral do Índice ACWR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Índice ACWR (Agudo / Crônico)",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: txtColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: corEstado.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${acwr.toStringAsFixed(2)}x",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: corEstado),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Barra com gradiente indicativo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (acwr / 2.0).clamp(0.0, 1.0),
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(corEstado),
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Escala explicativa da régua
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _legendaFaixa("< 0.8", "Regenerativo", const Color(0xFF0066FF)),
                            _legendaFaixa("0.8 - 1.3", "Ideal", const Color(0xFF10B981)),
                            _legendaFaixa("1.3 - 1.5", "Atenção", const Color(0xFFF59E0B)),
                            _legendaFaixa("> 1.5", "Perigo", const Color(0xFFEF4444)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cards Carga Aguda vs Carga Crônica
                  Row(
                    children: [
                      Expanded(
                        child: _cardCargaComparativa(
                          titulo: "Carga Aguda",
                          subtitulo: "Últimos 7 dias (Fadiga)",
                          valor: cargaAguda.toStringAsFixed(0),
                          icone: Icons.bolt_rounded,
                          cor: const Color(0xFF0066FF),
                          cardBg: cardBg,
                          borderColor: borderColor,
                          txtColor: txtColor,
                          subColor: subColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _cardCargaComparativa(
                          titulo: "Carga Crônica",
                          subtitulo: "Média 28 dias (Preparo)",
                          valor: cargaCronica.toStringAsFixed(0),
                          icone: Icons.shield_rounded,
                          cor: const Color(0xFF8B5CF6),
                          cardBg: cardBg,
                          borderColor: borderColor,
                          txtColor: txtColor,
                          subColor: subColor,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Recomendações Práticas do Treinador
                  Text(
                    "Recomendações Clínicas & Treinamento",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mensagens.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.priority_high_rounded, color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Pontos de Atenção Imediata:",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: txtColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...mensagens.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Icon(Icons.circle, size: 7, color: Color(0xFFF59E0B)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        m.toString(),
                                        style: TextStyle(color: txtColor, fontSize: 13.5, height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 14),
                          Divider(color: borderColor),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Orientações do PaceMind:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: txtColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (recomendacoes.isNotEmpty)
                          ...recomendacoes.map((r) => _itemRecomendacao(r.toString(), txtColor))
                        else ...[
                          _itemRecomendacao(
                            "80% do seu volume semanal de corrida deve ser mantido em Zona 1 e Zona 2 (rodagens leves regenerativas).",
                            txtColor,
                          ),
                          _itemRecomendacao(
                            "Mantenha 1 a 2 dias de descanso total na semana para evitar a saturação de lactato e lesões por sobreuso.",
                            txtColor,
                          ),
                          _itemRecomendacao(
                            "Monitore o sono: dormir pelo menos 7 a 8 horas por noite é crucial para a supercompensação fisiológica.",
                            txtColor,
                          ),
                          _itemRecomendacao(
                            "Em caso de asma induzida pelo exercício (AIE), realize aquecimentos graduais de 15 minutos em Z1 antes de correr.",
                            txtColor,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Explicação Científica do Modelo ACWR
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.school_rounded, color: Color(0xFF0066FF), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Ciência por trás do ACWR",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: txtColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "O método ACWR (Acute:Chronic Workload Ratio), desenvolvido pelo pesquisador Tim Gabbett, compara a fadiga acumulada na última semana com o preparo físico dos últimos 28 dias. Quando o índice ultrapassa 1.5, o risco relativo de lesão sobe de 2x para 4x. Manter-se na faixa entre 0.8 e 1.3 garante melhora constante de performance com máxima segurança.",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: subColor,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _legendaFaixa(String valor, String label, Color cor) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cor),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: cor.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _cardCargaComparativa({
    required String titulo,
    required String subtitulo,
    required String valor,
    required IconData icone,
    required Color cor,
    required Color cardBg,
    required Color borderColor,
    required Color txtColor,
    required Color subColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor, size: 20),
              ),
              Text(
                "U.A.",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: txtColor),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cor),
          ),
          Text(
            subtitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: subColor),
          ),
        ],
      ),
    );
  }

  Widget _itemRecomendacao(String texto, Color txtColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline_rounded, size: 17, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(color: txtColor, fontSize: 13, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
