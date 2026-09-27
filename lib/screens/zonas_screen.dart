import 'package:flutter/material.dart';
import '../core/api.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';

class ZonasPage extends StatefulWidget {
  const ZonasPage({super.key});

  @override
  State<ZonasPage> createState() => _ZonasPageState();
}

class _ZonasPageState extends State<ZonasPage> {
  bool loading = true;
  String? erroCarregamento;
  Map<String, dynamic>? zonasPace;
  Map<String, dynamic>? distribuicao;
  Map<String, dynamic>? analise;
  int paceReferencia = 330; // default 5:30 min/km (330 segundos)

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
      final paceData = await Api.getZonasPace();
      final distData = await Api.getZonasDistribuicao();
      final analiseData = await Api.getZonasAnalise();

      if (!mounted) return;

      setState(() {
        zonasPace = paceData;
        distribuicao = distData;
        analise = analiseData;
        if (paceData["pace_referencia"] != null) {
          paceReferencia = int.tryParse(paceData["pace_referencia"].toString()) ?? 330;
        }
        loading = false;
        erroCarregamento = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar as zonas fisiológicas.";
      });
    }
  }

  String _formatarPace(int segundos) {
    if (segundos <= 0) return "-";
    final min = segundos ~/ 60;
    final seg = segundos % 60;
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} /km";
  }

  String _formatarTempo(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    if (h > 0) return "${h}h ${m}m";
    return "${m}m";
  }

  void _modalSimuladorPace() {
    int minSimulado = paceReferencia ~/ 60;
    int segSimulado = paceReferencia % 60;

    AppModal.showBottomSheet(
      context: context,
      title: "Simulador de Zonas",
      subtitle: "Ajuste o pace de referência para simular suas zonas",
      icon: Icons.tune_rounded,
      iconColor: const Color(0xFF0066FF),
      builder: (ctx, scrollController) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
            final txtColor = Theme.of(modalCtx).colorScheme.onSurface;
            final totalSeg = minSimulado * 60 + segSimulado;

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0066FF).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Pace de Referência Simulado",
                        style: TextStyle(fontSize: 13, color: Color(0xFF0066FF), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatarPace(totalSeg),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: txtColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Equivalente a ${(3600 / totalSeg).toStringAsFixed(1)} km/h",
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  "Minutos: $minSimulado min",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txtColor),
                ),
                Slider(
                  value: minSimulado.toDouble(),
                  min: 3,
                  max: 9,
                  divisions: 6,
                  activeColor: const Color(0xFF0066FF),
                  onChanged: (v) {
                    setModalState(() => minSimulado = v.toInt());
                  },
                ),
                const SizedBox(height: 10),

                Text(
                  "Segundos: $segSimulado seg",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txtColor),
                ),
                Slider(
                  value: segSimulado.toDouble(),
                  min: 0,
                  max: 55,
                  divisions: 11,
                  activeColor: const Color(0xFF0066FF),
                  onChanged: (v) {
                    setModalState(() => segSimulado = v.toInt());
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      setState(() {
                        paceReferencia = totalSeg;
                      });
                      Navigator.pop(ctx);
                      AppSnackBar.sucesso(
                        context,
                        "Zonas recalculadas para ${_formatarPace(totalSeg)}/km.",
                        titulo: "Zonas Atualizadas",
                      );
                    },
                    child: const Text("Aplicar Simulação", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Definição das 5 Zonas Fisiológicas
    final z1Pace = (paceReferencia * 1.30).round();
    final z2Pace = (paceReferencia * 1.15).round();
    final z3Pace = (paceReferencia * 1.00).round();
    final z4Pace = (paceReferencia * 0.90).round();
    final z5Pace = (paceReferencia * 0.80).round();

    final zonasInfo = [
      {
        "nome": "Zona 1",
        "subtitulo": "Recuperação Ativa & Regenerativo",
        "descricao": "Melhora a circulação sem acúmulo de lactato. Essencial no pós-treino e aquecimento.",
        "cor": const Color(0xFF10B981),
        "pace": "> ${_formatarPace(z1Pace)}",
        "key": "z1",
        "fc": "< 65% FC Máx",
        "tipo": "Rodagem muito leve",
      },
      {
        "nome": "Zona 2",
        "subtitulo": "Base Aeróbica (Endurance)",
        "descricao": "Queima eficiente de gordura e expansão capilar. Deve compor 80% do seu volume semanal.",
        "cor": const Color(0xFF06B6D4),
        "pace": "${_formatarPace(z1Pace)} - ${_formatarPace(z2Pace)}",
        "key": "z2",
        "fc": "65% - 75% FC Máx",
        "tipo": "Longão / Rodagem moderada",
      },
      {
        "nome": "Zona 3",
        "subtitulo": "Tempo Run / Ritmo Alvo",
        "descricao": "Ritmo de prova sustentável. Aumenta a resistência muscular e eficiência mecânica.",
        "cor": const Color(0xFFF59E0B),
        "pace": "${_formatarPace(z2Pace)} - ${_formatarPace(z3Pace)}",
        "key": "z3",
        "fc": "76% - 85% FC Máx",
        "tipo": "Treino ritmado contínuo",
      },
      {
        "nome": "Zona 4",
        "subtitulo": "Limiar de Lactato (Anaeróbico)",
        "descricao": "Tolerância à queimação muscular. Expande o limiar para correr mais rápido sem cansar.",
        "cor": const Color(0xFFF97316),
        "pace": "${_formatarPace(z3Pace)} - ${_formatarPace(z4Pace)}",
        "key": "z4",
        "fc": "86% - 92% FC Máx",
        "tipo": "Intervalados / Fartlek longo",
      },
      {
        "nome": "Zona 5",
        "subtitulo": "VO2 Máximo / Potência Máxima",
        "descricao": "Estímulos neuromusculares e sprints. Aumenta a velocidade de pico e potência pulmonar.",
        "cor": const Color(0xFFEF4444),
        "pace": "< ${_formatarPace(z5Pace)}",
        "key": "z5",
        "fc": "> 93% FC Máx",
        "tipo": "Tiros curtos (200m a 400m)",
      },
    ];

    final pctMap = distribuicao?["porcentagem"] as Map<String, dynamic>? ?? {};
    final segMap = distribuicao?["zonas_segundos"] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Zonas de Treino",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: "Simular Zonas",
            icon: const Icon(Icons.tune_rounded),
            onPressed: _modalSimuladorPace,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
          : RefreshIndicator(
              color: const Color(0xFF0066FF),
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Banner Header com Pace de Referência
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                            : [const Color(0xFF0066FF), const Color(0xFF00C6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.35 : 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "PACE DE REFERÊNCIA (Z3)",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatarPace(paceReferencia),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: _modalSimuladorPace,
                              icon: const Icon(Icons.edit_rounded, size: 14),
                              label: const Text("Simular", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Calculado com base no seu teste de 3km e histórico de treinos.",
                                  style: TextStyle(color: Colors.white, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card de Análise Polarizada se disponível
                  if (analise != null) _buildCardAnalise(isDark, cardBg, txtColor, borderColor),

                  const SizedBox(height: 20),

                  // Distribuição Acumulada nos Treinos
                  Text(
                    "Distribuição Real nos Treinos",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tempo total acumulado pelo atleta em cada faixa de intensidade.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Barra Colorida de Distribuição Multi-Zonas
                  _buildBarraDistribuicao(pctMap, zonasInfo),

                  const SizedBox(height: 24),

                  // Lista detalhada das 5 Zonas
                  Text(
                    "As 5 Zonas de Treinamento",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...zonasInfo.map((z) {
                    final key = z["key"] as String;
                    final pct = double.tryParse(pctMap[key]?.toString() ?? "0") ?? 0.0;
                    final seg = int.tryParse(segMap[key]?.toString() ?? "0") ?? 0;
                    final cor = z["cor"] as Color;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
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
                          // Header da Zona
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: cor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    z["nome"] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: cor,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cor.withValues(alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: cor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  "${pct.toStringAsFixed(1)}% (${_formatarTempo(seg)})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: cor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            z["subtitulo"] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            z["descricao"] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Métricas de Ritmo e Frequência Cardíaca
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Ritmo Alvo (Pace)",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          z["pace"] as String,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: cor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Frequência Cardíaca",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          z["fc"] as String,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: txtColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildCardAnalise(bool isDark, Color cardBg, Color txtColor, Color borderColor) {
    final risco = analise?["risco"]?.toString() ?? "baixo";
    final analises = (analise?["analise"] as List? ?? []);
    final recomendacoes = (analise?["recomendacao"] as List? ?? []);
    final isAltoRisco = risco == "alto";

    final statusColor = isAltoRisco ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAltoRisco ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: statusColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAltoRisco ? "Atenção à Polarização do Treino" : "Distribuição Saudável das Zonas",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (analises.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...analises.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "• ${a.toString()}",
                    style: TextStyle(color: txtColor, fontSize: 13, height: 1.35),
                  ),
                )),
          ],
          if (recomendacoes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...recomendacoes.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "💡 ${r.toString()}",
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildBarraDistribuicao(Map<String, dynamic> pctMap, List<Map<String, dynamic>> zonasInfo) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 14,
            child: Row(
              children: zonasInfo.map((z) {
                final key = z["key"] as String;
                final pct = double.tryParse(pctMap[key]?.toString() ?? "0") ?? 0.0;
                final cor = z["cor"] as Color;

                if (pct <= 0) return const SizedBox.shrink();

                return Expanded(
                  flex: (pct * 10).round().clamp(1, 1000),
                  child: Container(color: cor),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: zonasInfo.map((z) {
            final key = z["key"] as String;
            final pct = double.tryParse(pctMap[key]?.toString() ?? "0") ?? 0.0;
            final cor = z["cor"] as Color;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  "${z["nome"]}: ${pct.toStringAsFixed(0)}%",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
