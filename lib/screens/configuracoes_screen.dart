import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/api.dart'; // Assumindo que este caminho está correto
import 'package:provider/provider.dart';
import '../core/theme_provider.dart';
import '../core/theme.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPage();
}

class _ConfiguracoesPage extends State<ConfiguracoesPage> {
  bool notificacoes = true;
  bool gpsSegundoPlano = true;

  // Cores personalizadas para o tema do aplicativo (Branco e Azul)
  static const Color primaryBlue = Color(
    0xFF007AFF,
  ); // Azul principal, vibrante e moderno
  static const Color lightBlue = Color(
    0xFFEBF5FF,
  ); // Azul muito claro para fundos sutis
  static const Color darkBlue = Color(
    0xFF1A237E,
  ); // Azul escuro para textos e ícones importantes
  static const Color textColor = Color(
    0xFF212529,
  ); // Cor de texto principal (quase preto)
  static const Color lightTextColor = Color(
    0xFF6C757D,
  ); // Cor de texto secundário (cinza médio)
  static const Color errorRed = Color(
    0xFFDC3545,
  ); // Vermelho para ações de erro/logout

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _logout() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: errorRed),
              const SizedBox(width: 10),
              Text(
                "Sair da conta",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Tem certeza que deseja sair da sua conta?\n\nSerá necessário fazer login novamente.",
            style: TextStyle(height: 1.4, color: lightTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: primaryBlue),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text("Sair"),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (sair != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
  }

  Future<void> _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      notificacoes = prefs.getBool("notificacoes") ?? true;
      gpsSegundoPlano = prefs.getBool("gpsSegundoPlano") ?? true;
    });
  }

  Future<void> _salvarNotificacoes(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notificacoes", valor);

    setState(() {
      notificacoes = valor;
    });
  }

  Future<void> _salvarGPS(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("gpsSegundoPlano", valor);

    setState(() {
      gpsSegundoPlano = valor;
    });
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

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: primaryBlue.withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: primaryBlue,
                            size: 36,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          "Alterar senha",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Sua nova senha deve ser segura e diferente da anterior.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 28),

                        TextFormField(
                          controller: atualController,
                          obscureText: !verAtual,
                          decoration: InputDecoration(
                            labelText: "Senha atual",
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),

                            hintText: "Digite sua senha",
                            hintStyle: TextStyle(color: Colors.grey.shade400),

                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF0066FF),
                            ),

                            suffixIcon: IconButton(
                              icon: Icon(
                                verAtual
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  verAtual = !verAtual;
                                });
                              },
                            ),

                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.2,
                              ),
                            ),

                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(18),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF0066FF),
                                width: 2,
                              ),
                            ),

                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.8,
                              ),
                            ),

                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B), // Cor do texto digitado
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
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: "Nova senha",
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),

                            hintText: "Digite sua nova senha",
                            hintStyle: TextStyle(color: Colors.grey.shade400),

                            prefixIcon: const Icon(
                              Icons.password_rounded,
                              color: Color(0xFF0066FF),
                            ),

                            suffixIcon: IconButton(
                              icon: Icon(
                                verNova
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  verNova = !verNova;
                                });
                              },
                            ),

                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.2,
                              ),
                            ),

                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(18),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF0066FF),
                                width: 2,
                              ),
                            ),

                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.8,
                              ),
                            ),

                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
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
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),

                            hintText: "Confirme sua nova senha",
                            hintStyle: TextStyle(color: Colors.grey.shade400),

                            prefixIcon: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF0066FF),
                            ),

                            suffixIcon: IconButton(
                              icon: Icon(
                                verConfirmar
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  verConfirmar = !verConfirmar;
                                });
                              },
                            ),

                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.2,
                              ),
                            ),

                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(18),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF0066FF),
                                width: 2,
                              ),
                            ),

                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.8,
                              ),
                            ),

                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
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
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: Color(0xFF0066FF),
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  "Cancelar",
                                  style: TextStyle(color: Color(0xFF0066FF)),
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

                                        setState(() {
                                          carregando = true;
                                        });

                                        try {
                                          await Api.alterarSenha(
                                            senhaAtual: atualController.text
                                                .trim(),
                                            novaSenha: novaController.text
                                                .trim(),
                                          );

                                          if (!mounted) return;

                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Senha alterada com sucesso!",
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          setState(() {
                                            carregando = false;
                                          });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String texto) {
    final customTheme = Theme.of(context).extension<AppCustomTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = customTheme?.sectionTitle ??
        (isDark ? const Color(0xFF64B5F6) : darkBlue);

    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 32, bottom: 12),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: sectionTitleColor,
        ),
        child: Text(texto),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customTheme = Theme.of(context).extension<AppCustomTheme>();
    final cardBg = customTheme?.cardBackground ?? Theme.of(context).cardColor;
    final cardShadow = customTheme?.cardShadow ??
        (isDark ? const Color(0x4D000000) : const Color(0x14000000));
    final avatarBg = customTheme?.avatarBackground ??
        (isDark ? const Color(0xFF1E3A8A) : lightBlue);
    final avatarIconColor = customTheme?.avatarIcon ??
        (isDark ? const Color(0xFF60A5FA) : primaryBlue);
    final txtColor = Theme.of(context).colorScheme.onSurface;
    final subColor = customTheme?.subtitleText ??
        (isDark ? const Color(0xFF94A3B8) : lightTextColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<Color?>(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      tween: ColorTween(end: avatarIconColor),
                      builder: (context, color, _) {
                        return Icon(
                          icon,
                          color: color,
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: txtColor,
                        ),
                        child: Text(title),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            style: TextStyle(fontSize: 13, color: subColor),
                            child: Text(subtitle),
                          ),
                        ),
                    ],
                  ),
                ),
                trailing ??
                    TweenAnimationBuilder<Color?>(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      tween: ColorTween(end: subColor),
                      builder: (context, color, _) => Icon(
                        Icons.chevron_right_rounded,
                        color: color,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
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
    final customTheme = Theme.of(context).extension<AppCustomTheme>();
    final cardBg = customTheme?.cardBackground ?? Theme.of(context).cardColor;
    final cardShadow = customTheme?.cardShadow ??
        (isDark ? const Color(0x4D000000) : const Color(0x14000000));
    final avatarBg = customTheme?.avatarBackground ??
        (isDark ? const Color(0xFF1E3A8A) : lightBlue);
    final avatarIconColor = customTheme?.avatarIcon ??
        (isDark ? const Color(0xFF60A5FA) : primaryBlue);
    final txtColor = Theme.of(context).colorScheme.onSurface;
    final subColor = customTheme?.subtitleText ??
        (isDark ? const Color(0xFF94A3B8) : lightTextColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        activeThumbColor: primaryBlue,
        inactiveThumbColor: isDark
            ? Colors.grey.shade600
            : Colors.grey.shade300,
        inactiveTrackColor: isDark
            ? Colors.grey.shade800
            : Colors.grey.shade200,
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: txtColor,
          ),
          child: Text(title),
        ),
        subtitle: subtitle == null
            ? null
            : AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                style: TextStyle(fontSize: 13, color: subColor),
                child: Text(subtitle),
              ),
        secondary: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              tween: ColorTween(end: avatarIconColor),
              builder: (context, color, _) {
                return Icon(
                  icon,
                  color: color,
                  size: 24,
                );
              },
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildThemeSettingsItem() {
    final isDark = context.watch<ThemeProvider>().darkMode;
    final customTheme = Theme.of(context).extension<AppCustomTheme>();
    final cardBg = customTheme?.cardBackground ?? Theme.of(context).cardColor;
    final cardShadow = customTheme?.cardShadow ??
        (isDark ? const Color(0x4D000000) : const Color(0x14000000));
    final avatarBg = customTheme?.avatarBackground ??
        (isDark ? const Color(0xFF1E3A8A) : lightBlue);
    final txtColor = Theme.of(context).colorScheme.onSurface;
    final subColor = customTheme?.subtitleText ??
        (isDark ? const Color(0xFF94A3B8) : lightTextColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                key: ValueKey<bool>(isDark),
                color: isDark ? Colors.amberAccent : Colors.orange,
                size: 24,
              ),
            ),
          ),
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: txtColor,
          ),
          child: const Text("Tema Escuro"),
        ),
        subtitle: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            isDark ? "Modo escuro ativado" : "Modo claro ativado",
            key: ValueKey<bool>(isDark),
            style: TextStyle(fontSize: 13, color: subColor),
          ),
        ),
        trailing: _SmoothDayNightSwitch(
          isDark: isDark,
          onChanged: (value) {
            context.read<ThemeProvider>().alterarTema(value);
          },
        ),
        onTap: () {
          context.read<ThemeProvider>().alterarTema(!isDark);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Configurações",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionTitle("Conta"),
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: "Editar perfil",
          ),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: "Alterar senha",
            onTap: _alterarSenhaDialog,
          ),
          _buildSettingsItem(
            icon: Icons.camera_alt_outlined,
            title: "Trocar foto",
          ),

          _buildSectionTitle("Treinos"),
          _buildSettingsItem(
            icon: Icons.flag_outlined,
            title: "Meta semanal",
            subtitle: "30 km",
          ),
          _buildSettingsItem(
            icon: Icons.straighten,
            title: "Unidade",
            subtitle: "Quilômetros",
          ),

          _buildSectionTitle("Localização"),
          _buildSwitchSettingsItem(
            icon: Icons.location_on_outlined,
            title: "GPS em segundo plano",
            value: gpsSegundoPlano,
            onChanged: _salvarGPS,
          ),

          _buildSectionTitle("Notificações"),
          _buildSwitchSettingsItem(
            icon: Icons.notifications_none,
            title: "Receber notificações",
            subtitle: "Receba lembretes de treinos e avisos importantes",
            value: notificacoes,
            onChanged: _salvarNotificacoes,
          ),

          _buildSectionTitle("Aparência"),
          _buildThemeSettingsItem(),

          _buildSectionTitle("PaceMind AI"),
          _buildSettingsItem(
            icon: Icons.smart_toy_outlined,
            title: "Limpar histórico da IA",
          ),
          _buildSettingsItem(
            icon: Icons.psychology_outlined,
            title: "Modelo da IA",
            subtitle: "Treinador",
          ),

          _buildSectionTitle("Dados"),
          _buildSettingsItem(
            icon: Icons.download_outlined,
            title: "Exportar treinos",
          ),
          _buildSettingsItem(icon: Icons.backup_outlined, title: "Backup"),

          _buildSectionTitle("Sobre"),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: "Versão",
            subtitle: "1.0.0",
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: "Política de Privacidade",
          ),
          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: "Termos de Uso",
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: errorRed, // Vermelho para ação de logout
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 3, // Sutil elevação para o botão
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 24),
              label: const Text("Sair da conta"),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SmoothDayNightSwitch extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SmoothDayNightSwitch({
    required this.isDark,
    required this.onChanged,
  });

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
