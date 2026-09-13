import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_modal.dart';
import '../core/api.dart';

class TestesPage extends StatefulWidget {
  const TestesPage({super.key});

  @override
  State<TestesPage> createState() => _TestesPageState();
}

class _TestesPageState extends State<TestesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool carregando = false;
  bool salvando = false;
  List<dynamic> historicoTestes = [];
  String filtroHistorico = "todos"; // "todos", "3km", "sprint_20m"

  // Controllers 3km
  final TextEditingController _min3kmController = TextEditingController();
  final TextEditingController _sec3kmController = TextEditingController();
  final TextEditingController _obs3kmController = TextEditingController();

  // Controllers Sprint 20m
  final TextEditingController _minSprintController = TextEditingController();
  final TextEditingController _secSprintController = TextEditingController();
  final TextEditingController _obsSprintController = TextEditingController();

  // Variáveis em tempo real
  double? vvo2maxCalculado;
  int? paceMedio3kmSeg;
  double? vmaxCalculada;
  double? asrCalculada;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _carregarHistorico();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _min3kmController.dispose();
    _sec3kmController.dispose();
    _obs3kmController.dispose();
    _minSprintController.dispose();
    _secSprintController.dispose();
    _obsSprintController.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    if (!mounted) return;
    setState(() => carregando = true);
    try {
      final testes = await Api.listarTestes();
      if (!mounted) return;
      setState(() {
        historicoTestes = testes;
        carregando = false;
      });
      // Recalcula ASR se o sprint estiver preenchido
      if (_secSprintController.text.isNotEmpty || _minSprintController.text.isNotEmpty) {
        _calcularSprint();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => carregando = false);
    }
  }

  void _calcular3km() {
    final min = int.tryParse(_min3kmController.text.trim()) ?? 0;
    final sec = int.tryParse(_sec3kmController.text.trim()) ?? 0;
    final totalSec = min * 60 + sec;

    if (totalSec > 0) {
      setState(() {
        vvo2maxCalculado = 3.0 / (totalSec / 3600.0);
        paceMedio3kmSeg = (totalSec / 3.0).round();
      });
    } else {
      setState(() {
        vvo2maxCalculado = null;
        paceMedio3kmSeg = null;
      });
    }
  }

  void _calcularSprint() {
    final min = int.tryParse(_minSprintController.text.trim()) ?? 0;
    final sec =
        double.tryParse(_secSprintController.text.replaceAll(',', '.').trim()) ??
        0.0;
    final totalSec = min * 60.0 + sec;

    if (totalSec > 0) {
      final vmax = 0.020 / (totalSec / 3600.0); // 20m em km/h

      // Buscar o vVO2max mais recente do histórico
      double? ultimoVVO2;
      for (var t in historicoTestes) {
        if (t['tipo_teste'] == '3km' && t['vvo2max_kmh'] != null) {
          ultimoVVO2 = double.tryParse(t['vvo2max_kmh'].toString());
          break;
        }
      }

      setState(() {
        vmaxCalculada = vmax;
        if (ultimoVVO2 != null && ultimoVVO2 > 0) {
          asrCalculada = vmax - ultimoVVO2;
        } else {
          asrCalculada = null;
        }
      });
    } else {
      setState(() {
        vmaxCalculada = null;
        asrCalculada = null;
      });
    }
  }

  String _formatarPace(int segundos) {
    if (segundos <= 0) return "-";
    final min = segundos ~/ 60;
    final seg = segundos % 60;
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} min/km";
  }

  String _formatarPaceDeVelocidade(double kmh) {
    if (kmh <= 0) return "-";
    final secPorKm = (3600.0 / kmh).round();
    return _formatarPace(secPorKm);
  }

  String _classificarVvo2max(double vvo2) {
    if (vvo2 >= 17.0) return "Elite / Alta Performance";
    if (vvo2 >= 14.5) return "Avançado";
    if (vvo2 >= 11.5) return "Intermediário";
    return "Iniciante / Em Desenvolvimento";
  }

  String _classificarAsr(double asr) {
    if (asr >= 11.0) return "Perfil Velocista (Alta Potência Anaeróbia)";
    if (asr >= 7.0) return "Perfil Híbrido (Meio-Fundo)";
    return "Perfil Fundista (Resistência Pura)";
  }

  Future<void> _salvar3km() async {
    final min = int.tryParse(_min3kmController.text.trim()) ?? 0;
    final sec = int.tryParse(_sec3kmController.text.trim()) ?? 0;
    final totalSec = min * 60 + sec;

    if (totalSec <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe o tempo em minutos e segundos do teste de 3km."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => salvando = true);
    try {
      await Api.salvarTeste(
        tipoTeste: '3km',
        tempoSegundos: totalSec.toDouble(),
        observacoes: _obs3kmController.text.trim(),
      );

      _min3kmController.clear();
      _sec3kmController.clear();
      _obs3kmController.clear();
      setState(() {
        vvo2maxCalculado = null;
        paceMedio3kmSeg = null;
        salvando = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Teste de 3km salvo com sucesso! Zonas calibradas."),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      await _carregarHistorico();
    } catch (e) {
      if (mounted) {
        setState(() => salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar teste: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _salvarSprint() async {
    final min = int.tryParse(_minSprintController.text.trim()) ?? 0;
    final sec =
        double.tryParse(_secSprintController.text.replaceAll(',', '.').trim()) ??
        0.0;
    final totalSec = min * 60.0 + sec;

    if (totalSec <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe o tempo em minutos ou segundos do Sprint 20m."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => salvando = true);
    try {
      await Api.salvarTeste(
        tipoTeste: 'sprint_20m',
        tempoSegundos: totalSec,
        observacoes: _obsSprintController.text.trim(),
      );

      _minSprintController.clear();
      _secSprintController.clear();
      _obsSprintController.clear();
      setState(() {
        vmaxCalculada = null;
        asrCalculada = null;
        salvando = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚡ Sprint 20m registrado com sucesso!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      await _carregarHistorico();
    } catch (e) {
      if (mounted) {
        setState(() => salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar teste: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarExclusao(dynamic item) async {
    final is3km = item['tipo_teste'] == '3km';
    final titulo = is3km ? "Excluir Teste de 3km" : "Excluir Sprint 20m";

    final confirmou = await AppModal.showConfirmDialog(
      context: context,
      title: titulo,
      message:
          "Deseja realmente excluir este registro de teste físico? Esta ação não pode ser desfeita.",
      confirmText: "Excluir",
      cancelText: "Cancelar",
      icon: Icons.delete_forever_rounded,
      iconColor: const Color(0xFFEF4444),
      confirmButtonColor: const Color(0xFFEF4444),
      isDestructive: true,
    );

    if (confirmou == true) {
      try {
        await Api.deletarTeste(item['id_teste']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Teste excluído com sucesso."),
            ),
          );
        }
        _carregarHistorico();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erro ao excluir teste."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _abrirModalInfoProtocolo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppModal.showBottomSheet(
      context: context,
      title: "Protocolos & Fisiologia",
      subtitle: "Como funcionam os testes científicos do PaceMind",
      icon: Icons.science_rounded,
      iconColor: const Color(0xFF0066FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _blocoInfoGuia(
            titulo: "🏃 Protocolo de Campo de 3km (vVO2max)",
            descricao:
                "O teste de 3.000 metros em terreno plano ou pista é o padrão ouro na corrida para identificar a Velocidade Aeróbica Máxima (vVO2max). "
                "Com ela, o PaceMind calibra as suas 5 Zonas de Treinamento (Regenerativo, Base, Maratona, Limiar e Tiros) de forma totalmente individualizada.",
            dica:
                "Importante: Faça um aquecimento de 10 a 15 minutos em ritmo leve. Tente manter o ritmo mais estável possível do início ao fim.",
            isDark: isDark,
            cor: const Color(0xFF0066FF),
          ),
          const SizedBox(height: 14),
          _blocoInfoGuia(
            titulo: "⚡ Teste de Sprint 20m (Vmax & ASR)",
            descricao:
                "Mede a Velocidade Máxima de Corrida (Vmax). Ao comparar a sua Vmax com a sua vVO2max do teste de 3km, descobrimos a sua Reserva de Velocidade Anaeróbica (ASR = Vmax - vVO2max).",
            dica:
                "Como executar: Inicie com 5 metros de aceleração prévia e passe pelos 20 metros cronometrados em aceleração 100% máxima.",
            isDark: isDark,
            cor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 14),
          _blocoInfoGuia(
            titulo: "🫁 Cuidados Respiratórios & Asma",
            descricao:
                "Para corredores com hiper-reatividade brônquica ou asma induzida pelo exercício, o aquecimento longo e progressivo é clinicamente protetor.",
            dica:
                "Tenha o broncodilatador de alívio por perto e evite testes máximos em dias de umidade relativa do ar extremamente baixa (<30%) ou alta poluição.",
            isDark: isDark,
            cor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _blocoInfoGuia({
    required String titulo,
    required String descricao,
    required String dica,
    required bool isDark,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_rounded, size: 16, color: cor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dica,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade900,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Testes Físicos de Corrida",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: "Protocolos e Informações",
            onPressed: _abrirModalInfoProtocolo,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0066FF),
        onRefresh: _carregarHistorico,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 1. BANNER HERO COM ESTILO ESPORTIVO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                        : [const Color(0xFF0052D4), const Color(0xFF4364F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052D4).withValues(alpha: 0.25),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 14),
                              SizedBox(width: 4),
                              Text(
                                "Fisiologia Esportiva PaceMind",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.speed_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Calibre Suas Zonas",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Monitore vVO2max, ritmo de tiro e reserva anaeróbica com testes de campo validados.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🎛️ 2. SELETOR SEGMENTADO CUSTOMIZADO (CAPSULE TABS)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                        titulo: "Teste 3km (vVO2max)",
                        icone: Icons.directions_run_rounded,
                        ativo: _tabController.index == 0,
                        onTap: () => setState(() => _tabController.animateTo(0)),
                        isDark: isDark,
                        corAtiva: const Color(0xFF0066FF),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _tabButton(
                        titulo: "Sprint 20m (ASR)",
                        icone: Icons.bolt_rounded,
                        ativo: _tabController.index == 1,
                        onTap: () => setState(() => _tabController.animateTo(1)),
                        isDark: isDark,
                        corAtiva: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 📝 3. FORMULÁRIO DO TESTE SELECIONADO
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _tabController.index == 0
                    ? _buildTab3kmForm(isDark, cardBg, txtColor)
                    : _buildTabSprintForm(isDark, cardBg, txtColor),
              ),

              const SizedBox(height: 28),

              // 📜 4. SEÇÃO DE HISTÓRICO DE TESTES
              _buildHistoricoSection(isDark, cardBg, txtColor),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton({
    required String titulo,
    required IconData icone,
    required bool ativo,
    required VoidCallback onTap,
    required bool isDark,
    required Color corAtiva,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: ativo
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: ativo
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 18,
              color: ativo
                  ? corAtiva
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                titulo,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                  color: ativo
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🏃 ABA TESTE 3KM
  // ==========================================
  Widget _buildTab3kmForm(bool isDark, Color cardBg, Color txtColor) {
    return Container(
      key: const ValueKey("tab_3km"),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  color: Color(0xFF0066FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Teste de 3.000 Metros",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Velocidade Aeróbica Máxima (vVO2max)",
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Protocolo Explicativo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.info_outline_rounded, color: Color(0xFF0066FF), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Aquecimento: 10-15 min em ritmo leve. Corra 3.000m em pista ou asfalto plano mantendo a maior intensidade que conseguir sustentar de forma estável.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF1E3A8A),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Inputs Minutos e Segundos
          const Text(
            "Tempo Total Concluído",
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _min3kmController,
                  rotulo: "Minutos",
                  hint: "Ex: 12",
                  sufixo: "min",
                  icone: Icons.timer_outlined,
                  isDark: isDark,
                  onChanged: (_) => _calcular3km(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _sec3kmController,
                  rotulo: "Segundos",
                  hint: "Ex: 45",
                  sufixo: "seg",
                  icone: Icons.timelapse_rounded,
                  isDark: isDark,
                  onChanged: (_) => _calcular3km(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Campo Observações
          _buildInputField(
            controller: _obs3kmController,
            rotulo: "Observações (opcional)",
            hint: "Ex: Pista de carvão, clima ameno, calçado de placa...",
            icone: Icons.edit_note_rounded,
            isDark: isDark,
            maxLines: 1,
            keyboardType: TextInputType.text,
          ),

          // 📊 RESULTADOS EM TEMPO REAL (DASHBOARD DINÂMICO)
          if (vvo2maxCalculado != null && paceMedio3kmSeg != null) ...[
            const SizedBox(height: 18),
            _buildResultados3kmCard(isDark),
          ],

          const SizedBox(height: 20),

          // Botão Salvar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: salvando ? null : _salvar3km,
              icon: salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 22),
              label: Text(
                salvando ? "Calculando e Salvando..." : "Salvar Teste de 3km",
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados3kmCard(bool isDark) {
    final vvo2 = vvo2maxCalculado!;
    final pace = _formatarPace(paceMedio3kmSeg!);
    final vo2maxEstimado = (3.5 * vvo2).toStringAsFixed(1);
    final classificacao = _classificarVvo2max(vvo2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Métricas Calculadas",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  classificacao,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // KPIs em Linha
          Row(
            children: [
              Expanded(
                child: _kpiItem(
                  rotulo: "vVO2max",
                  valor: "${vvo2.toStringAsFixed(2)} km/h",
                  cor: const Color(0xFF0066FF),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _kpiItem(
                  rotulo: "Pace Médio",
                  valor: pace,
                  cor: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _kpiItem(
                  rotulo: "VO2max Est.",
                  valor: "$vo2maxEstimado ml",
                  cor: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Projeção de Zonas de Treino
          const Text(
            "Zonas de Treino Calibradas:",
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _zonaItem(
            zona: "Z1 Regenerativo (60-70%)",
            velocidade: "${(vvo2 * 0.60).toStringAsFixed(1)} - ${(vvo2 * 0.70).toStringAsFixed(1)} km/h",
            pace: "${_formatarPaceDeVelocidade(vvo2 * 0.70)} a ${_formatarPaceDeVelocidade(vvo2 * 0.60)}",
            cor: const Color(0xFF10B981),
            isDark: isDark,
          ),
          _zonaItem(
            zona: "Z2 Base Aeróbica (70-75%)",
            velocidade: "${(vvo2 * 0.70).toStringAsFixed(1)} - ${(vvo2 * 0.75).toStringAsFixed(1)} km/h",
            pace: "${_formatarPaceDeVelocidade(vvo2 * 0.75)} a ${_formatarPaceDeVelocidade(vvo2 * 0.70)}",
            cor: const Color(0xFF0066FF),
            isDark: isDark,
          ),
          _zonaItem(
            zona: "Z3 Maratona/Ritmo (80-87%)",
            velocidade: "${(vvo2 * 0.80).toStringAsFixed(1)} - ${(vvo2 * 0.87).toStringAsFixed(1)} km/h",
            pace: "${_formatarPaceDeVelocidade(vvo2 * 0.87)} a ${_formatarPaceDeVelocidade(vvo2 * 0.80)}",
            cor: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          _zonaItem(
            zona: "Z4 Limiar Lactato (88-94%)",
            velocidade: "${(vvo2 * 0.88).toStringAsFixed(1)} - ${(vvo2 * 0.94).toStringAsFixed(1)} km/h",
            pace: "${_formatarPaceDeVelocidade(vvo2 * 0.94)} a ${_formatarPaceDeVelocidade(vvo2 * 0.88)}",
            cor: const Color(0xFFF97316),
            isDark: isDark,
          ),
          _zonaItem(
            zona: "Z5 VO2max / Tiros (95-105%)",
            velocidade: "${(vvo2 * 0.95).toStringAsFixed(1)} - ${(vvo2 * 1.05).toStringAsFixed(1)} km/h",
            pace: "${_formatarPaceDeVelocidade(vvo2 * 1.05)} a ${_formatarPaceDeVelocidade(vvo2 * 0.95)}",
            cor: const Color(0xFFEF4444),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ⚡ ABA SPRINT 20M
  // ==========================================
  Widget _buildTabSprintForm(bool isDark, Color cardBg, Color txtColor) {
    return Container(
      key: const ValueKey("tab_sprint"),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sprint Máximo de 20 Metros",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Velocidade Máxima (Vmax) & ASR",
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Protocolo Explicativo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Protocolo: 5m de aceleração prévia + 20m cronometrados em esforço 100% máximo. Permite quantificar a sua velocidade anaeróbica máxima.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Inputs Minutos e Segundos Sprint 20m
          const Text(
            "Tempo Total Concluído",
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _minSprintController,
                  rotulo: "Minutos",
                  hint: "Ex: 0",
                  sufixo: "min",
                  icone: Icons.timer_outlined,
                  isDark: isDark,
                  onChanged: (_) => _calcularSprint(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _secSprintController,
                  rotulo: "Segundos",
                  hint: "Ex: 2.45",
                  sufixo: "seg",
                  icone: Icons.timelapse_rounded,
                  isDark: isDark,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _calcularSprint(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Campo Observações
          _buildInputField(
            controller: _obsSprintController,
            rotulo: "Observações (opcional)",
            hint: "Ex: Vento a favor, piso seco, calçado com travas...",
            icone: Icons.edit_note_rounded,
            isDark: isDark,
            maxLines: 1,
            keyboardType: TextInputType.text,
          ),

          // 📊 RESULTADOS EM TEMPO REAL SPRINT
          if (vmaxCalculada != null) ...[
            const SizedBox(height: 18),
            _buildResultadosSprintCard(isDark),
          ],

          const SizedBox(height: 20),

          // Botão Salvar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: salvando ? null : _salvarSprint,
              icon: salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bolt_rounded, size: 22),
              label: Text(
                salvando ? "Calculando e Salvando..." : "Salvar Sprint 20m",
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadosSprintCard(bool isDark) {
    final vmax = vmaxCalculada!;
    final asr = asrCalculada;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Potência & Velocidade Máxima",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              if (asr != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _classificarAsr(asr),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _kpiItem(
                  rotulo: "Vmax (20m)",
                  valor: "${vmax.toStringAsFixed(1)} km/h",
                  cor: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              if (asr != null)
                Expanded(
                  child: _kpiItem(
                    rotulo: "ASR (Reserva Anaeróbica)",
                    valor: "+${asr.toStringAsFixed(1)} km/h",
                    cor: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Text(
                      "Faça o teste de 3km para obter o cálculo do ASR",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📜 SEÇÃO HISTÓRICO DE TESTES
  // ==========================================
  Widget _buildHistoricoSection(bool isDark, Color cardBg, Color txtColor) {
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final listaFiltrada = historicoTestes.where((t) {
      if (filtroHistorico == "todos") return true;
      return t['tipo_teste'] == filtroHistorico;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: Color(0xFF0066FF)),
                const SizedBox(width: 8),
                Text(
                  "Histórico de Testes",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: txtColor,
                  ),
                ),
              ],
            ),
            if (historicoTestes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${historicoTestes.length} registros",
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Filtros Rápidos (Chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filtroChip(
                rotulo: "Todos",
                ativo: filtroHistorico == "todos",
                onTap: () => setState(() => filtroHistorico = "todos"),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _filtroChip(
                rotulo: "3 km (vVO2max)",
                ativo: filtroHistorico == "3km",
                onTap: () => setState(() => filtroHistorico = "3km"),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _filtroChip(
                rotulo: "Sprint 20m",
                ativo: filtroHistorico == "sprint_20m",
                onTap: () => setState(() => filtroHistorico = "sprint_20m"),
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (carregando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0066FF)),
            ),
          )
        else if (listaFiltrada.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  child: Icon(
                    Icons.speed_outlined,
                    size: 32,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Nenhum teste encontrado",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: txtColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  filtroHistorico == "todos"
                      ? "Realize o teste de 3km ou o sprint de 20m para acompanhar a evolução fisiológica da sua corrida."
                      : "Nenhum teste deste tipo foi registrado ainda.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: subColor),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listaFiltrada.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = listaFiltrada[index];
              final is3km = item['tipo_teste'] == '3km';

              String dataFormatada = "-";
              if (item['criado_em'] != null) {
                try {
                  final dt = DateTime.parse(item['criado_em'].toString());
                  dataFormatada = DateFormat("dd 'de' MMMM 'de' yyyy", "pt_BR").format(dt);
                } catch (_) {
                  dataFormatada = item['criado_em'].toString().split('T')[0];
                }
              }

              final tempoSeg = double.tryParse(item['tempo_segundos']?.toString() ?? "0") ?? 0.0;
              String tempoLegivel;
              if (is3km) {
                final min = (tempoSeg ~/ 60);
                final seg = (tempoSeg % 60).toInt();
                tempoLegivel = "${min}m ${seg.toString().padLeft(2, '0')}s";
              } else {
                tempoLegivel = "${tempoSeg.toStringAsFixed(2)}s";
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topo do Card de Histórico
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: is3km
                                    ? const Color(0xFF0066FF).withValues(alpha: 0.12)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                is3km ? Icons.directions_run_rounded : Icons.bolt_rounded,
                                color: is3km ? const Color(0xFF0066FF) : const Color(0xFFF59E0B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  is3km ? "Teste de 3.000 Metros" : "Sprint 20m Max Speed",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  dataFormatada,
                                  style: TextStyle(fontSize: 12, color: subColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          tooltip: "Excluir registro",
                          onPressed: () => _confirmarExclusao(item),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Grid com Métricas
                    Row(
                      children: [
                        Expanded(
                          child: _miniMetricCard(
                            rotulo: "Tempo Total",
                            valor: tempoLegivel,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (is3km) ...[
                          Expanded(
                            child: _miniMetricCard(
                              rotulo: "vVO2max",
                              valor: "${item['vvo2max_kmh'] ?? '-'} km/h",
                              corValor: const Color(0xFF0066FF),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _miniMetricCard(
                              rotulo: "Pace Estimado",
                              valor: item['vvo2max_kmh'] != null
                                  ? _formatarPaceDeVelocidade(
                                      double.tryParse(item['vvo2max_kmh'].toString()) ?? 0,
                                    )
                                  : "-",
                              corValor: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: _miniMetricCard(
                              rotulo: "Vmax (20m)",
                              valor: "${item['velocidade_max_kmh'] ?? '-'} km/h",
                              corValor: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _miniMetricCard(
                              rotulo: "ASR",
                              valor: item['asr_kmh'] != null
                                  ? "+${item['asr_kmh']} km/h"
                                  : "-",
                              corValor: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Observações se houver
                    if (item['observacoes'] != null &&
                        item['observacoes'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes_rounded, size: 14, color: subColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item['observacoes'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ==========================================
  // 🧩 WIDGETS AUXILIARES
  // ==========================================
  Widget _buildInputField({
    required TextEditingController controller,
    required String rotulo,
    required String hint,
    required IconData icone,
    required bool isDark,
    String? sufixo,
    TextInputType keyboardType = TextInputType.number,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icone, size: 20, color: const Color(0xFF0066FF)),
            suffixText: sufixo,
            suffixStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0066FF),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0066FF),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiItem({
    required String rotulo,
    required String valor,
    required Color cor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _zonaItem({
    required String zona,
    required String velocidade,
    required String pace,
    required Color cor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                zona,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                velocidade,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
              Text(
                pace,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filtroChip({
    required String rotulo,
    required bool ativo,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: ativo
              ? const Color(0xFF0066FF)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ativo
                ? const Color(0xFF0066FF)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
            color: ativo
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _miniMetricCard({
    required String rotulo,
    required String valor,
    required bool isDark,
    Color? corValor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: corValor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
