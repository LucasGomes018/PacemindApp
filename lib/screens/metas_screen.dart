import 'package:flutter/material.dart';
import '../core/api.dart';

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  List metas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarMetas();
  }

  Future<void> carregarMetas() async {
    try {
      final data = await Api.listarMetas();

      setState(() {
        metas = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> criarMeta() async {
    final tituloController = TextEditingController();
    final objetivoController = TextEditingController();

    String tipoSelecionado = "km";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 barrinha
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
                          Icons.flag_rounded,
                          color: Color(0xFF0066FF),
                          size: 30,
                        ),

                        SizedBox(width: 10),

                        Text(
                          "Nova Meta",
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
                      "Defina um novo objetivo e acompanhe sua evolução.",
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),

                    const SizedBox(height: 28),

                    // 📝 TÍTULO
                    TextField(
                      controller: tituloController,
                      decoration: InputDecoration(
                        hintText: "Ex: Correr 100km esse mês",
                        labelText: "Título da meta",

                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
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

                    // 🎯 OBJETIVO
                    TextField(
                      controller: objetivoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Digite o objetivo",
                        labelText: "Objetivo",

                        prefixIcon: const Icon(
                          Icons.track_changes,
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

                    // 📊 TIPO
                    DropdownButtonFormField(
                      initialValue: tipoSelecionado,

                      decoration: InputDecoration(
                        labelText: "Tipo da meta",

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

                      items: const [
                        DropdownMenuItem(
                          value: "km",
                          child: Text("Quilometragem"),
                        ),

                        DropdownMenuItem(value: "tempo", child: Text("Tempo")),

                        DropdownMenuItem(
                          value: "treinos",
                          child: Text("Treinos"),
                        ),
                      ],

                      onChanged: (value) {
                        setModalState(() {
                          tipoSelecionado = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    // 🚀 BOTÃO
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await Api.criarMeta(
                              titulo: tituloController.text,
                              objetivo: double.parse(objetivoController.text),
                              tipo: tipoSelecionado,
                            );

                            if (!context.mounted) return;

                            Navigator.pop(context);

                            carregarMetas();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Erro ao criar meta"),
                              ),
                            );
                          }
                        },

                        icon: const Icon(Icons.flag),

                        label: const Text(
                          "Criar Meta",
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
            );
          },
        );
      },
    );
  }

  double calcularPorcentagem(meta) {
    final objetivo = double.tryParse(meta["objetivo"].toString()) ?? 0;

    final progresso = double.tryParse(meta["progresso"].toString()) ?? 0;

    if (objetivo == 0) return 0;

    return (progresso / objetivo).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
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
              "Metas",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "Acompanhe seus objetivos",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0066FF),
        onPressed: criarMeta,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : metas.isEmpty
          ? const Center(child: Text("Nenhuma meta criada"))
          : RefreshIndicator(
              onRefresh: carregarMetas,

              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 100),

                itemCount: metas.length,

                itemBuilder: (context, index) {
                  final meta = metas[index];

                  final porcentagem = calcularPorcentagem(meta);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),

                          blurRadius: 12,

                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                meta["titulo"],

                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            if (meta["concluida"] == true)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Objetivo: ${meta["objetivo"]}",

                          style: const TextStyle(
                            color: Color.fromARGB(255, 44, 44, 44),
                          ),
                        ),

                        const SizedBox(height: 16),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),

                          child: LinearProgressIndicator(
                            value: porcentagem,
                            minHeight: 10,

                            backgroundColor: Colors.grey.shade200,

                            color: const Color(0xFF0066FF),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "${(porcentagem * 100).toStringAsFixed(0)}% concluído",

                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
