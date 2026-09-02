import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? perfil;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    final data = await Api.getProfile();

    setState(() {
      perfil = data;
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");

    if (!mounted) return;

    Navigator.pop(context);

    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultItemColor = isDark ? Colors.white70 : Colors.black87;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0066FF), Color(0xFF4DA3FF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      backgroundImage: perfil?["foto_url"] != null
                          ? NetworkImage("${Api.baseUrl}${perfil!["foto_url"]}")
                          : null,
                      child: perfil?["foto_url"] == null
                          ? const Icon(
                              Icons.person,
                              size: 38,
                              color: Color(0xFF0066FF),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Olá,",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            perfil?["nome_usuario"] ?? "Carregando...",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  "PaceMind",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Seu centro de performance",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _sectionTitle("Performance"),

          _drawerItem(
            context,
            icon: Icons.timer_outlined,
            title: "Testes de Corrida (3km & ASR)",
            route: "/testes",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.calendar_month,
            title: "Eventos",
            route: "/eventos",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.speed,
            title: "Zonas de treino",
            route: "/zonas",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.show_chart,
            title: "Evolução",
            route: "/evolucao",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.warning_amber_rounded,
            title: "Overtraining",
            route: "/overtraining",
            color: defaultItemColor,
          ),

          const Divider(),

          _sectionTitle("Musculação"),

          _drawerItem(
            context,
            icon: Icons.fitness_center,
            title: "Treinos",
            route: "/treinos",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.history,
            title: "Execuções",
            route: "/execucoes",
            color: defaultItemColor,
          ),

          const Divider(),

          _sectionTitle("Saúde"),

          _drawerItem(
            context,
            icon: Icons.assignment_rounded,
            title: "Questionários de Asma",
            route: "/questionarios",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.description,
            title: "Ficha do aluno",
            route: "/ficha",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.biotech,
            title: "Exames",
            route: "/exames",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.medical_information,
            title: "Relatórios",
            route: "/relatorios",
            color: defaultItemColor,
          ),

          const Divider(),

          _sectionTitle("Objetivos"),

          _drawerItem(
            context,
            icon: Icons.flag,
            title: "Metas",
            route: "/metas",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.auto_awesome,
            title: "Recomendações",
            route: "/recomendacoes",
            color: defaultItemColor,
          ),

          const Divider(),

          _sectionTitle("Sistema"),

          _drawerItem(
            context,
            icon: Icons.notifications,
            title: "Notificações",
            route: "/notificacoes",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.settings,
            title: "Configurações",
            route: "/configuracoes",
            color: defaultItemColor,
          ),

          _drawerItem(
            context,
            icon: Icons.logout,
            title: "Sair",
            route: "/logout",
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: () async {
        if (route == "/logout") {
          await logout();
          return;
        }

        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
