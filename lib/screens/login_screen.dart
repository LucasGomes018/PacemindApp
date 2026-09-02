import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shared_preferences/shared_preferences.dart';

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

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.body.isEmpty) {
        setState(() {
          erro = "Servidor não respondeu";
        });
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["token"] != null) {
        final token = data["token"];

        print("TOKEN: $token");

        // 💾 Salvando token no SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);

        if (!context.mounted) return;

        Navigator.pushReplacementNamed(context, "/home");
      } else {
        setState(() {
          erro = data["message"] ?? "Erro no login";
        });
      }
    } catch (e) {
      print("ERRO: $e");

      setState(() {
        erro = "Erro de conexão";
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/logo.png",
                width: 1000,

                errorBuilder: (context, error, stackTrace) {
                  return const Text("❌ IMAGEM NÃO CARREGOU");
                },
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.black, fontSize: 22),

                decoration: InputDecoration(
                  labelText: "Email",

                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
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

              const SizedBox(height: 16),

              TextField(
                controller: senhaController,

                obscureText: !mostrarSenha,

                style: const TextStyle(color: Colors.black, fontSize: 22),

                decoration: InputDecoration(
                  labelText: "Senha",

                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
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
                      ? const CircularProgressIndicator(color: Colors.blue)
                      : const Text(
                          "Entrar",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/cadastro");
                },
                child: const Text(
                  "Criar conta",
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 1,
                    color: Colors.lightBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
