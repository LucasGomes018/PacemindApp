import 'package:flutter/material.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';

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

  final List<String> tiposSanguineos = [
    "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Não sei"
  ];

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
      if (!mounted) return;

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
          _possuiAsma = data["possui_patologia"] == true ||
              data["patologias"]?.toString().toLowerCase().contains("asma") == true;
        }
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  // Cálculo de IMC
  double? get imcCalculado {
    final peso = double.tryParse(_pesoController.text.replaceAll(',', '.'));
    final altura = double.tryParse(_alturaController.text.replaceAll(',', '.'));
    if (peso == null || altura == null || peso <= 0 || altura <= 0) return null;
    final alturaMetros = altura > 3 ? altura / 100 : altura;
    return peso / (alturaMetros * alturaMetros);
  }

  String get classificacaoImc {
    final imc = imcCalculado;
    if (imc == null) return "--";
    if (imc < 18.5) return "Abaixo do peso";
    if (imc < 24.9) return "Peso ideal / Normal";
    if (imc < 29.9) return "Sobrepeso";
    return "Obesidade";
  }

  Color get corImc {
    final imc = imcCalculado;
    if (imc == null) return const Color(0xFF64748B);
    if (imc >= 18.5 && imc <= 24.9) return const Color(0xFF10B981);
    if (imc < 18.5 || (imc >= 25 && imc <= 29.9)) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // Percentual de preenchimento da ficha
  double get percentualPreenchimento {
    int camposPreenchidos = 0;
    const totalCampos = 8;

    if (_nascController.text.isNotEmpty) camposPreenchidos++;
    if (_pesoController.text.isNotEmpty) camposPreenchidos++;
    if (_alturaController.text.isNotEmpty) camposPreenchidos++;
    if (_sangueController.text.isNotEmpty) camposPreenchidos++;
    if (_emergenciaNomeController.text.isNotEmpty) camposPreenchidos++;
    if (_emergenciaTelController.text.isNotEmpty) camposPreenchidos++;
    if (_medicamentosController.text.isNotEmpty || _alergiasController.text.isNotEmpty) camposPreenchidos++;
    if (_sexo.isNotEmpty) camposPreenchidos++;

    return (camposPreenchidos / totalCampos).clamp(0.0, 1.0);
  }

  Future<void> _salvarFicha() async {
    final pesoStr = _pesoController.text.replaceAll(',', '.').trim();
    final alturaStr = _alturaController.text.replaceAll(',', '.').trim();

    final peso = double.tryParse(pesoStr);
    final altura = int.tryParse(alturaStr);

    if (peso == null || peso <= 20 || peso > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, insira um peso válido (em kg)."),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (altura == null || altura <= 50 || altura > 260) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, insira uma altura válida (em centímetros, ex: 175)."),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => salvando = true);

    try {
      final dados = {
        "data_nascimento": _nascController.text.trim(),
        "sexo": _sexo,
        "altura_cm": altura,
        "peso_kg": peso,
        "tipo_sanguineo": _sangueController.text.trim(),
        "contato_emergencia": _emergenciaNomeController.text.trim(),
        "telefone_emergencia": _emergenciaTelController.text.trim(),
        "possui_patologia": _possuiAsma,
        "patologias": _possuiAsma ? "Asma / Bronquite" : "Nenhuma",
        "alergias": _alergiasController.text.trim(),
        "medicamentos": _medicamentosController.text.trim(),
        "observacoes_medicas": _obsController.text.trim(),
      };

      await Api.salvarFichaAluno(dados);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Ficha médica do aluno salva com sucesso!"),
            ],
          ),
        ),
      );
      _carregarFicha();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text("Erro ao salvar prontuário: $e"),
        ),
      );
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final pct = percentualPreenchimento;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ficha Médica & Anamnese",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: salvando ? null : _salvarFicha,
              icon: salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                salvando ? "Salvando Prontuário..." : "Salvar Alterações",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
          : RefreshIndicator(
              color: const Color(0xFF0066FF),
              onRefresh: _carregarFicha,
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Banner Header de Identificação e Progresso
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Prontuário do Aluno",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Mantenha seus dados atualizados para segurança do treino",
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Barra de Progresso do Preenchimento
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Nível de Preenchimento",
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "${(pct * 100).toInt()}% completo",
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),

                        // Card IMC caso disponível
                        if (imcCalculado != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.accessibility_new_rounded, size: 20, color: Colors.white),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Índice de Massa Corporal (IMC)",
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                      Text(
                                        "${imcCalculado!.toStringAsFixed(1)} kg/m² • $classificacaoImc",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SEÇÃO 1: BIOMETRIA
                  _cardSecao(
                    titulo: "Dados Biométricos",
                    subtitulo: "Peso, altura, nascimento e tipo sanguíneo",
                    icone: Icons.straighten_rounded,
                    corIcone: const Color(0xFF0066FF),
                    cardBg: cardBg,
                    borderColor: borderColor,
                    txtColor: txtColor,
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sexo Biológico
                        Text(
                          "Sexo Biológico",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: txtColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _chipSexo("M", "Masculino", Icons.male_rounded),
                            const SizedBox(width: 10),
                            _chipSexo("F", "Feminino", Icons.female_rounded),
                            const SizedBox(width: 10),
                            _chipSexo("Outro", "Outro", Icons.person_outline_rounded),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Altura e Peso
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _pesoController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: "Peso (kg)",
                                  hintText: "Ex: 72.5",
                                  prefixIcon: const Icon(Icons.fitness_center_rounded, color: Color(0xFF0066FF)),
                                  filled: true,
                                  fillColor: inputBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _alturaController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: "Altura (cm)",
                                  hintText: "Ex: 175",
                                  prefixIcon: const Icon(Icons.height_rounded, color: Color(0xFF0066FF)),
                                  filled: true,
                                  fillColor: inputBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Data de Nascimento
                        InkWell(
                          onTap: () async {
                            final atual = DateTime.tryParse(_nascController.text) ?? DateTime(1995, 1, 1);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: atual,
                              firstDate: DateTime(1920),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _nascController.text = AppDateUtils.paraIsoLocal(picked).split("T")[0];
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_rounded, size: 20, color: Color(0xFF0066FF)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Data de Nascimento", style: TextStyle(fontSize: 11, color: subColor)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _nascController.text.isNotEmpty
                                            ? AppDateUtils.formatarData(_nascController.text)
                                            : "Selecione sua data de nascimento",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _nascController.text.isNotEmpty ? txtColor : subColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.calendar_month_rounded, size: 20, color: subColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tipo Sanguíneo em Chips
                        Text(
                          "Tipo Sanguíneo",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: txtColor),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tiposSanguineos.map((ts) {
                            final isSel = _sangueController.text == ts;
                            return ChoiceChip(
                              label: Text(ts),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) setState(() => _sangueController.text = ts);
                              },
                              selectedColor: const Color(0xFF0066FF),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                              backgroundColor: inputBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSel ? const Color(0xFF0066FF) : borderColor,
                                ),
                              ),
                              showCheckmark: false,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // SEÇÃO 2: FISIOLOGIA RESPIRATÓRIA & DOENÇAS
                  _cardSecao(
                    titulo: "Saúde Pulmonar & Medicações",
                    subtitulo: "Histórico de asma, alergias e tratamentos",
                    icone: Icons.air_rounded,
                    corIcone: const Color(0xFF10B981),
                    cardBg: cardBg,
                    borderColor: borderColor,
                    txtColor: txtColor,
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de Toggle de Asma
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _possuiAsma
                                ? const Color(0xFF0066FF).withValues(alpha: isDark ? 0.2 : 0.08)
                                : inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _possuiAsma ? const Color(0xFF0066FF) : borderColor,
                              width: _possuiAsma ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _possuiAsma
                                      ? const Color(0xFF0066FF).withValues(alpha: 0.2)
                                      : subColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.medical_information_rounded,
                                  color: _possuiAsma ? const Color(0xFF0066FF) : subColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Diagnóstico de Asma ou Bronquite",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: txtColor,
                                      ),
                                    ),
                                    Text(
                                      "Permite calibrar zonas e orientações de segurança",
                                      style: TextStyle(fontSize: 11.5, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _possuiAsma,
                                activeThumbColor: const Color(0xFF0066FF),
                                onChanged: (v) => setState(() => _possuiAsma = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Medicamentos em Uso
                        TextField(
                          controller: _medicamentosController,
                          decoration: InputDecoration(
                            labelText: "Medicamentos de Uso Contínuo",
                            hintText: "Ex: Salbutamol, Budesonida, Formoterol...",
                            prefixIcon: const Icon(Icons.medication_rounded, color: Color(0xFF10B981)),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Alergias Conhecidas
                        TextField(
                          controller: _alergiasController,
                          decoration: InputDecoration(
                            labelText: "Alergias Conhecidas",
                            hintText: "Ex: Poeira, ácaros, pólen, medicamentos...",
                            prefixIcon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Observações Gerais
                        TextField(
                          controller: _obsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: "Observações Médicas Gerais",
                            hintText: "Ex: Histórico de lesão no joelho esquerdo, cirurgias...",
                            filled: true,
                            fillColor: inputBg,
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // SEÇÃO 3: CONTATO DE EMERGÊNCIA
                  _cardSecao(
                    titulo: "Contato de Emergência",
                    subtitulo: "Segurança para corridas de rua e treinos longos",
                    icone: Icons.contact_phone_rounded,
                    corIcone: const Color(0xFFEF4444),
                    cardBg: cardBg,
                    borderColor: borderColor,
                    txtColor: txtColor,
                    isDark: isDark,
                    child: Column(
                      children: [
                        TextField(
                          controller: _emergenciaNomeController,
                          decoration: InputDecoration(
                            labelText: "Nome do Contato",
                            hintText: "Ex: Maria Gomes (Mãe/Esposa)",
                            prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFFEF4444)),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _emergenciaTelController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Telefone de Emergência",
                            hintText: "Ex: (11) 98765-4321",
                            prefixIcon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFEF4444)),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
    );
  }

  Widget _chipSexo(String valor, String label, IconData icone) {
    final isSelected = _sexo == valor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _sexo = valor),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0066FF)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0066FF)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icone,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardSecao({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color corIcone,
    required Color cardBg,
    required Color borderColor,
    required Color txtColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: corIcone.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: corIcone, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: txtColor,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
