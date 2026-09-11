import 'package:flutter/material.dart';
import '../core/api.dart';
import '../components/app_modal.dart';

class MetasPage extends StatefulWidget {
  final bool abrirCriarMetaAoIniciar;

  const MetasPage({super.key, this.abrirCriarMetaAoIniciar = false});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  List<dynamic> metas = [];
  bool loading = true;
  String? erroCarregamento;
  int filtroSelecionado = 0; // 0: Todas, 1: Em Andamento, 2: Concluídas

  @override
  void initState() {
    super.initState();
    carregarMetas();
    if (widget.abrirCriarMetaAoIniciar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        criarMeta();
      });
    }
  }

  Future<void> carregarMetas() async {
    try {
      final data = await Api.listarMetas();

      // Sincroniza metas de km com a quilometragem real dos treinos
      try {
        final dash = await Api.getDashboard();
        final kmSemana = double.tryParse(dash["resumo"]?["total_km"]?.toString() ?? "0") ?? 0.0;
        if (kmSemana > 0) {
          for (var m in data) {
            if (m["tipo"]?.toString().toLowerCase() == "km") {
              final progressoAtual = double.tryParse(m["progresso"]?.toString() ?? "0") ?? 0.0;
              if (kmSemana > progressoAtual) {
                m["progresso"] = kmSemana;
                final id = (m["id_meta"] ?? m["id"] ?? m["_id"]).toString();
                Api.atualizarProgressoMeta(id: id, progresso: kmSemana)
                    .catchError((_) => <String, dynamic>{});
              }
            }
          }
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        metas = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar suas metas.";
      });
    }
  }

  double calcularPorcentagem(dynamic meta) {
    final objetivo = double.tryParse(meta["objetivo"]?.toString() ?? "0") ?? 0;
    final progresso = double.tryParse(meta["progresso"]?.toString() ?? "0") ?? 0;

    if (objetivo <= 0) return 0;
    return (progresso / objetivo).clamp(0.0, 1.0);
  }

  String _formatarValor(dynamic valor, String tipo) {
    final v = double.tryParse(valor?.toString() ?? "0") ?? 0;
    final formatado = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
    switch (tipo.toLowerCase()) {
      case "km":
        return "$formatado km";
      case "tempo":
        return "$formatado min";
      case "treinos":
        return "$formatado treinos";
      default:
        return "$formatado $tipo";
    }
  }

  Color _corTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case "km":
        return const Color(0xFF0066FF);
      case "tempo":
        return const Color(0xFFF59E0B);
      case "treinos":
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _iconeTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case "km":
        return Icons.directions_run_rounded;
      case "tempo":
        return Icons.timer_outlined;
      case "treinos":
        return Icons.fitness_center_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Future<void> _atualizarProgresso(dynamic meta, double novoProgresso) async {
    try {
      final id = (meta["id_meta"] ?? meta["id"] ?? meta["_id"]).toString();
      await Api.atualizarProgressoMeta(id: id, progresso: novoProgresso);
      if (!mounted) return;
      carregarMetas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao atualizar progresso da meta")),
      );
    }
  }

  Future<void> _concluirMeta(dynamic meta) async {
    try {
      final id = (meta["id_meta"] ?? meta["id"] ?? meta["_id"]).toString();
      await Api.concluirMeta(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 Parabéns! Meta concluída com sucesso!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      carregarMetas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao concluir meta")),
      );
    }
  }

  Future<void> _deletarMeta(dynamic meta) async {
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Excluir Meta?",
      message: "Tem certeza de que deseja remover a meta \"${meta["titulo"]}\"?",
      confirmText: "Excluir",
      cancelText: "Cancelar",
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.redAccent,
      confirmButtonColor: Colors.redAccent,
      isDestructive: true,
    );

    if (confirmar == true) {
      try {
        final id = (meta["id_meta"] ?? meta["id"] ?? meta["_id"]).toString();
        await Api.deletarMeta(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meta removida com sucesso")),
        );
        carregarMetas();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao remover meta")),
        );
      }
    }
  }

  void _abrirModalProgresso(dynamic meta) {
    final progressoAtual = double.tryParse(meta["progresso"]?.toString() ?? "0") ?? 0;
    final controller = TextEditingController(
      text: progressoAtual % 1 == 0
          ? progressoAtual.toInt().toString()
          : progressoAtual.toString(),
    );

    AppModal.showBottomSheet(
      context: context,
      title: "Ajustar Progresso",
      subtitle: "Meta: ${meta["titulo"]}",
      icon: Icons.edit_road_rounded,
      iconColor: const Color(0xFF0066FF),
      maxChildSize: 0.65,
      initialChildSize: 0.55,
      builder: (ctx, scrollController) {
        final theme = Theme.of(ctx);
        final colors = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text(
              "Atualize o quanto já conquistou para \"${meta["titulo"]}\":",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(color: colors.onSurface, fontSize: 18),
              decoration: InputDecoration(
                labelText: "Progresso atual (${meta["tipo"]})",
                labelStyle: TextStyle(color: colors.primary),
                prefixIcon: Icon(Icons.edit_road_rounded, color: colors.primary),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final valor = double.tryParse(controller.text.replaceAll(',', '.'));
                  if (valor != null && valor >= 0) {
                    Navigator.pop(ctx);
                    _atualizarProgresso(meta, valor);
                  }
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text("Salvar Progresso", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> criarMeta() async {
    final tituloController = TextEditingController();
    final objetivoController = TextEditingController();
    String tipoSelecionado = "km";

    await AppModal.showBottomSheet(
      context: context,
      title: "Nova Meta",
      subtitle: "Defina seu objetivo esportivo",
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFF0066FF),
      maxChildSize: 0.92,
      initialChildSize: 0.82,
      builder: (sheetCtx, scrollController) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final colors = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;
            final fillBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              children: [
                // TÍTULO
                TextField(
                  controller: tituloController,
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: "Ex: Correr 100km esse mês",
                    labelText: "Título da meta",
                    hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
                    labelStyle: TextStyle(color: colors.primary),
                    prefixIcon: Icon(Icons.edit_note_rounded, color: colors.primary),
                    filled: true,
                    fillColor: fillBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // TIPO
                DropdownButtonFormField<String>(
                  initialValue: tipoSelecionado,
                  dropdownColor: colors.surface,
                  style: TextStyle(color: colors.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: "Tipo da meta",
                    labelStyle: TextStyle(color: colors.primary),
                    prefixIcon: Icon(Icons.category_rounded, color: colors.primary),
                    filled: true,
                    fillColor: fillBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "km",
                      child: Text("Quilometragem (km)"),
                    ),
                    DropdownMenuItem(
                      value: "tempo",
                      child: Text("Tempo em minutos"),
                    ),
                    DropdownMenuItem(
                      value: "treinos",
                      child: Text("Quantidade de treinos"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() {
                        tipoSelecionado = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // OBJETIVO NUMÉRICO
                TextField(
                  controller: objetivoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: tipoSelecionado == "km"
                        ? "Ex: 50"
                        : tipoSelecionado == "tempo"
                            ? "Ex: 300"
                            : "Ex: 12",
                    labelText: "Objetivo numérico ($tipoSelecionado)",
                    hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
                    labelStyle: TextStyle(color: colors.primary),
                    prefixIcon: Icon(Icons.track_changes_rounded, color: colors.primary),
                    filled: true,
                    fillColor: fillBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // BOTÃO CRIAR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final objetivo = double.tryParse(
                        objetivoController.text.replaceAll(',', '.'),
                      );
                      if (tituloController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Informe um título para sua meta."),
                          ),
                        );
                        return;
                      }
                      if (objetivo == null || objetivo <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Informe um objetivo maior que zero."),
                          ),
                        );
                        return;
                      }

                      try {
                        await Api.criarMeta(
                          titulo: tituloController.text.trim(),
                          objetivo: objetivo,
                          tipo: tipoSelecionado,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        carregarMetas();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("🎯 Meta criada com sucesso!"),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Erro ao criar meta")),
                        );
                      }
                    },
                    icon: const Icon(Icons.flag_rounded),
                    label: const Text(
                      "Criar Meta",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
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

  List<dynamic> get metasFiltradas {
    if (filtroSelecionado == 1) {
      return metas.where((m) => m["concluida"] != true).toList();
    } else if (filtroSelecionado == 2) {
      return metas.where((m) => m["concluida"] == true).toList();
    }
    return metas;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final totalMetas = metas.length;
    final concluidas = metas.where((m) => m["concluida"] == true).length;
    final emAndamento = totalMetas - concluidas;

    double somaPorcentagens = 0;
    for (var m in metas) {
      somaPorcentagens += calcularPorcentagem(m);
    }
    final mediaProgresso = totalMetas > 0 ? (somaPorcentagens / totalMetas) * 100 : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Metas",
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Acompanhe seus objetivos e evolução",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Atualizar",
            icon: Icon(Icons.refresh_rounded, color: colors.onSurface),
            onPressed: carregarMetas,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: criarMeta,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Nova Meta", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : erroCarregamento != null
              ? _estadoErro(carregarMetas)
              : RefreshIndicator(
                  onRefresh: carregarMetas,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Header de estatísticas
                      _buildHeaderEstatisticas(
                        total: totalMetas,
                        concluidas: concluidas,
                        emAndamento: emAndamento,
                        mediaProgresso: mediaProgresso,
                        colors: colors,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),

                      // Filtros (Todas, Em Andamento, Concluídas)
                      _buildFiltros(colors, isDark),
                      const SizedBox(height: 18),

                      // Lista de Metas ou Estado Vazio
                      if (metasFiltradas.isEmpty)
                        _buildEstadoVazio(colors, isDark)
                      else
                        ...metasFiltradas.map(
                          (meta) => _buildCardMeta(meta, colors, isDark),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderEstatisticas({
    required int total,
    required int concluidas,
    required int emAndamento,
    required double mediaProgresso,
    required ColorScheme colors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.insights_rounded, color: Color(0xFF0066FF), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Desempenho Geral",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${mediaProgresso.toStringAsFixed(0)}% médio",
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStatItem("Total", total.toString(), Icons.flag_rounded, const Color(0xFF0066FF), colors),
              _buildDivisorVertical(isDark),
              _buildStatItem("Em Aberto", emAndamento.toString(), Icons.timelapse_rounded, const Color(0xFFF59E0B), colors),
              _buildDivisorVertical(isDark),
              _buildStatItem("Concluídas", concluidas.toString(), Icons.check_circle_rounded, const Color(0xFF10B981), colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String valor, IconData icone, Color cor, ColorScheme colors) {
    return Expanded(
      child: Column(
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivisorVertical(bool isDark) {
    return Container(
      width: 1,
      height: 38,
      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildFiltros(ColorScheme colors, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chipFiltro("Todas (${metas.length})", 0, colors, isDark),
          const SizedBox(width: 8),
          _chipFiltro("Em Andamento", 1, colors, isDark),
          const SizedBox(width: 8),
          _chipFiltro("Concluídas", 2, colors, isDark),
        ],
      ),
    );
  }

  Widget _chipFiltro(String texto, int index, ColorScheme colors, bool isDark) {
    final selecionado = filtroSelecionado == index;
    return ChoiceChip(
      label: Text(
        texto,
        style: TextStyle(
          color: selecionado
              ? Colors.white
              : colors.onSurface,
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: selecionado,
      selectedColor: const Color(0xFF0066FF),
      backgroundColor: isDark ? colors.surface : Colors.white,
      side: BorderSide(
        color: selecionado
            ? Colors.transparent
            : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() {
          filtroSelecionado = index;
        });
      },
    );
  }

  Widget _buildCardMeta(dynamic meta, ColorScheme colors, bool isDark) {
    final tipo = meta["tipo"]?.toString() ?? "km";
    final cor = _corTipo(tipo);
    final icone = _iconeTipo(tipo);
    final porcentagem = calcularPorcentagem(meta);
    final bool concluida = meta["concluida"] == true || porcentagem >= 1.0;
    final progresso = double.tryParse(meta["progresso"]?.toString() ?? "0") ?? 0;
    final objetivo = double.tryParse(meta["objetivo"]?.toString() ?? "0") ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: concluida
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
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
          // Topo: Ícone do Tipo, Título e Menu de Ações
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icone, color: cor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meta["titulo"] ?? "Meta",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tipo.toUpperCase(),
                        style: TextStyle(
                          color: cor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: colors.surface,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: "progresso",
                    child: Row(
                      children: [
                        Icon(Icons.edit_road_rounded, size: 18),
                        SizedBox(width: 8),
                        Text("Ajustar Progresso"),
                      ],
                    ),
                  ),
                  if (!concluida)
                    const PopupMenuItem(
                      value: "concluir",
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text("Marcar como Concluída"),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: "deletar",
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text("Excluir Meta", style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == "progresso") {
                    _abrirModalProgresso(meta);
                  } else if (value == "concluir") {
                    _concluirMeta(meta);
                  } else if (value == "deletar") {
                    _deletarMeta(meta);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Informações de Progresso e Objetivo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Progresso Atual",
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatarValor(progresso, tipo),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Objetivo",
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatarValor(objetivo, tipo),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra Animada de Progresso
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: porcentagem),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, valorAnimado, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LinearProgressIndicator(
                  value: valorAnimado,
                  minHeight: 10,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    concluida ? const Color(0xFF10B981) : cor,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Rodapé do Card: Percentual e Ações Rápidas
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: concluida
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      concluida ? Icons.check_circle_rounded : Icons.trending_up_rounded,
                      size: 14,
                      color: concluida ? const Color(0xFF10B981) : colors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      concluida
                          ? "Concluída 🎉"
                          : "${(porcentagem * 100).toStringAsFixed(0)}% concluído",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: concluida ? const Color(0xFF10B981) : colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!concluida)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão de incremento rápido (+1)
                    OutlinedButton(
                      onPressed: () {
                        _atualizarProgresso(meta, progresso + 1);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "+1 $tipo",
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: "Ajustar progresso",
                      style: IconButton.styleFrom(
                        backgroundColor: cor.withValues(alpha: 0.12),
                        foregroundColor: cor,
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      onPressed: () => _abrirModalProgresso(meta),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVazio(ColorScheme colors, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              filtroSelecionado == 0
                  ? "Nenhuma meta criada"
                  : filtroSelecionado == 1
                      ? "Nenhuma meta em andamento"
                      : "Nenhuma meta concluída ainda",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Defina objetivos semanais ou mensais para manter a motivação e medir sua evolução.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: criarMeta,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Criar Minha Primeira Meta"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoErro(Future<void> Function() tentarNovamente) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.redAccent),
            const SizedBox(height: 14),
            Text(
              erroCarregamento!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  loading = true;
                  erroCarregamento = null;
                });
                tentarNovamente();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }
}
