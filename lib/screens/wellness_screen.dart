import 'package:flutter/material.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';
import '../services/auto_notificacao_service.dart';

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  bool loading = true;
  String? erroCarregamento;
  List<dynamic> checkins = [];
  List<dynamic> historicoRecuperacao = [];

  // Estado do formulário de check-in diário
  double humor = 8.0;
  double energia = 8.0;
  bool dormiuBem = true;
  double qualidadeSono = 8.0;
  bool acordouComDor = false;
  final TextEditingController _localDorController = TextEditingController();
  double estresse = 3.0; // 1 a 10
  double fadiga = 3.0; // 1 a 10
  final TextEditingController _obsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _localDorController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      loading = true;
      erroCarregamento = null;
    });

    try {
      final wList = await Api.listarWellness();
      List<dynamic> rList = [];
      try {
        rList = await Api.listarRecuperacao();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        checkins = wList;
        historicoRecuperacao = rList;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar seus registros de bem-estar.";
      });
    }
  }

  // Calcula índice de prontidão (0 a 100) baseado no último check-in
  int? get prontidaoAtual {
    if (checkins.isEmpty) return null;
    final c = checkins.first;

    final h = (c["humor_antes"] as num?)?.toDouble() ?? 7.0;
    final e = (c["energia_antes"] as num?)?.toDouble() ?? 7.0;
    final dormiu = c["dormiu_bem"] == true;
    final dor = c["acordou_com_dor"] == true;

    // Fórmula científica de prontidão esportiva ponderada
    double score = (h * 4.0) + (e * 4.0) + (dormiu ? 15.0 : 0.0) - (dor ? 20.0 : 0.0);
    return score.clamp(10.0, 100.0).round();
  }

  String get textoProntidao {
    final p = prontidaoAtual;
    if (p == null) return "Faça seu check-in de hoje";
    if (p >= 80) return "Prontidão Alta • Treino Forte Liberado";
    if (p >= 55) return "Prontidão Moderada • Treino Normal";
    return "Fadiga Elevada • Sugerido Treino Leve ou Descanso";
  }

  Color get corProntidao {
    final p = prontidaoAtual;
    if (p == null) return const Color(0xFF64748B);
    if (p >= 80) return const Color(0xFF10B981);
    if (p >= 55) return const Color(0xFF0066FF);
    return const Color(0xFFEF4444);
  }

  Future<void> _abrirModalCheckin() async {
    humor = 8.0;
    energia = 8.0;
    dormiuBem = true;
    qualidadeSono = 8.0;
    acordouComDor = false;
    _localDorController.clear();
    estresse = 3.0;
    fadiga = 3.0;
    _obsController.clear();

    await AppModal.showBottomSheet(
      context: context,
      title: "Check-in Diário de Bem-Estar",
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFEC4899),
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Energia & Disposição
                Text(
                  "Nível de Energia e Disposição: ${energia.toInt()}/10",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Slider(
                  value: energia,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFF10B981),
                  label: "${energia.toInt()}",
                  onChanged: (val) => setModalState(() => energia = val),
                ),

                const SizedBox(height: 12),

                // Humor
                Text(
                  "Humor / Motivação Geral: ${humor.toInt()}/10",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Slider(
                  value: humor,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFF0066FF),
                  label: "${humor.toInt()}",
                  onChanged: (val) => setModalState(() => humor = val),
                ),

                const SizedBox(height: 12),

                // Sono
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bedtime_rounded, color: Color(0xFF8B5CF6), size: 20),
                              SizedBox(width: 8),
                              Text("Dormiu bem esta noite?", style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Switch(
                            value: dormiuBem,
                            activeThumbColor: const Color(0xFF8B5CF6),
                            onChanged: (val) => setModalState(() => dormiuBem = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("Qualidade do sono: ${qualidadeSono.toInt()}/10", style: const TextStyle(fontSize: 13)),
                          Expanded(
                            child: Slider(
                              value: qualidadeSono,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              activeColor: const Color(0xFF8B5CF6),
                              onChanged: (val) => setModalState(() => qualidadeSono = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Dor muscular
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.healing_rounded, color: Color(0xFFEF4444), size: 20),
                              SizedBox(width: 8),
                              Text("Acordou com alguma dor?", style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Switch(
                            value: acordouComDor,
                            activeThumbColor: const Color(0xFFEF4444),
                            onChanged: (val) => setModalState(() => acordouComDor = val),
                          ),
                        ],
                      ),
                      if (acordouComDor) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _localDorController,
                          decoration: InputDecoration(
                            hintText: "Onde? Ex: Panturrilha esquerda, joelho, posterior...",
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Fadiga e Estresse
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Fadiga: ${fadiga.toInt()}/10", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Slider(
                            value: fadiga,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: const Color(0xFFF59E0B),
                            onChanged: (val) => setModalState(() => fadiga = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Estresse: ${estresse.toInt()}/10", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Slider(
                            value: estresse,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: const Color(0xFFEC4899),
                            onChanged: (val) => setModalState(() => estresse = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Observações
                TextField(
                  controller: _obsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Observações do dia",
                    hintText: "Alimentação, cansaço do trabalho, hidratação...",
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingAction: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final hojeIso = DateTime.now().toIso8601String().substring(0, 10);

            try {
              // 1. Salvar no wellness_checkin
              await Api.criarWellness({
                "data": hojeIso,
                "humor_antes": humor.toInt(),
                "energia_antes": energia.toInt(),
                "dormiu_bem": dormiuBem,
                "acordou_com_dor": acordouComDor,
                "local_dor": acordouComDor ? _localDorController.text.trim() : null,
                "motivacao": humor.toInt(),
                "observacoes_antes": _obsController.text.trim(),
              });

              // 2. Salvar na tabela de recuperacao
              try {
                await Api.criarRecuperacao(
                  qualidadeSono: qualidadeSono.toInt(),
                  fadiga: fadiga.toInt(),
                  estresse: estresse.toInt(),
                  dorMuscular: acordouComDor ? 7 : 2,
                  prontoParaTreinar: !acordouComDor && fadiga <= 7,
                );
              } catch (_) {}

              // 🤖 Notificação automática caso prontidão esteja baixa ou haja dor
              final scoreCalculado = ((humor * 4.0) + (energia * 4.0) + (dormiuBem ? 15.0 : 0.0) - (acordouComDor ? 20.0 : 0.0)).clamp(10.0, 100.0).round();
              AutoNotificacaoService.notificarCheckinWellness(
                prontidao: scoreCalculado,
                acordouComDor: acordouComDor,
                localDor: _localDorController.text.trim(),
              );

              if (!mounted) return;
              AppSnackBar.sucesso(
                context,
                "Check-in de bem-estar gravado com sucesso!",
                titulo: "Bem-Estar Registrado ❤️",
              );
              _carregarDados();
            } catch (e) {
              if (!mounted) return;
              AppSnackBar.erro(
                context,
                "Erro ao registrar check-in. Tente novamente.",
                titulo: "Falha ao Salvar",
              );
            }
          },
          icon: const Icon(Icons.check_rounded, color: Colors.white),
          label: const Text("Registrar Check-in", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEC4899),
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(dynamic c) async {
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Excluir Registro?",
      message: "Tem certeza que deseja apagar o check-in do dia ${AppDateUtils.formatarData(c["data"] ?? c["criado_em"])}?",
      confirmText: "Excluir",
      cancelText: "Cancelar",
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      confirmButtonColor: const Color(0xFFEF4444),
      isDestructive: true,
    );

    if (confirmar == true) {
      try {
        final id = (c["id_checkin"] ?? c["id"]).toString();
        await Api.deletarWellness(id);
        if (!mounted) return;
        AppSnackBar.info(
          context,
          "Registro de bem-estar excluído.",
          titulo: "Excluído",
        );
        _carregarDados();
      } catch (_) {
        if (!mounted) return;
        AppSnackBar.erro(
          context,
          "Erro ao excluir registro.",
          titulo: "Erro",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final p = prontidaoAtual;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Wellness & Prontidão", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarDados,
            tooltip: "Atualizar",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalCheckin,
        backgroundColor: const Color(0xFFEC4899),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text("Fazer Check-in", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        color: const Color(0xFFEC4899),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Hero de Prontidão
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: p != null && p >= 80
                        ? [const Color(0xFF065F46), const Color(0xFF047857), const Color(0xFF10B981)]
                        : p != null && p >= 55
                            ? [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF3B82F6)]
                            : [const Color(0xFF831843), const Color(0xFFBE185D), const Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: corProntidao.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Score de Prontidão",
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text("Bio-Feedback", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          p != null ? "$p" : "--",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        const Text(
                          " / 100",
                          style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      textoProntidao,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _abrirModalCheckin,
                      icon: const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFFEC4899)),
                      label: Text(
                        checkins.isNotEmpty ? "Novo Check-in de Hoje" : "Realizar Primeiro Check-in",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEC4899)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEC4899),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Título Seção
              const Text(
                "Histórico de Bem-Estar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (loading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (erroCarregamento != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(erroCarregamento!, style: const TextStyle(color: Color(0xFFEF4444))),
                  ),
                )
              else if (checkins.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.spa_rounded, color: Color(0xFFEC4899), size: 40),
                      SizedBox(height: 12),
                      Text("Nenhum check-in registrado ainda.", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text(
                        "O check-in diário monitora fadiga, qualidade do sono e risco de lesão antes dos seus treinos de corrida.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: checkins.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = checkins[index];
                    final dataStr = c["data"] ?? c["criado_em"];
                    final dataFormatada = AppDateUtils.formatarData(dataStr);
                    final dormiu = c["dormiu_bem"] == true;
                    final dor = c["acordou_com_dor"] == true;
                    final localDor = c["local_dor"]?.toString() ?? "";
                    final energiaVal = c["energia_antes"] ?? 7;
                    final humorVal = c["humor_antes"] ?? 7;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (dor ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              dor ? Icons.healing_rounded : Icons.sentiment_very_satisfied_rounded,
                              color: dor ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dataFormatada,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      "Energia: $energiaVal/10 • Humor: $humorVal/10",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dor
                                      ? "Dor: ${localDor.isNotEmpty ? localDor : 'Relatada'}"
                                      : "Sem dor • Sono: ${dormiu ? 'Reparador' : 'Inquieto'}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: dor ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                            onPressed: () => _confirmarExclusao(c),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
