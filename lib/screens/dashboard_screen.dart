import 'package:flutter/material.dart';
import '/components/dashboard/dashboard_header.dart';
import '/components/dashboard/dashboard_stats.dart';
import '/components/dashboard/weekly_goal_card.dart';
import '/components/dashboard/weekly_chart_card.dart';
import '/components/dashboard/recent_workouts_card.dart';
import '/components/dashboard/quick_actions.dart';
import '/core/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/components/bottom_menu.dart';
import '/screens/perfil_screen.dart';
import '/screens/map_screen.dart';
import '/screens/treinos_screen.dart';
import '/screens/metas_screen.dart';
import '../services/notificacao_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '/components/drawer_menu.dart';
import '../utils/date_utils.dart';

class DashboardPage extends StatefulWidget {
  final int initialPage;

  const DashboardPage({super.key, this.initialPage = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? erroCarregamento;
  late int selectedIndex;

  // Gerenciamento de semana e período
  DateTime dataReferencia = DateTime.now();
  int periodoFiltroIndex = 0; // 0 = Esta Semana, 1 = Geral (Histórico)

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialPage.clamp(0, 3);
    carregarDados();
    pedirPermissaoNotificacao();
  }

  Future<void> pedirPermissaoNotificacao() async {
    try {
      await NotificacaoService.flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  DateTime _calcularInicioSemana(DateTime data) {
    final puro = DateTime(data.year, data.month, data.day);
    // Segunda-feira como início da semana (weekday: 1=Segunda, 7=Domingo)
    return DateTime(puro.year, puro.month, puro.day - (puro.weekday - 1));
  }

  DateTime _calcularFimSemana(DateTime inicio) {
    return DateTime(inicio.year, inicio.month, inicio.day + 6, 23, 59, 59);
  }

  bool _verificarSeSemanaAtual(DateTime inicio, DateTime fim) {
    final agora = DateTime.now();
    return !agora.isBefore(inicio) && !agora.isAfter(fim);
  }

  Future<void> carregarDados() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      erroCarregamento = null;
    });

    try {
      final inicioSemana = _calcularInicioSemana(dataReferencia);
      final fimSemana = _calcularFimSemana(inicioSemana);
      final isSemanaAtual = _verificarSeSemanaAtual(inicioSemana, fimSemana);

      // Busca dados do dashboard para a semana selecionada
      final dashboard = await Api.getDashboard(
        semana: isSemanaAtual ? null : inicioSemana,
      );

      List<dynamic> treinosConcluidos = [];
      List<dynamic> metasUsuario = [];
      Map<String, dynamic> perfilUsuario = {};

      try {
        treinosConcluidos = await Api.listarTreinosConcluidos();
      } catch (_) {}

      try {
        metasUsuario = await Api.listarMetas();
      } catch (_) {}

      try {
        perfilUsuario = await Api.getProfile();
      } catch (_) {}

      if (!mounted) return;

      final resultado = {
        ...dashboard,
        "perfil": perfilUsuario,
        "treinos": treinosConcluidos,
        "metas": metasUsuario,
      };

      setState(() {
        data = resultado;
        loading = false;
        erroCarregamento = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar seus dados no momento.";
      });
    }
  }

  void _irSemanaAnterior() {
    setState(() {
      dataReferencia = DateTime(
        dataReferencia.year,
        dataReferencia.month,
        dataReferencia.day - 7,
      );
    });
    carregarDados();
  }

  void _irProximaSemana() {
    final inicioAtual = _calcularInicioSemana(DateTime.now());
    final inicioRef = _calcularInicioSemana(dataReferencia);

    // Não permite avançar além da semana atual
    if (!inicioRef.isBefore(inicioAtual)) return;

    setState(() {
      dataReferencia = DateTime(
        dataReferencia.year,
        dataReferencia.month,
        dataReferencia.day + 7,
      );
    });
    carregarDados();
  }

