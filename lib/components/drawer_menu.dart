import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import 'app_modal.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? perfil;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    try {
      final data = await Api.getProfile();
      Map<String, dynamic>? usuario;
      try {
        usuario = await Api.me();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        perfil = data;
        isAdmin = (usuario?["tipo_usuario"] == "admin") || (data["tipo_usuario"] == "admin");
      });
    } catch (_) {}
  }

  Future<void> logout() async {
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Sair da conta",
      message: "Deseja realmente encerrar sua sessão e sair do aplicativo?",
      confirmText: "Sair",
      cancelText: "Cancelar",
      icon: Icons.logout_rounded,
      iconColor: const Color(0xFFEF4444),
      confirmButtonColor: const Color(0xFFEF4444),
      isDestructive: true,
    );

    if (confirmar != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!mounted) return;

    Navigator.pop(context); // fecha o drawer
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Drawer(
      backgroundColor: scaffoldBg,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // HEADER ESTILIZADO
                _buildDrawerHeader(context),

                const SizedBox(height: 12),

                // PERFORMANCE
                _sectionHeader(
                  title: "Performance",
                  color: const Color(0xFF0066FF),
                  icon: Icons.speed_rounded,
                ),
                _drawerItem(
                  icon: Icons.timer_outlined,
                  title: "Testes de Corrida (3km & ASR)",
                  route: "/testes",
                  accentColor: const Color(0xFF0066FF),
                ),
                _drawerItem(
                  icon: Icons.calendar_month_rounded,
                  title: "Eventos",
                  route: "/eventos",
                  accentColor: const Color(0xFF0066FF),
                ),
                _drawerItem(
                  icon: Icons.speed_rounded,
                  title: "Zonas de Treino",
                  route: "/zonas",
                  accentColor: const Color(0xFF0066FF),
                ),
                _drawerItem(
                  icon: Icons.show_chart_rounded,
                  title: "Evolução",
                  route: "/evolucao",
                  accentColor: const Color(0xFF0066FF),
                ),
                _drawerItem(
                  icon: Icons.warning_amber_rounded,
                  title: "Overtraining",
                  route: "/overtraining",
                  accentColor: const Color(0xFFF59E0B),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Divider(color: dividerColor, height: 1),
                ),

                // MUSCULAÇÃO
                _sectionHeader(
                  title: "Musculação",
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.fitness_center_rounded,
                ),
                _drawerItem(
                  icon: Icons.fitness_center_rounded,
                  title: "Treinos",
                  route: "/treinos",
                  accentColor: const Color(0xFF8B5CF6),
                ),
                _drawerItem(
                  icon: Icons.history_rounded,
                  title: "Execuções",
                  route: "/execucoes",
                  accentColor: const Color(0xFF8B5CF6),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Divider(color: dividerColor, height: 1),
                ),

                // SAÚDE
                _sectionHeader(
                  title: "Saúde & Avaliações",
                  color: const Color(0xFF10B981),
                  icon: Icons.favorite_border_rounded,
                ),
                _drawerItem(
                  icon: Icons.assignment_rounded,
                  title: "Questionários de Asma",
                  route: "/questionarios",
                  accentColor: const Color(0xFF10B981),
                ),
                _drawerItem(
                  icon: Icons.badge_outlined,
                  title: "Ficha do Aluno",
                  route: "/ficha",
                  accentColor: const Color(0xFF10B981),
                ),
                _drawerItem(
                  icon: Icons.biotech_rounded,
                  title: "Exames",
                  route: "/exames",
                  accentColor: const Color(0xFF10B981),
                ),
                _drawerItem(
                  icon: Icons.medical_information_outlined,
                  title: "Relatórios",
                  route: "/relatorios",
                  accentColor: const Color(0xFF10B981),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Divider(color: dividerColor, height: 1),
                ),

                // OBJETIVOS
                _sectionHeader(
                  title: "Objetivos & IA",
                  color: const Color(0xFFEC4899),
                  icon: Icons.auto_awesome_rounded,
                ),
                _drawerItem(
                  icon: Icons.flag_rounded,
                  title: "Metas",
                  route: "/metas",
                  accentColor: const Color(0xFFEC4899),
                ),
                _drawerItem(
                  icon: Icons.auto_awesome_rounded,
                  title: "Recomendações IA",
                  route: "/recomendacoes",
                  accentColor: const Color(0xFFEC4899),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Divider(color: dividerColor, height: 1),
                ),

                // ADMINISTRAÇÃO (Exclusivo para Treinadores / Admins)
                if (isAdmin) ...[
                  _sectionHeader(
                    title: "Administração",
                    color: const Color(0xFFF59E0B),
                    icon: Icons.admin_panel_settings_rounded,
                  ),
                  _drawerItem(
                    icon: Icons.people_alt_rounded,
                    title: "Gestão de Alunos",
                    route: "/admin/usuarios",
                    accentColor: const Color(0xFFF59E0B),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Divider(color: dividerColor, height: 1),
                  ),
                ],

                // SISTEMA
                _sectionHeader(
                  title: "Sistema",
                  color: const Color(0xFF64748B),
                  icon: Icons.settings_outlined,
                ),
                _drawerItem(
                  icon: Icons.notifications_none_rounded,
                  title: "Notificações",
                  route: "/notificacoes",
                  accentColor: const Color(0xFF64748B),
                ),
                _drawerItem(
                  icon: Icons.settings_rounded,
                  title: "Configurações",
                  route: "/configuracoes",
                  accentColor: const Color(0xFF64748B),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // RODAPÉ COM LOGOUT ESTILIZADO
          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final nome = perfil?["nome_usuario"] ?? "Atleta";
    final fotoUrl = perfil?["foto_url"];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0052CC), Color(0xFF0066FF), Color(0xFF00C6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330066FF),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar com borda luminosa
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFEBF5FF),
                  backgroundImage: fotoUrl != null
                      ? NetworkImage("${Api.baseUrl}$fotoUrl")
                      : null,
                  child: fotoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: Color(0xFF0066FF),
                        )
                      : null,
                ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_run_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Atleta PaceMind",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFFDE047),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Centro de Performance",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  "PRO",
                  style: TextStyle(
                    color: Color(0xFFFDE047),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required String route,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                // Ícone em caixinha arredondada colorida suave
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: logout,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Sair da conta",
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "PaceMind • Versão 1.0.0",
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
