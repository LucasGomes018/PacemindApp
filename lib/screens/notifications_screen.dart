import 'package:flutter/material.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> notificacoes = [];
  bool loading = true;
  String? erroCarregamento;

  String filtroSelecionado = "Todas";
  final List<String> filtros = [
    "Todas",
    "Não lidas",
    "Eventos",
    "Treinos",
    "Metas",
    "Alertas",
    "Sistema",
  ];

  @override
  void initState() {
    super.initState();
    carregarNotificacoes();
  }

  Future<void> carregarNotificacoes() async {
    try {
      final data = await Api.listarNotificacoes();
      if (!mounted) return;

      setState(() {
        notificacoes = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar as notificações.";
      });
    }
  }

  bool _isTipo(dynamic n, List<String> palavrasChave) {
    final tipo = (n["tipo"] ?? "").toString().toLowerCase();
    final titulo = (n["titulo"] ?? "").toString().toLowerCase();
    for (final palavra in palavrasChave) {
      if (tipo.contains(palavra) || titulo.contains(palavra)) {
        return true;
      }
    }
    return false;
  }

  int _contarPorFiltro(String filtro) {
    if (filtro == "Todas") return notificacoes.length;
    if (filtro == "Não lidas") {
      return notificacoes.where((n) => n["lida"] != true).length;
    }
    if (filtro == "Eventos") {
      return notificacoes
          .where((n) => _isTipo(n, ["evento"]))
          .length;
    }
    if (filtro == "Treinos") {
      return notificacoes
          .where((n) => _isTipo(n, ["treino", "corrida", "caminhada", "bike", "pace", "km"]))
          .length;
    }
    if (filtro == "Metas") {
      return notificacoes
          .where((n) => _isTipo(n, ["meta", "conquista", "recorde", "trofeu"]))
          .length;
    }
    if (filtro == "Alertas") {
      return notificacoes
          .where((n) => _isTipo(n, ["alerta", "aviso", "atencao", "overtraining", "fadiga", "lesao"]))
          .length;
    }
    if (filtro == "Sistema") {
      return notificacoes
          .where((n) => _isTipo(n, ["sistema", "dica", "ia", "pacemind", "wellness", "saude"]))
          .length;
    }
    return 0;
  }

  List<dynamic> get notificacoesFiltradas {
    if (filtroSelecionado == "Todas") return notificacoes;
    if (filtroSelecionado == "Não lidas") {
      return notificacoes.where((n) => n["lida"] != true).toList();
    }
    if (filtroSelecionado == "Eventos") {
      return notificacoes
          .where((n) => _isTipo(n, ["evento"]))
          .toList();
    }
    if (filtroSelecionado == "Treinos") {
      return notificacoes
          .where((n) => _isTipo(n, ["treino", "corrida", "caminhada", "bike", "pace", "km"]))
          .toList();
    }
    if (filtroSelecionado == "Metas") {
      return notificacoes
          .where((n) => _isTipo(n, ["meta", "conquista", "recorde", "trofeu"]))
          .toList();
    }
    if (filtroSelecionado == "Alertas") {
      return notificacoes
          .where((n) => _isTipo(n, ["alerta", "aviso", "atencao", "overtraining", "fadiga", "lesao"]))
          .toList();
    }
    if (filtroSelecionado == "Sistema") {
      return notificacoes
          .where((n) => _isTipo(n, ["sistema", "dica", "ia", "pacemind", "wellness", "saude"]))
          .toList();
    }
    return notificacoes;
  }

  int get qtdNaoLidas => notificacoes.where((n) => n["lida"] != true).length;

  Future<void> alternarLida(dynamic id, bool statusAtual) async {
    final novoStatus = !statusAtual;
    setState(() {
      final index = notificacoes.indexWhere((n) => (n["id_notificacao"] ?? n["id"]) == id);
      if (index != -1) {
        notificacoes[index]["lida"] = novoStatus;
      }
    });

    try {
      await Api.marcarNotificacaoLida(id, lida: novoStatus);
    } catch (_) {
      // Reverte se falhar
      if (mounted) {
        setState(() {
          final index = notificacoes.indexWhere((n) => (n["id_notificacao"] ?? n["id"]) == id);
          if (index != -1) {
            notificacoes[index]["lida"] = statusAtual;
          }
        });
      }
    }
  }

  Future<void> marcarTodasComoLidas() async {
    if (qtdNaoLidas == 0) return;

    final backup = notificacoes.map((n) => Map<String, dynamic>.from(n)).toList();

    setState(() {
      for (var n in notificacoes) {
        n["lida"] = true;
      }
    });

    try {
      await Api.marcarTodasNotificacoesLidas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text("Todas as notificações foram lidas"),
              ],
            ),
            backgroundColor: const Color(0xFF0066FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          notificacoes = backup;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar: $e"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  Future<void> deletarNotificacao(dynamic id, {bool mostrarUndo = true}) async {
    final index = notificacoes.indexWhere((n) => (n["id_notificacao"] ?? n["id"]) == id);
    if (index == -1) return;

    final itemRemovido = notificacoes[index];

    setState(() {
      notificacoes.removeAt(index);
    });

    if (mostrarUndo && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Notificação excluída"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          action: SnackBarAction(
            label: "Desfazer",
            textColor: const Color(0xFF00C6FF),
            onPressed: () {
              setState(() {
                notificacoes.insert(index, itemRemovido);
              });
            },
          ),
        ),
      );
    }

    try {
      await Api.deletarNotificacao(id);
    } catch (_) {
      // Reverte se a exclusão no backend falhar
      if (mounted) {
        setState(() {
          if (!notificacoes.any((n) => (n["id_notificacao"] ?? n["id"]) == id)) {
            notificacoes.insert(index, itemRemovido);
          }
        });
      }
    }
  }

  Future<void> limparTodas() async {
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Limpar Notificações",
      message: "Deseja realmente apagar todas as ${notificacoes.length} notificações da sua conta?",
      confirmText: "Limpar Tudo",
      cancelText: "Cancelar",
      isDestructive: true,
      icon: Icons.delete_sweep_rounded,
      iconColor: const Color(0xFFEF4444),
    );

    if (confirmar != true) return;

    final backup = List<dynamic>.from(notificacoes);

    setState(() {
      notificacoes.clear();
    });

    try {
      await Api.limparTodasNotificacoes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Todas as notificações foram apagadas"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          notificacoes = backup;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao limpar: $e"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  IconData pegarIcone(dynamic n) {
    if (_isTipo(n, ["evento"])) {
      return Icons.campaign_rounded;
    }
    if (_isTipo(n, ["treino", "corrida", "caminhada", "bike", "pace", "km"])) {
      return Icons.directions_run_rounded;
    }
    if (_isTipo(n, ["meta", "conquista", "recorde", "trofeu"])) {
      return Icons.emoji_events_rounded;
    }
    if (_isTipo(n, ["alerta", "aviso", "atencao", "overtraining", "fadiga", "lesao"])) {
      return Icons.warning_amber_rounded;
    }
    if (_isTipo(n, ["wellness", "saude", "recuperacao", "sono"])) {
      return Icons.favorite_rounded;
    }
    if (_isTipo(n, ["dica", "ia", "pacemind", "sistema"])) {
      return Icons.auto_awesome_rounded;
    }
    return Icons.notifications_rounded;
  }

  List<Color> pegarGradiente(dynamic n) {
    if (_isTipo(n, ["evento"])) {
      return const [Color(0xFF8B5CF6), Color(0xFF6366F1)];
    }
    if (_isTipo(n, ["treino", "corrida", "caminhada", "bike", "pace", "km"])) {
      return const [Color(0xFF0066FF), Color(0xFF00C6FF)];
    }
    if (_isTipo(n, ["meta", "conquista", "recorde", "trofeu"])) {
      return const [Color(0xFF10B981), Color(0xFF059669)];
    }
    if (_isTipo(n, ["alerta", "aviso", "atencao", "overtraining", "fadiga", "lesao"])) {
      return const [Color(0xFFF59E0B), Color(0xFFEA580C)];
    }
    if (_isTipo(n, ["wellness", "saude", "recuperacao", "sono"])) {
      return const [Color(0xFFEC4899), Color(0xFF8B5CF6)];
    }
    if (_isTipo(n, ["dica", "ia", "pacemind", "sistema"])) {
      return const [Color(0xFF6366F1), Color(0xFF4F46E5)];
    }
    return const [Color(0xFF0066FF), Color(0xFF3B82F6)];
  }

  String pegarNomeCategoria(dynamic n) {
    if (_isTipo(n, ["evento"])) {
      return "Evento";
    }
    if (_isTipo(n, ["treino", "corrida", "caminhada", "bike", "pace", "km"])) {
      return "Treino";
    }
    if (_isTipo(n, ["meta", "conquista", "recorde", "trofeu"])) {
      return "Meta";
    }
    if (_isTipo(n, ["alerta", "aviso", "atencao", "overtraining", "fadiga", "lesao"])) {
      return "Alerta";
    }
    if (_isTipo(n, ["wellness", "saude", "recuperacao", "sono"])) {
      return "Wellness";
    }
    if (_isTipo(n, ["dica", "ia", "pacemind", "sistema"])) {
      return "PaceMind IA";
    }
    return "Notificação";
  }

  void _abrirDetalhesNotificacao(dynamic n) {
    final id = n["id_notificacao"] ?? n["id"];
    final bool lida = n["lida"] == true;
    final gradiente = pegarGradiente(n);
    final categoria = pegarNomeCategoria(n);
    final icone = pegarIcone(n);
    final dataExtenso = AppDateUtils.formatarData(n["criado_em"]);
    final dataRelativa = AppDateUtils.formatarTempoRelativo(n["criado_em"]);

    // Marca como lida automaticamente ao abrir o detalhe
    if (!lida && id != null) {
      alternarLida(id, false);
    }

    AppModal.showBottomSheet(
      context: context,
      title: categoria,
      subtitle: dataRelativa,
      icon: icone,
      iconColor: gradiente.first,
      builder: (ctx, scrollController) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final colors = Theme.of(ctx).colorScheme;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Badge com Gradiente da Categoria
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradiente),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icone, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      categoria.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Título
            Text(
              n["titulo"] ?? "Sem título",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
                letterSpacing: -0.3,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 10),

            // Timestamp Detalhado
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  "$dataExtenso ($dataRelativa)",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Divisor
            Divider(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            ),

            const SizedBox(height: 16),

            // Mensagem Completa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162032) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                n["mensagem"] ?? "",
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Botão de Ação Direta Baseado na Categoria
            if (categoria == "Evento") ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, "/eventos");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.campaign_rounded, size: 20),
                label: const Text(
                  "Ver Eventos & Inscrições",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (categoria == "Treino") ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, "/treinos");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.directions_run_rounded, size: 20),
                label: const Text(
                  "Ver Meus Treinos",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Ações Secundárias (Alternar Leitura / Excluir)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (id != null) {
                        alternarLida(id, true);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 18,
                      color: colors.onSurface,
                    ),
                    label: Text(
                      "Marcar não lida",
                      style: TextStyle(fontSize: 13, color: colors.onSurface, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (id != null) {
                        deletarNotificacao(id);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    label: const Text(
                      "Excluir",
                      style: TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              "Notificações",
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (qtdNaoLidas > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "$qtdNaoLidas nova${qtdNaoLidas > 1 ? 's' : ''}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notificacoes.isNotEmpty) ...[
            if (qtdNaoLidas > 0)
              IconButton(
                icon: const Icon(Icons.done_all_rounded, color: Color(0xFF0066FF)),
                tooltip: "Marcar todas como lidas",
                onPressed: marcarTodasComoLidas,
              ),
            IconButton(
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              tooltip: "Limpar todas",
              onPressed: limparTodas,
            ),
          ],
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: loading && notificacoes.isEmpty
                ? _buildLoadingState(isDark)
                : erroCarregamento != null
                    ? _buildErrorState()
                    : Column(
                        children: [
                          // Banner de Status / KPI
                          if (notificacoes.isNotEmpty) _buildStatusBanner(colors, isDark),

                          // Barra de Filtros
                          if (notificacoes.isNotEmpty) _buildFiltrosBar(colors, isDark),

                          // Lista Principal
                          Expanded(
                            child: notificacoesFiltradas.isEmpty
                                ? _buildEmptyState(isDark)
                                : RefreshIndicator(
                                    color: const Color(0xFF0066FF),
                                    onRefresh: carregarNotificacoes,
                                    child: ListView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                      itemCount: notificacoesFiltradas.length,
                                      itemBuilder: (context, index) {
                                        final n = notificacoesFiltradas[index];
                                        final id = n["id_notificacao"] ?? n["id"];
                                        final bool lida = n["lida"] == true;

                                        return Dismissible(
                                          key: Key("notif_${id ?? index}"),
                                          // Suporta swipe para ambos os lados!
                                          // Direita: Marcar como lida/não lida
                                          // Esquerda: Excluir notificação
                                          background: _buildSwipeActionBackground(
                                            isLeft: false,
                                            isReadAction: true,
                                            lida: lida,
                                          ),
                                          secondaryBackground: _buildSwipeActionBackground(
                                            isLeft: true,
                                            isReadAction: false,
                                            lida: lida,
                                          ),
                                          confirmDismiss: (direction) async {
                                            if (direction == DismissDirection.startToEnd) {
                                              if (id != null) {
                                                alternarLida(id, lida);
                                              }
                                              return false; // Não remove do card ao alternar leitura
                                            }
                                            return true; // Remove ao excluir
                                          },
                                          onDismissed: (direction) {
                                            if (direction == DismissDirection.endToStart) {
                                              if (id != null) {
                                                deletarNotificacao(id);
                                              }
                                            }
                                          },
                                          child: _buildNotificacaoCard(
                                            n: n,
                                            id: id,
                                            lida: lida,
                                            colors: colors,
                                            isDark: isDark,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ColorScheme colors, bool isDark) {
    final temNaoLidas = qtdNaoLidas > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? (temNaoLidas ? const Color(0xFF132238) : const Color(0xFF111827))
            : (temNaoLidas ? const Color(0xFFEFF6FF) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: temNaoLidas
              ? const Color(0xFF0066FF).withValues(alpha: isDark ? 0.35 : 0.25)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: temNaoLidas
                  ? const Color(0xFF0066FF).withValues(alpha: isDark ? 0.25 : 0.12)
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              temNaoLidas ? Icons.mark_chat_unread_rounded : Icons.check_circle_outline_rounded,
              color: temNaoLidas ? const Color(0xFF0066FF) : const Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temNaoLidas
                      ? "Você tem $qtdNaoLidas pendência${qtdNaoLidas > 1 ? 's' : ''}"
                      : "Tudo em dia!",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  temNaoLidas
                      ? "Toque para abrir ou deslize para ações rápidas"
                      : "Nenhuma notificação nova no momento",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (temNaoLidas)
            TextButton(
              onPressed: marcarTodasComoLidas,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Ler todas",
                style: TextStyle(
                  color: Color(0xFF0066FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltrosBar(ColorScheme colors, bool isDark) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtros.length,
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final selecionado = filtroSelecionado == filtro;
          final totalFiltro = _contarPorFiltro(filtro);

          return GestureDetector(
            onTap: () {
              setState(() {
                filtroSelecionado = filtro;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: selecionado
                    ? const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF1E70EB)],
                      )
                    : null,
                color: selecionado
                    ? null
                    : (isDark ? const Color(0xFF162032) : colors.surface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selecionado
                      ? Colors.transparent
                      : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                ),
                boxShadow: selecionado
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.35),
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
                      fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: selecionado
                          ? Colors.white.withValues(alpha: 0.25)
                          : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$totalFiltro",
                      style: TextStyle(
                        color: selecionado
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeActionBackground({
    required bool isLeft,
    required bool isReadAction,
    required bool lida,
  }) {
    return Container(
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isReadAction
            ? (lida ? const Color(0xFF64748B) : const Color(0xFF10B981))
            : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) ...[
            Icon(
              lida ? Icons.mark_email_unread_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              lida ? "Marcar não lida" : "Marcar lida",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ] else ...[
            const Text(
              "Excluir",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificacaoCard({
    required dynamic n,
    required dynamic id,
    required bool lida,
    required ColorScheme colors,
    required bool isDark,
  }) {
    final gradiente = pegarGradiente(n);
    final categoria = pegarNomeCategoria(n);
    final icone = pegarIcone(n);
    final tempoRelativo = AppDateUtils.formatarTempoRelativo(n["criado_em"]);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrirDetalhesNotificacao(n),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lida
                ? (isDark ? const Color(0xFF111827) : Colors.white)
                : (isDark ? const Color(0xFF14223B) : const Color(0xFFF0F7FF)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: lida
                  ? (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0))
                  : const Color(0xFF0066FF).withValues(alpha: isDark ? 0.35 : 0.25),
              width: lida ? 1 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : (lida ? Colors.black.withValues(alpha: 0.03) : const Color(0xFF0066FF).withValues(alpha: 0.08)),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de destaque vertical para não lidas
              if (!lida)
                Container(
                  width: 3.5,
                  height: 48,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradiente,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

              // Avatar da Categoria
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradiente,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradiente.first.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icone, color: Colors.white, size: 22),
              ),

              const SizedBox(width: 12),

              // Conteúdo da Notificação
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoria + Timestamp + Bolinha Não Lida
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: gradiente.first.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoria.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: gradiente.first,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tempoRelativo,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (!lida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0066FF).withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Título
                    Text(
                      n["titulo"] ?? "Notificação",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: lida ? FontWeight.w600 : FontWeight.w800,
                        color: colors.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Mensagem
                    Text(
                      n["mensagem"] ?? "",
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Menu Popup de 3 Pontos
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  size: 20,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "toggle_lida",
                    child: Row(
                      children: [
                        Icon(
                          lida ? Icons.mark_email_unread_outlined : Icons.check_circle_outline_rounded,
                          size: 18,
                          color: const Color(0xFF0066FF),
                        ),
                        const SizedBox(width: 8),
                        Text(lida ? "Marcar como não lida" : "Marcar como lida"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: "detalhes",
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Text("Ver detalhes"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text("Excluir", style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == "toggle_lida" && id != null) {
                    alternarLida(id, lida);
                  } else if (val == "detalhes") {
                    _abrirDetalhesNotificacao(n);
                  } else if (val == "delete" && id != null) {
                    deletarNotificacao(id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 52,
                color: Color(0xFF0066FF),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              filtroSelecionado == "Todas"
                  ? "Tudo em dia!"
                  : "Nenhuma notificação em '$filtroSelecionado'",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filtroSelecionado == "Todas"
                  ? "Você receberá avisos sobre seus treinos realizados, metas atingidas e alertas de recuperação da IA aqui."
                  : "Não há notificações correspondentes a esta categoria no momento.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (filtroSelecionado != "Todas") ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    filtroSelecionado = "Todas";
                  });
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Color(0xFF0066FF)),
                ),
                icon: const Icon(Icons.clear_all_rounded, size: 18, color: Color(0xFF0066FF)),
                label: const Text(
                  "Ver todas as notificações",
                  style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
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
            "Carregando notificações...",
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(
              erroCarregamento!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  loading = true;
                  erroCarregamento = null;
                });
                carregarNotificacoes();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }
}
