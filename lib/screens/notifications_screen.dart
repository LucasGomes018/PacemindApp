import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List notificacoes = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarNotificacoes();
  }

  Future<String?> pegarToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("token");
  }

  Future<void> carregarNotificacoes() async {
    try {
      final token = await pegarToken();

      final response = await http.get(
        Uri.parse("https://pacemind-api.vercel.app/notificacoes"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);

      setState(() {
        notificacoes = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> marcarComoLida(String id) async {
    final token = await pegarToken();

    await http.patch(
      Uri.parse("https://pacemind-api.vercel.app/notificacoes/$id/lida"),
      headers: {"Authorization": "Bearer $token"},
    );

    carregarNotificacoes();
  }

  Future<void> deletarNotificacao(String id) async {
    final token = await pegarToken();

    await http.delete(
      Uri.parse("https://pacemind-api.vercel.app/notificacoes/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    carregarNotificacoes();
  }

  IconData pegarIcone(String? tipo) {
    switch (tipo) {
      case "treino":
        return Icons.directions_run;

      case "meta":
        return Icons.emoji_events;

      case "alerta":
        return Icons.warning_amber_rounded;

      default:
        return Icons.notifications;
    }
  }

  Color pegarCor(String? tipo) {
    switch (tipo) {
      case "treino":
        return Colors.blue;

      case "meta":
        return Colors.green;

      case "alerta":
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,

        title: const Text(
          "Notificações",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator( color: Colors.lightBlueAccent ))
          : notificacoes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 70, color: Colors.grey),

                  SizedBox(height: 16),

                  Text(
                    "Nenhuma notificação",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: carregarNotificacoes,

              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notificacoes.length,

                itemBuilder: (context, index) {
                  final n = notificacoes[index];

                  final bool lida = n["lida"] == true;

                  return GestureDetector(
                    onTap: () {
                      marcarComoLida(n["id_notificacao"]);
                    },

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),

                      margin: const EdgeInsets.only(bottom: 14),

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: lida ? Colors.white : const Color(0xFFEAF4FF),

                        borderRadius: BorderRadius.circular(22),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: pegarCor(n["tipo"]).withValues(alpha: 0.12),

                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              pegarIcone(n["tipo"]),
                              color: pegarCor(n["tipo"]),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  n["titulo"] ?? "",

                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: lida
                                        ? FontWeight.w500
                                        : FontWeight.bold,

                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  n["mensagem"] ?? "",

                                  style: const TextStyle(
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  n["criado_em"] ?? "",

                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Colors.black),

                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: "delete",
                                child: Text("Excluir"),
                              ),
                            ],

                            onSelected: (value) {
                              if (value == "delete") {
                                deletarNotificacao(n["id_notificacao"]);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
