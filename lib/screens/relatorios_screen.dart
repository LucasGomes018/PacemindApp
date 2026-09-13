import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../components/app_modal.dart';
import '../core/api.dart';
import '../services/relatorio_pdf_service.dart';
import '../services/recomendacao_parecer_service.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  bool loading = true;
  bool gerandoPdf = false;

  Map<String, dynamic>? user;
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

      Map<String, dynamic>? u;
      try {
        u = await Api.getProfile();
      } catch (_) {}

      if (mounted) {
        setState(() {
          dashboard = d;
          overtraining = o;
          questionarios = q;
          testes = t;
          user = u;
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
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} min/km";
  }

  Map<String, dynamic> _obterUltimosDados() {
    dynamic ultimoACQ5;
    for (var q in questionarios) {
      if (q["tipo"] == "acq5") {
        ultimoACQ5 = q;
        break;
      }
    }

    dynamic ultimoMiniAQLQ;
    for (var q in questionarios) {
      if (q["tipo"] == "miniaqlq") {
        ultimoMiniAQLQ = q;
        break;
      }
    }

    dynamic ultimo3km;
    for (var t in testes) {
      if (t["tipo_teste"] == "3km") {
        ultimo3km = t;
        break;
      }
    }

    return {
      "acq5": ultimoACQ5,
      "miniaqlq": ultimoMiniAQLQ,
      "3km": ultimo3km,
    };
  }

  Future<Uint8List> _gerarBytesPdf() async {
    final ultimos = _obterUltimosDados();
    return await RelatorioPdfService.gerarPdfRelatorio(
      user: user,
      dashboard: dashboard,
      overtraining: overtraining,
      ultimoACQ5: ultimos["acq5"],
      ultimoMiniAQLQ: ultimos["miniaqlq"],
      ultimo3km: ultimos["3km"],
    );
  }

  Future<void> _compartilharPdf() async {
    setState(() => gerandoPdf = true);
    try {
      final bytes = await _gerarBytesPdf();
      final nome = user?["nome_usuario"]?.toString() ?? "atleta";
      await RelatorioPdfService.compartilharPdf(
        pdfBytes: bytes,
        nomeAtleta: nome,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao compartilhar PDF: $e"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => gerandoPdf = false);
    }
  }

  Future<void> _salvarPdfNoDispositivo() async {
    setState(() => gerandoPdf = true);
    try {
      final bytes = await _gerarBytesPdf();
      final nome = user?["nome_usuario"]?.toString() ?? "atleta";
      final path = await RelatorioPdfService.salvarNoDispositivo(
        pdfBytes: bytes,
        nomeAtleta: nome,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "PDF salvo com sucesso!\n$path",
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar PDF: $e"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => gerandoPdf = false);
    }
  }

  Future<void> _visualizarPdf() async {
    setState(() => gerandoPdf = true);
    try {
      final bytes = await _gerarBytesPdf();
      final nome = user?["nome_usuario"]?.toString() ?? "atleta";
      await RelatorioPdfService.visualizarOuImprimirPdf(
        pdfBytes: bytes,
        nomeAtleta: nome,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao abrir visualizador de PDF: $e"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => gerandoPdf = false);
    }
  }

  void _abrirModalExportacao() {
    AppModal.showBottomSheet(
      context: context,
      title: "Exportar Relatório em PDF",
      subtitle: "Selecione como deseja exportar seus dados",
      icon: Icons.picture_as_pdf_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _exportOptionTile(
            icon: Icons.share_rounded,
            title: "Compartilhar PDF",
            subtitle: "Enviar via WhatsApp, E-mail, Drive ou outros apps",
            corIcone: const Color(0xFF0066FF),
            onTap: () {
              Navigator.pop(context);
              _compartilharPdf();
            },
          ),
          const SizedBox(height: 12),
          _exportOptionTile(
            icon: Icons.download_rounded,
            title: "Salvar no Dispositivo",
            subtitle: "Gravar arquivo PDF na pasta de Downloads ou Documentos",
            corIcone: const Color(0xFF10B981),
            onTap: () {
              Navigator.pop(context);
              _salvarPdfNoDispositivo();
            },
          ),
          const SizedBox(height: 12),
          _exportOptionTile(
            icon: Icons.print_rounded,
            title: "Visualizar & Imprimir",
            subtitle: "Abrir pré-visualização completa em tela cheia",
            corIcone: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.pop(context);
              _visualizarPdf();
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _exportOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color corIcone,
    required VoidCallback onTap,
  }) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: corIcone.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: corIcone, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: txtColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: subColor, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: subColor, size: 16),
            ],
          ),
        ),
      );
    });
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

    final ultimos = _obterUltimosDados();
    final ultimoACQ5 = ultimos["acq5"];
    final ultimoMiniAQLQ = ultimos["miniaqlq"];
    final ultimo3km = ultimos["3km"];

    final parecer = RecomendacaoParecerService.gerar(
      user: user,
      dashboard: dashboard,
      overtraining: overtraining,
      ultimoACQ5: ultimoACQ5,
      ultimoMiniAQLQ: ultimoMiniAQLQ,
      ultimo3km: ultimo3km,
    );

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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: "Exportar PDF",
            onPressed: loading || gerandoPdf ? null : _abrirModalExportacao,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
          : RefreshIndicator(
              color: const Color(0xFF0066FF),
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
                            : [const Color(0xFF0052D4), const Color(0xFF4364F7)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0052D4).withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Relatório Integrado PaceMind",
                                    style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?["nome_usuario"] != null
                                        ? "Atleta: ${user!["nome_usuario"]}"
                                        : "Performance na corrida alinhada ao controle respiratório.",
                                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
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

                  // 3. Parecer para o Treinador e Médico (Dinâmico e Individualizado)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF8B5CF6), size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "3. Parecer Técnico de Prescrição",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    parecer.statusGeral,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: parecer.corStatus,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: parecer.corStatus.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: parecer.corStatus.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                parecer.badgeTexto,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: parecer.corStatus,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Bloco 1: Diagnóstico da Carga
                        _blocoParecer(
                          titulo: "Diagnóstico de Carga (ACWR)",
                          descricao: parecer.diagnosticoCarga,
                          icone: Icons.speed_rounded,
                          cor: const Color(0xFF0066FF),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),

                        // Bloco 2: Avaliação Respiratória
                        _blocoParecer(
                          titulo: "Avaliação Respiratória (ACQ-5)",
                          descricao: parecer.avaliacaoRespiratoria,
                          icone: Icons.air_rounded,
                          cor: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),

                        // Bloco 3: Prescrição de Velocidades
                        _blocoParecer(
                          titulo: "Prescrição de Zonas & Velocidade",
                          descricao: parecer.prescricaoVelocidade,
                          icone: Icons.timer_rounded,
                          cor: const Color(0xFFF59E0B),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // Diretrizes Práticas
                        const Text(
                          "Diretrizes Recomendadas para a Semana:",
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...parecer.diretrizesPraticas.map(
                          (diretriz) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2, right: 8),
                                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                ),
                                Expanded(
                                  child: Text(
                                    diretriz,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🚀 BOTÃO EXPORTAR / COMPARTILHAR PDF
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: gerandoPdf ? null : _abrirModalExportacao,
                      icon: gerandoPdf
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded, size: 22),
                      label: Text(
                        gerandoPdf ? "Gerando Relatório PDF..." : "Exportar / Compartilhar Relatório",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      final txtColor = Theme.of(context).colorScheme.onSurface;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                rotulo,
                style: TextStyle(fontSize: 13, color: subColor),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 5,
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: txtColor),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _blocoParecer({
    required String titulo,
    required String descricao,
    required IconData icone,
    required Color cor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: cor),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            descricao,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
