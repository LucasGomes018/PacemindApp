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

  // 📱 Estado do Calendário estilo celular
  late DateTime mesReferencia;
  late DateTime diaSelecionado;
  bool visualizacaoMes = true; // true = Calendário Mensal + Dia | false = Linha do tempo completa

  final List<String> filtros = [
    "Todos",
    "Treinos",
    "Provas",
    "Consultas",
    "Exames",
    "Outros",
  ];

  final List<String> _diasDaSemana = [
    "DOM",
    "SEG",
    "TER",
    "QUA",
    "QUI",
    "SEX",
    "SÁB",
  ];

  final List<String> _mesesDoAno = [
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro",
  ];

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    diaSelecionado = DateTime(agora.year, agora.month, agora.day);
    mesReferencia = DateTime(agora.year, agora.month, 1);

    // ⚡ INSTANTÂNEO: Se houver cache de agenda, exibe imediatamente
    if (Api.agendaCache != null) {
      itensAgenda = Api.agendaCache!;
      loading = false;
    }
    _carregarAgenda();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarAgenda({bool forcar = false}) async {
    if (itensAgenda.isEmpty) {
      setState(() {
        loading = true;
        erroCarregamento = null;
      });
    }

    try {
      final data = await Api.listarAgenda(forcarAtualizacao: forcar);
      if (!mounted) return;

      setState(() {
        itensAgenda = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        if (itensAgenda.isEmpty) {
          erroCarregamento = "Não foi possível carregar seus compromissos.";
        }
      });
    }
  }

  bool _isMesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isHoje(DateTime d) {
    final agora = DateTime.now();
    return _isMesmoDia(d, agora);
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

  List<dynamic> _itensDoDia(DateTime dia) {
    return itensFiltrados.where((item) {
      final dataStr = item["data_inicio"]?.toString();
      if (dataStr == null) return false;
      final dt = DateTime.tryParse(dataStr);
      if (dt == null) return false;
      return _isMesmoDia(dt, dia);
    }).toList();
  }

  List<Color> _obterCoresEventosDia(DateTime dia) {
    final itens = itensFiltrados.where((item) {
      final dataStr = item["data_inicio"]?.toString();
      if (dataStr == null) return false;
      final dt = DateTime.tryParse(dataStr);
      if (dt == null) return false;
      return _isMesmoDia(dt, dia);
    });

    final cores = <Color>[];
    for (final it in itens) {
      final cor = _obterCorTipo(it["tipo"]?.toString() ?? "outro");
      if (!cores.contains(cor)) {
        cores.add(cor);
      }
      if (cores.length >= 3) break;
    }
    return cores;
  }

  IconData _obterIconeTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains("treino") || t.contains("corrida")) return Icons.directions_run_rounded;
    if (t.contains("prova") || t.contains("evento") || t.contains("competicao")) {
      return Icons.emoji_events_rounded;
    }
    if (t.contains("consulta") || t.contains("medico")) return Icons.medical_services_rounded;
    if (t.contains("exame")) return Icons.biotech_rounded;
    return Icons.event_note_rounded;
  }

  Color _obterCorTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains("treino") || t.contains("corrida")) return const Color(0xFF0066FF);
    if (t.contains("prova") || t.contains("evento") || t.contains("competicao")) {
      return const Color(0xFFF59E0B);
    }
    if (t.contains("consulta") || t.contains("medico")) return const Color(0xFF10B981);
    if (t.contains("exame")) return const Color(0xFF8B5CF6);
    return const Color(0xFF06B6D4);
  }

  String _obterNomeTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains("treino") || t.contains("corrida")) return "Treino";
    if (t.contains("prova") || t.contains("evento")) return "Prova";
    if (t.contains("consulta")) return "Consulta";
    if (t.contains("exame")) return "Exame";
    return "Compromisso";
  }

  void _irParaHoje() {
    final agora = DateTime.now();
    setState(() {
      diaSelecionado = DateTime(agora.year, agora.month, agora.day);
      mesReferencia = DateTime(agora.year, agora.month, 1);
    });
  }

  void _mudarMes(int delta) {
    setState(() {
      mesReferencia = DateTime(mesReferencia.year, mesReferencia.month + delta, 1);
    });
  }

  Future<void> _abrirModalCriarEditar([Map<String, dynamic>? itemExistente]) async {
    final isEdicao = itemExistente != null;
    final tituloCtrl = TextEditingController(text: itemExistente?["titulo"] ?? "");
    final descCtrl = TextEditingController(text: itemExistente?["descricao"] ?? "");

    // 📅 Data: Se estiver criando, pré-carrega o dia que o usuário selecionou no calendário da página
    DateTime dataDia = diaSelecionado;
    TimeOfDay? horaSelecionada;

    if (itemExistente?["data_inicio"] != null) {
      final parsed = DateTime.tryParse(itemExistente!["data_inicio"].toString());
      if (parsed != null) {
        dataDia = DateTime(parsed.year, parsed.month, parsed.day);
        horaSelecionada = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      }
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

              const SizedBox(height: 18),

              // =========================================================
              // 1️⃣ SEÇÃO: DATA DO COMPROMISSO (DEFINIDA PELO CALENDÁRIO)
              // =========================================================
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  const Text(
                    "DATA DO COMPROMISSO",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          "Definido no calendário",
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFF86EFAC),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${dataDia.day.toString().padLeft(2, '0')}/${dataDia.month.toString().padLeft(2, '0')}/${dataDia.year}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatarDataExtenso(dataDia),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final dataPick = await showDatePicker(
                          context: context,
                          initialDate: dataDia,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (dataPick == null) return;
                        setModalState(() {
                          dataDia = DateTime(dataPick.year, dataPick.month, dataPick.day);
                        });
                      },
                      icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                      label: const Text("Mudar dia", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // =========================================================
              // 2️⃣ SEÇÃO: HORÁRIO (AÇÃO PRINCIPAL QUE O USUÁRIO DEVE FAZER)
              // =========================================================
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF0066FF)),
                  const SizedBox(width: 6),
                  const Text(
                    "HORÁRIO DE INÍCIO *",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (horaSelecionada != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (horaSelecionada != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          horaSelecionada != null ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                          size: 12,
                          color: horaSelecionada != null ? const Color(0xFF10B981) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          horaSelecionada != null ? "Horário definido" : "Selecione o horário",
                          style: TextStyle(
                            color: horaSelecionada != null ? const Color(0xFF10B981) : const Color(0xFFD97706),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final horaPick = await showTimePicker(
                    context: context,
                    initialTime: horaSelecionada ?? TimeOfDay.now(),
                  );
                  if (horaPick == null) return;
                  setModalState(() {
                    horaSelecionada = horaPick;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF0066FF).withValues(alpha: horaSelecionada != null ? 0.22 : 0.12),
                              const Color(0xFF1E293B),
                            ]
                          : [
                              const Color(0xFF0066FF).withValues(alpha: horaSelecionada != null ? 0.12 : 0.05),
                              const Color(0xFFF0F7FF),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: horaSelecionada != null
                          ? const Color(0xFF0066FF)
                          : const Color(0xFFF59E0B),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (horaSelecionada != null ? const Color(0xFF0066FF) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: horaSelecionada != null ? const Color(0xFF0066FF) : const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (horaSelecionada != null ? const Color(0xFF0066FF) : const Color(0xFFF59E0B)).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              horaSelecionada != null ? "HORÁRIO CONFIRMADO" : "TOQUE PARA ESCOLHER",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: horaSelecionada != null ? const Color(0xFF0066FF) : const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              horaSelecionada != null
                                  ? "${horaSelecionada!.hour.toString().padLeft(2, '0')}:${horaSelecionada!.minute.toString().padLeft(2, '0')}"
                                  : "-- : --",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: horaSelecionada != null ? null : (isDark ? Colors.white38 : Colors.black38),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: horaSelecionada != null ? const Color(0xFF0066FF) : const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(horaSelecionada != null ? Icons.edit_rounded : Icons.touch_app_rounded, color: Colors.white, size: 15),
                            const SizedBox(width: 5),
                            Text(
                              horaSelecionada != null ? "Alterar" : "Selecionar",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Atalhos rápidos de horário
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _chipHoraRapida(
                    label: "06:00",
                    hora: 6,
                    minuto: 0,
                    horaAtual: horaSelecionada,
                    isDark: isDark,
                    onSelect: (h) => setModalState(() => horaSelecionada = h),
                  ),
                  _chipHoraRapida(
                    label: "07:00",
                    hora: 7,
                    minuto: 0,
                    horaAtual: horaSelecionada,
                    isDark: isDark,
                    onSelect: (h) => setModalState(() => horaSelecionada = h),
                  ),
                  _chipHoraRapida(
                    label: "08:30",
                    hora: 8,
                    minuto: 30,
                    horaAtual: horaSelecionada,
                    isDark: isDark,
                    onSelect: (h) => setModalState(() => horaSelecionada = h),
                  ),
                  _chipHoraRapida(
                    label: "18:00",
                    hora: 18,
                    minuto: 0,
                    horaAtual: horaSelecionada,
                    isDark: isDark,
                    onSelect: (h) => setModalState(() => horaSelecionada = h),
                  ),
                  _chipHoraRapida(
                    label: "19:30",
                    hora: 19,
                    minuto: 30,
                    horaAtual: horaSelecionada,
                    isDark: isDark,
                    onSelect: (h) => setModalState(() => horaSelecionada = h),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Dica informativa sobre os lembretes automáticos
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Lembretes automáticos: você será notificado 1 semana antes (se intervalo longo), na véspera (1 dia antes) e no dia do compromisso.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
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

            if (horaSelecionada == null) {
              AppSnackBar.aviso(
                context,
                "Por favor, selecione o horário de início do compromisso.",
                titulo: "Horário Obrigatório",
              );
              return;
            }

            final dataInicioFinal = DateTime(
              dataDia.year,
              dataDia.month,
              dataDia.day,
              horaSelecionada!.hour,
              horaSelecionada!.minute,
            );

            Navigator.pop(context);
            try {
              if (isEdicao) {
                final id = (itemExistente["id_agenda"] ?? itemExistente["id"]).toString();
                await Api.atualizarAgenda(
                  id: id,
                  titulo: titulo,
                  descricao: descCtrl.text.trim(),
                  dataInicio: dataInicioFinal.toIso8601String(),
                  tipo: tipoSelecionado,
                );
              } else {
                await Api.criarAgenda(
                  titulo: titulo,
                  descricao: descCtrl.text.trim(),
                  dataInicio: dataInicioFinal.toIso8601String(),
                  tipo: tipoSelecionado,
                );
              }

              // 🤖 Agenda os 3 lembretes automáticos (1 semana antes, 1 dia antes e no dia)
              final idLembrete = (titulo.hashCode.abs() % 100000);
              AutoNotificacaoService.agendarLembreteAgenda(
                id: idLembrete,
                titulo: titulo,
                dataInicio: dataInicioFinal,
                tipo: tipoSelecionado,
              );

              // Atualiza o dia selecionado para o dia do novo compromisso
              setState(() {
                diaSelecionado = DateTime(dataInicioFinal.year, dataInicioFinal.month, dataInicioFinal.day);
                mesReferencia = DateTime(dataInicioFinal.year, dataInicioFinal.month, 1);
              });

              if (!mounted) return;
              AppSnackBar.sucesso(
                context,
                isEdicao ? "Compromisso atualizado com sucesso!" : "Compromisso agendado com sucesso!",
                titulo: isEdicao ? "Agenda Atualizada" : "Agendado",
              );
              _carregarAgenda(forcar: true);
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

  Widget _chipHoraRapida({
    required String label,
    required int hora,
    required int minuto,
    required TimeOfDay? horaAtual,
    required Function(TimeOfDay) onSelect,
    bool isDark = false,
  }) {
    final selecionado = horaAtual != null && horaAtual.hour == hora && horaAtual.minute == minuto;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelect(TimeOfDay(hour: hora, minute: minuto)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFF0066FF)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFF0066FF).withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF0066FF)
                : (isDark ? Colors.white12 : const Color(0xFF0066FF).withValues(alpha: 0.25)),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.w600,
            color: selecionado ? Colors.white : const Color(0xFF0066FF),
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

        // Cancela os lembretes do compromisso removido
        final idLembrete = (titulo.hashCode.abs() % 100000);
        await AutoNotificacaoService.cancelarLembreteAgenda(idLembrete);

        if (!mounted) return;
        AppSnackBar.info(
          context,
          "Compromisso excluído da sua agenda.",
          titulo: "Item Excluído",
        );
        _carregarAgenda(forcar: true);
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
    final mediaQuery = MediaQuery.of(context);
    final larguraTela = mediaQuery.size.width;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Agenda & Calendário", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          // Botão HOJE com estilo de calendário nativo
          TextButton(
            onPressed: _irParaHoje,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(40, 36),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isHoje(diaSelecionado)
                    ? const Color(0xFF0066FF).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: const Text(
                "Hoje",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF0066FF),
                ),
              ),
            ),
          ),

          // Alternador de Visualização: Mês vs Lista
          IconButton(
            icon: Icon(
              visualizacaoMes ? Icons.view_agenda_outlined : Icons.calendar_month_rounded,
              color: const Color(0xFF0066FF),
            ),
            tooltip: visualizacaoMes ? "Ver Linha do Tempo" : "Ver Calendário Mensal",
            onPressed: () {
              setState(() {
                visualizacaoMes = !visualizacaoMes;
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _carregarAgenda(forcar: true),
            tooltip: "Atualizar",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalCriarEditar(),
        backgroundColor: const Color(0xFF0066FF),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Novo",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _carregarAgenda(forcar: true),
        color: const Color(0xFF0066FF),
        child: Column(
          children: [
            // Barra de pesquisa
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: TextField(
                controller: _buscaController,
                onChanged: (val) => setState(() => buscaQuery = val),
                decoration: InputDecoration(
                  hintText: "Buscar compromissos...",
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: buscaQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() => buscaQuery = "");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),

            // Chips de filtro horizontal
            SizedBox(
              height: 42,
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
                      fontSize: 12,
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Conteúdo Principal: Visualização Mensal ou Linha do Tempo
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))
                  : erroCarregamento != null
                      ? _buildErroView()
                      : visualizacaoMes
                          ? _buildVisaoCalendarioCelular(isDark, larguraTela)
                          : _buildVisaoLinhaDoTempoCompleta(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 📱 VISUALIZAÇÃO DE CALENDÁRIO NATIVO DE CELULAR (MÊS + DIA)
  // -------------------------------------------------------------
  Widget _buildVisaoCalendarioCelular(bool isDark, double larguraTela) {
    final itensDoDia = _itensDoDia(diaSelecionado);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Bloco do Calendário (Grade do Mês)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
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
              children: [
                // Barra de navegação do Mês (Outubro 2026 < >)
                _buildCabecalhoMes(isDark),

                const SizedBox(height: 10),

                // Linha dos dias da semana (DOM, SEG, TER...)
                _buildCabecalhoDiasSemana(isDark),

                const SizedBox(height: 6),

                // Grade dos dias do mês
                _buildGradeDiasDoMes(isDark, larguraTela),
              ],
            ),
          ),
        ),

        // 2. Faixa do Dia Selecionado com contagem e ação rápida
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        _formatarDataExtenso(diaSelecionado),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (_isHoje(diaSelecionado)) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Hoje",
                            style: TextStyle(
                              color: Color(0xFF0066FF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  "${itensDoDia.length} ${itensDoDia.length == 1 ? 'item' : 'itens'}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Lista de compromissos do dia selecionado
        if (itensDoDia.isEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event_available_rounded, size: 36, color: Color(0xFF0066FF)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Agenda livre neste dia",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Nenhum compromisso marcado para ${_formatarDataExtenso(diaSelecionado)}.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _abrirModalCriarEditar(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text("Adicionar neste dia"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0066FF),
                      side: const BorderSide(color: Color(0xFF0066FF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = itensDoDia[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildItemCard(item, isDark),
                  );
                },
                childCount: itensDoDia.length,
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 📋 CABEÇALHO DO MÊS COM SETAS
  // -------------------------------------------------------------
  Widget _buildCabecalhoMes(bool isDark) {
    final nomeMes = _mesesDoAno[mesReferencia.month - 1];
    final ano = mesReferencia.year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF0066FF), size: 20),
            const SizedBox(width: 8),
            Text(
              "$nomeMes $ano",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 24),
              onPressed: () => _mudarMes(-1),
              tooltip: "Mês Anterior",
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 24),
              onPressed: () => _mudarMes(1),
              tooltip: "Próximo Mês",
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 🗓️ CABEÇALHO DOS DIAS DA SEMANA (DOM, SEG, TER...)
  // -------------------------------------------------------------
  Widget _buildCabecalhoDiasSemana(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _diasDaSemana.map((dia) {
        final isFimDeSemana = dia == "DOM" || dia == "SÁB";
        return Expanded(
          child: Center(
            child: Text(
              dia,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isFimDeSemana
                    ? const Color(0xFF0066FF).withValues(alpha: 0.8)
                    : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // 🔢 GRADE INTERATIVA DOS DIAS DO MÊS
  // -------------------------------------------------------------
  Widget _buildGradeDiasDoMes(bool isDark, double larguraTela) {
    // 1º dia do mês
    final primeiroDiaMes = DateTime(mesReferencia.year, mesReferencia.month, 1);
    // Quantidade de dias no mês
    final ultimoDiaMes = DateTime(mesReferencia.year, mesReferencia.month + 1, 0);
    final totalDiasMes = ultimoDiaMes.day;

    // Offset do dia da semana (Domingo = 0, Segunda = 1, ..., Sábado = 6)
    // No Dart: weekday é 1=Segunda ... 7=Domingo
    final offsetInicio = primeiroDiaMes.weekday % 7;

    // Mês anterior para preenchimento
    final ultimoDiaMesAnterior = DateTime(mesReferencia.year, mesReferencia.month, 0).day;

    // Total de células (múltiplo de 7)
    final totalCelulas = ((offsetInicio + totalDiasMes) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCelulas,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        int numeroDia;
        bool pertenceAoMesAtual = true;
        DateTime dataCelula;

        if (index < offsetInicio) {
          // Dias do mês anterior
          numeroDia = ultimoDiaMesAnterior - (offsetInicio - index - 1);
          pertenceAoMesAtual = false;
          dataCelula = DateTime(mesReferencia.year, mesReferencia.month - 1, numeroDia);
        } else if (index >= offsetInicio + totalDiasMes) {
          // Dias do próximo mês
          numeroDia = index - (offsetInicio + totalDiasMes) + 1;
          pertenceAoMesAtual = false;
          dataCelula = DateTime(mesReferencia.year, mesReferencia.month + 1, numeroDia);
        } else {
          // Dias do mês atual
          numeroDia = index - offsetInicio + 1;
          pertenceAoMesAtual = true;
          dataCelula = DateTime(mesReferencia.year, mesReferencia.month, numeroDia);
        }

        final selecionado = _isMesmoDia(dataCelula, diaSelecionado);
        final hoje = _isHoje(dataCelula);
        final coresEventos = _obterCoresEventosDia(dataCelula);

        return GestureDetector(
          onTap: () {
            setState(() {
              diaSelecionado = dataCelula;
              if (!pertenceAoMesAtual) {
                mesReferencia = DateTime(dataCelula.year, dataCelula.month, 1);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selecionado
                  ? const Color(0xFF0066FF)
                  : (hoje && !selecionado
                      ? const Color(0xFF0066FF).withValues(alpha: 0.12)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: hoje && !selecionado
                  ? Border.all(color: const Color(0xFF0066FF), width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$numeroDia",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selecionado || hoje ? FontWeight.bold : FontWeight.w500,
                    color: selecionado
                        ? Colors.white
                        : (hoje
                            ? const Color(0xFF0066FF)
                            : (pertenceAoMesAtual
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)))),
                  ),
                ),
                const SizedBox(height: 3),
                // Pontos indicadores de eventos
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: coresEventos.isEmpty
                      ? [const SizedBox(height: 5)]
                      : coresEventos.map((c) {
                          return Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: selecionado ? Colors.white : c,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 📑 LINHA DO TEMPO COMPLETA (MODO LISTA CONTÍNUA)
  // -------------------------------------------------------------
  Widget _buildVisaoLinhaDoTempoCompleta(bool isDark) {
    final lista = itensFiltrados;

    if (lista.isEmpty) {
      return Center(
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
                    ? "Nenhum compromisso encontrado para os filtros."
                    : "Sua agenda está livre!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Adicione treinos futuros, provas, consultas ou exames para organizar sua rotina.",
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
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: lista.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = lista[index];
        return _buildItemCard(item, isDark);
      },
    );
  }

  // -------------------------------------------------------------
  // 💳 CARD MODERNO DO COMPROMISSO
  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // 💳 CARD MODERNO E ULTRA-PREMIUM DO COMPROMISSO
  // -------------------------------------------------------------
  Widget _buildItemCard(dynamic item, bool isDark) {
    final tipo = item["tipo"]?.toString() ?? "outro";
    final cor = _obterCorTipo(tipo);
    final icone = _obterIconeTipo(tipo);
    final nomeTipo = _obterNomeTipo(tipo);

    final dataStr = item["data_inicio"]?.toString() ?? "";
    DateTime? dt = DateTime.tryParse(dataStr);
    final horaFormatada = dt != null
        ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}"
        : "--:--";

    // Cálculo do status / contagem regressiva
    String statusTexto = "";
    Color statusCor = const Color(0xFF64748B);
    if (dt != null) {
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final diaCompromisso = DateTime(dt.year, dt.month, dt.day);
      final diffDias = diaCompromisso.difference(hoje).inDays;

      if (diffDias == 0) {
        statusTexto = "Hoje";
        statusCor = const Color(0xFF10B981);
      } else if (diffDias == 1) {
        statusTexto = "Amanhã";
        statusCor = const Color(0xFFF59E0B);
      } else if (diffDias > 1) {
        statusTexto = "Em $diffDias dias";
        statusCor = const Color(0xFF0066FF);
      } else {
        statusTexto = "Concluído";
        statusCor = const Color(0xFF94A3B8);
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _abrirDetalhesCompromisso(item),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    cor.withValues(alpha: 0.14),
                    const Color(0xFF1E293B),
                  ]
                : [
                    cor.withValues(alpha: 0.08),
                    Colors.white,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cor.withValues(alpha: isDark ? 0.35 : 0.22),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: isDark ? 0.16 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha Superior: Ícone com Gradiente + Categoria + Status + Menu de Opções
              Row(
                children: [
                  // Ícone temático com gradiente e sombra suave
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cor, cor.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: cor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icone, color: Colors.white, size: 20),
                  ),

                  const SizedBox(width: 10),

                  // Categoria + Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeTipo.toUpperCase(),
                          style: TextStyle(
                            color: cor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                            const SizedBox(width: 4),
                            Text(
                              horaFormatada,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            if (!visualizacaoMes && dt != null) ...[
                              Text(
                                " • ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Pill (Hoje, Amanhã, Em X dias)
                  if (statusTexto.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusCor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusCor.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusCor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusTexto,
                            style: TextStyle(
                              color: statusCor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Menu 3 pontinhos
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == "detalhes") {
                        _abrirDetalhesCompromisso(item);
                      } else if (val == "editar") {
                        _abrirModalCriarEditar(item);
                      } else if (val == "excluir") {
                        _confirmarExclusao(item);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: "detalhes",
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18),
                            SizedBox(width: 8),
                            Text("Ver Detalhes"),
                          ],
                        ),
                      ),
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
                ],
              ),

              const SizedBox(height: 10),

              // Título em Destaque
              Text(
                item["titulo"] ?? "Compromisso",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),

              // Descrição / Observações (se houver)
              if (item["descricao"] != null && item["descricao"].toString().trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_rounded, size: 15, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item["descricao"],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Rodapé do Card: Lembretes Ativos + Ações Rápidas
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active_rounded, size: 13, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          "Lembretes: 1 sem • 1 dia • hoje",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _abrirModalCriarEditar(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: cor),
                          const SizedBox(width: 3),
                          Text(
                            "Editar",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cor,
                            ),
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
      ),
    );
  }

  // -------------------------------------------------------------
  // 🔍 MODAL DE DETALHES COMPLETOS DO COMPROMISSO
  // -------------------------------------------------------------
  void _abrirDetalhesCompromisso(dynamic item) {
    final tipo = item["tipo"]?.toString() ?? "outro";
    final cor = _obterCorTipo(tipo);
    final icone = _obterIconeTipo(tipo);
    final nomeTipo = _obterNomeTipo(tipo);

    final dataStr = item["data_inicio"]?.toString() ?? "";
    DateTime? dt = DateTime.tryParse(dataStr);
    final dataFormatada = dt != null ? AppDateUtils.formatarData(dt) : dataStr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppModal.showBottomSheet(
      context: context,
      title: "Detalhes do Compromisso",
      icon: icone,
      iconColor: cor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header com Badge e Tipo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeTipo,
                        style: TextStyle(
                          color: cor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item["titulo"] ?? "Compromisso",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Data e Horário
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
            title: const Text("Data e Horário", style: TextStyle(fontSize: 13, color: Colors.grey)),
            subtitle: Text(
              dataFormatada,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),

          // Descrição completa
          if (item["descricao"] != null && item["descricao"].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notes_rounded, color: Color(0xFF8B5CF6), size: 20),
              ),
              title: const Text("Descrição / Observações", style: TextStyle(fontSize: 13, color: Colors.grey)),
              subtitle: Text(
                item["descricao"],
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Painel Informativo de Lembretes Agendados
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text(
                      "Lembretes Automáticos Ativos",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "• 1 semana antes às 09:00 (se agendado com antecedência)\n• 1 dia antes (véspera às 18:00)\n• No dia do evento (às 08:00 ou 1h antes)",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingAction: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _confirmarExclusao(item);
              },
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              label: const Text("Excluir", style: TextStyle(color: Color(0xFFEF4444))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _abrirModalCriarEditar(item);
              },
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              label: const Text("Editar Compromisso", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ⚠️ TELA DE ERRO
  // -------------------------------------------------------------
  Widget _buildErroView() {
    return Center(
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
              onPressed: () => _carregarAgenda(forcar: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Tentar Novamente"),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarDataExtenso(DateTime d) {
    const dias = [
      "Segunda-feira",
      "Terça-feira",
      "Quarta-feira",
      "Quinta-feira",
      "Sexta-feira",
      "Sábado",
      "Domingo",
    ];
    final nomeDia = dias[d.weekday - 1];
    final nomeMes = _mesesDoAno[d.month - 1];
    return "$nomeDia, ${d.day} de $nomeMes";
  }
}
