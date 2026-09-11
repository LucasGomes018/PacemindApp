import 'package:flutter/material.dart';
import '../core/api.dart';

class FichaPage extends StatefulWidget {
  const FichaPage({super.key});

  @override
  State<FichaPage> createState() => _FichaPageState();
}

class _FichaPageState extends State<FichaPage> {
  bool loading = true;
  bool salvando = false;
  Map<String, dynamic>? ficha;

  final TextEditingController _nascController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _sangueController = TextEditingController();
  final TextEditingController _emergenciaNomeController = TextEditingController();
  final TextEditingController _emergenciaTelController = TextEditingController();
  final TextEditingController _alergiasController = TextEditingController();
  final TextEditingController _medicamentosController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();
  String _sexo = "M";
  bool _possuiAsma = true;

  @override
  void initState() {
    super.initState();
    _carregarFicha();
  }

  @override
  void dispose() {
    _nascController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _sangueController.dispose();
    _emergenciaNomeController.dispose();
    _emergenciaTelController.dispose();
    _alergiasController.dispose();
    _medicamentosController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _carregarFicha() async {
    setState(() => loading = true);
    try {
      final data = await Api.getFichaAluno();
      if (mounted) {
        setState(() {
          ficha = data;
          if (data.isNotEmpty) {
            _nascController.text = data["data_nascimento"]?.toString() ?? "";
            _pesoController.text = data["peso_kg"]?.toString() ?? "";
            _alturaController.text = data["altura_cm"]?.toString() ?? "";
            _sangueController.text = data["tipo_sanguineo"]?.toString() ?? "";
            _emergenciaNomeController.text = data["contato_emergencia"]?.toString() ?? "";
            _emergenciaTelController.text = data["telefone_emergencia"]?.toString() ?? "";
            _alergiasController.text = data["alergias"]?.toString() ?? "";
            _medicamentosController.text = data["medicamentos"]?.toString() ?? "";
            _obsController.text = data["observacoes_medicas"]?.toString() ?? "";
            _sexo = data["sexo"]?.toString() ?? "M";
            _possuiAsma = data["possui_patologia"] == true || data["patologias"]?.toString().contains("asma") == true;
          }
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _salvarFicha() async {
    setState(() => salvando = true);
    try {
      final peso = double.tryParse(_pesoController.text.replaceAll(',', '.')) ?? 70.0;
      final altura = int.tryParse(_alturaController.text) ?? 175;

      final dados = {
        "data_nascimento": _nascController.text,
        "sexo": _sexo,
        "altura_cm": altura,
        "peso_kg": peso,
        "tipo_sanguineo": _sangueController.text,
        "contato_emergencia": _emergenciaNomeController.text,
        "telefone_emergencia": _emergenciaTelController.text,
        "possui_patologia": _possuiAsma,
        "patologias": _possuiAsma ? "Asma / Bronquite" : "Nenhuma",
        "alergias": _alergiasController.text,
        "medicamentos": _medicamentosController.text,
        "observacoes_medicas": _obsController.text,
      };

      await Api.salvarFichaAluno(dados);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Text("Ficha do aluno atualizada com sucesso!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text("Erro ao salvar ficha: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ficha do Aluno",
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
              onRefresh: _carregarFicha,
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Header de Identificação
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                            : [const Color(0xFF0066FF), const Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.badge_rounded, color: Colors.white, size: 30),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Prontuário & Anamnese",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Mantenha seus dados atualizados para segurança do treinamento e acompanhamento médico.",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Biometria
                  _secaoTitulo("Dados Biométricos", Icons.accessibility_new_rounded, txtColor),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 360;
                      if (isCompact) {
                        return Column(
                          children: [
                            TextField(
                              controller: _pesoController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: "Peso (kg)", hintText: "Ex: 72.5"),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _alturaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Altura (cm)", hintText: "Ex: 178"),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _sangueController,
                              decoration: const InputDecoration(labelText: "Tipo Sanguíneo", hintText: "Ex: O+"),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _sexo,
                              decoration: const InputDecoration(labelText: "Sexo"),
                              items: const [
                                DropdownMenuItem(value: "M", child: Text("Masculino")),
                                DropdownMenuItem(value: "F", child: Text("Feminino")),
                                DropdownMenuItem(value: "Outro", child: Text("Outro")),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _sexo = v);
                              },
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _pesoController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: "Peso (kg)", hintText: "Ex: 72.5"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _alturaController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: "Altura (cm)", hintText: "Ex: 178"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _sangueController,
                                  decoration: const InputDecoration(labelText: "Tipo Sanguíneo", hintText: "Ex: O+"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _sexo,
                                  decoration: const InputDecoration(labelText: "Sexo"),
                                  items: const [
                                    DropdownMenuItem(value: "M", child: Text("Masculino")),
                                    DropdownMenuItem(value: "F", child: Text("Feminino")),
                                    DropdownMenuItem(value: "Outro", child: Text("Outro")),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _sexo = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Saúde Respiratória e Asma
                  _secaoTitulo("Saúde Respiratória & Asma", Icons.air_rounded, txtColor),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: cardBg,
                    title: const Text("Diagnóstico de Asma ou Bronquite", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Ajuda o app a calibrar intensidade e alertas respiratórios."),
                    value: _possuiAsma,
                    activeThumbColor: const Color(0xFF0066FF),
                    onChanged: (val) => setState(() => _possuiAsma = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _medicamentosController,
                    decoration: const InputDecoration(
                      labelText: "Medicamentos em uso (Manutenção ou Resgate)",
                      hintText: "Ex: Salbutamol / Corticoide inalatório",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _alergiasController,
                    decoration: const InputDecoration(
                      labelText: "Alergias conhecidas (Poeira, ácaros, pólen...)",
                      hintText: "Ex: Poeira, pelos, pólen",
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Contato de Emergência
                  _secaoTitulo("Contato de Emergência", Icons.phone_in_talk_rounded, txtColor),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emergenciaNomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Contato",
                      hintText: "Ex: Maria (Esposa)",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emergenciaTelController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Telefone de Emergência",
                      hintText: "Ex: (11) 99999-9999",
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: _obsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Observações Médicas Adicionais",
                      hintText: "Cirurgias, histórico cardíaco, recomendações médicas...",
                    ),
                  ),

                  const SizedBox(height: 26),

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
                      onPressed: salvando ? null : _salvarFicha,
                      icon: salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        salvando ? "Salvando..." : "Salvar Ficha do Aluno",
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

  Widget _secaoTitulo(String titulo, IconData icon, Color txtColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0066FF)),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txtColor),
        ),
      ],
    );
  }
}
