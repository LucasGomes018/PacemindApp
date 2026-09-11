import 'package:flutter/material.dart';
import '../core/api.dart';
import '../services/notificacao_service.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';


class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  List<dynamic> eventos = [];
  bool loading = true;
  String? erroCarregamento;
  bool isAdmin = false;
  Map<String, String> inscricoesUsuario = {};
  int filtroSelecionado = 0; // 0: Todos, 1: Minhas Inscrições, 2: 5k, 3: 10k, 4: 21k+

  @override
  void initState() {
    super.initState();
    iniciarPagina();
  }

  Future<void> iniciarPagina() async {
    await carregarPerfil();
    await carregarMinhasInscricoes();
    await carregarEventos();
  }

  Future<void> carregarPerfil() async {
    try {
      final usuario = await Api.me();
      if (!mounted) return;
      setState(() {
        isAdmin = usuario["tipo_usuario"] == "admin";
      });
    } catch (_) {}
  }

  Future<void> carregarMinhasInscricoes() async {
    try {
      final response = await Api.minhasInscricoes();
      if (!mounted) return;

      setState(() {
        inscricoesUsuario.clear();
        for (var item in response) {
          final idEvento = item["id_evento"]?.toString() ?? "";
          final idInscricao = item["id_inscricao"]?.toString() ?? "";
          if (idEvento.isNotEmpty) {
            inscricoesUsuario[idEvento] = idInscricao;
          }
        }
      });
    } catch (_) {}
  }

  Future<void> carregarEventos() async {
    try {
      final data = await Api.listarEventos();
      if (!mounted) return;

      setState(() {
        eventos = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar os eventos.";
      });
    }
  }

  bool usuarioInscrito(String idEvento) {
    return inscricoesUsuario.containsKey(idEvento);
  }

  String formatarData(String? data) {
    return AppDateUtils.formatarData(data);
  }

  String formatarDiaMes(String? data) {
    if (data == null) return "-";
    final d = AppDateUtils.extrairDataPura(data);
    if (d == null) return "--";

    const meses = [
      "JAN", "FEV", "MAR", "ABR", "MAI", "JUN",
      "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"
    ];
    final mesNome = meses[(d.month - 1).clamp(0, 11)];
    return "${d.day}\n$mesNome";
  }

  Color corDistancia(double km) {
    if (km <= 5) return const Color(0xFF10B981); // Verde
    if (km <= 10) return const Color(0xFFF59E0B); // Laranja
    if (km <= 21) return const Color(0xFF0066FF); // Azul
    return const Color(0xFF8B5CF6); // Roxo / Maratona
  }

  Future<void> mostrarCardAcao({
    required String mensagem,
    required IconData icone,
    required Color cor,
    bool loading = false,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    loading
                        ? SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: cor,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icone, size: 40, color: cor),
                          ),
                    const SizedBox(height: 18),
                    Text(
                      mensagem,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void fecharCardAcao() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> inscrever(String idEvento) async {
    if (usuarioInscrito(idEvento)) return;

    mostrarCardAcao(
      mensagem: "Confirmando sua inscrição...",
      icone: Icons.hourglass_top_rounded,
      cor: const Color(0xFF0066FF),
      loading: true,
    );

    try {
      await Api.inscreverEvento(idEvento: idEvento);
      await carregarMinhasInscricoes();

      if (!mounted) return;
      fecharCardAcao();

      mostrarCardAcao(
        mensagem: "🎉 Inscrição realizada com sucesso!\nBons treinos!",
        icone: Icons.check_circle_rounded,
        cor: const Color(0xFF10B981),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      fecharCardAcao();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      fecharCardAcao();

      mostrarCardAcao(
        mensagem: "Erro ao realizar inscrição no evento.",
        icone: Icons.error_outline_rounded,
        cor: Colors.redAccent,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      fecharCardAcao();
    }
  }

  Future<void> cancelarInscricao(String idEvento) async {
    final idInscricao = inscricoesUsuario[idEvento];
    if (idInscricao == null) return;

    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Cancelar Inscrição?",
      message: "Tem certeza de que deseja abrir mão da sua vaga neste evento?",
      confirmText: "Confirmar Cancelamento",
      cancelText: "Voltar",
      isDestructive: true,
      icon: Icons.event_busy_rounded,
    );

    if (confirmar != true) return;

    mostrarCardAcao(
      mensagem: "Cancelando sua inscrição...",
      icone: Icons.hourglass_top_rounded,
      cor: Colors.orange,
      loading: true,
    );

    try {
      await Api.cancelarInscricao(idInscricao);
      await carregarMinhasInscricoes();

      if (!mounted) return;
      fecharCardAcao();

      mostrarCardAcao(
        mensagem: "Inscrição cancelada com sucesso.",
        icone: Icons.check_circle_outline_rounded,
        cor: Colors.orange,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      fecharCardAcao();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      fecharCardAcao();

      mostrarCardAcao(
        mensagem: "Erro ao cancelar inscrição.",
        icone: Icons.error_outline_rounded,
        cor: Colors.redAccent,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      fecharCardAcao();
    }
  }

  void mostrarInscritos(dynamic evento) async {
    final idEvento = (evento["id_evento"] ?? evento["id"]).toString();

    try {
      final data = await Api.listarInscricoes(idEvento);
      final inscritos = (data["inscritos"] as List?) ?? [];

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          final theme = Theme.of(sheetCtx);
          final colors = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.75,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: Color(0xFF0066FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evento["nome"] ?? "Inscritos no Evento",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            "${data["total"] ?? inscritos.length} atletas inscritos",
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: inscritos.isEmpty
                      ? Center(
                          child: Text(
                            "Nenhum atleta inscrito até o momento.",
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          itemCount: inscritos.length,
                          itemBuilder: (_, index) {
                            final inscrito = inscritos[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.15),
                                    child: const Icon(Icons.person, color: Color(0xFF0066FF)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inscrito["nome_usuario"] ?? "Atleta",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: colors.onSurface,
                                          ),
                                        ),
                                        if (inscrito["email"] != null)
                                          Text(
                                            inscrito["email"] ?? "",
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "Confirmado",
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível carregar os inscritos")),
      );
    }
  }

  void mostrarCriarEvento() {
    final nomeController = TextEditingController();
    final localController = TextEditingController();
    final distanciaController = TextEditingController();
    final descricaoController = TextEditingController();
    DateTime? dataSelecionada;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final colors = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;
            final fillBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Novo Evento Esportivo",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                "Crie uma prova e notifique todos os atletas",
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nome
                    _campoInput(
                      controller: nomeController,
                      label: "Nome do Evento",
                      hint: "Ex: Meia Maratona PaceMind",
                      icon: Icons.flag_rounded,
                      colors: colors,
                      fillBg: fillBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Local
                    _campoInput(
                      controller: localController,
                      label: "Local / Cidade",
                      hint: "Ex: Parque Ibirapuera - São Paulo, SP",
                      icon: Icons.location_on_rounded,
                      colors: colors,
                      fillBg: fillBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Distância KM
                    _campoInput(
                      controller: distanciaController,
                      label: "Distância (KM)",
                      hint: "Ex: 21",
                      icon: Icons.route_rounded,
                      isNumber: true,
                      colors: colors,
                      fillBg: fillBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Seletor de Data e Hora
                    GestureDetector(
                      onTap: () async {
                        final data = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2040),
                        );
                        if (data != null && context.mounted) {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 7, minute: 0),
                          );
                          if (hora != null) {
                            setModalState(() {
                              dataSelecionada = DateTime(
                                data.year,
                                data.month,
                                data.day,
                                hora.hour,
                                hora.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: fillBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: colors.primary),
                            const SizedBox(width: 14),
                            Text(
                              dataSelecionada == null
                                  ? "Selecionar data e hora do evento"
                                  : formatarData(dataSelecionada!.toIso8601String()),
                              style: TextStyle(
                                color: dataSelecionada == null
                                    ? colors.onSurfaceVariant
                                    : colors.onSurface,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Descrição
                    _campoInput(
                      controller: descricaoController,
                      label: "Descrição e Instruções",
                      hint: "Informações sobre trajeto, hidratação e retirada de kits...",
                      icon: Icons.description_rounded,
                      maxLines: 3,
                      colors: colors,
                      fillBg: fillBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 26),

                    // Botão Criar & Notificar Todos
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (nomeController.text.trim().isEmpty ||
                              localController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Preencha o nome e o local do evento")),
                            );
                            return;
                          }
                          if (dataSelecionada == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Selecione a data e hora do evento")),
                            );
                            return;
                          }

                          final dist = double.tryParse(
                                distanciaController.text.replaceAll(',', '.'),
                              ) ??
                              0;

                          Navigator.pop(context); // Fecha bottom sheet

                          mostrarCardAcao(
                            mensagem: "Criando evento e notificando todos os atletas...",
                            icone: Icons.campaign_rounded,
                            cor: const Color(0xFF0066FF),
                            loading: true,
                          );

                          try {
                            final nomeEv = nomeController.text.trim();
                            final localEv = localController.text.trim();
                            final dataIso = AppDateUtils.paraIsoLocal(dataSelecionada!);

                            await Api.criarEvento(
                              nome: nomeEv,
                              local: localEv,
                              distanciaKm: dist,
                              dataEvento: dataIso,
                              descricao: descricaoController.text.trim(),
                            );

                            // 📢 NOTIFICAÇÃO GLOBAL:
                            final tituloNotificacao = "🏃 Novo Evento Disponível: $nomeEv! 🏁";
                            final corpoNotificacao =
                                "Inscrições abertas! Venha encarar os ${dist.toStringAsFixed(0)} km em $localEv no dia ${formatarData(dataIso)}. Garanta já a sua vaga!";

                            // 1. Notificação no backend para todos os usuários
                            try {
                              await Api.criarNotificacao(
                                titulo: tituloNotificacao,
                                mensagem: corpoNotificacao,
                                tipo: "evento",
                              );
                            } catch (_) {}

                            // 2. Notificação local imediata no dispositivo
                            try {
                              await NotificacaoService.mostrarNotificacao(
                                titulo: tituloNotificacao,
                                corpo: corpoNotificacao,
                              );
                            } catch (_) {}

                            if (!mounted) return;
                            fecharCardAcao();

                            // 3. Exibir confirmação com estilo
                            _mostrarDialogoEventoCriadoComSucesso(nomeEv, dist);
                            carregarEventos();
                          } catch (e) {
                            if (!mounted) return;
                            fecharCardAcao();

                            mostrarCardAcao(
                              mensagem: "Erro ao criar evento. Tente novamente.",
                              icone: Icons.error_outline_rounded,
                              cor: Colors.redAccent,
                            );

                            await Future.delayed(const Duration(seconds: 2));
                            if (!mounted) return;
                            fecharCardAcao();
                          }
                        },
                        icon: const Icon(Icons.campaign_rounded),
                        label: const Text(
                          "Criar Evento e Notificar Todos",
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoEventoCriadoComSucesso(String nome, double dist) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.campaign_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                "Evento Criado com Sucesso!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "A notificação global foi transmitida com sucesso para toda a comunidade PaceMind sobre o evento \"$nome\". As inscrições já estão abertas!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void mostrarEditarEvento(dynamic evento) {
    final nomeController = TextEditingController(text: evento["nome"]);
    final localController = TextEditingController(text: evento["local"]);
    final distanciaController = TextEditingController(
      text: evento["distancia_km"]?.toString() ?? "0",
    );
    final descricaoController = TextEditingController(
      text: evento["descricao"] ?? "",
    );

    DateTime dataSelecionada = AppDateUtils.extrairDataPura(evento["data_evento"]) ??
        DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (editCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final colors = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;
            final fillBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.edit_calendar_rounded, color: Colors.orange, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Editar Evento",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _campoInput(
                      controller: nomeController,
                      label: "Nome",
                      hint: "Nome do evento",
                      icon: Icons.flag,
                      colors: colors,
                      fillBg: fillBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _campoInput(
                      controller: localController,
                      label: "Local",
                      hint: "Local",
                      icon: Icons.location_on,
                      colors: colors,
                      fillBg: fillBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _campoInput(
                      controller: distanciaController,
                      label: "Distância (KM)",
                      hint: "Ex: 21",
                      icon: Icons.route,
                      isNumber: true,
                      colors: colors,
                      fillBg: fillBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () async {
                        final data = await showDatePicker(
                          context: context,
                          initialDate: dataSelecionada,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2040),
                        );
                        if (data != null && context.mounted) {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dataSelecionada),
                          );
                          if (hora != null) {
                            setModalState(() {
                              dataSelecionada = DateTime(
                                data.year,
                                data.month,
                                data.day,
                                hora.hour,
                                hora.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: fillBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: colors.primary),
                            const SizedBox(width: 14),
                            Text(
                              formatarData(dataSelecionada.toIso8601String()),
                              style: TextStyle(color: colors.onSurface, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _campoInput(
                      controller: descricaoController,
                      label: "Descrição",
                      hint: "Descrição",
                      icon: Icons.description,
                      maxLines: 3,
                      colors: colors,
                      fillBg: fillBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          mostrarCardAcao(
                            mensagem: "Atualizando dados do evento...",
                            icone: Icons.hourglass_top,
                            cor: Colors.orange,
                            loading: true,
                          );

                          try {
                            final id = (evento["id_evento"] ?? evento["id"]).toString();
                            await Api.atualizarEvento(
                              id: id,
                              nome: nomeController.text.trim(),
                              local: localController.text.trim(),
                              distanciaKm: double.tryParse(
                                    distanciaController.text.replaceAll(',', '.'),
                                  ) ??
                                  0,
                              dataEvento: AppDateUtils.paraIsoLocal(dataSelecionada),
                              descricao: descricaoController.text.trim(),
                            );

                            if (!mounted) return;
                            fecharCardAcao();

                            mostrarCardAcao(
                              mensagem: "Evento atualizado com sucesso!",
                              icone: Icons.check_circle_outline_rounded,
                              cor: Colors.orange,
                            );

                            await Future.delayed(const Duration(seconds: 2));
                            if (!mounted) return;
                            fecharCardAcao();
                            carregarEventos();
                          } catch (e) {
                            if (!mounted) return;
                            fecharCardAcao();
                            mostrarCardAcao(
                              mensagem: "Erro ao atualizar evento.",
                              icone: Icons.error_outline_rounded,
                              cor: Colors.redAccent,
                            );
                            await Future.delayed(const Duration(seconds: 2));
                            if (!mounted) return;
                            fecharCardAcao();
                          }
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text("Salvar Alterações"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deletarEvento(dynamic evento) async {
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Deletar Evento?",
      message: "Essa ação removerá o evento \"${evento["nome"]}\" e cancelará as inscrições de todos os atletas.",
      confirmText: "Deletar",
      cancelText: "Cancelar",
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmar == true) {
      mostrarCardAcao(
        mensagem: "Excluindo evento...",
        icone: Icons.hourglass_top,
        cor: Colors.redAccent,
        loading: true,
      );

      try {
        final id = (evento["id_evento"] ?? evento["id"]).toString();
        await Api.deletarEvento(id);

        if (!mounted) return;
        fecharCardAcao();

        mostrarCardAcao(
          mensagem: "Evento excluído com sucesso.",
          icone: Icons.delete_outline_rounded,
          cor: Colors.redAccent,
        );

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        fecharCardAcao();
        carregarEventos();
      } catch (e) {
        if (!mounted) return;
        fecharCardAcao();

        mostrarCardAcao(
          mensagem: "Erro ao excluir evento.",
          icone: Icons.error_outline_rounded,
          cor: Colors.redAccent,
        );

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        fecharCardAcao();
      }
    }
  }

  Widget _campoInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colors,
    required Color fillBg,
    required bool isDark,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: colors.primary),
        hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: colors.primary),
        filled: true,
        fillColor: fillBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }

  List<dynamic> get eventosFiltrados {
    return eventos.where((e) {
      final id = (e["id_evento"] ?? e["id"]).toString();
      final dist = double.tryParse(e["distancia_km"]?.toString() ?? "0") ?? 0;

      if (filtroSelecionado == 1) {
        return usuarioInscrito(id);
      } else if (filtroSelecionado == 2) {
        return dist <= 5.5;
      } else if (filtroSelecionado == 3) {
        return dist > 5.5 && dist <= 10.5;
      } else if (filtroSelecionado == 4) {
        return dist > 10.5;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final totalEventos = eventos.length;
    final minhasInscricoesTotal = inscricoesUsuario.length;

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
              "Eventos & Provas",
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Desafios esportivos e corridas oficiais",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Recarregar",
            icon: Icon(Icons.refresh_rounded, color: colors.onSurface),
            onPressed: iniciarPagina,
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: mostrarCriarEvento,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Criar Evento", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : erroCarregamento != null
              ? _estadoErro()
              : RefreshIndicator(
                  onRefresh: iniciarPagina,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Header de estatísticas
                      _buildHeaderEventos(
                        total: totalEventos,
                        inscricoes: minhasInscricoesTotal,
                        colors: colors,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),

                      // Filtros por Categoria / Distância
                      _buildFiltrosEventos(colors, isDark),
                      const SizedBox(height: 18),

                      // Lista de Eventos
                      if (eventosFiltrados.isEmpty)
                        _buildEstadoVazio(colors, isDark)
                      else
                        ...eventosFiltrados.map((e) => _buildCardEvento(e, colors, isDark)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderEventos({
    required int total,
    required int inscricoes,
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
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF0066FF), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "$total",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        "Provas Abertas",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "$inscricoes",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        "Minhas Inscrições",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosEventos(ColorScheme colors, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chipFiltro("Todos (${eventos.length})", 0, colors, isDark),
          const SizedBox(width: 8),
          _chipFiltro("Minhas Inscrições (${inscricoesUsuario.length})", 1, colors, isDark),
          const SizedBox(width: 8),
          _chipFiltro("5 km", 2, colors, isDark),
          const SizedBox(width: 8),
          _chipFiltro("10 km", 3, colors, isDark),
          const SizedBox(width: 8),
          _chipFiltro("21 km+", 4, colors, isDark),
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
          color: selecionado ? Colors.white : colors.onSurface,
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

  Widget _buildCardEvento(dynamic evento, ColorScheme colors, bool isDark) {
    final idEvento = (evento["id_evento"] ?? evento["id"]).toString();
    final dist = double.tryParse(evento["distancia_km"]?.toString() ?? "0") ?? 0;
    final cor = corDistancia(dist);
    final bool inscrito = usuarioInscrito(idEvento);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: inscrito
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOPO: Badge Dia/Mês + Título + Badge Distância + Menu Admin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Calendário
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  formatarDiaMes(evento["data_evento"]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Nome e Local
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento["nome"] ?? "Evento Esportivo",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            evento["local"] ?? "Local a confirmar",
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tag Distância
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${dist.toStringAsFixed(0)} km",
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

              // Menu Admin
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: colors.surface,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: "inscritos",
                      child: Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text("Ver Inscritos"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "editar",
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text("Editar"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "deletar",
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text("Excluir", style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == "inscritos") {
                      mostrarInscritos(evento);
                    } else if (value == "editar") {
                      mostrarEditarEvento(evento);
                    } else if (value == "deletar") {
                      _deletarEvento(evento);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Data e Horário Completo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  formatarData(evento["data_evento"]),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Descrição do Evento
          Text(
            evento["descricao"] ?? "Prepare-se para mais uma corrida inesquecível.",
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
              height: 1.45,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),

          // Rodapé: Status de Inscrição e Botão de Ação
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: inscrito
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      inscrito ? Icons.check_circle_rounded : Icons.campaign_rounded,
                      size: 14,
                      color: inscrito ? const Color(0xFF10B981) : colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      inscrito ? "Inscrição Confirmada" : "Inscrições Abertas",
                      style: TextStyle(
                        color: inscrito ? const Color(0xFF10B981) : colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (inscrito)
                OutlinedButton.icon(
                  onPressed: () => cancelarInscricao(idEvento),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text("Cancelar"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => inscrever(idEvento),
                  icon: const Icon(Icons.directions_run_rounded, size: 18),
                  label: const Text("Participar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_rounded, size: 60, color: colors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              filtroSelecionado == 1
                  ? "Você ainda não está inscrito em eventos"
                  : "Nenhum evento encontrado",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filtroSelecionado == 1
                  ? "Explore a lista de provas abertas e garanta sua vaga para correr com a comunidade."
                  : "Novos desafios e provas serão adicionados em breve.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoErro() {
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
                iniciarPagina();
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
