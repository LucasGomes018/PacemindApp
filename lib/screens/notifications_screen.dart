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
  String? erroCarregamento;

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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Falha ao carregar notificações");
      }

      final data = jsonDecode(response.body);
      if (data is! List) throw Exception("Formato inválido");
      if (!mounted) return;

      setState(() {
        notificacoes = data;
        loading = false;
        erroCarregamento = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        erroCarregamento = "Não foi possível carregar as notificações.";
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

      case "evento":
        return Icons.campaign_rounded;

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

      case "evento":
        return const Color(0xFF8B5CF6);

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Notificações",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : erroCarregamento != null
          ? _estadoErro()
          : notificacoes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 70,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),

                  SizedBox(height: 16),

                  Text(
                    "Nenhuma notificação",
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: lida
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: .10),

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
                              color: pegarCor(
                                n["tipo"],
                              ).withValues(alpha: 0.12),

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

                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  n["mensagem"] ?? "",

                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  n["criado_em"] ?? "",

                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),

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

  Widget _estadoErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 12),
            Text(erroCarregamento!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  loading = true;
                  erroCarregamento = null;
                });
                carregarNotificacoes();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }
}
