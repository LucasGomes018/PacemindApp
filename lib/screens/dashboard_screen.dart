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

DateTime? semanaSelecionada;

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

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialPage.clamp(0, 3);
    carregarDados();
    pedirPermissaoNotificacao();
  }

  Future<void> pedirPermissaoNotificacao() async {
    await NotificacaoService.flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> carregarDados() async {
    try {
      final dashboard = await Api.getDashboard(semana: semanaSelecionada);
      List<dynamic> treinosConcluidos = [];
      List<dynamic> metasUsuario = [];

      try {
        treinosConcluidos = await Api.listarTreinosConcluidos();
      } catch (_) {}

      try {
        metasUsuario = await Api.listarMetas();
      } catch (_) {}

      if (!mounted) return;

      final resultado = {
        ...dashboard,
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
        erroCarregamento = "Não foi possível carregar seus dados.";
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  // 🧠 PÁGINA DASHBOARD (SEPARADA)
  Widget _buildDashboard() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.lightBlueAccent),
      );
    }

    if (data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 52),
              const SizedBox(height: 12),
              Text(
                erroCarregamento ?? "Erro ao carregar dados",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    loading = true;
                    erroCarregamento = null;
                  });
                  carregarDados();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Tentar novamente"),
              ),
            ],
          ),
        ),
      );
    }

    final d = data!;
    final resumo = d["resumo"] ?? {};

    int asInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double asDouble(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    String asString(dynamic value, [String fallback = ""]) {
      if (value == null) return fallback;
      return value.toString();
    }

    final nomeUsuario = asString(d["nome"], "Usuário");
    final kmSemana = asDouble(resumo["total_km"]);
    final tempoTotalSegundos = asInt(resumo["total_tempo"]);
    final treinos = asInt(resumo["total_treinos"]);
    final carga = (d["carga"] is List && d["carga"].isNotEmpty)
        ? asInt(d["carga"][0]["carga"])
        : 0;

    final ultimosTreinos = (d["treinos"] as List? ?? []);
    final treinosConcluidos = ultimosTreinos.where((t) {
      return asString(t["status"]).toLowerCase() == "concluido";
    }).toList();

    // Calcula os 7 dias da semana atual (Segunda a Domingo)
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));

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

    final kmPorDiaSemana = List.generate(7, (i) {
      final diaAlvo = inicioSemana.add(Duration(days: i));
      double kmNoDia = 0.0;

      for (var t in treinosConcluidos) {
        final dt = AppDateUtils.extrairDataPura(t["data"]);
        if (dt != null &&
            dt.year == diaAlvo.year &&
            dt.month == diaAlvo.month &&
            dt.day == diaAlvo.day) {
          kmNoDia += asDouble(t["distancia_km"] ?? t["km"]);
        }
      }

      final diaFormatado = "${diaAlvo.day.toString().padLeft(2, '0')}/${diaAlvo.month.toString().padLeft(2, '0')}";

      return {
        "dia": diasNomes[i],
        "dia_completo": "${diasCompletos[i]} ($diaFormatado)",
        "km": kmNoDia,
        "data": diaAlvo,
      };
    });

    final ritmo = asDouble(resumo["ritmo_medio"]);
    final listaMetas = (d["metas"] as List? ?? []);
    dynamic metaAtiva;

    // 1. Procura primeiro meta em aberto de km
    for (var m in listaMetas) {
      if (m["concluida"] != true && (m["tipo"]?.toString().toLowerCase() == "km")) {
        metaAtiva = m;
        break;
      }
    }
    // 2. Se não houver, procura qualquer meta em aberto
    if (metaAtiva == null) {
      for (var m in listaMetas) {
        if (m["concluida"] != true) {
          metaAtiva = m;
          break;
        }
      }
    }
    // 3. Se todas concluídas, pega a última criada
    if (metaAtiva == null && listaMetas.isNotEmpty) {
      metaAtiva = listaMetas.last;
    }



    final consistencia = d["consistencia"] ?? {};
    String formatarRitmoMinKm(double segundos) {
      if (segundos <= 0) return "-";
      final minutos = (segundos ~/ 60);
      final segs = (segundos % 60).round();
      return "$minutos:${segs.toString().padLeft(2, '0')} min/km";
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: carregarDados,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(nome: nomeUsuario),

            const SizedBox(height: 20),

            DashboardStats(
              kmSemana: kmSemana,
              tempo: tempoTotalSegundos,
              carga: carga,
              treinos: treinos,
            ),

            // const SizedBox(height: 4),

            WeeklyGoalCard(
              kmAtual: kmSemana,
              meta: metaAtiva,
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

            const SizedBox(height: 22),

            WeeklyChartCard(dados: kmPorDiaSemana),

            const SizedBox(height: 22),

            RecentWorkoutsCard(treinos: treinosConcluidos),

            const SizedBox(height: 22),

            QuickActions(
              iniciarCorrida: () {
                setState(() {
                  selectedIndex = 1;
                });
              },
              abrirTreinos: () {
                setState(() {
                  selectedIndex = 2;
                });
              },
              atualizar: carregarDados,
            ),

            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : const Color(0xFF6366F1).withValues(alpha: 0.06),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
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
                              "Insight da Semana",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              "Análise de desempenho",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "PaceMind AI",
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      // Pace Médio Formatado
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.speed_rounded,
                                  color: Color(0xFF0066FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pace Médio",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        formatarRitmoMinKm(ritmo),
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
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

                      const SizedBox(width: 12),

                      // Treinos Concluídos
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Consistência",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "${asInt(consistencia["concluidos"])} feitos",
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
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

                  const SizedBox(height: 14),

                  // Dica contextual
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFF6366F1),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ritmo > 0
                                ? "Seu ritmo médio está em ${formatarRitmoMinKm(ritmo)}. Manter um ritmo controlado nos treinos longos melhora a economia de corrida."
                                : "Registre suas primeiras corridas da semana para acompanhar o ritmo médio e desbloquear insights da IA.",
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
            ),

            const SizedBox(height: 30),
          ],
        ),
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
        onBack: () {
          setState(() {
            selectedIndex = 0;
          });
        },
      ),
      const ProfilePage(),
    ];

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 72, 172, 254),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_run, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PaceMind",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Seu treino de hoje",
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.pushNamed(context, "/notificacoes");
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: pages[selectedIndex],

      // 🔥 MENU AQUI
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