  void _irSemanaAtual() {
    setState(() {
      dataReferencia = DateTime.now();
    });
    carregarDados();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  String _asString(dynamic value, [String fallback = ""]) {
    if (value == null) return fallback;
    return value.toString().trim();
  }

  String _formatarRitmoMinKm(double segundos) {
    if (segundos <= 0) return "--:--";
    final minutos = (segundos ~/ 60);
    final segs = (segundos % 60).round();
    return "$minutos:${segs.toString().padLeft(2, '0')} min/km";
  }

  Widget _buildPeriodoSelector(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F33) : const Color(0xFFEFF4F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: "Esta Semana",
              icon: Icons.date_range_rounded,
              isSelected: periodoFiltroIndex == 0,
              isDark: isDark,
              onTap: () => setState(() => periodoFiltroIndex = 0),
            ),
          ),
          Expanded(
            child: _tabButton(
              label: "Geral (Total)",
              icon: Icons.all_inclusive_rounded,
              isSelected: periodoFiltroIndex == 1,
              isDark: isDark,
              onTap: () => setState(() => periodoFiltroIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF0066FF)
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧠 PÁGINA DASHBOARD
  Widget _buildDashboard() {
    if (loading && data == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF0066FF),
              strokeWidth: 3,
            ),
            SizedBox(height: 14),
            Text(
              "Carregando seu treino...",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                erroCarregamento ?? "Não foi possível carregar os dados",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Verifique sua conexão com a internet e tente novamente.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: carregarDados,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Tentar novamente"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d = data!;
    final resumo = d["resumo"] is Map ? d["resumo"] as Map<String, dynamic> : {};
    final resumoGeral = d["resumo_geral"] is Map ? d["resumo_geral"] as Map<String, dynamic> : {};
    final perfil = d["perfil"] is Map ? d["perfil"] as Map<String, dynamic> : {};

    // Dados do usuário
    final nomeUsuario = _asString(
      d["nome"] ?? perfil["nome_usuario"] ?? perfil["nome"],
      "Corredor",
    );
    final fotoUrl = _asString(d["foto_url"] ?? perfil["foto_url"]);

    // Cálculos de datas da semana atual
    final inicioSemana = _calcularInicioSemana(dataReferencia);
    final fimSemana = _calcularFimSemana(inicioSemana);
    final isSemanaAtual = _verificarSeSemanaAtual(inicioSemana, fimSemana);

    // Treinos concluídos
    final ultimosTreinos = (d["treinos"] as List? ?? []);
    final treinosConcluidos = ultimosTreinos.where((t) {
      return _asString(t["status"]).toLowerCase() == "concluido";
    }).toList();

    // Filtra treinos da semana selecionada
    final treinosSemanaSelecionada = treinosConcluidos.where((t) {
      final dt = AppDateUtils.extrairDataPura(t["data"]);
      if (dt == null) return false;
      return !dt.isBefore(DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day)) &&
          !dt.isAfter(DateTime(fimSemana.year, fimSemana.month, fimSemana.day));
    }).toList();

    // 7 Dias da semana para o gráfico
    const diasNomes = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"];
    const diasCompletos = [
      "Segunda-feira",
      "Terça-feira",
      "Quarta-feira",
      "Quinta-feira",
      "Sexta-feira",
      "Sábado",
      "Domingo"
    ];

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    final kmPorDiaSemana = List.generate(7, (i) {
      final diaAlvo = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day + i);
      double kmNoDia = 0.0;

      for (var t in treinosConcluidos) {
        final dt = AppDateUtils.extrairDataPura(t["data"]);
        if (dt != null &&
            dt.year == diaAlvo.year &&
            dt.month == diaAlvo.month &&
            dt.day == diaAlvo.day) {
          kmNoDia += _asDouble(t["distancia_km"] ?? t["km"]);
        }
      }

      final diaFormatado = "${diaAlvo.day.toString().padLeft(2, '0')}/${diaAlvo.month.toString().padLeft(2, '0')}";
      final isHoje = diaAlvo.year == hoje.year && diaAlvo.month == hoje.month && diaAlvo.day == hoje.day;

      return {
        "dia": diasNomes[i],
        "dia_completo": "${diasCompletos[i]} ($diaFormatado)",
        "km": kmNoDia,
        "data": diaAlvo,
        "is_hoje": isHoje,
      };
    });

    // Métrica total de km calculada localmente para garantir exatidão
    final kmCalculadoSemana = kmPorDiaSemana.fold<double>(
      0.0,
      (total, item) => total + _asDouble(item["km"]),
    );

    // Tempo total da semana calculado localmente como garantia defensiva
    int tempoCalculadoSemanaSegundos = 0;
    for (var t in treinosSemanaSelecionada) {
      tempoCalculadoSemanaSegundos += _asInt(t["tempo_segundos"]);
    }

    // Carga semanal calculada com fallback
    int cargaSemanaCalculada = 0;
    if (d["carga"] is List && (d["carga"] as List).isNotEmpty) {
      // Backend agora retorna ordenado DESC, primeiro item é a semana selecionada/recente
      cargaSemanaCalculada = _asInt(d["carga"][0]["carga"]);
    }
    if (cargaSemanaCalculada <= 0 && treinosSemanaSelecionada.isNotEmpty) {
      for (var t in treinosSemanaSelecionada) {
        final sensacao = _asInt(t["sensacao"], 5);
        final tempoMinutos = _asInt(t["tempo_segundos"]) / 60;
        cargaSemanaCalculada += (tempoMinutos * sensacao).round();
      }
    }

    // Alterna dados conforme o seletor (Esta Semana vs Todo o Histórico)
    final bool modoSemana = periodoFiltroIndex == 0;

    final kmExibicao = modoSemana
        ? (_asDouble(resumo["total_km"]) > 0 ? _asDouble(resumo["total_km"]) : kmCalculadoSemana)
        : (_asDouble(resumoGeral["total_km"]) > 0 ? _asDouble(resumoGeral["total_km"]) : _asDouble(resumo["total_km"]));

    final tempoExibicaoSegundos = modoSemana
        ? (_asInt(resumo["total_tempo"]) > 0 ? _asInt(resumo["total_tempo"]) : tempoCalculadoSemanaSegundos)
        : (_asInt(resumoGeral["total_tempo"]) > 0 ? _asInt(resumoGeral["total_tempo"]) : _asInt(resumo["total_tempo"]));

    final treinosQtd = modoSemana
        ? (_asInt(resumo["total_treinos"]) > 0 ? _asInt(resumo["total_treinos"]) : treinosSemanaSelecionada.length)
        : (_asInt(resumoGeral["total_treinos"]) > 0 ? _asInt(resumoGeral["total_treinos"]) : treinosConcluidos.length);

    final ritmoExibicao = modoSemana
        ? _asDouble(resumo["ritmo_medio"])
        : _asDouble(resumoGeral["ritmo_medio"]);

    // Comparação semanal
    final comparacao = d["comparacao"] is Map ? d["comparacao"] as Map<String, dynamic> : null;

    // Metas
    final listaMetas = (d["metas"] as List? ?? []);
    dynamic metaAtiva;

    for (var m in listaMetas) {
      if (m["concluida"] != true && (m["tipo"]?.toString().toLowerCase() == "km")) {
        metaAtiva = m;
        break;
      }
    }
    if (metaAtiva == null) {
      for (var m in listaMetas) {
        if (m["concluida"] != true) {
          metaAtiva = m;
          break;
        }
      }
    }
    if (metaAtiva == null && listaMetas.isNotEmpty) {
      metaAtiva = listaMetas.first;
    }

    final objetivoPerfilKm = _asDouble(
      d["objetivo_semanal_km"] ?? perfil["objetivo_semanal_km"],
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: const Color(0xFF0066FF),
      onRefresh: carregarDados,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO HEADER DE ALTO IMPACTO
            DashboardHeader(
              nome: nomeUsuario,
              fotoUrl: fotoUrl.isNotEmpty ? fotoUrl : null,
              dataReferencia: dataReferencia,
              inicioSemana: inicioSemana,
              fimSemana: fimSemana,
              isSemanaAtual: isSemanaAtual,
              onSemanaAnterior: _irSemanaAnterior,
              onProximaSemana: isSemanaAtual ? null : _irProximaSemana,
              onSemanaAtual: _irSemanaAtual,
              onAbrirPerfil: () {
                setState(() => selectedIndex = 3);
              },
            ),

            const SizedBox(height: 16),

            // 2. SELETOR DE PERÍODO (ESTA SEMANA VS HISTÓRICO GERAL)
            _buildPeriodoSelector(isDark),

            const SizedBox(height: 16),

            // 3. CARDS DE ESTATÍSTICAS ESPORTIVAS
            DashboardStats(
              kmSemana: kmExibicao,
              tempo: tempoExibicaoSegundos,
              carga: cargaSemanaCalculada,
              treinos: treinosQtd,
              ritmoMedioSegundos: ritmoExibicao > 0 ? ritmoExibicao : null,
              comparacao: modoSemana ? comparacao : null,
            ),

            const SizedBox(height: 18),

            // 4. CARD DE META DA SEMANA
            WeeklyGoalCard(
              kmAtual: kmCalculadoSemana,
              meta: metaAtiva,
              objetivoPerfilKm: objetivoPerfilKm > 0 ? objetivoPerfilKm : null,
              onCriarMeta: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MetasPage(abrirCriarMetaAoIniciar: true),
                  ),
                );
                carregarDados();
              },
              onVerMetas: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MetasPage(),
                  ),
                );
                carregarDados();
              },
            ),

            const SizedBox(height: 18),

            // 5. GRÁFICO DE VOLUME SEMANAL (SEGUNDA A DOMINGO)
            WeeklyChartCard(
              dados: kmPorDiaSemana,
              titulo: isSemanaAtual ? "Volume Semanal" : "Volume da Semana",
              subtitulo: "Segunda a Domingo (${kmCalculadoSemana.toStringAsFixed(1)} km)",
            ),

            const SizedBox(height: 18),

            // 6. ATALHOS E AÇÕES RÁPIDAS
            QuickActions(
              iniciarCorrida: () {
                setState(() => selectedIndex = 1);
              },
              abrirTreinos: () {
                setState(() => selectedIndex = 2);
              },
              abrirMetas: () async {
                await Navigator.pushNamed(context, "/metas");
                carregarDados();
              },
              atualizar: carregarDados,
            ),

            const SizedBox(height: 18),

            // 7. CARD PACEMIND AI INSIGHTS
            _buildAiInsightCard(
              ritmo: ritmoExibicao,
              kmSemana: kmCalculadoSemana,
              treinosSemana: treinosSemanaSelecionada.length,
              isDark: isDark,
            ),

            const SizedBox(height: 18),

            // 8. TREINOS RECENTES
            RecentWorkoutsCard(
              treinos: treinosConcluidos,
              onVerTodos: () {
                setState(() => selectedIndex = 2);
              },
              onTreinoTap: (_) {
                setState(() => selectedIndex = 2);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard({
    required double ritmo,
    required double kmSemana,
    required int treinosSemana,
    required bool isDark,
  }) {
    String dica = "Inicie seus treinos da semana para desbloquear diagnósticos da inteligência artificial.";
    if (kmSemana > 30) {
      dica = "Excelente volume semanal! Mantenha a hidratação reforçada e faça treinos regenerativos para evitar fadiga excessiva.";
    } else if (kmSemana > 15) {
      dica = "Ritmo constante! Seu volume está equilibrado para ganho de resistência aeróbica sem sobrecarga.";
    } else if (treinosSemana >= 1) {
      dica = "Bom início de semana! Manter um ritmo controlado nos primeiros treinos prepara as fibras musculares para sessões mais intensas.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFF6366F1).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF6366F1).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PaceMind AI Coach",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "Inteligência e Análise do Atleta",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, "/recomendacoes");
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Abrir IA",
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF6366F1),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Métricas de Ritmo e Consistência
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          color: Color(0xFF0066FF),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ritmo Geral",
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatarRitmoMinKm(ritmo),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sessões",
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "$treinosSemana concluída${treinosSemana != 1 ? 's' : ''}",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dica contextual da IA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dica,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
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
    final pages = [
      _buildDashboard(),
      const MapPage(),
      TreinosPage(
        isEmbedded: true,
        onBack: () {
          setState(() {
            selectedIndex = 0;
          });
        },
      ),
      const ProfilePage(),
    ];

    String getTitulo() {
      switch (selectedIndex) {
        case 1:
          return "Corrida GPS";
        case 2:
          return "Meus Treinos";
        case 3:
          return "Meu Perfil";
        default:
          return "PaceMind";
      }
    }

    String getSubtitulo() {
      switch (selectedIndex) {
        case 1:
          return "Gravação e telemetria";
        case 2:
          return "Histórico e rotinas";
        case 3:
          return "Seus dados e metas";
        default:
          return "Seu treino de hoje";
      }
    }

    IconData getIcone() {
      switch (selectedIndex) {
        case 1:
          return Icons.location_on_rounded;
        case 2:
          return Icons.calendar_month_rounded;
        case 3:
          return Icons.person_rounded;
        default:
          return Icons.directions_run_rounded;
      }
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(getIcone(), color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTitulo(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  getSubtitulo(),
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.pushNamed(context, "/notificacoes");
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: pages[selectedIndex],

      // 🔥 MENU INFERIOR
      bottomNavigationBar: BottomMenu(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
