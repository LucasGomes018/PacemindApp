import 'package:flutter/material.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';

class ExecucoesPage extends StatefulWidget {
  const ExecucoesPage({super.key});

  @override
  State<ExecucoesPage> createState() => _ExecucoesPageState();
}

class _ExecucoesPageState extends State<ExecucoesPage> {
  bool loading = true;
  String? erroCarregamento;
  List<dynamic> treinos = [];
  String filtroStatus = "todos"; // todos, concluido, parcial, nao_feito
  String buscaQuery = "";
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarTreinos() async {
    setState(() {
      loading = true;
      erroCarregamento = null;
    });

    try {
      final lista = await Api.listarTreinosPlanejados();
      final concluidos = await Api.listarTreinosConcluidos();

      final Map<String, dynamic> mapa = {};
      for (var t in lista) {
        final id = (t["id_treino"] ?? t["id"]).toString();
        mapa[id] = t;
      }
      for (var t in concluidos) {
        final id = (t["id_treino"] ?? t["id"]).toString();
        mapa[id] = t;
      }

      if (!mounted) return;

      final resultado = mapa.values.toList();
      resultado.sort((a, b) {
        final dtA = AppDateUtils.extrairDataPura(a["data"]) ?? DateTime(2000);
        final dtB = AppDateUtils.extrairDataPura(b["data"]) ?? DateTime(2000);
        return dtB.compareTo(dtA);
      });

      setState(() {
        treinos = resultado;
        loading = false;
        erroCarregamento = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar as execuções de treinos.";
      });
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

  String _formatarTempo(dynamic segundos) {
    if (segundos == null) return "-";
    final total = int.tryParse(segundos.toString()) ?? 0;
    if (total <= 0) return "-";
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) return "${h}h ${m}m";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  Color _corStatus(String status) {
    switch (status.toLowerCase()) {
      case "concluido":
        return const Color(0xFF10B981);
      case "parcial":
        return const Color(0xFFF59E0B);
      case "nao_feito":
      case "faltou":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF0066FF);
    }
  }

  String _textoStatus(String status) {
    switch (status.toLowerCase()) {
      case "concluido":
        return "Concluído";
      case "parcial":
        return "Parcial";
      case "nao_feito":
        return "Não Feito";
      case "faltou":
        return "Faltou";
      default:
        return status;
    }
  }

  List<dynamic> get _treinosFiltrados {
    return treinos.where((t) {
      final s = (t["status"]?.toString() ?? "").toLowerCase();
      final tipo = (t["tipo"]?.toString() ?? "").toLowerCase();
      final obs = (t["observacoes"]?.toString() ?? "").toLowerCase();

      bool matchStatus = true;
      if (filtroStatus == "concluido") {
        matchStatus = s == "concluido";
      } else if (filtroStatus == "parcial") {
        matchStatus = s == "parcial";
      } else if (filtroStatus == "nao_feito") {
        matchStatus = s == "nao_feito" || s == "faltou";
      }

      bool matchBusca = true;
      if (buscaQuery.trim().isNotEmpty) {
        final q = buscaQuery.trim().toLowerCase();
        matchBusca = tipo.contains(q) || obs.contains(q);
      }

      return matchStatus && matchBusca;
    }).toList();
  }

  // Métricas do Header
  double get totalKmExecutado {
    double total = 0.0;
    for (var t in treinos) {
      final d = double.tryParse(t["distancia_km"]?.toString() ?? "0") ?? 0.0;
      total += d;
    }
    return total;
  }

  int get totalSegundosExecutado {
    int total = 0;
    for (var t in treinos) {
      final s = int.tryParse(t["tempo_segundos"]?.toString() ?? "0") ?? 0;
      total += s;
    }
    return total;
  }

  int get totalConcluidos {
    return treinos.where((t) => (t["status"]?.toString() ?? "").toLowerCase() == "concluido").length;
  }

  void _modalDetalhesTreino(dynamic t) {
    final status = t["status"]?.toString() ?? "concluido";
    final cor = _corStatus(status);
    final dist = double.tryParse(t["distancia_km"]?.toString() ?? "0") ?? 0.0;
    final tempoSeg = int.tryParse(t["tempo_segundos"]?.toString() ?? "0") ?? 0;
    final paceSeg = int.tryParse(t["ritmo_medio_segundos"]?.toString() ?? "0") ?? 0;
    final fcMed = t["fc_media"];
    final fcMax = t["fc_max"];
    final rpe = t["sensacao"] ?? 5;
    final obs = (t["observacoes"]?.toString() ?? "").trim();
    final dataStr = AppDateUtils.formatarData(t["data"]);
    final tipo = t["tipo"]?.toString() ?? "Corrida";

    AppModal.showBottomSheet(
      context: context,
      title: tipo,
      subtitle: dataStr,
      icon: Icons.directions_run_rounded,
      iconColor: cor,
      builder: (ctx, scrollController) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Status Badge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: cor),
                    const SizedBox(width: 6),
                    Text(
                      _textoStatus(status).toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Grid de Métricas Principais
            Row(
              children: [
                Expanded(
                  child: _cardMiniMetrica(
                    "Distância",
                    "${dist.toStringAsFixed(2)} km",
                    Icons.straighten_rounded,
                    const Color(0xFF0066FF),
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _cardMiniMetrica(
                    "Duração",
                    _formatarTempo(tempoSeg),
                    Icons.timer_outlined,
                    const Color(0xFF10B981),
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _cardMiniMetrica(
                    "Ritmo Médio",
                    _formatarPace(paceSeg),
                    Icons.speed_rounded,
                    const Color(0xFFF59E0B),
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Frequência Cardíaca & RPE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Fisiologia & Percepção de Esforço",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "FC Média / Máxima:",
                            style: TextStyle(fontSize: 13, color: subTextColor),
                          ),
                        ],
                      ),
                      Text(
                        "${fcMed ?? '--'} / ${fcMax ?? '--'} bpm",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Esforço Percebido (RPE):",
                            style: TextStyle(fontSize: 13, color: subTextColor),
                          ),
                        ],
                      ),
                      Text(
                        "$rpe / 10",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (obs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notes_rounded, color: Color(0xFF0066FF), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Observações do Atleta",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      obs,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _cardMiniMetrica(String label, String valor, IconData icone, Color cor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 18),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cor),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: cor.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  void _modalNovaExecucao() {
    final tipoController = TextEditingController(text: "Corrida");
    final distController = TextEditingController();
    final minController = TextEditingController();
    final secController = TextEditingController();
    final fcMedController = TextEditingController();
    final fcMaxController = TextEditingController();
    final obsController = TextEditingController();
    DateTime dataExecucao = DateTime.now();
    int sensacao = 5;
    String status = "concluido";
    bool salvando = false;

    AppModal.showBottomSheet(
      context: context,
      title: "Registrar Treino Executado",
      subtitle: "Insira os dados da sua corrida ou treino",
      icon: Icons.directions_run_rounded,
      iconColor: const Color(0xFF0066FF),
      maxChildSize: 0.95,
      initialChildSize: 0.88,
      builder: (ctx, scrollController) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDarkModal = Theme.of(modalCtx).brightness == Brightness.dark;
            final txtColorModal = Theme.of(modalCtx).colorScheme.onSurface;
            final subColorModal = isDarkModal ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final inputBg = isDarkModal ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
            final borderColor = isDarkModal ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            // Cálculo do Pace Preview
            final distPreview = double.tryParse(distController.text.replaceAll(',', '.')) ?? 0.0;
            final minPreview = int.tryParse(minController.text) ?? 0;
            final secPreview = int.tryParse(secController.text) ?? 0;
            final totalSegPreview = minPreview * 60 + secPreview;
            int? pacePreview;
            if (distPreview > 0 && totalSegPreview > 0) {
              pacePreview = (totalSegPreview / distPreview).round();
            }

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                // Data da Execução
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: modalCtx,
                      initialDate: dataExecucao,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() {
                        dataExecucao = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: inputBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF0066FF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Data da Execução", style: TextStyle(fontSize: 11, color: subColorModal)),
                              Text(
                                AppDateUtils.formatarData(dataExecucao),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txtColorModal),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, color: subColorModal),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Tipo e Status
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: tipoController,
                        decoration: InputDecoration(
                          labelText: "Tipo de Treino",
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: InputDecoration(
                          labelText: "Status",
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: const [
                          DropdownMenuItem(value: "concluido", child: Text("Concluído")),
                          DropdownMenuItem(value: "parcial", child: Text("Parcial")),
                          DropdownMenuItem(value: "nao_feito", child: Text("Não feito")),
                        ],
                        onChanged: (v) {
                          if (v != null) setModalState(() => status = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Distância e Tempo
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: distController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: "Distância (km)",
                          hintText: "Ex: 5.0",
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: minController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: "Minutos",
                          hintText: "25",
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: secController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: "Segundos",
                          hintText: "30",
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Preview do Ritmo Calculado
                if (pacePreview != null && pacePreview > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withValues(alpha: isDarkModal ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed_rounded, size: 16, color: Color(0xFF0066FF)),
                        const SizedBox(width: 8),
                        Text(
                          "Pace médio calculado: ${_formatarPace(pacePreview)}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // FC Média e Máxima
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fcMedController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "FC Média (bpm)",
                          hintText: "Ex: 145",
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: fcMaxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "FC Máx (bpm)",
                          hintText: "Ex: 172",
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sensação RPE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Sensação de Esforço (RPE):", style: TextStyle(fontWeight: FontWeight.w600, color: txtColorModal)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$sensacao / 10",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0066FF)),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: sensacao.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFF0066FF),
                  onChanged: (val) {
                    setModalState(() => sensacao = val.round());
                  },
                ),

                // Observações
                TextField(
                  controller: obsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Observações do Treino (opcional)",
                    hintText: "Ex: Treino em aclive, bom fôlego, clima úmido...",
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: salvando
                        ? null
                        : () async {
                            final dist = double.tryParse(distController.text.replaceAll(',', '.')) ?? 0.0;
                            final min = int.tryParse(minController.text) ?? 0;
                            final sec = int.tryParse(secController.text) ?? 0;
                            final totalSeg = min * 60 + sec;

                            if (dist <= 0) {
                              AppSnackBar.aviso(
                                modalCtx,
                                "Informe uma distância válida em km.",
                                titulo: "Distância Obrigatória",
                              );
                              return;
                            }

                            setModalState(() => salvando = true);

                            final fcMed = int.tryParse(fcMedController.text);
                            final fcMax = int.tryParse(fcMaxController.text);

                            try {
                              await Api.criarTreinoCompleto(
                                tipo: tipoController.text.trim(),
                                distanciaKm: dist,
                                tempoSegundos: totalSeg,
                                data: AppDateUtils.paraDataPura(dataExecucao),
                                fcMedia: fcMed,
                                fcMax: fcMax,
                                sensacao: sensacao,
                                observacoes: obsController.text.trim(),
                                status: status,
                              );

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);

                              if (!mounted) return;
                              AppSnackBar.sucesso(
                                context,
                                "Execução de treino registrada com sucesso!",
                                titulo: "Treino Registrado",
                              );
                              _carregarTreinos();
                            } catch (_) {
                              setModalState(() => salvando = false);
                              if (!modalCtx.mounted) return;
                              AppSnackBar.erro(
                                modalCtx,
                                "Erro ao registrar execução do treino.",
                                titulo: "Erro ao Salvar",
                              );
                            }
                          },
                    child: salvando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 20),
                              SizedBox(width: 8),
                              Text("Salvar Execução", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _chipFiltro(String label, String valor, bool isDark) {
    final isSelected = filtroStatus == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => filtroStatus = valor);
        },
        selectedColor: const Color(0xFF0066FF),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0066FF) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Histórico de Execuções",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _modalNovaExecucao,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text("Registrar Treino", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
          : RefreshIndicator(
              color: const Color(0xFF0066FF),
              onRefresh: _carregarTreinos,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Banner Header com Estatísticas Acumuladas
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Registro de Atividades",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Histórico completo de treinos executados",
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: _cardMiniBanner(
                                "Total de Treinos",
                                treinos.length.toString(),
                                Icons.fitness_center_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _cardMiniBanner(
                                "KM Total",
                                "${totalKmExecutado.toStringAsFixed(1)} km",
                                Icons.straighten_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _cardMiniBanner(
                                "Tempo Total",
                                _formatarTempo(totalSegundosExecutado),
                                Icons.timer_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Barra de Busca
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _buscaController,
                      onChanged: (v) => setState(() => buscaQuery = v),
                      decoration: InputDecoration(
                        hintText: "Buscar por tipo de treino ou anotação...",
                        hintStyle: TextStyle(fontSize: 13.5, color: subColor),
                        prefixIcon: Icon(Icons.search_rounded, color: subColor),
                        suffixIcon: buscaQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _buscaController.clear();
                                  setState(() => buscaQuery = "");
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Filtros de Status
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chipFiltro("Todos (${treinos.length})", "todos", isDark),
                        _chipFiltro("Concluídos ($totalConcluidos)", "concluido", isDark),
                        _chipFiltro("Parciais", "parcial", isDark),
                        _chipFiltro("Não Feitos", "nao_feito", isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_treinosFiltrados.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_run_rounded,
                              size: 34,
                              color: Color(0xFF0066FF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            buscaQuery.isNotEmpty
                                ? "Nenhum treino encontrado para sua busca."
                                : "Nenhuma execução registrada.",
                            style: TextStyle(
                              color: txtColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            buscaQuery.isNotEmpty
                                ? "Tente alterar os termos da busca ou mudar o filtro."
                                : "Quando você registrar ou concluir um treino, ele aparecerá detalhado aqui.",
                            style: TextStyle(color: subColor, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._treinosFiltrados.map((t) {
                      final status = t["status"]?.toString() ?? "concluido";
                      final cor = _corStatus(status);
                      final dist = double.tryParse(t["distancia_km"]?.toString() ?? "0") ?? 0.0;
                      final tempoSeg = int.tryParse(t["tempo_segundos"]?.toString() ?? "0") ?? 0;
                      final paceSeg = int.tryParse(t["ritmo_medio_segundos"]?.toString() ?? "0") ?? 0;
                      final rpe = t["sensacao"];
                      final obs = t["observacoes"]?.toString();
                      final dataStr = AppDateUtils.formatarData(t["data"]);
                      final tipo = t["tipo"]?.toString() ?? "Corrida";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _modalDetalhesTreino(t),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Tipo, Data e Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: cor.withValues(alpha: isDark ? 0.2 : 0.1),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                Icons.directions_run_rounded,
                                                color: cor,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tipo,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: txtColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    dataStr,
                                                    style: TextStyle(fontSize: 12, color: subColor),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: cor.withValues(alpha: isDark ? 0.2 : 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: cor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          _textoStatus(status),
                                          style: TextStyle(
                                            color: cor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  // Métricas em Linha
                                  Row(
                                    children: [
                                      _itemMetricaResumo(
                                        "Distância",
                                        "${dist.toStringAsFixed(1)} km",
                                        const Color(0xFF0066FF),
                                      ),
                                      _itemMetricaResumo(
                                        "Tempo",
                                        _formatarTempo(tempoSeg),
                                        const Color(0xFF10B981),
                                      ),
                                      _itemMetricaResumo(
                                        "Pace",
                                        _formatarPace(paceSeg),
                                        const Color(0xFFF59E0B),
                                      ),
                                      if (rpe != null)
                                        _itemMetricaResumo(
                                          "RPE",
                                          "$rpe/10",
                                          const Color(0xFF8B5CF6),
                                        ),
                                    ],
                                  ),

                                  if (obs != null && obs.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      obs,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: subColor, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _cardMiniBanner(String label, String valor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMetricaResumo(String label, String valor, Color cor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
