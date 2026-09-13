import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../components/app_modal.dart';
import '../utils/date_utils.dart';

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

  static String? resolverFotoUrl(dynamic url) {
    if (url == null) return null;
    final str = url.toString().trim();
    if (str.isEmpty || str == "null") return null;
    if (str.startsWith("http://") || str.startsWith("https://")) {
      return str;
    }
    final base = Api.baseUrl.endsWith("/")
        ? Api.baseUrl.substring(0, Api.baseUrl.length - 1)
        : Api.baseUrl;
    final path = str.startsWith("/") ? str : "/$str";
    return "$base$path";
  }

  void _abrirDetalhesAluno(Map<String, dynamic> usuario) {
    final idUsuario = usuario["id_usuario"]?.toString() ?? "";
    final nome = usuario["nome"] ?? usuario["nome_usuario"] ?? "Aluno";
    final email = usuario["email"] ?? "";
    final tipo = usuario["tipo_usuario"] == "admin" ? "Administrador" : "Atleta PaceMind";
    final perfil = _perfisPorUsuario[idUsuario] ?? {};

    AppModal.showBottomSheet(
      context: context,
      title: nome,
      subtitle: "$tipo • $email",
      icon: Icons.person_rounded,
      iconColor: const Color(0xFF0066FF),
      maxChildSize: 0.96,
      initialChildSize: 0.92,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestão de Alunos",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text(
              "Painel de Controle do Treinador",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
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

    // Foto do aluno
    final rawFoto = usuario["foto_url"] ?? perfil?["foto_url"];
    final fotoUrl = resolverFotoUrl(rawFoto);

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
                // AVATAR COM FOTO OU GRADIENTE + INICIAIS
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
                  child: ClipOval(
                    child: (fotoUrl != null)
                        ? Image.network(
                            fotoUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                iniciais,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        : Center(
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
  String _filtroTreino = "todos";

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

  (String, Color) _classificacaoIMC(double? imc) {
    if (imc == null || imc <= 0) return ("Não informado", Colors.grey);
    if (imc < 18.5) return ("Abaixo do peso", const Color(0xFF3B82F6));
    if (imc < 25.0) return ("Peso ideal", const Color(0xFF10B981));
    if (imc < 30.0) return ("Sobrepeso", const Color(0xFFF59E0B));
    return ("Obesidade", const Color(0xFFEF4444));
  }

  (String, Color) _detalheSensacao(dynamic rpeVal) {
    final rpe = int.tryParse(rpeVal?.toString() ?? "");
    if (rpe == null) return ("Não informada", Colors.grey);
    if (rpe <= 3) return ("Leve ($rpe/10)", const Color(0xFF10B981));
    if (rpe <= 6) return ("Moderado ($rpe/10)", const Color(0xFF0066FF));
    if (rpe <= 8) return ("Intenso ($rpe/10)", const Color(0xFFF59E0B));
    return ("Exaustivo ($rpe/10)", const Color(0xFFEF4444));
  }

  (IconData, List<Color>) _estiloTipoTreino(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains("long") || t.contains("rodag")) {
      return (Icons.alt_route_rounded, [const Color(0xFF8B5CF6), const Color(0xFFA855F7)]);
    }
    if (t.contains("interv") || t.contains("tiro") || t.contains("veloc")) {
      return (Icons.flash_on_rounded, [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]);
    }
    if (t.contains("regen") || t.contains("leve")) {
      return (Icons.spa_rounded, [const Color(0xFF10B981), const Color(0xFF34D399)]);
    }
    if (t.contains("muscul") || t.contains("func") || t.contains("forca")) {
      return (Icons.fitness_center_rounded, [const Color(0xFF06B6D4), const Color(0xFF22D3EE)]);
    }
    return (Icons.directions_run_rounded, [const Color(0xFF0066FF), const Color(0xFF00C6FF)]);
  }

  (String, Color, IconData) _estiloStatus(String status) {
    switch (status.toLowerCase()) {
      case "concluido":
        return ("Concluído", const Color(0xFF10B981), Icons.check_circle_rounded);
      case "parcial":
        return ("Parcial", const Color(0xFF3B82F6), Icons.timelapse_rounded);
      case "nao_feito":
      case "faltou":
        return ("Faltou", const Color(0xFFEF4444), Icons.cancel_rounded);
      default:
        return ("Planejado", const Color(0xFFF59E0B), Icons.event_note_rounded);
    }
  }

  List<dynamic> get _treinosFiltrados {
    if (_filtroTreino == "todos") return _treinos;
    return _treinos.where((t) {
      final s = (t["status"]?.toString() ?? "planejado").toLowerCase();
      if (_filtroTreino == "faltou") {
        return s == "faltou" || s == "nao_feito";
      }
      return s == _filtroTreino;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardColor;
    final txtColor = theme.colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final nome = widget.usuario["nome"] ?? widget.usuario["nome_usuario"] ?? "Aluno";
    final email = widget.usuario["email"] ?? "";
    final tipo = (widget.usuario["tipo_usuario"]?.toString() ?? "atleta").toLowerCase();
    final isRoleAdmin = tipo == "admin";

    // Resolução de foto
    final rawFoto = widget.usuario["foto_url"] ?? widget.perfil["foto_url"];
    final fotoUrl = _AdminUsuariosPageState.resolverFotoUrl(rawFoto);

    // Iniciais para avatar fallback
    final nomes = nome.trim().split(" ");
    final iniciais = nomes.isNotEmpty
        ? (nomes.length > 1
            ? "${nomes.first[0]}${nomes.last[0]}".toUpperCase()
            : nomes.first.substring(0, nomes.first.length.clamp(1, 2)).toUpperCase())
        : "A";

    // Métricas de Destaque
    double volumeTotalKm = 0.0;
    for (var t in _treinos) {
      final d = double.tryParse(t["distancia_km"]?.toString() ?? "0") ?? 0.0;
      volumeTotalKm += d;
    }

    final paceRefSeg = widget.perfil["pace_referencia_segundos"];
    final paceRefFormatado = widget.formatarPace(paceRefSeg);
    final metaKm = widget.perfil["objetivo_semanal_km"];
    final metaKmStr = metaKm != null ? "${metaKm}k/sem" : "--";

    return Column(
      children: [
        // 🌟 HERO BANNER DO ATLETA
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF0066FF).withValues(alpha: 0.08), const Color(0xFF00C6FF).withValues(alpha: 0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Identificação do Atleta
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: (fotoUrl != null)
                        ? ClipOval(
                            child: Image.network(
                              fotoUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Text(
                                  iniciais,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              iniciais,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nome,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: txtColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF0066FF)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(fontSize: 12, color: subColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isRoleAdmin
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : const Color(0xFF0066FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isRoleAdmin ? "ADMIN" : "ATLETA",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isRoleAdmin ? const Color(0xFFF59E0B) : const Color(0xFF0066FF),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 12),

              // 4 Mini KPIs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeroKPI(Icons.bolt_rounded, "${_treinos.length}", "Treinos", const Color(0xFF0066FF), isDark, txtColor, subColor),
                  _buildHeroKPI(Icons.route_rounded, "${volumeTotalKm.toStringAsFixed(1)}k", "Volume", const Color(0xFF10B981), isDark, txtColor, subColor),
                  _buildHeroKPI(Icons.speed_rounded, paceRefFormatado, "Pace Ref", const Color(0xFF8B5CF6), isDark, txtColor, subColor),
                  _buildHeroKPI(Icons.flag_rounded, metaKmStr, "Meta Sem.", const Color(0xFFF59E0B), isDark, txtColor, subColor),
                ],
              ),
            ],
          ),
        ),

        // 🏷️ ABAS DE NAVEGAÇÃO SEGMENTADA
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF0066FF),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: subColor,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_run_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text("Treinos (${_treinos.length})"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.medical_services_rounded, size: 16),
                    const SizedBox(width: 6),
                    const Text("Ficha Médica"),
                    if (_ficha.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_rounded, size: 16),
                    SizedBox(width: 6),
                    Text("Perfil"),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // CONTEÚDO DAS ABAS
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAbaTreinos(isDark, cardBg, txtColor, subColor),
                    _buildAbaFicha(isDark, cardBg, txtColor, subColor),
                    _buildAbaPerfil(isDark, cardBg, txtColor, subColor),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHeroKPI(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
    Color txtColor,
    Color subColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: subColor,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🏃 ABA 1: TREINOS DO ALUNO
  // ==========================================
  Widget _buildAbaTreinos(bool isDark, Color cardBg, Color txtColor, Color subColor) {
    if (_treinos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_run_rounded, size: 48, color: Color(0xFF0066FF)),
              ),
              const SizedBox(height: 16),
              Text(
                "Nenhum treino registrado",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: txtColor),
              ),
              const SizedBox(height: 6),
              Text(
                "Este aluno ainda não concluiu nem salvou sessões de treino.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subColor),
              ),
            ],
          ),
        ),
      );
    }

    final concluidos = _treinos.where((t) => t["status"]?.toString().toLowerCase() == "concluido").length;
    final planejados = _treinos.where((t) => (t["status"]?.toString().toLowerCase() ?? "planejado") == "planejado").length;
    final faltas = _treinos.where((t) {
      final s = t["status"]?.toString().toLowerCase();
      return s == "faltou" || s == "nao_feito";
    }).length;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Barra de Filtros Rápidos
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFiltroChip("Todos (${_treinos.length})", "todos", isDark),
              _buildFiltroChip("Concluídos ($concluidos)", "concluido", isDark),
              _buildFiltroChip("Planejados ($planejados)", "planejado", isDark),
              if (faltas > 0) _buildFiltroChip("Faltas ($faltas)", "faltou", isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_treinosFiltrados.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "Nenhum treino nesta categoria.",
                style: TextStyle(color: subColor, fontSize: 13.5),
              ),
            ),
          )
        else
          ..._treinosFiltrados.map((treino) {
            final tipo = treino["tipo"]?.toString() ?? "Corrida";
            final distancia = double.tryParse(treino["distancia_km"]?.toString() ?? "0") ?? 0.0;
            final tempoSeg = int.tryParse(treino["tempo_segundos"]?.toString() ?? "0") ?? 0;
            final dataStr = AppDateUtils.formatarData(treino["data"]);
            final ritmoSeg = int.tryParse(treino["ritmo_medio_segundos"]?.toString() ?? "0") ?? 0;
            final status = treino["status"]?.toString() ?? "concluido";
            final sensacao = treino["sensacao"];
            final fcMedia = treino["fc_media"];
            final obs = treino["observacoes"]?.toString();

            final (iconeTipo, gradienteTipo) = _estiloTipoTreino(tipo);
            final (statusLabel, statusColor, statusIcon) = _estiloStatus(status);
            final (sensacaoTexto, sensacaoCor) = _detalheSensacao(sensacao);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F33) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do Card: Tipo + Data + Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradienteTipo),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: gradienteTipo.first.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(iconeTipo, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tipo.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: txtColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                dataStr,
                                style: TextStyle(fontSize: 11.5, color: subColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Grid de Métricas do Treino
                  Row(
                    children: [
                      Expanded(
                        child: _buildWorkoutMetricBox(
                          "Distância",
                          "${distancia.toStringAsFixed(2)} km",
                          Icons.straighten_rounded,
                          const Color(0xFF0066FF),
                          isDark,
                          txtColor,
                          subColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWorkoutMetricBox(
                          "Tempo",
                          widget.formatarTempo(tempoSeg),
                          Icons.timer_outlined,
                          const Color(0xFF10B981),
                          isDark,
                          txtColor,
                          subColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWorkoutMetricBox(
                          "Pace Médio",
                          widget.formatarPace(ritmoSeg),
                          Icons.speed_rounded,
                          const Color(0xFF8B5CF6),
                          isDark,
                          txtColor,
                          subColor,
                        ),
                      ),
                    ],
                  ),

                  // Faixa de Intensidade (RPE / Frequência Cardíaca)
                  if (sensacao != null || fcMedia != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (sensacao != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sensacaoCor.withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fitness_center_rounded, size: 12, color: sensacaoCor),
                                const SizedBox(width: 4),
                                Text(
                                  "Esforço: $sensacaoTexto",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sensacaoCor),
                                ),
                              ],
                            ),
                          ),
                        if (fcMedia != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_rounded, size: 12, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Text(
                                  "FC: $fcMedia bpm",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // Observações
                  if (obs != null && obs.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                              obs,
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String valor, bool isDark) {
    final selecionado = _filtroTreino == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _filtroTreino = valor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selecionado
                ? const Color(0xFF0066FF)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selecionado
                  ? const Color(0xFF0066FF)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
              color: selecionado ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutMetricBox(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color txtColor,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10.5, color: subColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🩺 ABA 2: FICHA MÉDICA & ANAMNESE
  // ==========================================
  Widget _buildAbaFicha(bool isDark, Color cardBg, Color txtColor, Color subColor) {
    if (_ficha.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_late_rounded, size: 48, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 16),
              Text(
                "Ficha médica ainda não preenchida",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: txtColor),
              ),
              const SizedBox(height: 6),
              Text(
                "O aluno ainda não enviou as respostas da ficha de anamnese clínica.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subColor),
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

    // IMC
    double? imcCalculado;
    final p = double.tryParse(peso);
    final a = double.tryParse(altura);
    if (p != null && a != null && a > 0) {
      final aMetros = a / 100;
      imcCalculado = p / (aMetros * aMetros);
    }
    final (imcLabel, imcColor) = _classificacaoIMC(imcCalculado);

    final temAsma = patologias.toLowerCase().contains("asma") ||
        patologias.toLowerCase().contains("bronq") ||
        patologias.toLowerCase().contains("respirat");

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Biometria do Atleta
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161F33) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.straighten_rounded, size: 16, color: Color(0xFF0066FF)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Biometria & Composição",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildBioTile("Peso", "$peso kg", Icons.fitness_center_rounded, const Color(0xFF0066FF), isDark, txtColor, subColor)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBioTile("Altura", "$altura cm", Icons.height_rounded, const Color(0xFF10B981), isDark, txtColor, subColor)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBioTile(
                      "IMC",
                      imcCalculado != null ? imcCalculado.toStringAsFixed(1) : "-",
                      Icons.monitor_weight_outlined,
                      imcColor,
                      isDark,
                      txtColor,
                      subColor,
                      badge: imcCalculado != null ? imcLabel : null,
                      badgeColor: imcColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBioTile("Sangue", tipoSanguineo, Icons.bloodtype_rounded, const Color(0xFFEF4444), isDark, txtColor, subColor)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Destaque Especial de Asma & Saúde Respiratória PaceMind
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: temAsma
                ? (isDark ? const Color(0xFF1F1E38) : const Color(0xFFF5F3FF))
                : (isDark ? const Color(0xFF161F33) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: temAsma
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (temAsma ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  temAsma ? Icons.air_rounded : Icons.healing_rounded,
                  color: temAsma ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Condições Clínicas / Respiratórias",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: txtColor,
                          ),
                        ),
                        if (temAsma) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "ASMA / DPOC",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      patologias,
                      style: TextStyle(fontSize: 13, color: txtColor, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Contato de Emergência
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contato de Emergência",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contatoEmergencia,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: txtColor,
                      ),
                    ),
                    Text(
                      telEmergencia,
                      style: TextStyle(fontSize: 12.5, color: subColor),
                    ),
                  ],
                ),
              ),
              if (telEmergencia != "-")
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFFEF4444)),
                  tooltip: "Copiar telefone",
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: telEmergencia));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Telefone copiado para a área de transferência")),
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Alergias & Medicamentos (2 colunas ou sequencial)
        _buildMedicalNoteCard(
          "Alergias Relatadas",
          alergias,
          Icons.warning_amber_rounded,
          const Color(0xFFF59E0B),
          isDark,
          txtColor,
          subColor,
        ),

        const SizedBox(height: 10),

        _buildMedicalNoteCard(
          "Medicamentos de Uso Contínuo",
          medicamentos,
          Icons.medication_rounded,
          const Color(0xFF10B981),
          isDark,
          txtColor,
          subColor,
        ),

        const SizedBox(height: 10),

        _buildMedicalNoteCard(
          "Observações Médicas Gerais",
          obs,
          Icons.sticky_note_2_rounded,
          const Color(0xFF0066FF),
          isDark,
          txtColor,
          subColor,
        ),
      ],
    );
  }

  Widget _buildBioTile(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color txtColor,
    Color subColor, {
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: subColor),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: badgeColor ?? color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalNoteCard(
    String title,
    String content,
    IconData icon,
    Color color,
    bool isDark,
    Color txtColor,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
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
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(fontSize: 13, color: txtColor, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 👤 ABA 3: PERFIL & METAS
  // ==========================================
  Widget _buildAbaPerfil(bool isDark, Color cardBg, Color txtColor, Color subColor) {
    final nome = widget.usuario["nome"] ?? widget.usuario["nome_usuario"] ?? "-";
    final email = widget.usuario["email"] ?? "-";
    final tipo = (widget.usuario["tipo_usuario"]?.toString() ?? "atleta").toUpperCase();
    final criadoEm = AppDateUtils.formatarData(widget.usuario["criado_em"]);

    final paceRefSeg = widget.perfil["pace_referencia_segundos"];
    final paceRefStr = widget.formatarPace(paceRefSeg);
    final metaKm = widget.perfil["objetivo_semanal_km"];

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Card Metas Esportivas
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161F33) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                      color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.speed_rounded, color: Color(0xFF0066FF), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Configuração de Performance",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pace de Referência", style: TextStyle(fontSize: 11, color: subColor)),
                          const SizedBox(height: 4),
                          Text(
                            paceRefStr,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0066FF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Calibra as zonas Z1 a Z5",
                            style: TextStyle(fontSize: 10, color: subColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Meta Semanal", style: TextStyle(fontSize: 11, color: subColor)),
                          const SizedBox(height: 4),
                          Text(
                            metaKm != null ? "$metaKm km" : "--",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Volume alvo semanal",
                            style: TextStyle(fontSize: 10, color: subColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Card Dados da Conta
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161F33) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_circle_rounded, color: Color(0xFF8B5CF6), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Informações da Conta",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: txtColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInfoRowWithIcon(Icons.badge_rounded, "Nome Completo", nome, isDark, txtColor, subColor),
              _buildInfoRowWithIcon(Icons.email_rounded, "Email de Acesso", email, isDark, txtColor, subColor),
              _buildInfoRowWithIcon(Icons.admin_panel_settings_rounded, "Tipo de Conta", tipo, isDark, txtColor, subColor),
              _buildInfoRowWithIcon(Icons.calendar_month_rounded, "Cadastrado em", criadoEm, isDark, txtColor, subColor),
              _buildInfoRowWithIcon(
                Icons.fingerprint_rounded,
                "ID do Aluno",
                widget.idUsuario,
                isDark,
                txtColor,
                subColor,
                canCopy: true,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: widget.idUsuario));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ID do aluno copiado!")),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithIcon(
    IconData icon,
    String label,
    String value,
    bool isDark,
    Color txtColor,
    Color subColor, {
    bool canCopy = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: subColor),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: subColor),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: txtColor,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onCopy,
                    child: Icon(Icons.copy_rounded, size: 14, color: const Color(0xFF0066FF)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
