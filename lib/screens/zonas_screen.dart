import 'package:flutter/material.dart';
import '../core/api.dart';

class ZonasPage extends StatefulWidget {
  const ZonasPage({super.key});

  @override
  State<ZonasPage> createState() => _ZonasPageState();
}

class _ZonasPageState extends State<ZonasPage> {
  bool loading = true;
  Map<String, dynamic>? zonasPace;
  Map<String, dynamic>? distribuicao;
  Map<String, dynamic>? analise;
  int paceReferencia = 330; // default 5:30 min/km

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => loading = true);
    try {
      final paceData = await Api.getZonasPace();
      final distData = await Api.getZonasDistribuicao();
      final analiseData = await Api.getZonasAnalise();

      if (mounted) {
        setState(() {
          zonasPace = paceData;
          distribuicao = distData;
          analise = analiseData;
          if (paceData["pace_referencia"] != null) {
            paceReferencia = int.tryParse(paceData["pace_referencia"].toString()) ?? 330;
          }
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    // Definição das 5 Zonas de Treino
    final z1Pace = (paceReferencia * 1.30).round();
    final z2Pace = (paceReferencia * 1.15).round();
    final z3Pace = (paceReferencia * 1.00).round();
    final z4Pace = (paceReferencia * 0.90).round();
    final z5Pace = (paceReferencia * 0.80).round();

    final zonasInfo = [
      {
        "nome": "Zona 1",
        "subtitulo": "Muito Leve / Recuperação",
        "descricao": "Recuperação ativa, baixíssimo impacto cardíaco.",
        "cor": const Color(0xFF10B981),
        "pace": "> ${_formatarPace(z1Pace)}",
        "key": "z1",
        "fc": "< 65% FC Máx",
      },
      {
        "nome": "Zona 2",
        "subtitulo": "Leve / Aeróbico (Base)",
        "descricao": "Construção de base mitocondrial e queima eficiente de gordura.",
        "cor": const Color(0xFF06B6D4),
        "pace": "${_formatarPace(z1Pace)} - ${_formatarPace(z2Pace)}",
        "key": "z2",
        "fc": "65% - 75% FC Máx",
      },
      {
        "nome": "Zona 3",
        "subtitulo": "Moderado / Tempo Run",
        "descricao": "Ritmo de maratona sustentável e resistência aeróbica.",
        "cor": const Color(0xFFF59E0B),
        "pace": "${_formatarPace(z2Pace)} - ${_formatarPace(z3Pace)}",
        "key": "z3",
        "fc": "76% - 85% FC Máx",
      },
      {
        "nome": "Zona 4",
        "subtitulo": "Forte / Limiar Anaeróbico",
        "descricao": "Melhora a tolerância ao lactato e capacidade de sustentar ritmos fortes.",
        "cor": const Color(0xFFF97316),
        "pace": "${_formatarPace(z3Pace)} - ${_formatarPace(z4Pace)}",
        "key": "z4",
        "fc": "86% - 92% FC Máx",
      },
      {
        "nome": "Zona 5",
        "subtitulo": "Máximo / Alta Intensidade",
        "descricao": "Estímulos máximos, sprints e desenvolvimento de VO2max.",
        "cor": const Color(0xFFEF4444),
        "pace": "< ${_formatarPace(z5Pace)}",
        "key": "z5",
        "fc": "> 93% FC Máx",
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
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Card Header com Pace de Referência
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
                          color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.speed_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pace de Referência (Z3)",
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatarPace(paceReferencia),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Calculado a partir do seu teste de 3km e histórico.",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Card de Análise Inteligente de Distribuição
                  if (analise != null) _buildCardAnalise(isDark, cardBg, txtColor),

                  const SizedBox(height: 22),

                  // Distribuição Real dos Treinos
                  Text(
                    "Distribuição Real nos Treinos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tempo total acumulado em cada zona de intensidade.",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Barra Colorida de Distribuição Multi-Zonas
                  _buildBarraDistribuicao(pctMap, zonasInfo),

                  const SizedBox(height: 24),

                  // Lista detalhada das 5 Zonas
                  Text(
                    "As 5 Zonas Fisiológicas",
                    style: TextStyle(
                      fontSize: 18,
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
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
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
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: cor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        z["nome"] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: cor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${pct.toStringAsFixed(1)}% (${_formatarTempo(seg)})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: cor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            z["subtitulo"] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: txtColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            z["descricao"] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions_run_rounded, size: 18, color: cor),
                                  const SizedBox(width: 6),
                                  Text(
                                    z["pace"] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: txtColor,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite_rounded, size: 18, color: Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    z["fc"] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCardAnalise(bool isDark, Color cardBg, Color txtColor) {
    final risco = analise?["risco"]?.toString() ?? "baixo";
    final analises = (analise?["analise"] as List? ?? []);
    final recomendacoes = (analise?["recomendacao"] as List? ?? []);
    final isAltoRisco = risco == "alto";

    final statusColor = isAltoRisco ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAltoRisco ? Icons.warning_amber_rounded : Icons.psychology_rounded,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Diagnóstico do Modelo de Intensidade",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...analises.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        msg.toString(),
                        style: TextStyle(fontSize: 13.5, color: txtColor),
                      ),
                    ),
                  ],
                ),
              )),
          if (recomendacoes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                recomendacoes.join(" "),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarraDistribuicao(Map<String, dynamic> pctMap, List<Map<String, dynamic>> zonasInfo) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 26,
            child: Row(
              children: zonasInfo.map((z) {
                final key = z["key"] as String;
                final pct = double.tryParse(pctMap[key]?.toString() ?? "0") ?? 0.0;
                final cor = z["cor"] as Color;

                if (pct <= 0) return const SizedBox.shrink();
                return Expanded(
                  flex: (pct * 10).round().clamp(1, 1000),
                  child: Container(
                    color: cor,
                    child: Center(
                      child: pct > 8
                          ? Text(
                              "${pct.round()}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
