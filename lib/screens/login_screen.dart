import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

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
        Uri.parse("${Api.baseUrl}/usuarios/login"),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                          maxHeight: 180,
                        ),
                        child: Image.asset(
                          logoAsset,
                          key: ValueKey<String>(logoAsset),
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
                    ),
                    const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colors.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(
                      color: isDark ? colors.onSurfaceVariant : const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.email_rounded, color: accent),
                    filled: true,
                    fillColor: fieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
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
                  style: TextStyle(color: colors.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Senha",
                    labelStyle: TextStyle(
                      color: isDark ? colors.onSurfaceVariant : const Color(0xFF64748B),
                      fontSize: 14,
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
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: erro == null
                      ? const SizedBox(height: 12)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  erro!,
                                  key: ValueKey(erro),
                                  style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Entrar",
                              key: ValueKey('enter'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, "/cadastro"),
                  child: Text(
                    "Não tem uma conta? Cadastre-se",
                    style: TextStyle(
                      fontSize: 14,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
