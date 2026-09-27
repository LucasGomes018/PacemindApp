import 'package:flutter/material.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';

class ExamesPage extends StatefulWidget {
  const ExamesPage({super.key});

  @override
  State<ExamesPage> createState() => _ExamesPageState();
}

class _ExamesPageState extends State<ExamesPage> {
  bool loading = true;
  String? erroCarregamento;
  List<dynamic> exames = [];
  String filtroTipo = "Todos";
  String buscaQuery = "";
  final TextEditingController _buscaController = TextEditingController();

  final List<String> filtros = [
    "Todos",
    "Espirometria",
    "Ergométrico",
    "Laboratorial",
  ];

  @override
  void initState() {
    super.initState();
    _carregarExames();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarExames() async {
    setState(() {
      loading = true;
      erroCarregamento = null;
    });

    try {
      final data = await Api.listarExames();
      if (!mounted) return;

      setState(() {
        exames = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar seus exames clínicos.";
      });
    }
  }

  Future<void> _confirmarExclusao(dynamic exame) async {
    final tipo = exame["tipo_exame"]?.toString() ?? "Exame";
    final dataStr = AppDateUtils.formatarData(exame["data_exame"]);

    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Excluir Exame?",
      message: "Tem certeza que deseja remover o laudo de $tipo ($dataStr)? Esta ação não pode ser desfeita.",
      confirmText: "Excluir",
      cancelText: "Cancelar",
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      confirmButtonColor: const Color(0xFFEF4444),
      isDestructive: true,
    );

    if (confirmar == true) {
      try {
        final id = (exame["id_exame"] ?? exame["id"]).toString();
        await Api.deletarExame(id);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Laudo excluído com sucesso."),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _carregarExames();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao excluir laudo. Tente novamente."),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<dynamic> get examesFiltrados {
    return exames.where((e) {
      final tipo = (e["tipo_exame"]?.toString() ?? "").toLowerCase();
      final laudo = (e["laudo"]?.toString() ?? "").toLowerCase();

      // Filtro de Categoria
      bool matchFiltro = true;
      if (filtroTipo == "Espirometria") {
        matchFiltro = tipo.contains("espiro") || tipo.contains("pulmonar");
      } else if (filtroTipo == "Ergométrico") {
        matchFiltro = tipo.contains("ergom") || tipo.contains("cardio") || tipo.contains("esforço");
      } else if (filtroTipo == "Laboratorial") {
        matchFiltro = tipo.contains("sangue") || tipo.contains("lab") || tipo.contains("hemograma");
      }

      // Filtro de Busca
      bool matchBusca = true;
      if (buscaQuery.trim().isNotEmpty) {
        final q = buscaQuery.trim().toLowerCase();
        matchBusca = tipo.contains(q) || laudo.contains(q);
      }

      return matchFiltro && matchBusca;
    }).toList();
  }

  // Métricas para o Card de Resumo
  double? get mediaVef1 {
    final valores = exames
        .map((e) => double.tryParse(e["vef1_percentual"]?.toString() ?? ""))
        .whereType<double>()
        .toList();
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a + b) / valores.length;
  }

  double? get mediaCvf {
    final valores = exames
        .map((e) => double.tryParse(e["cvf_percentual"]?.toString() ?? ""))
        .whereType<double>()
        .toList();
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a + b) / valores.length;
  }

  Color _corClassificacaoPulmonar(double? valor) {
    if (valor == null) return const Color(0xFF64748B);
    if (valor >= 80) return const Color(0xFF10B981); // Normal
    if (valor >= 60) return const Color(0xFFF59E0B); // Obstrução leve/moderada
    return const Color(0xFFEF4444); // Obstrução grave
  }

  String _textoClassificacaoPulmonar(double? valor) {
    if (valor == null) return "Não informado";
    if (valor >= 80) return "Normal (≥80%)";
    if (valor >= 60) return "Atenção (60-79%)";
    return "Alerta Crítico (<60%)";
  }

