import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class TreinosPage extends StatefulWidget {
  const TreinosPage({super.key});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  List treinos = [];
  bool loading = true;

  String filtroSelecionado = "Todos";

  final List<String> filtros = [
    "Todos",
    "Corrida",
    "Musculação",
    "Bike",
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

      final data = jsonDecode(response.body);

      setState(() {
        treinos = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
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
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.lightBlueAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FB),
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Treinos",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "Gerencie seus treinos",
              style: TextStyle(color: Colors.grey, fontSize: 13),
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
                            : Colors.white,

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
                            color: selecionado ? Colors.white : Colors.black87,

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
              child: treinosFiltrados.isEmpty
                  ? const Center(child: Text("Nenhum treino encontrado"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: treinosFiltrados.length,

                      itemBuilder: (context, index) {
                        final treino = treinosFiltrados[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),

                          padding: const EdgeInsets.all(18),

                          decoration: BoxDecoration(
                            color: Colors.white,

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

                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19,
                                            color: Colors.black87,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          treino["data"] ?? "",

                                          style: const TextStyle(
                                            color: Colors.grey,
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
                                    "Distância",
                                    "${treino["distancia_km"] ?? 0} km",
                                  ),

                                  _info(
                                    "Tempo",
                                    formatarTempo(treino["tempo_segundos"]),
                                  ),

                                  _info(
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

                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
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

  Widget _info(String titulo, String valor) {
    return Column(
      children: [
        Text(
          valor,

          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),

        const SizedBox(height: 4),

        Text(titulo, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  void mostrarCriarTreino() {
    final tipoController = TextEditingController();
    final distanciaController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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

                  const SizedBox(height: 26),

                  const Row(
                    children: [
                      Icon(
                        Icons.fitness_center_rounded,
                        color: Color(0xFF0066FF),
                        size: 30,
                      ),

                      SizedBox(width: 10),

                      Text(
                        "Novo Treino",

                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Cadastre um novo treino na sua rotina.",
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),

                  const SizedBox(height: 28),

                  TextField(
                    controller: tipoController,

                    decoration: InputDecoration(
                      hintText: "Ex: Corrida",
                      labelText: "Tipo do treino",

                      prefixIcon: const Icon(
                        Icons.category_rounded,
                        color: Color(0xFF0066FF),
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: distanciaController,
                    keyboardType: TextInputType.number,

                    decoration: InputDecoration(
                      hintText: "Ex: 5",
                      labelText: "Distância em KM",

                      prefixIcon: const Icon(
                        Icons.straighten_rounded,
                        color: Color(0xFF0066FF),
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await criarTreino(
                          tipoController.text,
                          distanciaController.text,
                        );

                        if (!context.mounted) return;

                        Navigator.pop(context);
                      },

                      icon: const Icon(Icons.add),

                      label: const Text(
                        "Criar treino",

                        style: TextStyle(fontSize: 17),
                      ),

                      style: ElevatedButton.styleFrom(
                        elevation: 0,

                        backgroundColor: const Color(0xFF0066FF),

                        foregroundColor: Colors.white,

                        padding: const EdgeInsets.symmetric(vertical: 18),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
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
  }

  Future<void> criarTreino(String tipo, String distancia) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    await http.post(
      Uri.parse("${Api.baseUrl}/treinos"),

      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },

      body: jsonEncode({
        "data": DateTime.now().toIso8601String(),
        "tipo": tipo,
        "distancia_km": double.tryParse(distancia),
      }),
    );

    carregarTreinos();
  }
}
