import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api.dart';

class RecomendacoesPage extends StatefulWidget {
  const RecomendacoesPage({super.key});

  @override
  State<RecomendacoesPage> createState() => _RecomendacoesPageState();
}

class _RecomendacoesPageState extends State<RecomendacoesPage> {
  final mensagemController = TextEditingController();
  final scrollController = ScrollController();
  final mensagens = <Map<String, dynamic>>[];

  bool respondendo = false;
  bool carregandoHistorico = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void dispose() {
    mensagemController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    try {
      final historico = await Api.listarMensagensChat();
      final mensagensChat = historico
          .where(
            (item) =>
                item["tipo"] == "chat_usuario" || item["tipo"] == "chat_ia",
          )
          .toList()
          .reversed
          .map<Map<String, dynamic>>((item) {
            return {
              "texto": item["mensagem"]?.toString() ?? "",
              "usuario": item["tipo"] == "chat_usuario",
            };
          })
          .where((item) => (item["texto"] as String).isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        mensagens
          ..clear()
          ..addAll(mensagensChat);
        if (mensagens.isEmpty) {
          mensagens.add({
            "texto":
                "Oi! Eu sou a PaceMind IA. Posso ajudar com seus treinos, pace, recuperação e metas. O que você quer entender hoje?",
            "usuario": false,
          });
        }
        carregandoHistorico = false;
      });
      _rolarParaFim();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        carregandoHistorico = false;
        if (mensagens.isEmpty) {
          mensagens.add({
            "texto":
                "Oi! Eu sou a PaceMind IA. Posso ajudar com seus treinos, pace, recuperação e metas. O que você quer entender hoje?",
            "usuario": false,
          });
        }
      });
    }
  }

  Future<void> enviarMensagem([String? sugestao]) async {
    final texto = (sugestao ?? mensagemController.text).trim();
    if (texto.isEmpty || respondendo || carregandoHistorico) return;

    mensagemController.clear();
    setState(() {
      mensagens.add({"texto": texto, "usuario": true});
      respondendo = true;
    });
    _rolarParaFim();

    try {
      await Api.salvarMensagemChat(mensagem: texto, enviadaPeloUsuario: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A pergunta não pôde ser salva.")),
        );
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    final resposta = _responder(texto);
    setState(() {
      mensagens.add({"texto": resposta, "usuario": false});
      respondendo = false;
    });
    _rolarParaFim();

    try {
      await Api.salvarMensagemChat(
        mensagem: resposta,
        enviadaPeloUsuario: false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A resposta não pôde ser salva.")),
        );
      }
    }
  }

  String _responder(String pergunta) {
    final texto = pergunta.toLowerCase();

    if (texto.contains("pace") || texto.contains("ritmo")) {
      return "Para controlar o pace, comece mais confortável e evite acelerar nos primeiros minutos. Use um ritmo em que consiga falar frases curtas sem perder o controle da respiração.";
    }
    if (texto.contains("treino") || texto.contains("correr")) {
      return "Uma boa semana combina treinos leves, um estímulo de qualidade e descanso. Aumente volume ou intensidade gradualmente e observe como seu corpo responde.";
    }
    if (texto.contains("descanso") ||
        texto.contains("recuper") ||
        texto.contains("dor")) {
      return "Recuperação faz parte do treino. Priorize sono, hidratação e intensidade leve. Se a dor for forte, persistente ou mudar sua passada, interrompa o treino e procure um profissional de saúde.";
    }
    if (texto.contains("meta") ||
        texto.contains("quilometr") ||
        texto.contains("km")) {
      return "Divida sua meta semanal em sessões possíveis e deixe margem para descanso. Consistência ao longo das semanas costuma ser mais importante do que buscar um grande volume em poucos dias.";
    }
    if (texto.contains("frequência") ||
        texto.contains("cardíaca") ||
        texto.contains("batimento")) {
      return "A frequência cardíaca ajuda a perceber o esforço, mas deve ser interpretada junto com pace, terreno e sensação corporal. Em treinos leves, mantenha esforço controlado e constante.";
    }

    return "Posso ajudar a interpretar seu pace, organizar a semana, pensar em recuperação ou acompanhar uma meta. Tente perguntar, por exemplo: ‘como melhorar meu ritmo?’";
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PaceMind IA",
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Seu apoio para treinar melhor",
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              itemCount: mensagens.length + (respondendo ? 1 : 0),
              itemBuilder: (context, index) {
                if (respondendo && index == mensagens.length) {
                  return _bolhaDigitando(colors);
                }
                final mensagem = mensagens[index];
                return _bolha(
                  context,
                  mensagem["texto"] as String,
                  mensagem["usuario"] as bool,
                  index,
                );
              },
            ),
          ),
          if (mensagens.length <= 1 && !respondendo && !carregandoHistorico)
            _sugestoes(context, colors),
          _campoMensagem(context, colors),
        ],
      ),
    );
  }

  Widget _bolha(BuildContext context, String texto, bool usuario, int index) {
    final colors = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(usuario ? 16 * (1 - value) : -16 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * .82,
          ),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: usuario ? colors.primary : colors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(usuario ? 20 : 5),
              bottomRight: Radius.circular(usuario ? 5 : 20),
            ),
            border: usuario
                ? null
                : Border.all(color: colors.onSurface.withValues(alpha: .08)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: .06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            texto,
            style: TextStyle(
              color: usuario ? colors.onPrimary : colors.onSurface,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bolhaDigitando(ColorScheme colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(5),
          ),
          border: Border.all(color: colors.onSurface.withValues(alpha: .08)),
        ),
        child: SizedBox(
          width: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (index) => CircleAvatar(
                radius: 3,
                backgroundColor: colors.primary.withValues(alpha: .55),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sugestoes(BuildContext context, ColorScheme colors) {
    const sugestoes = [
      "Como melhorar meu pace?",
      "Preciso de mais descanso?",
      "Como organizar minha semana?",
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: sugestoes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            avatar: Icon(Icons.bolt_rounded, size: 16, color: colors.primary),
            label: Text(sugestoes[index]),
            labelStyle: TextStyle(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: colors.surface,
            side: BorderSide(color: colors.onSurface.withValues(alpha: .10)),
            onPressed: () => enviarMensagem(sugestoes[index]),
          );
        },
      ),
    );
  }

  Widget _campoMensagem(BuildContext context, ColorScheme colors) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: mensagemController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => enviarMensagem(),
                decoration: InputDecoration(
                  hintText: "Pergunte sobre seus treinos...",
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: colors.onSurface.withValues(alpha: .10),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: colors.onSurface.withValues(alpha: .10),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: "Enviar mensagem",
              onPressed: respondendo ? null : enviarMensagem,
              icon: const Icon(Icons.arrow_upward_rounded),
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size(50, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
