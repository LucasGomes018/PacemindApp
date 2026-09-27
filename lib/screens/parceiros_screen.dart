import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';

class ParceirosPage extends StatefulWidget {
  const ParceirosPage({super.key});

  @override
  State<ParceirosPage> createState() => _ParceirosPageState();
}

class _ParceirosPageState extends State<ParceirosPage> {
  bool loading = true;
  bool isAdmin = false;
  String? erroCarregamento;
  List<dynamic> parceiros = [];
  String filtroEspecialidade = "Todos";
  String buscaQuery = "";
  final TextEditingController _buscaController = TextEditingController();

  final List<String> especialidades = [
    "Todos",
    "Cardiologia",
    "Nutrição",
    "Fisioterapia",
    "Pneumologia",
    "Treinadores",
    "Ortopedia",
  ];

  @override
  void initState() {
    super.initState();
    _carregarPerfilEParceiros();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfilEParceiros() async {
    setState(() {
      loading = true;
      erroCarregamento = null;
    });

    try {
      final me = await Api.me();
      isAdmin = me["tipo_usuario"] == "admin" || me["tipo"] == "admin";
    } catch (_) {}

    try {
      final data = await Api.listarParceiros();
      if (!mounted) return;
      setState(() {
        parceiros = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar a lista de especialistas.";
      });
    }
  }

  List<dynamic> get parceirosFiltrados {
    return parceiros.where((p) {
      final nome = (p["nome"]?.toString() ?? "").toLowerCase();
      final esp = (p["especialidade"]?.toString() ?? "").toLowerCase();
      final end = (p["endereco"]?.toString() ?? "").toLowerCase();

      bool matchFiltro = true;
      if (filtroEspecialidade != "Todos") {
        matchFiltro = esp.contains(filtroEspecialidade.toLowerCase());
      }

      final matchBusca = buscaQuery.isEmpty ||
          nome.contains(buscaQuery.toLowerCase()) ||
          esp.contains(buscaQuery.toLowerCase()) ||
          end.contains(buscaQuery.toLowerCase());

      return matchFiltro && matchBusca;
    }).toList();
  }

  void _copiarParaAreaTransferencia(String texto, String rotulo) {
    Clipboard.setData(ClipboardData(text: texto));
    AppSnackBar.sucesso(
      context,
      "$rotulo copiado para a área de transferência!",
      titulo: "Copiado 📋",
    );
  }

  Future<void> _abrirModalCriarEditar([Map<String, dynamic>? itemExistente]) async {
    final isEdicao = itemExistente != null;
    final nomeCtrl = TextEditingController(text: itemExistente?["nome"] ?? "");
    final espCtrl = TextEditingController(text: itemExistente?["especialidade"] ?? "");
    final formacaoCtrl = TextEditingController(text: itemExistente?["formacao"] ?? "");
    final telCtrl = TextEditingController(text: itemExistente?["telefone"] ?? "");
    final emailCtrl = TextEditingController(text: itemExistente?["email"] ?? "");
    final instaCtrl = TextEditingController(text: itemExistente?["instagram"] ?? "");
    final endCtrl = TextEditingController(text: itemExistente?["endereco"] ?? "");
    final obsCtrl = TextEditingController(text: itemExistente?["observacoes"] ?? "");

    await AppModal.showBottomSheet(
      context: context,
      title: isEdicao ? "Editar Parceiro" : "Novo Especialista Parceiro",
      icon: isEdicao ? Icons.edit_note_rounded : Icons.person_add_rounded,
      iconColor: const Color(0xFF10B981),
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final fillColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeCtrl,
                  decoration: InputDecoration(
                    labelText: "Nome Completo *",
                    hintText: "Ex: Dr. Roberto Alencar",
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: espCtrl,
                  decoration: InputDecoration(
                    labelText: "Especialidade *",
                    hintText: "Ex: Cardiologia Esportiva, Nutricionista",
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: formacaoCtrl,
                  decoration: InputDecoration(
                    labelText: "Formação / Registro",
                    hintText: "Ex: CRM 12345 / Especialista USP",
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: telCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Telefone / WhatsApp",
                          hintText: "(11) 98765-4321",
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: instaCtrl,
                        decoration: InputDecoration(
                          labelText: "Instagram",
                          hintText: "@dr.roberto",
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "E-mail de Contato",
                    hintText: "contato@clinica.com",
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endCtrl,
                  decoration: InputDecoration(
                    labelText: "Endereço / Consultório",
                    hintText: "Av. Paulista, 1000 - Cj 52",
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obsCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Observações / Descontos aos Alunos",
                    hintText: "Oferece 15% de desconto para atletas PaceMind...",
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingAction: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final nome = nomeCtrl.text.trim();
            final esp = espCtrl.text.trim();
            if (nome.isEmpty || esp.isEmpty) {
              AppSnackBar.aviso(
                context,
                "Preencha o nome e a especialidade do parceiro.",
                titulo: "Campos Obrigatórios",
              );
              return;
            }

            Navigator.pop(context);
            final dados = {
              "nome": nome,
              "especialidade": esp,
              "formacao": formacaoCtrl.text.trim(),
              "telefone": telCtrl.text.trim(),
              "email": emailCtrl.text.trim(),
              "instagram": instaCtrl.text.trim(),
              "endereco": endCtrl.text.trim(),
              "observacoes": obsCtrl.text.trim(),
            };

            try {
              if (isEdicao) {
                final id = (itemExistente["id_parceiro"] ?? itemExistente["id"]).toString();
                await Api.atualizarParceiro(id, dados);
              } else {
                await Api.criarParceiro(dados);
              }

              if (!mounted) return;
              AppSnackBar.sucesso(
                context,
                isEdicao ? "Dados do parceiro atualizados com sucesso!" : "Novo parceiro cadastrado com sucesso!",
                titulo: isEdicao ? "Atualizado 🤝" : "Cadastrado 🤝",
              );
              _carregarPerfilEParceiros();
            } catch (_) {
              if (!mounted) return;
              AppSnackBar.erro(
                context,
                "Erro ao salvar parceiro. Verifique suas permissões.",
                titulo: "Falha ao Salvar",
              );
            }
          },
          icon: const Icon(Icons.check_rounded, color: Colors.white),
          label: Text(
            isEdicao ? "Salvar Alterações" : "Cadastrar Parceiro",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(dynamic p) async {
    final nome = p["nome"]?.toString() ?? "Parceiro";
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Remover Parceiro?",
      message: "Tem certeza que deseja desativar \"$nome\" da rede de parceiros PaceMind?",
      confirmText: "Remover",
      cancelText: "Cancelar",
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      confirmButtonColor: const Color(0xFFEF4444),
      isDestructive: true,
    );

    if (confirmar == true) {
      try {
        final id = (p["id_parceiro"] ?? p["id"]).toString();
        await Api.deletarParceiro(id);
        if (!mounted) return;
        AppSnackBar.info(
          context,
          "Parceiro removido com sucesso.",
          titulo: "Removido",
        );
        _carregarPerfilEParceiros();
      } catch (_) {
        if (!mounted) return;
        AppSnackBar.erro(
          context,
          "Erro ao remover parceiro.",
          titulo: "Erro",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final lista = parceirosFiltrados;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Rede de Especialistas", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarPerfilEParceiros,
            tooltip: "Atualizar",
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _abrirModalCriarEditar(),
              backgroundColor: const Color(0xFF10B981),
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text("Novo Especialista", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _carregarPerfilEParceiros,
        color: const Color(0xFF10B981),
        child: Column(
          children: [
            // Banner explicativo
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x330D9488), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Parceiros Credenciados",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Especialistas em saúde, medicina esportiva e performance física conectados ao PaceMind.",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Barra de busca
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _buscaController,
                onChanged: (val) => setState(() => buscaQuery = val),
                decoration: InputDecoration(
                  hintText: "Buscar médico, nutricionista, fisioterapeuta...",
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

            // Filtro por especialidade
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: especialidades.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final e = especialidades[index];
                  final isSel = e == filtroEspecialidade;
                  return ChoiceChip(
                    label: Text(e),
                    selected: isSel,
                    onSelected: (_) => setState(() => filtroEspecialidade = e),
                    selectedColor: const Color(0xFF10B981),
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

            // Lista de Especialistas
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
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
                                  onPressed: _carregarPerfilEParceiros,
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
                                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF10B981)),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      buscaQuery.isNotEmpty || filtroEspecialidade != "Todos"
                                          ? "Nenhum profissional encontrado para os filtros."
                                          : "Nenhum parceiro cadastrado no momento.",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isAdmin
                                          ? "Como treinador/admin, clique abaixo para cadastrar especialistas credenciados."
                                          : "Novos médicos e especialistas esportivos serão adicionados em breve!",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: () => _abrirModalCriarEditar(),
                                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                                        label: const Text("Cadastrar Parceiro", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: lista.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final p = lista[index];
                                final nome = p["nome"] ?? "Profissional";
                                final esp = p["especialidade"] ?? "Saúde";
                                final formacao = p["formacao"]?.toString() ?? "";
                                final tel = p["telefone"]?.toString() ?? "";
                                final insta = p["instagram"]?.toString() ?? "";
                                final email = p["email"]?.toString() ?? "";
                                final endereco = p["endereco"]?.toString() ?? "";
                                final obs = p["observacoes"]?.toString() ?? "";

                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(22),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                                            child: Text(
                                              nome.isNotEmpty ? nome[0].toUpperCase() : "P",
                                              style: const TextStyle(
                                                color: Color(0xFF10B981),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nome,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    esp,
                                                    style: const TextStyle(
                                                      color: Color(0xFF0F766E),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                if (formacao.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    formacao,
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (isAdmin)
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert_rounded),
                                              onSelected: (val) {
                                                if (val == "editar") {
                                                  _abrirModalCriarEditar(p);
                                                } else if (val == "excluir") {
                                                  _confirmarExclusao(p);
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
                                                      Text("Remover", style: TextStyle(color: Color(0xFFEF4444))),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),

                                      if (endereco.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                endereco,
                                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      if (obs.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Text(
                                            obs,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 14),

                                      // Ações rápidas de contato
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (tel.isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () => _copiarParaAreaTransferencia(tel, "Telefone"),
                                              icon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF10B981)),
                                              label: Text(
                                                tel,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF10B981),
                                                side: const BorderSide(color: Color(0xFF10B981)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          if (insta.isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () => _copiarParaAreaTransferencia(insta, "Instagram"),
                                              icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFFEC4899)),
                                              label: Text(
                                                insta.startsWith('@') ? insta : '@$insta',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFFEC4899),
                                                side: const BorderSide(color: Color(0xFFEC4899)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          if (email.isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () => _copiarParaAreaTransferencia(email, "E-mail"),
                                              icon: const Icon(Icons.mail_outline_rounded, size: 16, color: Color(0xFF0066FF)),
                                              label: Text(
                                                email,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF0066FF),
                                                side: const BorderSide(color: Color(0xFF0066FF)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
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
