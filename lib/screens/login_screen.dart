import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool loading = false;
  String? erro;
  bool mostrarSenha = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      loading = true;
      erro = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://pacemind-api.vercel.app/usuarios/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "senha": senhaController.text,
        }),
      );

      if (response.body.isEmpty) {
        if (mounted) setState(() => erro = "Servidor não respondeu");
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["token"] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/home");
      } else if (mounted) {
        setState(() => erro = data["message"] ?? "Erro no login");
      }
    } catch (_) {
      if (mounted) setState(() => erro = "Erro de conexão");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final logoAsset = isDark
        ? "assets/images/logoLoginDark.png"
        : "assets/images/logoLogin2.png";
    final accent = isDark ? colors.secondary : Colors.lightBlue;
    final fieldFill = isDark ? colors.surface : Colors.grey.shade100;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    logoAsset,
                    key: ValueKey<String>(logoAsset),
                    width: 320,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.directions_run_rounded,
                        size: 92,
                        color: accent,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colors.onSurface, fontSize: 22),
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                    ),
                    prefixIcon: Icon(Icons.email_rounded, color: accent),
                    filled: true,
                    fillColor: fieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: senhaController,
                  obscureText: !mostrarSenha,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => loading ? null : login(),
                  style: TextStyle(color: colors.onSurface, fontSize: 22),
                  decoration: InputDecoration(
                    labelText: "Senha",
                    labelStyle: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                    ),
                    prefixIcon: Icon(Icons.lock_rounded, color: accent),
                    suffixIcon: IconButton(
                      tooltip: mostrarSenha ? "Ocultar senha" : "Mostrar senha",
                      onPressed: () =>
                          setState(() => mostrarSenha = !mostrarSenha),
                      icon: Icon(
                        mostrarSenha
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark ? colors.onSurfaceVariant : Colors.grey,
                      ),
                    ),
                    filled: true,
                    fillColor: fieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: erro == null
                      ? const SizedBox(height: 20)
                      : Text(
                          erro!,
                          key: ValueKey(erro),
                          style: TextStyle(color: colors.error),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? colors.primary
                          : Colors.lightBlueAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: loading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.blue,
                              ),
                            )
                          : const Text(
                              "Entrar",
                              key: ValueKey('enter'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, "/cadastro"),
                  child: Text(
                    "Criar conta",
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 1,
                      color: accent,
                      fontWeight: FontWeight.bold,
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
}
