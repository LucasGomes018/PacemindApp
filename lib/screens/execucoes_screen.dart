import 'package:flutter/material.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';

class ExecucoesPage extends StatefulWidget {
  const ExecucoesPage({super.key});

  @override
  State<ExecucoesPage> createState() => _ExecucoesPageState();
}

class _ExecucoesPageState extends State<ExecucoesPage> {
  bool loading = true;
  List<dynamic> treinos = [];
  String filtroStatus = "todos"; // todos, concluido, parcial, nao_feito

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  Future<void> _carregarTreinos() async {
    setState(() => loading = true);
    try {
      final lista = await Api.listarTreinosPlanejados(); // ou listar todos
      final concluidos = await Api.listarTreinosConcluidos();

      // Combinar e evitar duplicações
      final Map<String, dynamic> mapa = {};
      for (var t in lista) {
        mapa[t["id_treino"].toString()] = t;
      }
      for (var t in concluidos) {
        mapa[t["id_treino"].toString()] = t;
      }

      if (mounted) {
        setState(() {
          treinos = mapa.values.toList();
          treinos.sort((a, b) {
            final dtA = AppDateUtils.extrairDataPura(a["data"]) ?? DateTime(2000);
            final dtB = AppDateUtils.extrairDataPura(b["data"]) ?? DateTime(2000);
            return dtB.compareTo(dtA);
          });
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

  String _formatarTempo(dynamic segundos) {
    if (segundos == null) return "-";
    final total = int.tryParse(segundos.toString()) ?? 0;
    if (total <= 0) return "-";
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) return "${h}h ${m}m ${s}s";
    return "${m}m ${s}s";
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
        return const Color(0xFF3B82F6);
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
    if (filtroStatus == "todos") return treinos;
    return treinos.where((t) {
      final s = (t["status"]?.toString() ?? "").toLowerCase();
      if (filtroStatus == "nao_feito") {
        return s == "nao_feito" || s == "faltou";
      }
      return s == filtroStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

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
        onPressed: _modalNovaExecucao,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text("Registrar Treino"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarTreinos,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Filtros de Status
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chipFiltro("Todos", "todos", isDark),
                        _chipFiltro("Concluídos", "concluido", isDark),
                        _chipFiltro("Parciais", "parcial", isDark),
                        _chipFiltro("Não Feitos", "nao_feito", isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_treinosFiltrados.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_run_rounded, size: 50, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            "Nenhum treino encontrado para este filtro.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
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
                      final fcMed = t["fc_media"];
                      final fcMax = t["fc_max"];
                      final rpe = t["sensacao"] ?? 5;
                      final obs = t["observacoes"]?.toString();
                      final dataStr = AppDateUtils.formatarData(t["data"]);
                      final tipo = t["tipo"]?.toString() ?? "Corrida";

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
                            // Linha Superior: Tipo, Data e Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.12),
                                      child: const Icon(
                                        Icons.directions_run_rounded,
                                        color: Color(0xFF0066FF),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tipo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: txtColor,
                                          ),
                                        ),
                                        Text(
                                          dataStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _textoStatus(status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cor,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Linha de Métricas Principais: Distância, Tempo, Pace
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _metricaItem("Distância", "${dist.toStringAsFixed(2)} km", txtColor),
                                _metricaItem("Tempo", _formatarTempo(tempoSeg), txtColor),
                                _metricaItem("Pace Médio", _formatarPace(paceSeg), txtColor),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Métricas de Intensidade: FC Média, FC Máx, Sensação RPE
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.favorite_rounded, size: 16, color: Colors.redAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                      fcMed != null ? "FC Média: $fcMed bpm" : "FC: -",
                                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                    ),
                                    if (fcMax != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        "• Máx: $fcMax",
                                        style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Sensação RPE: $rpe/10",
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),

                            if (obs != null && obs.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Obs: $obs",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _metricaItem(String titulo, String valor, Color txtColor) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txtColor),
        ),
        const SizedBox(height: 2),
        Text(
          titulo,
          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _chipFiltro(String label, String valor, bool isDark) {
    final selecionado = filtroStatus == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selecionado,
        selectedColor: const Color(0xFF0066FF),
        labelStyle: TextStyle(
          color: selecionado ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        onSelected: (val) {
          if (val) setState(() => filtroStatus = valor);
        },
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final colors = Theme.of(ctx).colorScheme;

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Registrar Nova Execução de Treino",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
                    ),
                    const SizedBox(height: 16),

                    // Data da Execução
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dataExecucao,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            dataExecucao = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              DateTime.now().hour,
                              DateTime.now().minute,
                            );
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF0066FF)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Data da Execução", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text(
                                    AppDateUtils.formatarData(dataExecucao),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tipo e Status
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: tipoController,
                            decoration: const InputDecoration(labelText: "Tipo de Treino"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(labelText: "Status"),
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
                    const SizedBox(height: 12),

                    // Distância e Tempo (Minutos e Segundos)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: distController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: "Distância (km)", hintText: "Ex: 5.0"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Minutos", hintText: "25"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: secController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Segundos", hintText: "30"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // FC Média e Máxima
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fcMedController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "FC Média (bpm)", hintText: "Ex: 145"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: fcMaxController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "FC Máx (bpm)", hintText: "Ex: 172"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sensação RPE (1 a 10)
                    Text("Sensação de Esforço (RPE): $sensacao / 10", style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      decoration: const InputDecoration(labelText: "Observações do Treino (opcional)"),
                    ),
                    const SizedBox(height: 20),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final dist = double.tryParse(distController.text.replaceAll(',', '.')) ?? 0.0;
                          final min = int.tryParse(minController.text) ?? 0;
                          final sec = int.tryParse(secController.text) ?? 0;
                          final totalSeg = min * 60 + sec;
                          final fcMed = int.tryParse(fcMedController.text);
                          final fcMax = int.tryParse(fcMaxController.text);

                          await Api.criarTreinoCompleto(
                            tipo: tipoController.text,
                            distanciaKm: dist,
                            tempoSegundos: totalSeg,
                            data: AppDateUtils.paraDataPura(dataExecucao),
                            fcMedia: fcMed,
                            fcMax: fcMax,
                            sensacao: sensacao,
                            observacoes: obsController.text,
                            status: status,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                          _carregarTreinos();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Salvar Execução", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
