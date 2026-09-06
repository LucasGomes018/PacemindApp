import 'package:flutter/material.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';

class ExamesPage extends StatefulWidget {
  const ExamesPage({super.key});

  @override
  State<ExamesPage> createState() => _ExamesPageState();
}

class _ExamesPageState extends State<ExamesPage> {
  bool loading = true;
  List<dynamic> exames = [];

  @override
  void initState() {
    super.initState();
    _carregarExames();
  }

  Future<void> _carregarExames() async {
    setState(() => loading = true);
    try {
      final data = await Api.listarExames();
      if (mounted) {
        setState(() {
          exames = data;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deletarExame(String id) async {
    try {
      await Api.deletarExame(id);
      _carregarExames();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Exames & Espirometria",
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
        onPressed: _modalNovoExame,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Novo Exame"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarExames,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Banner informativo
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                            : [const Color(0xFF0066FF), const Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.biotech_rounded, color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Controle Pulmonar & Clínico",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Registre laudos de espirometria (VEF1, CVF) e testes ergométricos para acompanhar a capacidade respiratória.",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Exames Cadastrados",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: txtColor),
                  ),
                  const SizedBox(height: 12),

                  if (exames.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            "Nenhum exame cadastrado.",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Toque no botão abaixo para adicionar seu primeiro laudo.",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...exames.map((exame) {
                      final tipo = exame["tipo_exame"]?.toString() ?? "Espirometria";
                      final data = exame["data_exame"]?.toString() ?? "";
                      final vef1 = exame["vef1_percentual"];
                      final cvf = exame["cvf_percentual"];
                      final laudo = exame["laudo"]?.toString() ?? "";
                      final id = exame["id_exame"]?.toString() ?? "";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
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
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Color(0xFFE0F2FE),
                                      child: Icon(Icons.description_rounded, color: Color(0xFF0066FF), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      tipo,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: txtColor),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deletarExame(id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("Data: ${AppDateUtils.formatarData(data)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (vef1 != null || cvf != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (vef1 != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text("VEF1: $vef1%", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
                                    ),
                                  if (cvf != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text("CVF: $cvf%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ),
                                ],
                              ),
                            ],
                            if (laudo.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text("Laudo: $laudo", style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
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

  void _modalNovoExame() {
    final tipoController = TextEditingController(text: "Espirometria");
    final vef1Controller = TextEditingController();
    final cvfController = TextEditingController();
    final laudoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Adicionar Novo Exame", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: tipoController,
                  decoration: const InputDecoration(labelText: "Tipo de Exame (Espirometria, Teste Ergométrico...)"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: vef1Controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "VEF1 (%)", hintText: "Ex: 85"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: cvfController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "CVF (%)", hintText: "Ex: 92"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: laudoController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Conclusão / Laudo do Médico"),
                ),
                const SizedBox(height: 20),
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
                      final vef1 = double.tryParse(vef1Controller.text);
                      final cvf = double.tryParse(cvfController.text);

                      await Api.salvarExame({
                        "tipo_exame": tipoController.text,
                        "data_exame": AppDateUtils.paraIsoLocal(DateTime.now()).split("T")[0],
                        "vef1_percentual": vef1,
                        "cvf_percentual": cvf,
                        "laudo": laudoController.text,
                      });

                      if (ctx.mounted) Navigator.pop(ctx);
                      _carregarExames();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Salvar Exame", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
