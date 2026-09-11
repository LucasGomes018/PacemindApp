import 'package:flutter/material.dart';
import '../core/api.dart';
import '../components/app_modal.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  bool _carregando = true;
  String? _erro;
  List<dynamic> _todosUsuarios = [];
  List<dynamic> _usuariosFiltrados = [];
  Map<String, dynamic> _perfisPorUsuario = {};
  final TextEditingController _pesquisaController = TextEditingController();
  String _filtroTipo = "todos"; // 'todos', 'atleta', 'admin'

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _pesquisaController.addListener(_filtrarUsuarios);
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final usuarios = await Api.listarUsuariosAdmin();
      List<dynamic> perfis = [];
      try {
        perfis = await Api.listarPerfisAdmin();
      } catch (_) {}

      final mapaPerfis = <String, dynamic>{};
      for (var p in perfis) {
        final id = p["id_usuario"]?.toString();
        if (id != null) {
          mapaPerfis[id] = p;
        }
      }

      if (!mounted) return;
      setState(() {
        _todosUsuarios = usuarios;
        _perfisPorUsuario = mapaPerfis;
        _carregando = false;
      });
      _filtrarUsuarios();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = "Não foi possível carregar os usuários. Verifique suas permissões de administrador.";
        _carregando = false;
      });
    }
  }

  void _filtrarUsuarios() {
    final query = _pesquisaController.text.toLowerCase().trim();
    setState(() {
      _usuariosFiltrados = _todosUsuarios.where((u) {
        final nome = (u["nome"] ?? u["nome_usuario"] ?? "").toString().toLowerCase();
        final email = (u["email"] ?? "").toString().toLowerCase();
        final tipo = (u["tipo_usuario"] ?? "atleta").toString().toLowerCase();

        final matchTexto = query.isEmpty || nome.contains(query) || email.contains(query);
        final matchTipo = _filtroTipo == "todos" ||
            (_filtroTipo == "admin" && tipo == "admin") ||
            (_filtroTipo == "atleta" && tipo != "admin");

        return matchTexto && matchTipo;
      }).toList();
    });
  }

  String _formatarPace(dynamic segundos) {
    if (segundos == null) return "--'--\"/km";
    final s = int.tryParse(segundos.toString()) ?? 0;
    if (s <= 0) return "--'--\"/km";
    final min = s ~/ 60;
    final seg = s % 60;
    return "$min'${seg.toString().padLeft(2, '0')}\"/km";
  }

  String _formatarTempo(dynamic segundos) {
    if (segundos == null) return "0 min";
    final s = int.tryParse(segundos.toString()) ?? 0;
    final min = s ~/ 60;
    final seg = s % 60;
    if (min >= 60) {
      final h = min ~/ 60;
      final mRest = min % 60;
      return "${h}h ${mRest}m";
    }
    return "$min min ${seg > 0 ? '$seg s' : ''}".trim();
  }

  void _abrirDetalhesAluno(Map<String, dynamic> usuario) {
    final idUsuario = usuario["id_usuario"]?.toString() ?? "";
    final nome = usuario["nome"] ?? usuario["nome_usuario"] ?? "Aluno";
    final email = usuario["email"] ?? "";
    final tipo = usuario["tipo_usuario"] == "admin" ? "Administrador" : "Atleta";
    final perfil = _perfisPorUsuario[idUsuario] ?? {};

    AppModal.showBottomSheet(
      context: context,
      title: nome,
      subtitle: "$tipo • $email",
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF0066FF),
      maxChildSize: 0.95,
      initialChildSize: 0.85,
      builder: (modalContext, scrollController) {
        return _AlunoDetalhesSheet(
          idUsuario: idUsuario,
          usuario: usuario,
          perfil: perfil,
          formatarPace: _formatarPace,
          formatarTempo: _formatarTempo,
          scrollController: scrollController,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    final totalAlunos = _todosUsuarios.where((u) => u["tipo_usuario"] != "admin").length;
    final totalAdmins = _todosUsuarios.where((u) => u["tipo_usuario"] == "admin").length;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gestão de Alunos",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text(
              "Painel de Controle do Treinador",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _carregarDados,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Atualizar lista",
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _carregarDados,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("Tentar Novamente"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // RESUMO DE MÉTRICAS RÁPIDAS
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  label: "Total Alunos",
                                  value: totalAlunos.toString(),
                                  icon: Icons.directions_run_rounded,
                                  color: const Color(0xFF0066FF),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  label: "Administradores",
                                  value: totalAdmins.toString(),
                                  icon: Icons.shield_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  label: "Total Geral",
                                  value: _todosUsuarios.length.toString(),
                                  icon: Icons.group_rounded,
                                  color: const Color(0xFF10B981),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // BARRA DE PESQUISA
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _pesquisaController,
                          decoration: InputDecoration(
                            hintText: "Pesquisar aluno por nome ou email...",
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            suffixIcon: _pesquisaController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _pesquisaController.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // FILTRO POR CHIPS (Todos / Atletas / Admins)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("Todos", "todos", isDark),
                            const SizedBox(width: 8),
                            _buildFilterChip("Atletas ($totalAlunos)", "atleta", isDark),
                            const SizedBox(width: 8),
                            _buildFilterChip("Admins ($totalAdmins)", "admin", isDark),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // CONTAGEM DE RESULTADOS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${_usuariosFiltrados.length} ${_usuariosFiltrados.length == 1 ? 'aluno encontrado' : 'alunos encontrados'}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            if (_pesquisaController.text.isNotEmpty)
                              TextButton(
                                onPressed: () => _pesquisaController.clear(),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: const Text("Limpar busca", style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // LISTA DE CARDS DE ALUNOS
                      if (_usuariosFiltrados.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 54,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Nenhum aluno encontrado",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Tente buscar com outro termo ou filtro.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._usuariosFiltrados.map((usuario) {
                          final id = usuario["id_usuario"]?.toString() ?? "";
                          final perfil = _perfisPorUsuario[id];
                          return _buildAlunoCard(usuario, perfil, isDark);
                        }),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filtroTipo == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroTipo = value;
        });
        _filtrarUsuarios();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0066FF)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildAlunoCard(Map<String, dynamic> usuario, Map<String, dynamic>? perfil, bool isDark) {
    final nome = (usuario["nome"] ?? usuario["nome_usuario"] ?? "Aluno").toString();
    final email = (usuario["email"] ?? "").toString();
    final tipo = (usuario["tipo_usuario"] ?? "atleta").toString();
    final isAdmin = tipo == "admin";
    final criadoEm = usuario["criado_em"]?.toString() ?? "";

    final pace = perfil?["pace_referencia_segundos"];
    final metaKm = perfil?["objetivo_semanal_km"];

    // Iniciais do nome
    final partes = nome.trim().split(" ");
    final iniciais = partes.length > 1
        ? "${partes[0][0]}${partes[1][0]}".toUpperCase()
        : (nome.isNotEmpty ? nome[0].toUpperCase() : "A");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _abrirDetalhesAluno(usuario),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // AVATAR COM GRADIENTE
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isAdmin
                          ? [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]
                          : [const Color(0xFF0066FF), const Color(0xFF00B4D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isAdmin ? const Color(0xFF8B5CF6) : const Color(0xFF0066FF))
                            .withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      iniciais,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // INFORMAÇÕES DO ALUNO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nome,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.12)
                                  : const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isAdmin ? "Admin" : "Atleta",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAdmin ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // CHIPS DE PACE E META
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (pace != null && int.tryParse(pace.toString()) != null && int.parse(pace.toString()) > 0)
                            _buildInfoBadge(
                              icon: Icons.speed_rounded,
                              label: _formatarPace(pace),
                              isDark: isDark,
                            ),
                          if (metaKm != null)
                            _buildInfoBadge(
                              icon: Icons.flag_rounded,
                              label: "$metaKm km/sem",
                              isDark: isDark,
                            ),
                          if (criadoEm.isNotEmpty)
                            _buildInfoBadge(
                              icon: Icons.calendar_today_rounded,
                              label: criadoEm.split(" ")[0],
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: isDark ? Colors.white60 : Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal / BottomSheet de detalhamento completo do aluno para o Administrador.
class _AlunoDetalhesSheet extends StatefulWidget {
  final String idUsuario;
  final Map<String, dynamic> usuario;
  final Map<String, dynamic> perfil;
  final String Function(dynamic) formatarPace;
  final String Function(dynamic) formatarTempo;
  final ScrollController scrollController;

  const _AlunoDetalhesSheet({
    required this.idUsuario,
    required this.usuario,
    required this.perfil,
    required this.formatarPace,
    required this.formatarTempo,
    required this.scrollController,
  });

  @override
  State<_AlunoDetalhesSheet> createState() => _AlunoDetalhesSheetState();
}

class _AlunoDetalhesSheetState extends State<_AlunoDetalhesSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _carregando = true;
  List<dynamic> _treinos = [];
  Map<String, dynamic> _ficha = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDadosAluno();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosAluno() async {
    setState(() => _carregando = true);
    try {
      final treinosFuture = Api.buscarTreinosPorAluno(widget.idUsuario);
      final fichaFuture = Api.buscarFichaPorAluno(widget.idUsuario);

      final resultados = await Future.wait([treinosFuture, fichaFuture]);
      if (!mounted) return;
      setState(() {
        _treinos = resultados[0] as List<dynamic>;
        _ficha = resultados[1] as Map<String, dynamic>;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ABAS DE NAVEGAÇÃO INTERNA
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF0066FF),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "Treinos"),
              Tab(text: "Ficha Médica"),
              Tab(text: "Perfil"),
            ],
          ),
        ),

        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // ABA 1: TREINOS DO ALUNO
                    _buildAbaTreinos(isDark),

                    // ABA 2: FICHA MÉDICA / ANAMNESE
                    _buildAbaFicha(isDark),

                    // ABA 3: PERFIL & OBJETIVOS
                    _buildAbaPerfil(isDark),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAbaTreinos(bool isDark) {
    if (_treinos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 12),
              Text(
                "Nenhum treino registrado",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                "O aluno ainda não registrou sessões de treino.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _treinos.length,
      itemBuilder: (context, index) {
        final treino = _treinos[index];
        final tipo = treino["tipo"]?.toString() ?? "Corrida";
        final distancia = double.tryParse(treino["distancia_km"]?.toString() ?? "0") ?? 0.0;
        final tempo = treino["tempo_segundos"];
        final data = treino["data"]?.toString() ?? "";
        final ritmo = treino["ritmo_medio_segundos"];
        final status = treino["status"]?.toString() ?? "concluido";
        final sensacao = treino["sensacao"];

        final isConcluido = status == "concluido";

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.directions_run_rounded, color: Color(0xFF0066FF), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipo.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            data,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isConcluido
                          ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12)
                          : const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isConcluido ? "Concluído" : "Planejado",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isConcluido ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCol("Distância", "${distancia.toStringAsFixed(1)} km", isDark),
                  _buildMetricCol("Tempo", widget.formatarTempo(tempo), isDark),
                  _buildMetricCol("Pace Médio", widget.formatarPace(ritmo), isDark),
                  if (sensacao != null)
                    _buildMetricCol("Sensação", "$sensacao/10", isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCol(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildAbaFicha(bool isDark) {
    if (_ficha.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_late_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 12),
              Text(
                "Ficha médica ainda não preenchida",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                "O aluno ainda não completou os dados da ficha de anamnese.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    final peso = _ficha["peso_kg"]?.toString() ?? "-";
    final altura = _ficha["altura_cm"]?.toString() ?? "-";
    final tipoSanguineo = _ficha["tipo_sanguineo"]?.toString() ?? "-";
    final contatoEmergencia = _ficha["contato_emergencia"]?.toString() ?? "-";
    final telEmergencia = _ficha["telefone_emergencia"]?.toString() ?? "-";
    final patologias = _ficha["patologias"]?.toString() ?? "Nenhuma relatada";
    final alergias = _ficha["alergias"]?.toString() ?? "Nenhuma relatada";
    final medicamentos = _ficha["medicamentos"]?.toString() ?? "Nenhum relatado";
    final obs = _ficha["observacoes_medicas"]?.toString() ?? "Sem observações adicionais";

    // Cálculo IMC
    String imcTexto = "-";
    final p = double.tryParse(peso);
    final a = double.tryParse(altura);
    if (p != null && a != null && a > 0) {
      final aMetros = a / 100;
      final imc = p / (aMetros * aMetros);
      imcTexto = imc.toStringAsFixed(1);
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // DADOS FÍSICOS
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Biometria do Atleta",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCol("Peso", "$peso kg", isDark),
                  _buildMetricCol("Altura", "$altura cm", isDark),
                  _buildMetricCol("IMC", imcTexto, isDark),
                  _buildMetricCol("Tipo Sang.", tipoSanguineo, isDark),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // CONTATO DE EMERGÊNCIA
        _buildFichaCard(
          title: "Contato de Emergência",
          icon: Icons.contact_phone_rounded,
          color: const Color(0xFFEF4444),
          content: "$contatoEmergencia • $telEmergencia",
          isDark: isDark,
        ),

        const SizedBox(height: 10),

        // PATOLOGIAS E ASMA
        _buildFichaCard(
          title: "Patologias / Condições Respiratórias",
          icon: Icons.healing_rounded,
          color: const Color(0xFFF59E0B),
          content: patologias,
          isDark: isDark,
        ),

        const SizedBox(height: 10),

        // ALERGIAS
        _buildFichaCard(
          title: "Alergias",
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFF8B5CF6),
          content: alergias,
          isDark: isDark,
        ),

        const SizedBox(height: 10),

        // MEDICAMENTOS
        _buildFichaCard(
          title: "Medicamentos de Uso Contínuo",
          icon: Icons.medication_rounded,
          color: const Color(0xFF10B981),
          content: medicamentos,
          isDark: isDark,
        ),

        const SizedBox(height: 10),

        // OBSERVAÇÕES MÉDICAS
        _buildFichaCard(
          title: "Observações Médicas Gerais",
          icon: Icons.notes_rounded,
          color: const Color(0xFF0066FF),
          content: obs,
          isDark: isDark,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFichaCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbaPerfil(bool isDark) {
    final nome = widget.usuario["nome"] ?? widget.usuario["nome_usuario"] ?? "-";
    final email = widget.usuario["email"] ?? "-";
    final tipo = widget.usuario["tipo_usuario"] ?? "atleta";
    final criadoEm = widget.usuario["criado_em"] ?? "-";

    final paceRef = widget.perfil["pace_referencia_segundos"];
    final metaKm = widget.perfil["objetivo_semanal_km"];

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dados de Acesso & Registro",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              _buildInfoRow("Nome Completo", nome, isDark),
              _buildInfoRow("Email", email, isDark),
              _buildInfoRow("Tipo de Conta", tipo.toUpperCase(), isDark),
              _buildInfoRow("Cadastrado em", criadoEm, isDark),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Configuração Esportiva",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              _buildInfoRow("Pace de Referência", widget.formatarPace(paceRef), isDark),
              _buildInfoRow("Meta Semanal", metaKm != null ? "$metaKm km por semana" : "Não cadastrado", isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
