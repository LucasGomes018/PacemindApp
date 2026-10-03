import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/api.dart'; // Assumindo que este caminho está correto
import 'package:provider/provider.dart';
import '../core/theme_provider.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';
import '../screens/perfil_screen.dart';
import '../services/auto_notificacao_service.dart';
import '../services/background_tracking_service.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPage();
}

class _ConfiguracoesPage extends State<ConfiguracoesPage> {
  bool notificacoes = true;
  bool gpsSegundoPlano = true;
  bool _limpandoHistorico = false;
  double? metaSemanalKm;

  // Cores personalizadas para o tema do aplicativo (Branco e Azul)
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color errorRed = Color(0xFFDC3545);

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _logout() async {
    final sair = await AppModal.showConfirmDialog(
      context: context,
      title: "Sair da conta",
      message:
          "Tem certeza que deseja sair da sua conta?\nSerá necessário fazer login novamente.",
      confirmText: "Sair",
      cancelText: "Cancelar",
      icon: Icons.logout_rounded,
      iconColor: errorRed,
      confirmButtonColor: errorRed,
      isDestructive: true,
    );

    if (sair != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
  }

  Future<void> _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      notificacoes = prefs.getBool("notificacoes") ?? true;
      gpsSegundoPlano = prefs.getBool("gpsSegundoPlano") ?? true;
      metaSemanalKm = prefs.getDouble("metaSemanalKmCache");
    });

    try {
      final perfil = await Api.getProfile();
      final meta = double.tryParse(
        perfil["objetivo_semanal_km"]?.toString() ?? "",
      );
      if (meta != null && meta > 0) {
        await prefs.setDouble("metaSemanalKmCache", meta);
        if (mounted) setState(() => metaSemanalKm = meta);
      }
    } catch (_) {}
  }

  Future<void> _salvarNotificacoes(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notificacoes", valor);

    if (mounted) setState(() => notificacoes = valor);

    try {
      await AutoNotificacaoService.atualizarPreferencia(valor);
    } catch (e) {
      await prefs.setBool("notificacoes", !valor);
      if (!mounted) return;
      setState(() => notificacoes = !valor);
      AppSnackBar.erro(
        context,
        "Não foi possível atualizar as notificações.",
        titulo: "Preferência não salva",
      );
    }
  }

  Future<void> _salvarGPS(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("gpsSegundoPlano", valor);

    if (!valor) {
      await BackgroundTrackingService.stop();
    } else if (prefs.getBool("corrida_ativa") == true) {
      final idCorrida = prefs.getInt("id_corrida_ativa");
      if (idCorrida != null) await BackgroundTrackingService.start(idCorrida);
    }

    if (mounted) setState(() => gpsSegundoPlano = valor);
  }

  Future<void> _editarMetaSemanal() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> perfil = {};
    try {
      perfil = await Api.getProfile();
    } catch (_) {}
    if (!mounted) return;
    final valorAtual =
        double.tryParse(perfil["objetivo_semanal_km"]?.toString() ?? "") ??
        metaSemanalKm;
    var valorDigitado = valorAtual?.toStringAsFixed(1) ?? "";
    String? erro;

    final novaMeta = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Meta semanal"),
          content: TextFormField(
            initialValue: valorDigitado,
            onChanged: (value) => valorDigitado = value,
            decoration: InputDecoration(
              labelText: "Distância semanal",
              suffixText: "km",
              errorText: erro,
            ),
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () {
                final valor = double.tryParse(
                  valorDigitado.trim().replaceAll(",", "."),
                );
                if (valor == null || valor <= 0 || valor > 500) {
                  setDialogState(
                    () => erro = "Informe um valor entre 0 e 500 km",
                  );
                  return;
                }
                Navigator.pop(dialogContext, valor);
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
    if (novaMeta == null) return;

    try {
      await Api.atualizarPerfil(objetivo: novaMeta);
      await prefs.setDouble("metaSemanalKmCache", novaMeta);
      if (!mounted) return;
      setState(() => metaSemanalKm = novaMeta);
      AppSnackBar.sucesso(
        context,
        "Meta semanal atualizada para ${novaMeta.toStringAsFixed(1)} km.",
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.erro(
        context,
        e.toString().replaceAll("Exception: ", ""),
        titulo: "Erro ao salvar meta",
      );
    }
  }

  Future<void> _limparHistoricoIa() async {
    final confirmado = await AppModal.showConfirmDialog(
      context: context,
      title: "Limpar histórico da IA",
      message: "As mensagens da conversa serão excluídas permanentemente.",
      confirmText: "Limpar histórico",
      cancelText: "Cancelar",
      icon: Icons.delete_outline_rounded,
      iconColor: errorRed,
      confirmButtonColor: errorRed,
      isDestructive: true,
    );
    if (confirmado != true) return;

    setState(() => _limpandoHistorico = true);
    try {
      final historico = await Api.listarMensagensChat();
      final mensagens = historico.where((item) {
        return item["tipo"] == "chat_usuario" || item["tipo"] == "chat_ia";
      });
      var excluidas = 0;
      for (final item in mensagens) {
        final id = item["id_recomendacao"]?.toString();
        if (id == null || id.isEmpty) continue;
        await Api.deletarRecomendacao(id);
        excluidas++;
      }

      if (!mounted) return;
      AppSnackBar.sucesso(
        context,
        excluidas == 0
            ? "O histórico já está vazio."
            : "$excluidas mensagens removidas.",
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.erro(
        context,
        e.toString().replaceAll("Exception: ", ""),
        titulo: "Não foi possível limpar o histórico",
      );
    } finally {
      if (mounted) setState(() => _limpandoHistorico = false);
    }
  }

  void _abrirPerfil({bool editar = false, bool foto = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfilePage(abrirEditorInicial: editar, abrirFotoInicial: foto),
      ),
    );
  }

  Future<void> _alterarSenhaDialog() async {
    final formKey = GlobalKey<FormState>();

    final atualController = TextEditingController();
    final novaController = TextEditingController();
    final confirmarController = TextEditingController();

    bool verAtual = false;
    bool verNova = false;
    bool verConfirmar = false;
    bool carregando = false;

    String forcaSenha(String senha) {
      if (senha.length < 6) return "Fraca";
      if (senha.length < 10) return "Média";
      return "Forte";
    }

    Color corForca(String senha) {
      if (senha.length < 6) return Colors.red;
      if (senha.length < 10) return Colors.orange;
      return Colors.green;
    }

    await AppModal.showBottomSheet(
      context: context,
      title: "Alterar senha",
      subtitle: "Sua nova senha deve ser segura e diferente da anterior.",
      icon: Icons.lock_reset_rounded,
      iconColor: const Color(0xFF0066FF),
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      builder: (sheetContext, scrollController) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final isDark = Theme.of(modalContext).brightness == Brightness.dark;
            final textColor = Theme.of(modalContext).colorScheme.onSurface;
            final subTextColor = isDark
                ? const Color(0xFF94A3B8)
                : Colors.grey.shade600;
            final inputBg = isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC);
            final borderColor = isDark
                ? const Color(0xFF334155)
                : Colors.grey.shade300;
            final hintColor = isDark
                ? const Color(0xFF64748B)
                : Colors.grey.shade400;

            return Form(
              key: formKey,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                children: [
                  TextFormField(
                    controller: atualController,
                    obscureText: !verAtual,
                    decoration: InputDecoration(
                      labelText: "Senha atual",
                      labelStyle: TextStyle(
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: "Digite sua senha",
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF0066FF),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          verAtual
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: subTextColor,
                        ),
                        onPressed: () {
                          setModalState(() {
                            verAtual = !verAtual;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor, width: 1.2),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: Color(0xFF0066FF),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.8,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    cursorColor: const Color(0xFF0066FF),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Informe sua senha atual";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    controller: novaController,
                    obscureText: !verNova,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      labelText: "Nova senha",
                      labelStyle: TextStyle(
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: "Digite sua nova senha",
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: const Icon(
                        Icons.password_rounded,
                        color: Color(0xFF0066FF),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          verNova
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: subTextColor,
                        ),
                        onPressed: () {
                          setModalState(() {
                            verNova = !verNova;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor, width: 1.2),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: Color(0xFF0066FF),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.8,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    cursorColor: const Color(0xFF0066FF),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Digite uma nova senha";
                      }
                      if (v.length < 6) {
                        return "Mínimo de 6 caracteres";
                      }
                      return null;
                    },
                  ),

                  if (novaController.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Força: ${forcaSenha(novaController.text)}",
                        style: TextStyle(
                          color: corForca(novaController.text),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  TextFormField(
                    controller: confirmarController,
                    obscureText: !verConfirmar,
                    decoration: InputDecoration(
                      labelText: "Confirmar senha",
                      labelStyle: TextStyle(
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: "Confirme sua nova senha",
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF0066FF),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          verConfirmar
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: subTextColor,
                        ),
                        onPressed: () {
                          setModalState(() {
                            verConfirmar = !verConfirmar;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor, width: 1.2),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: Color(0xFF0066FF),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.8,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    cursorColor: const Color(0xFF0066FF),
                    validator: (v) {
                      if (v != novaController.text) {
                        return "As senhas não coincidem";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: carregando
                              ? null
                              : () => Navigator.pop(modalContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFF0066FF)),
                            ),
                          ),
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(
                              color: Color(0xFF0066FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: carregando
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setModalState(() {
                                    carregando = true;
                                  });

                                  try {
                                    await Api.alterarSenha(
                                      senhaAtual: atualController.text.trim(),
                                      novaSenha: novaController.text.trim(),
                                    );

                                    if (!modalContext.mounted) return;
                                    Navigator.pop(modalContext);

                                    if (!mounted) return;
                                    AppSnackBar.sucesso(
                                      context,
                                      "Sua senha foi alterada com sucesso.",
                                      titulo: "Senha Atualizada",
                                    );
                                  } catch (e) {
                                    if (modalContext.mounted) {
                                      setModalState(() {
                                        carregando = false;
                                      });

                                      AppSnackBar.erro(
                                        modalContext,
                                        e.toString().replaceAll(
                                          "Exception: ",
                                          "",
                                        ),
                                        titulo: "Erro ao Alterar Senha",
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: carregando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Salvar",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 22, bottom: 9),
      child: Text(
        texto,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(title),
        Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.65)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 66,
                    endIndent: 14,
                    color: theme.dividerColor.withValues(alpha: 0.65),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final colors = Theme.of(context).colorScheme;
    final activeTrailing =
        trailing ??
        (onTap == null
            ? null
            : Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
              ));

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      minLeadingWidth: 40,
      horizontalTitleGap: 12,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.primary, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: activeTrailing,
    );
  }

  Widget _buildSwitchSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = context.watch<ThemeProvider>().darkMode;
    final colors = Theme.of(context).colorScheme;

    return SwitchListTile(
      activeThumbColor: primaryBlue,
      inactiveThumbColor: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
      inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.primary, size: 21),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    );
  }

  Widget _buildThemeSettingsItem() {
    final isDark = context.watch<ThemeProvider>().darkMode;
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Icon(
            isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            key: ValueKey<bool>(isDark),
            color: isDark ? Colors.amber : Colors.orange,
            size: 21,
          ),
        ),
      ),
      title: const Text(
        "Tema escuro",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(isDark ? "Ativado" : "Desativado"),
      trailing: Semantics(
        button: true,
        label: "Tema escuro",
        value: isDark ? "Ativado" : "Desativado",
        child: _SmoothDayNightSwitch(
          isDark: isDark,
          onChanged: (value) =>
              context.read<ThemeProvider>().alterarTema(value),
        ),
      ),
      onTap: () => context.read<ThemeProvider>().alterarTema(!isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Configurações",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700 ? 24.0 : 16.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                28,
              ),
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSettingsGroup(
                          title: "Conta",
                          children: [
                            _buildSettingsItem(
                              icon: Icons.person_outline_rounded,
                              title: "Editar perfil",
                              onTap: () => _abrirPerfil(editar: true),
                            ),
                            _buildSettingsItem(
                              icon: Icons.lock_outline_rounded,
                              title: "Alterar senha",
                              onTap: _alterarSenhaDialog,
                            ),
                            _buildSettingsItem(
                              icon: Icons.camera_alt_outlined,
                              title: "Trocar foto",
                              onTap: () => _abrirPerfil(foto: true),
                            ),
                          ],
                        ),
                        _buildSettingsGroup(
                          title: "Treinos",
                          children: [
                            _buildSettingsItem(
                              icon: Icons.flag_outlined,
                              title: "Meta semanal",
                              subtitle: metaSemanalKm == null
                                  ? "Definir objetivo de distância"
                                  : "${metaSemanalKm!.toStringAsFixed(1)} km por semana",
                              onTap: _editarMetaSemanal,
                            ),
                          ],
                        ),
                        _buildSettingsGroup(
                          title: "Aplicativo",
                          children: [
                            _buildSwitchSettingsItem(
                              icon: Icons.location_on_outlined,
                              title: "GPS em segundo plano",
                              subtitle:
                                  "Manter o registro durante uma corrida com o app minimizado",
                              value: gpsSegundoPlano,
                              onChanged: _salvarGPS,
                            ),
                            _buildSwitchSettingsItem(
                              icon: Icons.notifications_none_rounded,
                              title: "Receber notificações",
                              subtitle: "Lembretes e avisos no dispositivo",
                              value: notificacoes,
                              onChanged: _salvarNotificacoes,
                            ),
                            _buildThemeSettingsItem(),
                          ],
                        ),
                        _buildSettingsGroup(
                          title: "PaceMind IA",
                          children: [
                            _buildSettingsItem(
                              icon: Icons.smart_toy_outlined,
                              title: "Abrir treinador",
                              subtitle: "Conversar com a PaceMind IA",
                              onTap: () => Navigator.pushNamed(
                                context,
                                "/recomendacoes",
                              ),
                            ),
                            _buildSettingsItem(
                              icon: Icons.delete_outline_rounded,
                              title: "Limpar histórico",
                              subtitle: "Excluir mensagens salvas da conversa",
                              onTap: _limpandoHistorico
                                  ? null
                                  : _limparHistoricoIa,
                              trailing: _limpandoHistorico
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.delete_outline_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                            ),
                          ],
                        ),
                        _buildSettingsGroup(
                          title: "Dados e privacidade",
                          children: [
                            _buildSettingsItem(
                              icon: Icons.download_outlined,
                              title: "Exportar treinos e relatórios",
                              subtitle: "Gerar e compartilhar PDF",
                              onTap: () =>
                                  Navigator.pushNamed(context, "/relatorios"),
                            ),
                            _buildSettingsItem(
                              icon: Icons.privacy_tip_outlined,
                              title: "Política de privacidade",
                              onTap: () => Navigator.pushNamed(
                                context,
                                "/politica-privacidade",
                              ),
                            ),
                            _buildSettingsItem(
                              icon: Icons.description_outlined,
                              title: "Termos de uso",
                              onTap: () =>
                                  Navigator.pushNamed(context, "/termos-uso"),
                            ),
                            _buildSettingsItem(
                              icon: Icons.info_outline_rounded,
                              title: "Versão",
                              subtitle: "1.0.0",
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text("Sair da conta"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: errorRed,
                            side: BorderSide(
                              color: errorRed.withValues(alpha: 0.55),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SmoothDayNightSwitch extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SmoothDayNightSwitch({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: 66,
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)]
                : [const Color(0xFF60A5FA), const Color(0xFF38BDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                  : const Color(0xFF38BDF8).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutBack,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isDark
                        ? const Icon(
                            Icons.nightlight_round,
                            key: ValueKey("moon"),
                            size: 16,
                            color: Color(0xFF1E3A8A),
                          )
                        : const Icon(
                            Icons.wb_sunny_rounded,
                            key: ValueKey("sun"),
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
