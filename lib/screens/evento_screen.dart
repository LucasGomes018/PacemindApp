import 'package:flutter/material.dart';
import '/core/api.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  List eventos = [];
  bool loading = true;

  bool isAdmin = false;

  Map<String, String> inscricoesUsuario = {};

  bool carregandoAcao = false;

  String mensagemAcao = "";

  IconData iconeAcao = Icons.check_circle_outline_rounded;

  Color corAcao = Colors.green;

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
      builder: (_) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 270,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    loading
                        ? SizedBox(
                            width: 42,
                            height: 42,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: cor,
                            ),
                          )
                        : Icon(icone, size: 55, color: cor),

                    const SizedBox(height: 22),

                    Text(
                      mensagem,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
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

  Future<void> carregarPerfil() async {
    try {
      final usuario = await Api.me();

      setState(() {
        isAdmin = usuario["tipo_usuario"] == "admin";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao carregar inscritos")),
      );
    }
  }

  Future<void> carregarMinhasInscricoes() async {
    try {
      final response = await Api.minhasInscricoes();

      print("RESPOSTA API:");
      print(response);

      setState(() {
        inscricoesUsuario.clear();

        for (var item in response) {
          final idEvento = item["id_evento"].toString();
          final idInscricao = item["id_inscricao"].toString();

          inscricoesUsuario[idEvento] = idInscricao;
        }
      });

      print("MAPA FINAL:");
      print(inscricoesUsuario);
    } catch (e) {
      print("ERRO INSCRIÇÕES:");
      print(e);
    }
  }

  Future<void> carregarEventos() async {
    try {
      final data = await Api.listarEventos();

      setState(() {
        eventos = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  String formatarData(String? data) {
    if (data == null) return "-";

    final d = DateTime.parse(data).toLocal();

    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year} às "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

  Color corDistancia(double km) {
    if (km <= 5) return Colors.green;
    if (km <= 10) return Colors.orange;
    if (km <= 21) return Colors.deepPurple;
    return Colors.redAccent;
  }

  bool usuarioInscrito(String idEvento) {
    print("VERIFICANDO EVENTO:");
    print(idEvento);

    print("MAPA:");
    print(inscricoesUsuario);

    return inscricoesUsuario[idEvento] != null;
  }

  Future<void> inscrever(String idEvento) async {
    final jaInscrito = usuarioInscrito(idEvento);

    if (jaInscrito) return;

    mostrarCardAcao(
      mensagem: "Realizando inscrição...",
      icone: Icons.hourglass_top,
      cor: const Color(0xFF0066FF),
      loading: true,
    );

    try {
      await Api.inscreverEvento(idEvento: idEvento);

      await carregarMinhasInscricoes();

      if (!mounted) return;

      fecharCardAcao();

      mostrarCardAcao(
        mensagem: "Inscrição realizada com sucesso",
        icone: Icons.check_circle_outline_rounded,
        cor: Colors.green,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      fecharCardAcao();

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      fecharCardAcao();

      mostrarCardAcao(
        mensagem: "Erro ao realizar inscrição",
        icone: Icons.error,
        cor: Colors.red,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      fecharCardAcao();
    }
  }

  Future<void> cancelarInscricao(String idEvento) async {
    try {
      final idInscricao = inscricoesUsuario[idEvento];

      if (idInscricao == null) return;

      mostrarCardAcao(
        mensagem: "Cancelando inscrição...",
        icone: Icons.hourglass_top,
        cor: Colors.orange,
        loading: true,
      );

      await Api.cancelarInscricao(idInscricao);

      await carregarMinhasInscricoes();

      if (!mounted) return;

      fecharCardAcao();

      mostrarCardAcao(
        mensagem: "Inscrição cancelada",
        icone: Icons.check_circle_outline_rounded,
        cor: Colors.red,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      fecharCardAcao();

      setState(() {});
    } catch (e) {
      print(e);

      if (!mounted) return;

      fecharCardAcao();

      mostrarCardAcao(
        mensagem: "Erro ao cancelar inscrição",
        icone: Icons.error,
        cor: Colors.red,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      fecharCardAcao();
    }
  }

  void mostrarInscritos(dynamic evento) async {
    try {
      final data = await Api.listarInscricoes(evento["id_evento"].toString());

      final inscritos = data["inscritos"] as List;

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,

        builder: (_) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,

            padding: const EdgeInsets.all(24),

            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFD),

              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,

                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  evento["nome"],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "${data["total"]} inscritos",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: inscritos.isEmpty
                      ? const Center(
                          child: Text(
                            "Nenhum inscrito",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: inscritos.length,

                          itemBuilder: (_, index) {
                            final inscrito = inscritos[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),

                              padding: const EdgeInsets.all(16),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),

                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.blue.withValues(
                                      alpha: 0.1,
                                    ),

                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF0066FF),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(
                                          inscrito["nome_usuario"] ??
                                              "Sem nome",

                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          inscrito["email"] ?? "",

                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),

                                      borderRadius: BorderRadius.circular(30),
                                    ),

                                    child: Text(
                                      inscrito["status"],

                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao carregar inscritos")),
      );
    }
  }

  void mostrarEditarEvento(dynamic evento) {
    final nomeController = TextEditingController(text: evento["nome"]);

    final localController = TextEditingController(text: evento["local"]);

    final distanciaController = TextEditingController(
      text: evento["distancia_km"].toString(),
    );

    final descricaoController = TextEditingController(
      text: evento["descricao"],
    );

    DateTime dataSelecionada = DateTime.parse(evento["data_evento"]).toLocal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (_) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),

          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFD),

            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),

          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 5,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 24),

                const Row(
                  children: [
                    Icon(
                      Icons.edit_calendar_rounded,
                      color: Colors.orange,
                      size: 30,
                    ),

                    SizedBox(width: 10),

                    Text(
                      "Editar Evento",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _campo(
                  controller: nomeController,
                  label: "Nome",
                  icon: Icons.flag,
                ),

                const SizedBox(height: 16),

                _campo(
                  controller: localController,
                  label: "Local",
                  icon: Icons.location_on,
                ),

                const SizedBox(height: 16),

                _campo(
                  controller: distanciaController,
                  label: "Distância KM",
                  icon: Icons.route,
                  number: true,
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(3000),
                    );

                    if (data != null) {
                      final hora = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(dataSelecionada),
                      );

                      if (hora != null) {
                        setState(() {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF0066FF),
                        ),

                        const SizedBox(width: 14),

                        Text(
                          formatarData(dataSelecionada.toIso8601String()),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _campo(
                  controller: descricaoController,
                  label: "Descrição",
                  icon: Icons.description,
                  maxLines: 4,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        mostrarCardAcao(
                          mensagem: "Atualizando evento...",
                          icone: Icons.hourglass_top,
                          cor: Colors.orange,
                          loading: true,
                        );

                        await Api.atualizarEvento(
                          id: evento["id_evento"].toString(),

                          nome: nomeController.text,

                          local: localController.text,

                          distanciaKm:
                              double.tryParse(
                                distanciaController.text.replaceAll(",", "."),
                              ) ??
                              0,

                          dataEvento: dataSelecionada.toUtc().toIso8601String(),

                          descricao: descricaoController.text,
                        );

                        if (!mounted) return;

                        Navigator.pop(context); // fecha bottomsheet

                        fecharCardAcao();

                        mostrarCardAcao(
                          mensagem: "Evento atualizado",
                          icone: Icons.check_circle_outline_rounded,
                          cor: Colors.orange,
                        );

                        await Future.delayed(const Duration(seconds: 2));

                        if (!mounted) return;

                        fecharCardAcao();

                        carregarEventos();

                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text("Evento atualizado")),
                        // );
                      } catch (e) {
                        fecharCardAcao();

                        mostrarCardAcao(
                          mensagem: "Erro ao atualizar",
                          icone: Icons.error,
                          cor: Colors.red,
                        );

                        await Future.delayed(const Duration(seconds: 2));

                        if (!mounted) return;

                        fecharCardAcao();
                      }
                    },

                    icon: const Icon(Icons.save),

                    label: const Text("Salvar alterações"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,

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
  }

  void mostrarCriarEvento() {
    final nomeController = TextEditingController();
    final localController = TextEditingController();
    final distanciaController = TextEditingController();
    final descricaoController = TextEditingController();

    DateTime? dataSelecionada;
    TimeOfDay? horaSelecionada;

    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),

              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFD),

                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // 🔹 barrinha
                    Center(
                      child: Container(
                        width: 55,
                        height: 5,

                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,

                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // 🏁 TÍTULO
                    const Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFF0066FF),
                          size: 30,
                        ),

                        SizedBox(width: 10),

                        Text(
                          "Novo Evento",

                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Crie um novo evento esportivo para os atletas.",
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),

                    const SizedBox(height: 28),

                    // 📝 NOME
                    TextField(
                      controller: nomeController,

                      decoration: InputDecoration(
                        hintText: "Ex: Meia Maratona PaceMind",
                        labelText: "Nome do evento",

                        labelStyle: const TextStyle(color: Colors.blueAccent),

                        prefixIcon: const Icon(
                          Icons.flag_rounded,
                          color: Color(0xFF0066FF),
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 📍 LOCAL
                    TextField(
                      controller: localController,

                      decoration: InputDecoration(
                        hintText: "Ex: São Paulo - SP",
                        labelText: "Local",

                        labelStyle: const TextStyle(color: Colors.blueAccent),

                        prefixIcon: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF0066FF),
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 📏 DISTÂNCIA
                    TextField(
                      controller: distanciaController,
                      keyboardType: TextInputType.number,

                      decoration: InputDecoration(
                        hintText: "Ex: 21",
                        labelText: "Distância (KM)",

                        labelStyle: const TextStyle(color: Colors.blueAccent),

                        prefixIcon: const Icon(
                          Icons.route_rounded,
                          color: Color(0xFF0066FF),
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 📅 DATA
                    GestureDetector(
                      onTap: () async {
                        final data = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(3000),
                        );

                        if (data != null) {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (hora != null) {
                            final dataCompleta = DateTime(
                              data.year,
                              data.month,
                              data.day,
                              hora.hour,
                              hora.minute,
                            );

                            setModalState(() {
                              dataSelecionada = dataCompleta;
                              horaSelecionada = hora;
                            });
                          }
                        }
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF0066FF),
                            ),

                            const SizedBox(width: 14),
                            Text(
                              dataSelecionada == null
                                  ? "Selecionar data"
                                  : formatarData(
                                      dataSelecionada!.toIso8601String(),
                                    ),

                              style: TextStyle(
                                color: dataSelecionada == null
                                    ? Colors.grey
                                    : Colors.black87,

                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 📄 DESCRIÇÃO
                    TextField(
                      controller: descricaoController,
                      maxLines: 4,

                      decoration: InputDecoration(
                        hintText: "Descreva detalhes do evento...",
                        labelText: "Descrição",

                        labelStyle: const TextStyle(color: Colors.blueAccent),

                        alignLabelWithHint: true,

                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 70),
                          child: Icon(
                            Icons.description_rounded,
                            color: Color(0xFF0066FF),
                          ),
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 🚀 BOTÃO
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            if (dataSelecionada == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Selecione uma data"),
                                ),
                              );

                              return;
                            }

                            mostrarCardAcao(
                              mensagem: "Criando evento...",
                              icone: Icons.hourglass_top,
                              cor: const Color(0xFF0066FF),
                              loading: true,
                            );

                            await Api.criarEvento(
                              nome: nomeController.text,
                              local: localController.text,
                              distanciaKm:
                                  double.tryParse(
                                    distanciaController.text.replaceAll(
                                      ",",
                                      ".",
                                    ),
                                  ) ??
                                  0,
                              dataEvento: dataSelecionada!
                                  .toUtc()
                                  .toIso8601String(),
                              descricao: descricaoController.text,
                            );

                            if (!context.mounted) return;

                            // fecha loading
                            fecharCardAcao();

                            // fecha bottomsheet
                            Navigator.pop(pageContext);
                            // mostra sucesso
                            mostrarCardAcao(
                              mensagem: "Evento criado com sucesso",
                              icone: Icons.check_circle_outline_rounded,
                              cor: Colors.green,
                            );

                            await Future.delayed(const Duration(seconds: 2));

                            if (!mounted) return;

                            // fecha sucesso
                            fecharCardAcao();

                            await carregarEventos();

                            // ScaffoldMessenger.of(pageContext).showSnackBar(
                            //   const SnackBar(
                            //     content: Text("Evento criado com sucesso"),
                            //   ),
                            // );
                          } catch (e) {
                            print("ERRO:");
                            print(e);

                            fecharCardAcao();

                            mostrarCardAcao(
                              mensagem: "Erro ao criar evento",
                              icone: Icons.error,
                              cor: Colors.red,
                            );

                            await Future.delayed(const Duration(seconds: 2));

                            if (!mounted) return;

                            fecharCardAcao();
                          }
                        },

                        icon: const Icon(Icons.add_rounded),

                        label: const Text(
                          "Criar evento",

                          style: TextStyle(fontSize: 17),
                        ),

                        style: ElevatedButton.styleFrom(
                          elevation: 0,

                          backgroundColor: const Color(0xFF0066FF),

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 18),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0066FF),

              onPressed: mostrarCriarEvento,

              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Eventos",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.black87,
      ),

      body: RefreshIndicator(
        onRefresh: carregarEventos,
        child: eventos.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 250),

                  Center(
                    child: Text(
                      "Nenhum evento encontrado",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: eventos.length,
                itemBuilder: (context, index) {
                  final evento = eventos[index];

                  final distancia =
                      double.tryParse(evento["distancia_km"].toString()) ?? 0;

                  return GestureDetector(
                    onTap: isAdmin
                        ? () {
                            mostrarInscritos(evento);
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TOPO
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: corDistancia(
                                      distancia,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.flag,
                                    color: corDistancia(distancia),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        evento["nome"] ?? "",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        evento["local"] ?? "",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // INFOS
                            Row(
                              children: [
                                _infoChip(
                                  Icons.route,
                                  "${distancia.toStringAsFixed(0)} km",
                                  corDistancia(distancia),
                                ),

                                const SizedBox(width: 10),

                                _infoChip(
                                  Icons.calendar_month,
                                  formatarData(evento["data_evento"]),
                                  Colors.blue,
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            Text(
                              evento["descricao"] ?? "Sem descrição",
                              style: const TextStyle(
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 22),

                            Row(
                              children: [
                                // PARTICIPAR
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final inscrito = usuarioInscrito(
                                        evento["id_evento"].toString(),
                                      );

                                      if (inscrito) {
                                        cancelarInscricao(
                                          evento["id_evento"].toString(),
                                        );
                                      } else {
                                        inscrever(
                                          evento["id_evento"].toString(),
                                        );
                                      }
                                    },

                                    icon: Icon(
                                      usuarioInscrito(
                                            evento["id_evento"].toString(),
                                          )
                                          ? Icons.close
                                          : Icons.directions_run,
                                    ),

                                    label: Text(
                                      usuarioInscrito(
                                            evento["id_evento"].toString(),
                                          )
                                          ? "Cancelar inscrição"
                                          : "Participar",
                                    ),

                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,

                                      backgroundColor:
                                          usuarioInscrito(
                                            evento["id_evento"].toString(),
                                          )
                                          ? Colors.red
                                          : const Color(0xFF0066FF),

                                      foregroundColor: Colors.white,

                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),

                                if (isAdmin) ...[
                                  const SizedBox(width: 10),

                                  IconButton(
                                    onPressed: () {
                                      mostrarEditarEvento(evento);
                                    },

                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.orange
                                          .withValues(alpha: 0.12),
                                      padding: const EdgeInsets.all(14),
                                    ),

                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.orange,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  IconButton(
                                    onPressed: () async {
                                      final confirmar = await showDialog(
                                        context: context,
                                        barrierColor: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),

                                        builder: (_) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.all(24),

                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(28),
                                              ),

                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 70,
                                                    height: 70,

                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withValues(alpha: 0.1),
                                                      shape: BoxShape.circle,
                                                    ),

                                                    child: const Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color: Colors.red,
                                                      size: 38,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 22),

                                                  const Text(
                                                    "Deletar evento?",
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 12),

                                                  const Text(
                                                    "Essa ação não poderá ser desfeita.",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 15,
                                                      height: 1.5,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 28),

                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                              false,
                                                            );
                                                          },

                                                          style: OutlinedButton.styleFrom(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 16,
                                                                ),

                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                          ),

                                                          child: const Text(
                                                            "Cancelar",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      const SizedBox(width: 12),

                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                              true,
                                                            );
                                                          },

                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            foregroundColor:
                                                                Colors.white,

                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 16,
                                                                ),

                                                            elevation: 0,

                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                          ),

                                                          child: const Text(
                                                            "Deletar",
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );

                                      if (confirmar == true) {
                                        try {
                                          mostrarCardAcao(
                                            mensagem: "Deletando evento...",
                                            icone: Icons.hourglass_top,
                                            cor: Colors.red,
                                            loading: true,
                                          );

                                          await Api.deletarEvento(
                                            evento["id_evento"].toString(),
                                          );

                                          if (!mounted) return;

                                          fecharCardAcao();

                                          mostrarCardAcao(
                                            mensagem: "Evento deletado",
                                            icone: Icons.delete_outline_rounded,
                                            cor: Colors.red,
                                          );

                                          await Future.delayed(
                                            const Duration(seconds: 2),
                                          );

                                          if (!mounted) return;

                                          fecharCardAcao();

                                          carregarEventos();
                                        } catch (e) {
                                          if (!mounted) return;

                                          fecharCardAcao();

                                          mostrarCardAcao(
                                            mensagem: "Erro ao deletar",
                                            icone: Icons.error,
                                            cor: Colors.red,
                                          );

                                          await Future.delayed(
                                            const Duration(seconds: 2),
                                          );

                                          if (!mounted) return;

                                          fecharCardAcao();
                                        }
                                      }
                                    },

                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.withValues(
                                        alpha: 0.12,
                                      ),
                                      padding: const EdgeInsets.all(14),
                                    ),

                                    icon: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),

          const SizedBox(width: 6),

          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool number = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,

      style: const TextStyle(color: Colors.black),

      decoration: InputDecoration(
        labelText: label,

        labelStyle: const TextStyle(color: Colors.black87),

        hintStyle: const TextStyle(color: Colors.black54),

        prefixIcon: Icon(icon, color: const Color(0xFF0066FF)),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
