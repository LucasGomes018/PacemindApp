import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';
import 'map_screen.dart';

class TreinosPage extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isEmbedded;
  final Function(int)? onNavigateTab;

  const TreinosPage({
    super.key,
    this.onBack,
    this.isEmbedded = false,
    this.onNavigateTab,
  });

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  List treinos = [];
  bool loading = true;
  String? erroCarregamento;

  String filtroSelecionado = "Todos";

  final List<String> filtros = [
    "Todos",
    "Corrida",
    "Caminhada",
    "Bike",
  ];

  @override
  void initState() {
    super.initState();
    // ⚡ INSTANTÂNEO: Se houver cache de treinos, renderiza imediatamente sem delay
    if (Api.treinosCache != null) {
      treinos = Api.treinosCache!;
      loading = false;
    }
    carregarTreinos();
  }

  Future<void> carregarTreinos({bool forcar = false}) async {
    if (treinos.isEmpty) {
      if (mounted) {
        setState(() {
          loading = true;
          erroCarregamento = null;
        });
      }
    }

    try {
      final data = await Api.listarTreinos(forcarAtualizacao: forcar);
      if (!mounted) return;

      setState(() {
        treinos = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        if (treinos.isEmpty) {
          erroCarregamento = "Não foi possível carregar seus treinos.";
        }
      });
    }
  }

  List get treinosFiltrados {
    if (filtroSelecionado == "Todos") {
      return treinos;
    }

    return treinos.where((treino) {
      final tipo = (treino["tipo"] ?? "").toString().toLowerCase();

      switch (filtroSelecionado) {
        case "Corrida":
          return tipo.contains("corrida") ||
              tipo.contains("run") ||
              tipo.contains("running");

        // case "Musculação":
        //   return tipo.contains("muscul") ||
        //       tipo.contains("academia") ||
        //       tipo.contains("força") ||
        //       tipo.contains("gym");

        case "Bike":
          return tipo.contains("bike") || tipo.contains("cicl");

        case "Caminhada":
          return tipo.contains("caminhada") || tipo.contains("walk");

        default:
          return true;
      }
    }).toList();
  }

  int _contagemPorFiltro(String f) {
    if (f == "Todos") return treinos.length;
    return treinos.where((t) {
      final tipo = (t["tipo"] ?? "").toString().toLowerCase();
      switch (f) {
        case "Corrida":
          return tipo.contains("corrida") || tipo.contains("run") || tipo.contains("running");
        // case "Musculação":
        //   return tipo.contains("muscul") || tipo.contains("academia") || tipo.contains("gym");
        case "Bike":
          return tipo.contains("bike") || tipo.contains("cicl");
        case "Caminhada":
          return tipo.contains("caminhada") || tipo.contains("walk");
        default:
          return false;
      }
    }).length;
  }

  String formatarTempo(dynamic segundos) {
    if (segundos == null) return "--";

    final total = int.tryParse(segundos.toString()) ?? 0;
    if (total <= 0) return "--";

    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;

    if (h > 0) {
      return "${h}h ${m.toString().padLeft(2, '0')}m";
    }

    if (m > 0) {
      return "${m}m ${s > 0 ? '${s.toString().padLeft(2, '0')}s' : ''}".trim();
    }

    return "${s}s";
  }

  String formatarPace(dynamic ritmoRaw) {
    if (ritmoRaw == null) return "--:--";

    // Usa double.tryParse para aceitar valores com decimais da API (ex: "320.5")
    final numVal = double.tryParse(ritmoRaw.toString())?.round() ?? 0;
    if (numVal <= 0) return "--:--";

    final min = numVal ~/ 60;
    final seg = numVal % 60;

    return "$min:${seg.toString().padLeft(2, '0')} min/km";
  }

  Future<void> _iniciarCorridaParaTreino(dynamic treino) async {
    final idTreino = (treino["id_treino"] ?? treino["id"])?.toString();
    final tipo = (treino["tipo"] ?? "Treino").toString();
    final distMeta = double.tryParse((treino["distancia_km"] ?? "0").toString()) ?? 0.0;
    final distAtual = double.tryParse((treino["distancia_atual_km"] ?? "0").toString()) ?? 0.0;
    final tempoAnterior = int.tryParse((treino["tempo_segundos"] ?? "0").toString()) ?? 0;

    if (idTreino == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("id_treino_ativo", idTreino);
    await prefs.setString("titulo_treino_ativo", "$tipo (${distMeta.toStringAsFixed(1)} km)");
    await prefs.setDouble("distancia_meta_treino_km", distMeta);
    await prefs.setDouble("distancia_atual_treino_km", distAtual);
    await prefs.setInt("tempo_treino_segundos", tempoAnterior);

    if (!mounted) return;

    final mensagem = distAtual > 0
        ? "Continuando \"$tipo\" (${distAtual.toStringAsFixed(2)} / ${distMeta.toStringAsFixed(1)} km)..."
        : "Treino \"$tipo\" vinculado! Abrindo o mapa de corrida...";

    AppSnackBar.treino(
      context,
      mensagem,
      titulo: distAtual > 0 ? "Retomando Treino 🏃" : "Treino Vinculado 🏃",
    );

    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapPage(
            treinoInicial: Map<String, dynamic>.from(treino is Map ? treino : {}),
          ),
        ),
      );
    }
  }

  Color corStatus(String status) {
    switch (status.toLowerCase()) {
      case "concluido":
        return const Color(0xFF10B981);
      case "em_andamento":
        return const Color(0xFFF59E0B);
      case "planejado":
        return const Color(0xFF0066FF);
      case "faltou":
      case "nao_feito":
        return const Color(0xFFEF4444);
      case "cancelado":
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF0066FF);
    }
  }

  String labelStatus(String status) {
    switch (status.toLowerCase()) {
      case "concluido":
        return "Concluído";
      case "em_andamento":
        return "Em andamento";
      case "planejado":
        return "Planejado";
      case "faltou":
      case "nao_feito":
        return "Não feito";
      case "cancelado":
        return "Cancelado";
      default:
        return status;
    }
  }

  IconData iconeStatus(String status) {
    switch (status.toLowerCase()) {
      case "concluido":
        return Icons.check_circle_rounded;
      case "em_andamento":
        return Icons.timelapse_rounded;
      case "planejado":
        return Icons.event_available_rounded;
      case "faltou":
      case "nao_feito":
        return Icons.cancel_rounded;
      case "cancelado":
        return Icons.block_rounded;
      default:
        return Icons.directions_run_rounded;
    }
  }

  IconData iconeTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains("corrida") || t.contains("run")) {
      return Icons.directions_run_rounded;
    }
    if (t.contains("bike") || t.contains("cicl")) {
      return Icons.directions_bike_rounded;
    }
    if (t.contains("caminhada") || t.contains("walk")) {
      return Icons.directions_walk_rounded;
    }
    if (t.contains("muscul") || t.contains("força") || t.contains("gym")) {
      return Icons.fitness_center_rounded;
    }
    return Icons.sports_score_rounded;
  }

  Color corTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains("corrida") || t.contains("run")) {
      return const Color(0xFF0066FF);
    }
    if (t.contains("bike") || t.contains("cicl")) {
      return const Color(0xFF10B981);
    }
    if (t.contains("caminhada") || t.contains("walk")) {
      return const Color(0xFF06B6D4);
    }
    if (t.contains("muscul") || t.contains("força")) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Se estiver carregando inicialmente
    if (loading && treinos.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: widget.isEmbedded ? null : _buildAppBar(colors, isDark),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF0066FF),
                strokeWidth: 3,
              ),
              SizedBox(height: 14),
              Text(
                "Carregando seus treinos...",
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // Se for embutido dentro da DashboardPage, NÃO renderiza AppBar duplicada!
      appBar: widget.isEmbedded ? null : _buildAppBar(colors, isDark),

      // FAB ajustado: se for embutido, fica 95dp acima da barra inferior!
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: widget.isEmbedded ? 92.0 : 16.0),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0066FF),
          elevation: 4,
          onPressed: mostrarCriarTreino,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          label: const Text(
            "Novo Treino",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        color: const Color(0xFF0066FF),
        onRefresh: carregarTreinos,
        child: Column(
          children: [
            // Resumo Superior e Botão de Ação Rápida
            _buildResumoTopo(isDark),

            // Filtros de Categoria
            _buildFiltrosBar(colors, isDark),

            const SizedBox(height: 4),

            // Lista de Treinos
            Expanded(
              child: erroCarregamento != null
                  ? _estadoErro()
                  : treinosFiltrados.isEmpty
                      ? _estadoVazio(isDark)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            widget.isEmbedded ? 170 : 100,
                          ),
                          itemCount: treinosFiltrados.length,
                          itemBuilder: (context, index) {
                            final treino = treinosFiltrados[index];
                            return _buildTreinoCard(treino, colors, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colors, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Meus Treinos",
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            "Histórico e rotinas",
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0066FF)),
          tooltip: "Criar Treino",
          onPressed: mostrarCriarTreino,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildResumoTopo(bool isDark) {
    final concluidos = treinos.where((t) => (t["status"] ?? "").toString().toLowerCase() == "concluido").toList();
    double totalKm = 0.0;
    int totalTempoSegs = 0;

    for (var t in concluidos) {
      totalKm += double.tryParse((t["distancia_km"] ?? t["km"] ?? "0").toString()) ?? 0.0;
      totalTempoSegs += int.tryParse((t["tempo_segundos"] ?? "0").toString()) ?? 0;
    }

    final mediaPace = totalKm > 0 ? (totalTempoSegs / totalKm) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F33) : const Color(0xFFEFF4F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _miniMetric(
            label: "Total Treinos",
            value: "${treinos.length}",
            icon: Icons.fitness_center_rounded,
            color: const Color(0xFF0066FF),
            isDark: isDark,
          ),
          Container(
            height: 28,
            width: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          ),
          _miniMetric(
            label: "Volume Total",
            value: "${totalKm.toStringAsFixed(1)} km",
            icon: Icons.directions_run_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          Container(
            height: 28,
            width: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          ),
          _miniMetric(
            label: "Pace Médio",
            value: mediaPace > 0 ? formatarPace(mediaPace) : "--:--",
            icon: Icons.speed_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _miniMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltrosBar(ColorScheme colors, bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtros.length,
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final selecionado = filtroSelecionado == filtro;
          final count = _contagemPorFiltro(filtro);

          return GestureDetector(
            onTap: () {
              setState(() {
                filtroSelecionado = filtro;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: selecionado
                    ? const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF1E70EB)],
                      )
                    : null,
                color: selecionado
                    ? null
                    : (isDark ? const Color(0xFF161F33) : colors.surface),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selecionado
                      ? Colors.transparent
                      : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                ),
                boxShadow: selecionado
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filtro,
                    style: TextStyle(
                      color: selecionado
                          ? Colors.white
                          : (isDark ? const Color(0xFFCBD5E1) : colors.onSurface),
                      fontWeight: selecionado ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selecionado
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$count",
                        style: TextStyle(
                          color: selecionado
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTreinoCard(dynamic treino, ColorScheme colors, bool isDark) {
    final tipo = (treino["tipo"] ?? "Treino").toString();
    final status = (treino["status"] ?? "concluido").toString().toLowerCase();
    final cor = corTipo(tipo);
    final statusColor = corStatus(status);
    final distMeta = double.tryParse((treino["distancia_km"] ?? treino["km"] ?? "0").toString()) ?? 0.0;
    final distAtual = double.tryParse((treino["distancia_atual_km"] ?? "0").toString()) ?? 0.0;
    final tempoFormatado = formatarTempo(treino["tempo_segundos"]);
    final paceFormatado = formatarPace(treino["ritmo_medio_segundos"]);
    final fcMedia = treino["fc_media"];
    final sensacao = treino["sensacao"];
    final observacoes = treino["observacoes"];

    final isPlanejadoOuAndamento = status == "planejado" || status == "em_andamento";
    final progresso = distMeta > 0 ? (distAtual / distMeta).clamp(0.0, 1.0) : 0.0;
    final pctProgresso = (progresso * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPlanejadoOuAndamento
              ? (status == "em_andamento"
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                  : const Color(0xFF0066FF).withValues(alpha: 0.25))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.04)),
          width: isPlanejadoOuAndamento ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPlanejadoOuAndamento
                ? (status == "em_andamento"
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                    : const Color(0xFF0066FF).withValues(alpha: 0.1))
                : (isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF0066FF).withValues(alpha: 0.05)),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _mostrarDetalhesTreino(treino),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha Superior: Ícone da Modalidade + Título/Data + Badge de Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cor, cor.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: cor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(iconeTipo(tipo), color: Colors.white, size: 22),
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
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colors.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  AppDateUtils.formatarData(treino["data"]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconeStatus(status), color: statusColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            labelStatus(status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (isPlanejadoOuAndamento) ...[
                  // 🏃 PAINEL DE PROGRESSO AUTOMÁTICO (TREINO PLANEJADO / EM ANDAMENTO)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF1F6FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: status == "em_andamento"
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                            : const Color(0xFF0066FF).withValues(alpha: 0.15),
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
                                Icon(
                                  Icons.flag_rounded,
                                  size: 15,
                                  color: status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Meta: ${distMeta > 0 ? "${distMeta.toStringAsFixed(1)} km" : "Distância livre"}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${distAtual.toStringAsFixed(2)} km  •  $pctProgresso%",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Barra de Progresso do Treino
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progresso,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Botão Iniciar Corrida
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => _iniciarCorridaParaTreino(treino),
                            icon: Icon(
                              status == "em_andamento" ? Icons.play_arrow_rounded : Icons.directions_run_rounded,
                              size: 20,
                            ),
                            label: Text(
                              status == "em_andamento" ? "Continuar Corrida com GPS" : "Iniciar Corrida com GPS",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: status == "em_andamento"
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Painel de Métricas Concluídas (Distância, Tempo, Pace)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        _metricBox(
                          context: context,
                          label: "Distância",
                          value: "${distAtual > 0 ? distAtual.toStringAsFixed(2) : distMeta.toStringAsFixed(1)} km",
                          valueColor: const Color(0xFF0066FF),
                          isDark: isDark,
                        ),
                        Container(
                          height: 28,
                          width: 1,
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                        ),
                        _metricBox(
                          context: context,
                          label: "Tempo",
                          value: tempoFormatado,
                          valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          isDark: isDark,
                        ),
                        Container(
                          height: 28,
                          width: 1,
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                        ),
                        _metricBox(
                          context: context,
                          label: "Pace",
                          value: paceFormatado,
                          valueColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],

                // Tags de FC e RPE (se disponíveis)
                if (fcMedia != null || sensacao != null || (observacoes != null && observacoes.toString().trim().isNotEmpty)) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (fcMedia != null)
                        _badgeInfo(
                          icon: Icons.favorite_rounded,
                          label: "$fcMedia bpm",
                          color: const Color(0xFFEF4444),
                          isDark: isDark,
                        ),
                      if (sensacao != null)
                        _badgeInfo(
                          icon: Icons.local_fire_department_rounded,
                          label: "RPE $sensacao/10",
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                        ),
                      if (observacoes != null && observacoes.toString().trim().isNotEmpty)
                        Flexible(
                          child: Text(
                            "📝 ${observacoes.toString().trim()}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricBox({
    required BuildContext context,
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeInfo({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoVazio(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                size: 48,
                color: Color(0xFF0066FF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Nenhum treino encontrado",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filtroSelecionado == "Todos"
                  ? "Você ainda não possui treinos cadastrados. Clique no botão abaixo para adicionar."
                  : "Nenhum treino na categoria '$filtroSelecionado'.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: mostrarCriarTreino,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Registrar Treino"),
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

  Widget _estadoErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(erroCarregamento!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  loading = true;
                  erroCarregamento = null;
                });
                carregarTreinos();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhesTreino(dynamic treino) {
    final idTreino = treino["id_treino"] ?? treino["id"];
    final tipo = (treino["tipo"] ?? "Treino").toString();
    final dataFormatada = AppDateUtils.formatarData(treino["data"]);
    final distMeta = double.tryParse((treino["distancia_km"] ?? "0").toString()) ?? 0.0;
    final distAtual = double.tryParse((treino["distancia_atual_km"] ?? "0").toString()) ?? 0.0;
    final tempo = formatarTempo(treino["tempo_segundos"]);
    final pace = formatarPace(treino["ritmo_medio_segundos"]);
    final fcMed = treino["fc_media"];
    final fcMax = treino["fc_max"];
    final sensacao = treino["sensacao"];
    final obs = treino["observacoes"];
    final status = (treino["status"] ?? "concluido").toString().toLowerCase();

    final isPlanejadoOuAndamento = status == "planejado" || status == "em_andamento";
    final progresso = distMeta > 0 ? (distAtual / distMeta).clamp(0.0, 1.0) : 0.0;
    final pctProgresso = (progresso * 100).toInt();

    AppModal.showBottomSheet(
      context: context,
      title: tipo,
      subtitle: "$dataFormatada • ${labelStatus(status)}",
      icon: iconeTipo(tipo),
      iconColor: corTipo(tipo),
      maxChildSize: 0.85,
      initialChildSize: 0.65,
      builder: (modalContext, scrollController) {
        final isDark = Theme.of(modalContext).brightness == Brightness.dark;
        final onSurface = Theme.of(modalContext).colorScheme.onSurface;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            if (isPlanejadoOuAndamento) ...[
              // Card de Progresso Planejado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F6FD),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: status == "em_andamento"
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                        : const Color(0xFF0066FF).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Meta do Treino",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "$pctProgresso% concluído",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                              color: status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "${distAtual.toStringAsFixed(2)} km",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "de ${distMeta > 0 ? "${distMeta.toStringAsFixed(1)} km" : "livre"}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progresso,
                        minHeight: 10,
                        backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Botão Iniciar Corrida dentro do modal
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(modalContext);
                    _iniciarCorridaParaTreino(treino);
                  },
                  icon: Icon(
                    status == "em_andamento" ? Icons.play_arrow_rounded : Icons.directions_run_rounded,
                    size: 22,
                  ),
                  label: Text(
                    status == "em_andamento" ? "Continuar Corrida com GPS" : "Iniciar Corrida com GPS",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == "em_andamento"
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Bloco de Métricas Principais (Concluído)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricDetail(
                          "Distância",
                          "${distAtual > 0 ? distAtual.toStringAsFixed(2) : distMeta.toStringAsFixed(2)} km",
                          const Color(0xFF0066FF),
                        ),
                        _metricDetail("Duração", tempo, onSurface),
                        _metricDetail("Pace Médio", pace, onSurface),
                      ],
                    ),
                    if (fcMed != null || fcMax != null || sensacao != null) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (fcMed != null)
                            _metricDetail("FC Média", "$fcMed bpm", const Color(0xFFEF4444)),
                          if (fcMax != null)
                            _metricDetail("FC Máx", "$fcMax bpm", const Color(0xFFDC2626)),
                          if (sensacao != null)
                            _metricDetail("Esforço (RPE)", "$sensacao/10", const Color(0xFFF59E0B)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (obs != null && obs.toString().trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "Observações",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161F33) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  obs.toString().trim(),
                  style: TextStyle(fontSize: 13.5, color: onSurface, height: 1.4),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botão Excluir Treino
            if (idTreino != null)
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmar = await AppModal.showConfirmDialog(
                    context: context,
                    title: "Excluir Treino",
                    message: "Deseja realmente remover este treino? Esta ação não pode ser desfeita.",
                    confirmText: "Excluir",
                    cancelText: "Cancelar",
                    isDestructive: true,
                    icon: Icons.delete_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                  );

                  if (confirmar == true) {
                    try {
                      await Api.deletarTreino(idTreino);
                      if (!modalContext.mounted) return;
                      Navigator.pop(modalContext);
                      carregarTreinos();
                    } catch (e) {
                      if (!modalContext.mounted) return;
                      AppSnackBar.erro(
                        modalContext,
                        "Erro ao excluir treino: $e",
                        titulo: "Falha na Exclusão",
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                label: const Text(
                  "Excluir este treino",
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _metricDetail(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: valColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  void mostrarCriarTreino() {
    final tipoController = TextEditingController(text: "Corrida Leve");
    final distanciaController = TextEditingController(text: "5.0");
    final observacoesController = TextEditingController();
    DateTime dataTreino = DateTime.now();
    bool salvando = false;

    final tiposSugeridos = [
      "Corrida Leve",
      "Longão",
      "Intervalado / Tiros",
      "Regenerativo",
      "Fartlek",
      "Tempo Run",
    ];

    final distanciasSugeridas = [3.0, 5.0, 8.0, 10.0, 15.0, 21.1];

    AppModal.showBottomSheet(
      context: context,
      title: "Planejar Novo Treino",
      subtitle: "Defina sua meta e corra com GPS quando quiser",
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFF0066FF),
      maxChildSize: 0.92,
      initialChildSize: 0.85,
      builder: (modalContext, scrollController) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDarkModal = Theme.of(context).brightness == Brightness.dark;
            final txtColorModal = Theme.of(context).colorScheme.onSurface;
            final subColorModal = isDarkModal ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // 1. Data do Treino
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataTreino,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() {
                        dataTreino = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          DateTime.now().hour,
                          DateTime.now().minute,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkModal ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF0066FF)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Data Planejada", style: TextStyle(fontSize: 11, color: subColorModal)),
                              Text(
                                AppDateUtils.formatarData(dataTreino),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txtColorModal),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, color: subColorModal),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Tipo de Treino
                Text(
                  "Tipo de Treino",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: txtColorModal,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tiposSugeridos.map((t) {
                    final sel = tipoController.text == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: sel,
                      onSelected: (_) {
                        setModalState(() {
                          tipoController.text = t;
                        });
                      },
                      selectedColor: const Color(0xFF0066FF).withValues(alpha: 0.18),
                      side: BorderSide(
                        color: sel ? const Color(0xFF0066FF) : (isDarkModal ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      labelStyle: TextStyle(
                        color: sel ? const Color(0xFF0066FF) : subColorModal,
                        fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tipoController,
                  decoration: const InputDecoration(
                    labelText: "Nome do treino",
                    hintText: "Ex: Corrida Leve, Longão...",
                    prefixIcon: Icon(Icons.directions_run_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Meta de Distância
                Text(
                  "Meta de Distância",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: txtColorModal,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: distanciasSugeridas.map((d) {
                    final sel = distanciaController.text == d.toString() ||
                        distanciaController.text == d.toStringAsFixed(1);
                    return ActionChip(
                      label: Text("${d.toStringAsFixed(d % 1 == 0 ? 0 : 1)} km"),
                      backgroundColor: sel ? const Color(0xFF0066FF).withValues(alpha: 0.15) : null,
                      side: BorderSide(
                        color: sel ? const Color(0xFF0066FF) : (isDarkModal ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      labelStyle: TextStyle(
                        color: sel ? const Color(0xFF0066FF) : subColorModal,
                        fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onPressed: () {
                        setModalState(() {
                          distanciaController.text = d.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: distanciaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Distância Alvo (km)",
                    hintText: "Ex: 5.0",
                    suffixText: "km",
                    prefixIcon: Icon(Icons.route_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Observações / Instruções
                TextField(
                  controller: observacoesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Instruções do treino (opcional)",
                    hintText: "Ex: Pace confortável abaixo de 5:30/km, terreno plano...",
                    prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Botão Salvar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: salvando
                        ? null
                        : () async {
                            final dist = double.tryParse(
                                  distanciaController.text.replaceAll(',', '.'),
                                ) ??
                                0.0;

                            if (dist <= 0) {
                              AppSnackBar.aviso(
                                context,
                                "Informe uma distância válida maior que zero.",
                                titulo: "Distância Inválida",
                              );
                              return;
                            }

                            setModalState(() => salvando = true);

                            try {
                              await Api.criarTreinoCompleto(
                                tipo: tipoController.text.trim().isEmpty
                                    ? "Corrida"
                                    : tipoController.text.trim(),
                                distanciaKm: dist,
                                distanciaAtualKm: 0.0,
                                tempoSegundos: 0,
                                data: AppDateUtils.paraDataPura(dataTreino),
                                observacoes: observacoesController.text.trim().isEmpty
                                    ? null
                                    : observacoesController.text.trim(),
                                status: "planejado",
                              );

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              carregarTreinos();
                              AppSnackBar.sucesso(
                                context,
                                "Treino planejado com sucesso! Ele já pode ser vinculado à corrida.",
                                titulo: "Treino Planejado 🎯",
                              );
                            } catch (e) {
                              setModalState(() => salvando = false);
                              if (!context.mounted) return;
                              AppSnackBar.erro(
                                context,
                                "Erro ao criar treino: $e",
                                titulo: "Falha ao Criar",
                              );
                            }
                          },
                    icon: salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_task_rounded),
                    label: Text(
                      salvando ? "Salvando..." : "Criar Treino Planejado",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
}
