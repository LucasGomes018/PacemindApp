import 'package:flutter/material.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';
import '../services/auto_notificacao_service.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  bool loading = true;
  String? erroCarregamento;
  List<dynamic> itensAgenda = [];
  String filtroTipo = "Todos";
  String buscaQuery = "";
  final TextEditingController _buscaController = TextEditingController();

  final List<String> filtros = [
    "Todos",
    "Treinos",
    "Provas",
    "Consultas",
    "Exames",
    "Outros",
  ];

  @override
  void initState() {
    super.initState();
    _carregarAgenda();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarAgenda() async {
    setState(() {
      loading = true;
      erroCarregamento = null;
    });

    try {
      final data = await Api.listarAgenda();
      if (!mounted) return;

      setState(() {
        itensAgenda = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar seus compromissos.";
      });
    }
  }

  List<dynamic> get itensFiltrados {
    return itensAgenda.where((item) {
      final tipo = (item["tipo"]?.toString() ?? "outro").toLowerCase();
      final titulo = (item["titulo"]?.toString() ?? "").toLowerCase();
      final desc = (item["descricao"]?.toString() ?? "").toLowerCase();

      bool matchFiltro = true;
      if (filtroTipo == "Treinos") {
        matchFiltro = tipo.contains("treino") || tipo.contains("corrida");
      } else if (filtroTipo == "Provas") {
        matchFiltro = tipo.contains("prova") || tipo.contains("evento") || tipo.contains("competicao");
      } else if (filtroTipo == "Consultas") {
        matchFiltro = tipo.contains("consulta") || tipo.contains("medico");
      } else if (filtroTipo == "Exames") {
        matchFiltro = tipo.contains("exame");
      } else if (filtroTipo == "Outros") {
        matchFiltro = !tipo.contains("treino") &&
            !tipo.contains("corrida") &&
            !tipo.contains("prova") &&
            !tipo.contains("evento") &&
            !tipo.contains("consulta") &&
            !tipo.contains("exame");
      }

      final matchBusca = buscaQuery.isEmpty ||
          titulo.contains(buscaQuery.toLowerCase()) ||
          desc.contains(buscaQuery.toLowerCase());

      return matchFiltro && matchBusca;
    }).toList();
  }

  IconData _obterIconeTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains("treino") || t.contains("corrida")) return Icons.directions_run_rounded;
    if (t.contains("prova") || t.contains("evento")) return Icons.emoji_events_rounded;
    if (t.contains("consulta") || t.contains("medico")) return Icons.medical_services_rounded;
    if (t.contains("exame")) return Icons.biotech_rounded;
    return Icons.event_note_rounded;
  }

  Color _obterCorTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains("treino") || t.contains("corrida")) return const Color(0xFF0066FF);
    if (t.contains("prova") || t.contains("evento")) return const Color(0xFFF59E0B);
    if (t.contains("consulta") || t.contains("medico")) return const Color(0xFF10B981);
    if (t.contains("exame")) return const Color(0xFF8B5CF6);
    return const Color(0xFF64748B);
  }

  Future<void> _abrirModalCriarEditar([Map<String, dynamic>? itemExistente]) async {
    final isEdicao = itemExistente != null;
    final tituloCtrl = TextEditingController(text: itemExistente?["titulo"] ?? "");
    final descCtrl = TextEditingController(text: itemExistente?["descricao"] ?? "");

    DateTime dataInicio = DateTime.now().add(const Duration(hours: 1));
    if (itemExistente?["data_inicio"] != null) {
      dataInicio = DateTime.tryParse(itemExistente!["data_inicio"].toString()) ?? dataInicio;
    }

    String tipoSelecionado = itemExistente?["tipo"] ?? "treino";

    await AppModal.showBottomSheet(
      context: context,
      title: isEdicao ? "Editar Compromisso" : "Novo Compromisso",
      icon: isEdicao ? Icons.edit_calendar_rounded : Icons.add_alarm_rounded,
      iconColor: const Color(0xFF0066FF),
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Tipo de Compromisso",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chipTipoModal("treino", "Treino", Icons.directions_run_rounded, tipoSelecionado, (t) {
                    setModalState(() => tipoSelecionado = t);
                  }),
                  _chipTipoModal("prova", "Prova/Corrida", Icons.emoji_events_rounded, tipoSelecionado, (t) {
                    setModalState(() => tipoSelecionado = t);
                  }),
                  _chipTipoModal("consulta", "Consulta", Icons.medical_services_rounded, tipoSelecionado, (t) {
                    setModalState(() => tipoSelecionado = t);
                  }),
                  _chipTipoModal("exame", "Exame", Icons.biotech_rounded, tipoSelecionado, (t) {
                    setModalState(() => tipoSelecionado = t);
                  }),
                  _chipTipoModal("outro", "Outro", Icons.event_note_rounded, tipoSelecionado, (t) {
                    setModalState(() => tipoSelecionado = t);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tituloCtrl,
                decoration: InputDecoration(
                  labelText: "Título *",
                  hintText: "Ex: Treino de Tiro 8x400m, Consulta Cardiologista",
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Descrição / Observações",
                  hintText: "Detalhes, local, recomendações pré-evento...",
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF0066FF), size: 20),
                ),
                title: const Text("Data e Hora"),
                subtitle: Text(
                  "${AppDateUtils.formatarData(dataInicio)} às ${dataInicio.hour.toString().padLeft(2, '0')}:${dataInicio.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final dataPick = await showDatePicker(
                      context: context,
                      initialDate: dataInicio,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (dataPick == null) return;
                    if (!mounted) return;
                    final horaPick = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(dataInicio),
                    );
                    if (horaPick == null) return;
                    if (!mounted) return;
                    setModalState(() {
                      dataInicio = DateTime(
                        dataPick.year,
                        dataPick.month,
                        dataPick.day,
                        horaPick.hour,
                        horaPick.minute,
                      );
                    });
                  },
                  child: const Text("Alterar"),
                ),
              ),
            ],
          );
        },
      ),
      floatingAction: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final titulo = tituloCtrl.text.trim();
            if (titulo.isEmpty) {
              AppSnackBar.aviso(
                context,
                "Informe o título do compromisso.",
                titulo: "Título Obrigatório",
              );
              return;
            }

            Navigator.pop(context);
            try {
              if (isEdicao) {
                final id = (itemExistente["id_agenda"] ?? itemExistente["id"]).toString();
                await Api.atualizarAgenda(
                  id: id,
                  titulo: titulo,
                  descricao: descCtrl.text.trim(),
                  dataInicio: dataInicio.toIso8601String(),
                  tipo: tipoSelecionado,
                );
              } else {
                await Api.criarAgenda(
                  titulo: titulo,
                  descricao: descCtrl.text.trim(),
                  dataInicio: dataInicio.toIso8601String(),
                  tipo: tipoSelecionado,
                );
              }

              // 🤖 Agenda notificação automática no dispositivo
              AutoNotificacaoService.agendarLembreteAgenda(
                id: titulo.hashCode.abs() % 100000,
                titulo: titulo,
                dataInicio: dataInicio,
                tipo: tipoSelecionado,
              );

              if (!mounted) return;
              AppSnackBar.sucesso(
                context,
                isEdicao ? "Compromisso atualizado com sucesso!" : "Compromisso agendado com sucesso!",
                titulo: isEdicao ? "Agenda Atualizada" : "Agendado",
              );
              _carregarAgenda();
            } catch (e) {
              if (!mounted) return;
              AppSnackBar.erro(
                context,
                "Erro ao salvar compromisso. Tente novamente.",
                titulo: "Erro ao Salvar",
              );
            }
          },
          icon: const Icon(Icons.check_rounded, color: Colors.white),
          label: Text(
            isEdicao ? "Salvar Alterações" : "Agendar Compromisso",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066FF),
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _chipTipoModal(String valor, String label, IconData icon, String selecionado, Function(String) onSelect) {
    final ativo = valor == selecionado;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSelect(valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? const Color(0xFF0066FF) : const Color(0xFF0066FF).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ativo ? Colors.white : const Color(0xFF0066FF)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ativo ? Colors.white : const Color(0xFF0066FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(dynamic item) async {
    final titulo = item["titulo"]?.toString() ?? "Compromisso";
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Excluir Compromisso?",
      message: "Tem certeza que deseja remover \"$titulo\" da sua agenda?",
      confirmText: "Excluir",
      cancelText: "Cancelar",
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      confirmButtonColor: const Color(0xFFEF4444),
      isDestructive: true,
    );

    if (confirmar == true) {
      try {
        final id = (item["id_agenda"] ?? item["id"]).toString();
        await Api.deletarAgenda(id);
        if (!mounted) return;
        AppSnackBar.info(
          context,
          "Compromisso excluído da sua agenda.",
          titulo: "Item Excluído",
        );
        _carregarAgenda();
      } catch (_) {
        if (!mounted) return;
        AppSnackBar.erro(
          context,
          "Erro ao excluir compromisso.",
          titulo: "Erro na Exclusão",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final lista = itensFiltrados;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Agenda & Calendário", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarAgenda,
            tooltip: "Atualizar",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalCriarEditar(),
        backgroundColor: const Color(0xFF0066FF),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Novo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarAgenda,
        color: const Color(0xFF0066FF),
        child: Column(
          children: [
            // Barra de pesquisa
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _buscaController,
                onChanged: (val) => setState(() => buscaQuery = val),
                decoration: InputDecoration(
                  hintText: "Buscar compromissos...",
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: buscaQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() => buscaQuery = "");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Chips de filtro horizontal
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtros.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = filtros[index];
                  final isSel = f == filtroTipo;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSel,
                    onSelected: (_) => setState(() => filtroTipo = f),
                    selectedColor: const Color(0xFF0066FF),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Lista de itens
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
                  : erroCarregamento != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                                const SizedBox(height: 12),
                                Text(erroCarregamento!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _carregarAgenda,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text("Tentar Novamente"),
                                ),
                              ],
                            ),
                          ),
                        )
                      : lista.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.calendar_month_rounded, size: 48, color: Color(0xFF0066FF)),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      buscaQuery.isNotEmpty || filtroTipo != "Todos"
                                          ? "Nenhum compromisso encontrado para os filtros selecionados."
                                          : "Sua agenda está livre!",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Adicione seus treinos futuros, competições, consultas médicas e exames para manter tudo organizado.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () => _abrirModalCriarEditar(),
                                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                                      label: const Text("Adicionar Compromisso", style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0066FF),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: lista.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = lista[index];
                                final tipo = item["tipo"]?.toString() ?? "outro";
                                final cor = _obterCorTipo(tipo);
                                final icone = _obterIconeTipo(tipo);

                                final dataStr = item["data_inicio"]?.toString() ?? "";
                                DateTime? dt = DateTime.tryParse(dataStr);
                                final dataFormatada = dt != null ? AppDateUtils.formatarData(dt) : dataStr;
                                final horaFormatada = dt != null
                                    ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}"
                                    : "";

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(icone, color: cor, size: 24),
                                    ),
                                    title: Text(
                                      item["titulo"] ?? "Compromisso",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              "$dataFormatada ${horaFormatada.isNotEmpty ? '• $horaFormatada' : ''}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item["descricao"] != null && item["descricao"].toString().trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item["descricao"],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded),
                                      onSelected: (val) {
                                        if (val == "editar") {
                                          _abrirModalCriarEditar(item);
                                        } else if (val == "excluir") {
                                          _confirmarExclusao(item);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: "editar",
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_rounded, size: 18),
                                              SizedBox(width: 8),
                                              Text("Editar"),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: "excluir",
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                              SizedBox(width: 8),
                                              Text("Excluir", style: TextStyle(color: Color(0xFFEF4444))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
