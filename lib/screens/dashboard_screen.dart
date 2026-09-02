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
import '../services/notificacao_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '/components/drawer_menu.dart';

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

      try {
        treinosConcluidos = await Api.listarTreinosConcluidos();
      } catch (_) {}

      if (!mounted) return;

      final resultado = {...dashboard, "treinos": treinosConcluidos};

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

    final kmPorSemana = (d["semanal"] as List? ?? []).map<Map<String, dynamic>>(
      (item) {
        return {"semana": asString(item["semana"]), "km": asDouble(item["km"])};
      },
    ).toList();

    final ritmo = asDouble(resumo["ritmo_medio"]);
    final metaKm = asDouble(resumo["meta_km"]);
    final ultimosTreinos = (d["treinos"] as List? ?? []);

    final consistencia = d["consistencia"] ?? {};
    final insight1 = "Treinos concluídos: ${asInt(consistencia["concluidos"])}";

    final treinosConcluidos = ultimosTreinos.where((t) {
      return asString(t["status"]).toLowerCase() == "concluido";
    }).toList();

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

            const SizedBox(height: 22),

            WeeklyGoalCard(
              kmAtual: kmSemana,
              metaKm: metaKm == 0 ? 30 : metaKm,
            ),

            const SizedBox(height: 22),

            WeeklyChartCard(dados: kmPorSemana),

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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Insight da semana",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    insight1,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Pace médio: ${ritmo == 0 ? "-" : "${ritmo.toStringAsFixed(0)} s/km"}",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
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
