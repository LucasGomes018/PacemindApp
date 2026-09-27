import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../core/api.dart';
import '../components/app_snackbar.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final codigoController = TextEditingController();

  bool codigoEnviado = false;
  bool emailValidado = false;
  Timer? timer;

  int segundosRestantes = 300;
  bool enviandoCodigo = false;
  bool validandoCodigo = false;
  bool mostrarMensagemSucesso = false;

  bool loading = false;
  String? erro;
  bool mostrarSenha = false;

  @override
  void dispose() {
    timer?.cancel();
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    codigoController.dispose();
    super.dispose();
  }

  Future<void> cadastrar() async {
    // 🛑 VALIDAÇÃO ANTES DE TUDO
    if (nomeController.text.isEmpty ||
        emailController.text.isEmpty ||
        senhaController.text.isEmpty) {
      if (!mounted) return;
      setState(() {
        erro = "Preencha todos os campos";
      });
      AppSnackBar.aviso(context, "Preencha todos os campos obrigatórios");
      return;
    }
    if (!emailValidado) {
      if (!mounted) return;
      setState(() {
        erro = "Valide seu email antes de continuar";
      });
      AppSnackBar.aviso(context, "Valide seu e-mail com o código de 6 dígitos antes de prosseguir");
      return;
    }

    if (!mounted) return;
    setState(() {
      loading = true;
      erro = null;
    });

    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/usuarios/cadastro"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nomeController.text,
          "email": emailController.text,
          "senha": senhaController.text,
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 201) {
        // 🔐 LOGIN AUTOMÁTICO
        final loginResponse = await http.post(
          Uri.parse("${Api.baseUrl}/usuarios/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": emailController.text,
            "senha": senhaController.text,
          }),
        );

        final loginData = jsonDecode(loginResponse.body);

        if (loginResponse.statusCode == 200 && loginData["token"] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", loginData["token"]);

          if (!mounted) return;
          AppSnackBar.sucesso(context, "Cadastro realizado com sucesso! Bem-vindo ao PaceMind.");
          Navigator.pushReplacementNamed(context, "/home");
        } else {
          if (!mounted) return;
          setState(() {
            erro = "Conta criada, mas falhou no login automático";
          });
          AppSnackBar.aviso(context, "Conta criada! Faça login com seu email e senha.");
        }
      } else {
        if (!mounted) return;
        setState(() {
          erro = data["message"] ?? "Erro ao cadastrar";
        });
        AppSnackBar.erro(context, erro!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = "Erro de conexão";
      });
      AppSnackBar.erro(context, "Falha de conexão com o servidor");
    }

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  Future<void> enviarCodigo() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains("@")) {
      setState(() {
        erro = "Informe um e-mail válido";
      });
      AppSnackBar.aviso(context, "Informe um endereço de e-mail válido");
      return;
    }

    try {
      if (!mounted) return;
      setState(() {
        enviandoCodigo = true;
        erro = null;
      });
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/usuarios/otp/enviar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        // Sem preenchimento automático: campo limpo para o usuário digitar o código recebido no e-mail
        codigoController.clear();

        setState(() {
          codigoEnviado = true;
          erro = null;
          enviandoCodigo = false;
        });

        iniciarContagem();

        AppSnackBar.sucesso(
          context,
          "Código enviado com sucesso! Verifique sua caixa de entrada e spam.",
          titulo: "E-mail Enviado 📬",
          icon: Icons.mark_email_read_rounded,
          duracao: const Duration(seconds: 4),
        );
      } else {
        if (!mounted) return;
        setState(() {
          erro = data["message"] ?? "Erro ao enviar código";
          enviandoCodigo = false;
        });
        AppSnackBar.erro(
          context,
          erro!,
          titulo: "Falha no Envio",
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        enviandoCodigo = false;
        erro = "Erro ao enviar código";
      });
      AppSnackBar.erro(context, "Não foi possível conectar ao servidor de autenticação");
    }
  }

  Future<void> validarCodigo() async {
    final codigo = codigoController.text.trim();
    if (codigo.isEmpty) {
      AppSnackBar.aviso(context, "Digite o código de 6 dígitos recebido");
      return;
    }

    try {
      setState(() {
        validandoCodigo = true;
        erro = null;
      });

      final response = await http.post(
        Uri.parse("${Api.baseUrl}/usuarios/otp/verificar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "codigo": codigo,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          emailValidado = true;
          mostrarMensagemSucesso = true;
          validandoCodigo = false;
          codigoEnviado = false; // esconde a área do código
        });

        AppSnackBar.sucesso(context, "E-mail verificado com sucesso! Prossiga com o cadastro.");

        Future.delayed(const Duration(seconds: 4), () {
          if (!mounted) return;

          setState(() {
            mostrarMensagemSucesso = false;
          });
        });
      } else {
        if (!mounted) return;
        setState(() {
          erro = data["message"] ?? "Código inválido ou expirado";
          validandoCodigo = false;
        });
        AppSnackBar.erro(context, erro!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = "Erro ao validar código";
        validandoCodigo = false;
      });
      AppSnackBar.erro(context, "Falha de comunicação ao validar código");
    }
  }

  void iniciarContagem() {
    segundosRestantes = 300;

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosRestantes <= 0) {
        timer.cancel();

        if (!mounted) return;
        setState(() {
          codigoEnviado = false;
          codigoController.clear();
        });

        return;
      }

      setState(() {
        segundosRestantes--;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final fieldFill = isDark ? colors.surface : Colors.grey.shade100;
    final logoAsset = isDark
        ? "assets/images/logoLoginDark.png"
        : "assets/images/logoLogin2.png";

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Align(
                    alignment: Alignment.centerLeft,

                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, "/");
                      },

                      child: Container(
                        padding: const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),
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
                          return const Icon(
                            Icons.directions_run_rounded,
                            size: 92,
                            color: Colors.blue,
                          );
                        },
                      ),
                    ),
                  ),
                Text(
                  "Criar conta",
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Preencha seus dados para iniciar sua jornada",
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                // 👤 NOME
                TextField(
                  controller: nomeController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colors.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Nome",
                    labelStyle: TextStyle(
                      color: isDark ? colors.onSurfaceVariant : const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF0066FF),
                    ),
                    filled: true,
                    fillColor: fieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF0066FF),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 📧 EMAIL
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
                    prefixIcon: const Icon(
                      Icons.email_rounded,
                      color: Color(0xFF0066FF),
                    ),
                    filled: true,
                    fillColor: fieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF0066FF),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                if (!codigoEnviado)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: enviandoCodigo ? null : enviarCodigo,
                      icon: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: enviandoCodigo
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Enviar código de validação",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                if (codigoEnviado) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.4 : 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: codigoController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            labelText: "Código de Verificação",
                            labelStyle: TextStyle(
                              color: isDark ? colors.onSurfaceVariant : const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF0066FF),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF0066FF),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF0066FF)),
                            const SizedBox(width: 6),
                            Text(
                              "Código expira em ${(segundosRestantes ~/ 60).toString().padLeft(2, '0')}:${(segundosRestantes % 60).toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0066FF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: validandoCodigo ? null : validarCodigo,
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: validandoCodigo
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Validar código", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (mostrarMensagemSucesso) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Email verificado com sucesso!",
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 🔒 SENHA
                TextField(
                  controller: senhaController,
                  obscureText: !mostrarSenha,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: colors.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Senha",
                    labelStyle: TextStyle(
                      color: isDark ? colors.onSurfaceVariant : const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF0066FF),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          mostrarSenha = !mostrarSenha;
                        });
                      },
                      icon: Icon(
                        mostrarSenha
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                    filled: true,
                    fillColor: fieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF0066FF),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                if (erro != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            erro!,
                            style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 🚀 BOTÃO CADASTRAR
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (loading || !emailValidado) ? null : cadastrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            emailValidado
                                ? "Concluir Cadastro"
                                : "Verifique seu email para continuar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: emailValidado
                                  ? Colors.white
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
