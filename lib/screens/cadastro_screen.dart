import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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

  Future<void> cadastrar() async {
    // 🛑 VALIDAÇÃO ANTES DE TUDO
    if (nomeController.text.isEmpty ||
        emailController.text.isEmpty ||
        senhaController.text.isEmpty) {
      setState(() {
        erro = "Preencha todos os campos";
      });
      return;
    }
    if (!emailValidado) {
      setState(() {
        erro = "Valide seu email antes de continuar";
      });
      return;
    }

    setState(() {
      loading = true;
      erro = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://pacemind-api.vercel.app/usuarios/cadastro"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nomeController.text,
          "email": emailController.text,
          "senha": senhaController.text,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 201) {
        // 🔐 LOGIN AUTOMÁTICO
        final loginResponse = await http.post(
          Uri.parse("https://pacemind-api.vercel.app/usuarios/login"),

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

          if (!context.mounted) return;

          Navigator.pushReplacementNamed(context, "/home");
        } else {
          setState(() {
            erro = "Conta criada, mas falhou no login automático";
          });
        }
      } else {
        setState(() {
          erro = data["message"] ?? "Erro ao cadastrar";
        });
      }
    } catch (e) {
      setState(() {
        erro = "Erro de conexão";
      });
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> enviarCodigo() async {
    try {
      setState(() {
        enviandoCodigo = true;
      });
      print("EMAIL: ${emailController.text}");
      final response = await http.post(
        Uri.parse("https://pacemind-api.vercel.app/usuarios/otp/enviar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailController.text}),
      );
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          codigoEnviado = true;
          erro = null;
          enviandoCodigo = false;
        });

        iniciarContagem();

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Código enviado para seu email")),
        // );
      } else {
        setState(() {
          erro = data["message"];
          enviandoCodigo = false;
        });
      }
    } catch (e) {
      setState(() {
        enviandoCodigo = false;
        erro = "Erro ao enviar código";
      });
    }
  }

  Future<void> validarCodigo() async {
    try {
      setState(() {
        validandoCodigo = true;
      });

      final response = await http.post(
        Uri.parse("https://pacemind-api.vercel.app/usuarios/otp/verificar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "codigo": codigoController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          emailValidado = true;
          mostrarMensagemSucesso = true;
          validandoCodigo = false;
          codigoEnviado = false; // esconde a área do código
        });
        Future.delayed(const Duration(seconds: 4), () {
          if (!mounted) return;

          setState(() {
            mostrarMensagemSucesso = false;
          });
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Email validado com sucesso")),
        // );
      } else {
        setState(() {
          erro = data["message"];
          validandoCodigo = false;
        });
      }
    } catch (e) {
      setState(() {
        erro = "Erro ao validar código";
        validandoCodigo = false;
      });
    }
  }

  void iniciarContagem() {
    segundosRestantes = 300;

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosRestantes <= 0) {
        timer.cancel();

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
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

                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Image.asset(
                  "assets/images/logo.png",
                  width: 1000,

                  errorBuilder: (context, error, stackTrace) {
                    return const Text("❌ IMAGEM NÃO CARREGOU");
                  },
                ),
                const Text(
                  "Criar conta",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // 👤 NOME
                TextField(
                  controller: nomeController,

                  style: const TextStyle(color: Colors.black, fontSize: 20),

                  decoration: InputDecoration(
                    labelText: "Nome",

                    labelStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),

                    prefixIcon: const Icon(
                      Icons.person_rounded,
                      color: Colors.lightBlue,
                    ),

                    filled: true,
                    fillColor: Colors.grey.shade100,

                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.lightBlue,
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

                  style: const TextStyle(color: Colors.black, fontSize: 20),

                  decoration: InputDecoration(
                    labelText: "Email",

                    labelStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),

                    prefixIcon: const Icon(
                      Icons.email_rounded,
                      color: Colors.lightBlue,
                    ),

                    filled: true,
                    fillColor: Colors.grey.shade100,

                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.lightBlue,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (!codigoEnviado)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: enviandoCodigo ? null : enviarCodigo,
                      icon: const Icon(
                        Icons.mark_email_read,
                        color: Colors.white,
                      ),
                      label: enviandoCodigo
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.lightBlueAccent,
                              ),
                            )
                          : const Text("Enviar código"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                if (codigoEnviado) ...[
                  Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),

                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        TextField(
                          controller: codigoController,
                          keyboardType: TextInputType.number,

                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),

                          decoration: InputDecoration(
                            labelText: "Código recebido",

                            labelStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                            ),
                            prefixIcon: const Icon(
                              Icons.verified_user,
                              color: Colors.lightBlue,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.lightBlue,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.lightBlue,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          "Código expira em "
                          "${(segundosRestantes ~/ 60).toString().padLeft(2, '0')}:"
                          "${(segundosRestantes % 60).toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: validandoCodigo ? null : validarCodigo,
                            icon: const Icon(
                              Icons.verified,
                              color: Colors.greenAccent,
                            ),
                            label: validandoCodigo
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.lightBlueAccent,
                                    ),
                                  )
                                : const Text("Validar código"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Email verificado com sucesso",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
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

                  style: const TextStyle(color: Colors.black, fontSize: 20),

                  decoration: InputDecoration(
                    labelText: "Senha",

                    labelStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),

                    prefixIcon: const Icon(
                      Icons.lock_rounded,
                      color: Colors.lightBlue,
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

                        color: Colors.grey,
                      ),
                    ),

                    filled: true,
                    fillColor: Colors.grey.shade100,

                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.lightBlue,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (erro != null)
                  Text(erro!, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 16),

                // 🚀 BOTÃO
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (loading || !emailValidado) ? null : cadastrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.lightBlueAccent)
                        : Text(
                            emailValidado
                                ? "Cadastrar"
                                : "Verifique seu email primeiro",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: emailValidado
                                  ? Colors.white
                                  : Colors.black,
                            ),
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
