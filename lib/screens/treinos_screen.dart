import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';

class TreinosPage extends StatefulWidget {
  final VoidCallback? onBack;

  const TreinosPage({super.key, this.onBack});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  List treinos = [];
  bool loading = true;
  String? erroCarregamento;

  String filtroSelecionado = "Todos";

  final List<String> filtros = [
    "Todos",
    "Corrida",
    // "Musculação",
    // "Bike",
    "Caminhada",
  ];

  @override
  void initState() {
    super.initState();
    carregarTreinos();
  }

  Future<void> carregarTreinos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("${Api.baseUrl}/treinos"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Falha ao carregar treinos");
      }

      final data = jsonDecode(response.body);
      if (data is! List) throw Exception("Formato inválido");
      if (!mounted) return;

      setState(() {
        treinos = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar seus treinos.";
      });
    }
  }

  List get treinosFiltrados {
    if (filtroSelecionado == "Todos") {
      return treinos;
    }

    return treinos.where((treino) {
      final tipo = treino["tipo"].toString().toLowerCase();

      switch (filtroSelecionado) {
        case "Corrida":
          return tipo.contains("corrida") ||
              tipo.contains("run") ||
              tipo.contains("running");

        case "Musculação":
          return tipo.contains("muscul") ||
              tipo.contains("academia") ||
              tipo.contains("gym");

        case "Bike":
          return tipo.contains("bike") || tipo.contains("cicl");

        case "Caminhada":
          return tipo.contains("caminhada") || tipo.contains("walk");

        default:
          return true;
      }
    }).toList();
  }

  String formatarTempo(dynamic segundos) {
    if (segundos == null) return "-";

    final total = int.tryParse(segundos.toString()) ?? 0;

    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;

    if (h > 0) {
      return "${h}h ${m}m";
    }

    return "${m}m ${s}s";
  }

  String formatarPace(dynamic segundos) {
    if (segundos == null) return "-";

    final total = int.tryParse(segundos.toString()) ?? 0;

    final min = total ~/ 60;
    final seg = total % 60;

    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} min/km";
  }

  Color corStatus(String status) {
    switch (status) {
      case "concluido":
        return Colors.green;

      case "em_andamento":
        return Colors.orange;

      case "faltou":
        return Colors.red;

      case "cancelado":
        return Colors.grey;

      default:
        return Colors.blue;
    }
  }

  IconData iconeTipo(String tipo) {
    final t = tipo.toLowerCase();

    if (t.contains("corrida") || t.contains("run")) {
      return Icons.directions_run;
    }

    if (t.contains("bike") || t.contains("cicl")) {
      return Icons.directions_bike;
    }

    if (t.contains("caminhada") || t.contains("walk")) {
      return Icons.directions_walk;
    }

    if (t.contains("muscul")) {
      return Icons.fitness_center;
    }

    return Icons.sports;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.lightBlueAccent),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Treinos",
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "Gerencie seus treinos",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0066FF),
        onPressed: mostrarCriarTreino,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: RefreshIndicator(
        onRefresh: carregarTreinos,

        child: Column(
          children: [
            // FILTROS
            SizedBox(
              height: 58,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),

                itemCount: filtros.length,

                itemBuilder: (context, index) {
                  final filtro = filtros[index];

                  final selecionado = filtroSelecionado == filtro;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        filtroSelecionado = filtro;
                      });
                    },

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),

                      margin: const EdgeInsets.only(
                        right: 10,
                        top: 8,
                        bottom: 8,
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),

                      decoration: BoxDecoration(
                        color: selecionado
                            ? const Color(0xFF0066FF)
                            : colors.surface,

                        borderRadius: BorderRadius.circular(18),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),

                      child: Center(
                        child: Text(
                          filtro,
                          style: TextStyle(
                            color: selecionado
                                ? Colors.white
                                : colors.onSurface,

                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: erroCarregamento != null
                  ? _estadoErro()
                  : treinosFiltrados.isEmpty
                  ? const Center(child: Text("Nenhum treino encontrado"))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: treinosFiltrados.length,

                      itemBuilder: (context, index) {
                        final treino = treinosFiltrados[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),

                          padding: const EdgeInsets.all(18),

                          decoration: BoxDecoration(
                            color: colors.surface,

                            borderRadius: BorderRadius.circular(24),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),

                                    decoration: BoxDecoration(
                                      color: corStatus(
                                        treino["status"],
                                      ).withValues(alpha: 0.12),

                                      shape: BoxShape.circle,
                                    ),

                                    child: Icon(
                                      iconeTipo(treino["tipo"]),
                                      color: corStatus(treino["status"]),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(
                                          treino["tipo"] ?? "Treino",

                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19,
                                            color: colors.onSurface,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          AppDateUtils.formatarData(treino["data"]),

                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),

                                    decoration: BoxDecoration(
                                      color: corStatus(treino["status"]),

                                      borderRadius: BorderRadius.circular(30),
                                    ),

                                    child: Text(
                                      treino["status"],

                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [
                                  _info(
                                    context,
                                    "Distância",
                                    "${treino["distancia_km"] ?? 0} km",
                                  ),

                                  _info(
                                    context,
                                    "Tempo",
                                    formatarTempo(treino["tempo_segundos"]),
                                  ),

                                  _info(
                                    context,
                                    "Pace",
                                    formatarPace(
                                      treino["ritmo_medio_segundos"],
                                    ),
                                  ),
                                ],
                              ),

                              if (treino["observacoes"] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 18),

                                  child: Text(
                                    treino["observacoes"],

                                    style: TextStyle(color: colors.onSurface),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 12),
            Text(erroCarregamento!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  loading = true;
                  erroCarregamento = null;
                });
                carregarTreinos();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(BuildContext context, String titulo, String valor) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void mostrarCriarTreino() {
    final tipoController = TextEditingController(text: "Corrida");
    final distanciaController = TextEditingController();
    final minutosController = TextEditingController();
    final segundosController = TextEditingController();
    final fcMediaController = TextEditingController();
    final fcMaxController = TextEditingController();
    final observacoesController = TextEditingController();
    DateTime dataTreino = DateTime.now();
    int sensacao = 5;
    String status = "concluido";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final colors = Theme.of(context).colorScheme;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 55,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Icon(
                            Icons.directions_run_rounded,
                            color: Color(0xFF0066FF),
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Novo Treino",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Registre as métricas completas de volume e intensidade.",
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // Data do Treino
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dataTreino,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() {
                              dataTreino = DateTime(
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
                                    const Text("Data do Treino", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      AppDateUtils.formatarData(dataTreino),
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
                              decoration: const InputDecoration(
                                labelText: "Tipo de treino",
                                hintText: "Ex: Corrida, Longão, Intervalado",
                              ),
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

                      // Distância e Tempo (Min e Seg)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: distanciaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: "Distância (km)",
                                hintText: "Ex: 5.0",
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: minutosController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Minutos",
                                hintText: "30",
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: segundosController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Segundos",
                                hintText: "0",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Frequência Cardíaca Média e Máxima
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fcMediaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "FC Média (bpm)",
                                hintText: "Ex: 148",
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: fcMaxController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "FC Máxima (bpm)",
                                hintText: "Ex: 175",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Sensação de Esforço RPE (1 a 10)
                      Text(
                        "Sensação de Esforço (RPE): $sensacao / 10",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
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
                        controller: observacoesController,
                        decoration: const InputDecoration(
                          labelText: "Observações (opcional)",
                          hintText: "Condições climáticas, terreno, sensações...",
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Botão Salvar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final dist = double.tryParse(distanciaController.text.replaceAll(',', '.')) ?? 0.0;
                            final min = int.tryParse(minutosController.text) ?? 0;
                            final sec = int.tryParse(segundosController.text) ?? 0;
                            final totalSeg = min * 60 + sec;
                            final fcMed = int.tryParse(fcMediaController.text);
                            final fcMax = int.tryParse(fcMaxController.text);

                            await Api.criarTreinoCompleto(
                              tipo: tipoController.text,
                              distanciaKm: dist,
                              tempoSegundos: totalSeg,
                              data: AppDateUtils.paraDataPura(dataTreino),
                              fcMedia: fcMed,
                              fcMax: fcMax,
                              sensacao: sensacao,
                              observacoes: observacoesController.text,
                              status: status,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            carregarTreinos();
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text(
                            "Salvar Treino Completo",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