  void _abrirDetalhesExame(dynamic exame) {
    final tipo = exame["tipo_exame"]?.toString() ?? "Exame Pulmonar";
    final dataStr = AppDateUtils.formatarData(exame["data_exame"]);
    final vef1 = double.tryParse(exame["vef1_percentual"]?.toString() ?? "");
    final cvf = double.tryParse(exame["cvf_percentual"]?.toString() ?? "");
    final laudo = (exame["laudo"]?.toString() ?? "").trim();

    double? tiffeneau;
    if (vef1 != null && cvf != null && cvf > 0) {
      tiffeneau = (vef1 / cvf) * 100;
    }

    AppModal.showBottomSheet(
      context: context,
      title: tipo,
      subtitle: "Registrado em $dataStr",
      icon: Icons.biotech_rounded,
      iconColor: const Color(0xFF0066FF),
      maxChildSize: 0.90,
      initialChildSize: 0.75,
      builder: (ctx, scrollController) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Card com Parâmetros Ventilatórios
            if (vef1 != null || cvf != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
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
                        const Icon(Icons.speed_rounded, color: Color(0xFF0066FF), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Parâmetros Espirométricos",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (vef1 != null)
                          Expanded(
                            child: _parametroItem(
                              "VEF1",
                              "${vef1.toStringAsFixed(0)}%",
                              _corClassificacaoPulmonar(vef1),
                              "Volume expiratório no 1º seg",
                              isDark,
                            ),
                          ),
                        if (vef1 != null && cvf != null) const SizedBox(width: 12),
                        if (cvf != null)
                          Expanded(
                            child: _parametroItem(
                              "CVF",
                              "${cvf.toStringAsFixed(0)}%",
                              _corClassificacaoPulmonar(cvf),
                              "Capacidade vital forçada",
                              isDark,
                            ),
                          ),
                      ],
                    ),
                    if (tiffeneau != null) ...[
                      const SizedBox(height: 14),
                      Divider(color: isDark ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Relação VEF1 / CVF (Tiffeneau)",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                "Índice de obstrução de vias aéreas",
                                style: TextStyle(fontSize: 11, color: subTextColor),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _corClassificacaoPulmonar(tiffeneau).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${tiffeneau.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _corClassificacaoPulmonar(tiffeneau),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Laudo / Parecer Médico
            Container(
              padding: const EdgeInsets.all(18),
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
                      const Icon(Icons.notes_rounded, color: Color(0xFF0066FF), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Parecer & Laudo Médico",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    laudo.isNotEmpty ? laudo : "Nenhuma observação clínica ou parecer médico registrado para este exame.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: laudo.isNotEmpty ? (isDark ? Colors.grey.shade200 : Colors.grey.shade800) : subTextColor,
                      fontStyle: laudo.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botão Excluir
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _confirmarExclusao(exame);
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text("Excluir Este Laudo", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _parametroItem(
    String label,
    String valor,
    Color cor,
    String desc,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cor),
              ),
              Icon(Icons.check_circle_outline_rounded, size: 14, color: cor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cor),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: cor.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  void _modalNovoExame() {
    final tipoController = TextEditingController(text: "Espirometria");
    final vef1Controller = TextEditingController();
    final cvfController = TextEditingController();
    final laudoController = TextEditingController();
    DateTime dataSelecionada = DateTime.now();
    bool salvando = false;

    AppModal.showBottomSheet(
      context: context,
      title: "Novo Laudo de Exame",
      subtitle: "Espirometria, teste ergométrico ou laudo clínico",
      icon: Icons.biotech_rounded,
      iconColor: const Color(0xFF0066FF),
      maxChildSize: 0.95,
      initialChildSize: 0.88,
      builder: (sheetCtx, scrollController) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
            final colors = Theme.of(modalCtx).colorScheme;
            final fillBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
            final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

            final vef1Preview = double.tryParse(vef1Controller.text.replaceAll(',', '.'));
            final cvfPreview = double.tryParse(cvfController.text.replaceAll(',', '.'));

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                // Presets Rápidos
                Text(
                  "Tipo de Exame",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.onSurface),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    "Espirometria",
                    "Teste Ergométrico",
                    "Gasometria",
                    "Check-up Geral",
                  ].map((preset) {
                    final isSelected = tipoController.text == preset;
                    return InkWell(
                      onTap: () {
                        setModalState(() {
                          tipoController.text = preset;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0066FF)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0066FF)
                                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          preset,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : colors.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: tipoController,
                  onChanged: (_) => setModalState(() {}),
                  decoration: InputDecoration(
                    labelText: "Nome / Descrição do Exame",
                    hintText: "Ex: Espirometria Computadorizada",
                    prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF0066FF)),
                    filled: true,
                    fillColor: fillBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),

                // Seletor de Data
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: modalCtx,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setModalState(() {
                        dataSelecionada = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: fillBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF0066FF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Data de Realização do Exame",
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppDateUtils.formatarData(dataSelecionada),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_calendar_rounded, size: 20, color: subColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Parâmetros VEF1 e CVF com Indicador Visual
                Text(
                  "Indicadores Espirométricos (% do Previsto)",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.onSurface),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: vef1Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: "VEF1 (%)",
                          hintText: "Ex: 85",
                          filled: true,
                          fillColor: fillBg,
                          prefixIcon: const Icon(Icons.air_rounded, color: Color(0xFF0066FF)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: cvfController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: "CVF (%)",
                          hintText: "Ex: 92",
                          filled: true,
                          fillColor: fillBg,
                          prefixIcon: const Icon(Icons.expand_rounded, color: Color(0xFF10B981)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Diagnóstico Instantâneo Preview
                if (vef1Preview != null || cvfPreview != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _corClassificacaoPulmonar(vef1Preview).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: _corClassificacaoPulmonar(vef1Preview)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Status estimado: ${_textoClassificacaoPulmonar(vef1Preview)}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _corClassificacaoPulmonar(vef1Preview),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Parecer / Laudo Médico
                TextField(
                  controller: laudoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Conclusão ou Laudo Médico",
                    hintText: "Ex: Padrão espirométrico dentro dos limites da normalidade...",
                    filled: true,
                    fillColor: fillBg,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão de Ação
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
                            final tipo = tipoController.text.trim();
                            if (tipo.isEmpty) {
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                const SnackBar(
                                  content: Text("Informe o tipo de exame."),
                                  backgroundColor: Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            setModalState(() => salvando = true);

                            final vef1 = double.tryParse(vef1Controller.text.replaceAll(',', '.'));
                            final cvf = double.tryParse(cvfController.text.replaceAll(',', '.'));

                            try {
                              await Api.salvarExame({
                                "tipo_exame": tipo,
                                "data_exame": AppDateUtils.paraIsoLocal(dataSelecionada).split("T")[0],
                                "vef1_percentual": vef1,
                                "cvf_percentual": cvf,
                                "laudo": laudoController.text.trim(),
                              });

                              if (!sheetCtx.mounted) return;
                              Navigator.pop(sheetCtx);

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Exame salvo com sucesso!"),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              _carregarExames();
                            } catch (_) {
                              setModalState(() => salvando = false);
                              if (!modalCtx.mounted) return;
                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                const SnackBar(
                                  content: Text("Erro ao salvar exame. Verifique os dados."),
                                  backgroundColor: Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                ),
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
                              Text("Salvar Exame", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
        elevation: 4,
        onPressed: _modalNovoExame,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Novo Exame", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
          : RefreshIndicator(
              color: const Color(0xFF0066FF),
              onRefresh: _carregarExames,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Banner Header com Métricas Pulmonares
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
                              child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Saúde Pulmonar & Clínica",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Monitoramento de VEF1, CVF e testes ergométricos",
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Estatísticas em Pílulas
                        Row(
                          children: [
                            Expanded(
                              child: _cardMiniEstatistica(
                                "Laudos",
                                exames.length.toString(),
                                Icons.folder_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _cardMiniEstatistica(
                                "VEF1 Médio",
                                mediaVef1 != null ? "${mediaVef1!.toStringAsFixed(0)}%" : "--",
                                Icons.air_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _cardMiniEstatistica(
                                "CVF Médio",
                                mediaCvf != null ? "${mediaCvf!.toStringAsFixed(0)}%" : "--",
                                Icons.expand_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Barra de Busca
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TextField(
                      controller: _buscaController,
                      onChanged: (v) {
                        setState(() {
                          buscaQuery = v;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Buscar por exame ou observação médica...",
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

                  // Chips de Filtro
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filtros.map((f) {
                        final isSelected = filtroTipo == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => filtroTipo = f);
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
                                color: isSelected
                                    ? const Color(0xFF0066FF)
                                    : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Cabeçalho da Lista
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Exames Cadastrados (${examesFiltrados.length})",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: txtColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Estado Vazio ou Lista
                  if (examesFiltrados.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
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
                              Icons.folder_open_rounded,
                              size: 34,
                              color: Color(0xFF0066FF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            buscaQuery.isNotEmpty
                                ? "Nenhum laudo encontrado para sua busca."
                                : "Nenhum exame cadastrado.",
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
                                ? "Tente alterar os termos pesquisados ou limpar os filtros."
                                : "Registre laudos de espirometria e testes físicos para acompanhar sua capacidade respiratória com segurança.",
                            style: TextStyle(color: subColor, fontSize: 13, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          if (buscaQuery.isEmpty) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: _modalNovoExame,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text("Adicionar Primeiro Exame", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ...examesFiltrados.map((exame) {
                      final tipo = exame["tipo_exame"]?.toString() ?? "Espirometria";
                      final dataStr = AppDateUtils.formatarData(exame["data_exame"]);
                      final vef1 = double.tryParse(exame["vef1_percentual"]?.toString() ?? "");
                      final cvf = double.tryParse(exame["cvf_percentual"]?.toString() ?? "");
                      final laudo = (exame["laudo"]?.toString() ?? "").trim();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _abrirDetalhesExame(exame),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header do Card
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.2 : 0.1),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.biotech_rounded,
                                          color: Color(0xFF0066FF),
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
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today_rounded, size: 12, color: subColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  dataStr,
                                                  style: TextStyle(fontSize: 12, color: subColor),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                        tooltip: "Excluir exame",
                                        onPressed: () => _confirmarExclusao(exame),
                                      ),
                                    ],
                                  ),

                                  // Métricas em Chips
                                  if (vef1 != null || cvf != null) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (vef1 != null)
                                          _chipMetrica(
                                            "VEF1: ${vef1.toStringAsFixed(0)}%",
                                            _corClassificacaoPulmonar(vef1),
                                            isDark,
                                          ),
                                        if (cvf != null)
                                          _chipMetrica(
                                            "CVF: ${cvf.toStringAsFixed(0)}%",
                                            _corClassificacaoPulmonar(cvf),
                                            isDark,
                                          ),
                                        if (vef1 != null && cvf != null && cvf > 0)
                                          _chipMetrica(
                                            "VEF1/CVF: ${((vef1 / cvf) * 100).toStringAsFixed(0)}%",
                                            const Color(0xFF0066FF),
                                            isDark,
                                          ),
                                      ],
                                    ),
                                  ],

                                  // Parecer / Resumo
                                  if (laudo.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        laudo,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                          height: 1.35,
                                        ),
                                      ),
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

  Widget _cardMiniEstatistica(String label, String valor, IconData icon) {
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
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipMetrica(String texto, Color cor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
