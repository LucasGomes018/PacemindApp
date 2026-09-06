import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../services/ia_treinador_service.dart';

class RecomendacoesPage extends StatefulWidget {
  const RecomendacoesPage({super.key});

  @override
  State<RecomendacoesPage> createState() => _RecomendacoesPageState();
}

class _RecomendacoesPageState extends State<RecomendacoesPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final IaTreinadorService _iaService = IaTreinadorService();

  final List<Map<String, dynamic>> _mensagens = [];

  bool _respondendo = false;
  bool _carregandoHistorico = true;
  String _statusDigitando = "PaceMind IA está digitando...";

  final List<String> _chipsRapidos = [
    "📊 Analisar meus dados",
    "⏱️ Como baixar meu pace?",
    "🛌 Devo descansar hoje?",
    "🎯 Minhas metas no app",
    "🏁 Dicas para provas",
    "🫁 Respiração e asma",
    "⚡ Overtraining e carga",
    "🥗 O que comer pré-treino?",
  ];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    _scrollController.dispose();
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
              "hora": item["criado_em"] ?? "",
            };
          })
          .where((item) => (item["texto"] as String).trim().isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _mensagens
          ..clear()
          ..addAll(mensagensChat);

        if (_mensagens.isEmpty) {
          _mensagens.add({
            "texto":
                "Olá! Eu sou a PaceMind IA, seu treinador inteligente de corrida e saúde. Estou conectado aos seus dados de treinos, pace e metas. Como posso te orientar hoje?",
            "usuario": false,
            "hora": "",
          });
        }
        _carregandoHistorico = false;
      });
      _rolarParaFim();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoHistorico = false;
        if (_mensagens.isEmpty) {
          _mensagens.add({
            "texto":
                "Olá! Eu sou a PaceMind IA. Analiso seus treinos, pace, recuperação e metas para apoiar sua evolução. O que você gostaria de explorar hoje?",
            "usuario": false,
            "hora": "",
          });
        }
      });
    }
  }

  Future<void> _enviarMensagem([String? sugestao]) async {
    final texto = (sugestao ?? _mensagemController.text).trim();
    if (texto.isEmpty || _respondendo || _carregandoHistorico) return;

    _mensagemController.clear();

    setState(() {
      _mensagens.add({"texto": texto, "usuario": true, "hora": ""});
      _respondendo = true;
      _statusDigitando = "PaceMind IA analisando dados...";
    });
    _rolarParaFim();

    // Salva mensagem do usuário no backend em background
    Api.salvarMensagemChat(mensagem: texto, enviadaPeloUsuario: true).catchError((_) {});

    // Processa a pergunta no motor de IA próprio
    final respostasSequenciais = await _iaService.processarPergunta(texto);

    if (!mounted) return;

    // Envia cada mensagem sequencialmente, dividindo como em uma conversa real
    for (int i = 0; i < respostasSequenciais.length; i++) {
      final msg = respostasSequenciais[i];

      setState(() {
        _statusDigitando = i == 0
            ? "PaceMind IA formulando resposta..."
            : "PaceMind IA digitando...";
      });

      // Pausa humanizada proporcional ao tamanho da mensagem
      final delayMs = (500 + (msg.length * 10)).clamp(750, 1400);
      await Future.delayed(Duration(milliseconds: delayMs));

      if (!mounted) return;

      setState(() {
        _mensagens.add({"texto": msg, "usuario": false, "hora": ""});
      });
      _rolarParaFim();

      // Salva cada bloco de resposta da IA
      Api.salvarMensagemChat(mensagem: msg, enviadaPeloUsuario: false).catchError((_) {});
    }

    if (!mounted) return;
    setState(() {
      _respondendo = false;
    });
    _rolarParaFim();
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? colors.surface : colors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "PaceMind IA",
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _respondendo ? _statusDigitando : "Seu apoio para treinar melhor",
                    style: TextStyle(
                      color: _respondendo ? colors.primary : colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Recarregar dados do atleta",
            icon: Icon(Icons.sync_rounded, color: colors.onSurfaceVariant),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Sincronizando dados esportivos mais recentes..."),
                  duration: Duration(seconds: 1),
                ),
              );
              await _iaService.obterContextoAtualizado(forcar: true);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _carregandoHistorico
                  ? Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: _mensagens.length + (_respondendo ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_respondendo && index == _mensagens.length) {
                          return _bolhaDigitando(colors, isDark);
                        }
                        final mensagem = _mensagens[index];
                        return _bolhaMensagem(
                          context,
                          texto: mensagem["texto"] as String,
                          usuario: mensagem["usuario"] as bool,
                          isDark: isDark,
                          colors: colors,
                        );
                      },
                    ),
            ),

            // Chips rápidos de sugestão
            if (!_respondendo && !_carregandoHistorico)
              _buildChipsSugestao(colors, isDark),

            // Campo de digitação
            _campoMensagem(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildChipsSugestao(ColorScheme colors, bool isDark) {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _chipsRapidos.length,
        itemBuilder: (context, index) {
          final sugestao = _chipsRapidos[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: isDark
                  ? colors.surface
                  : const Color(0xFFF1F5F9),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              label: Text(
                sugestao,
                style: TextStyle(
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0066FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _enviarMensagem(sugestao),
            ),
          );
        },
      ),
    );
  }

  Widget _bolhaMensagem(
    BuildContext context, {
    required String texto,
    required bool usuario,
    required bool isDark,
    required ColorScheme colors,
  }) {
    return Align(
      alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: usuario
              ? const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: usuario
              ? null
              : isDark
                  ? colors.surface
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: usuario ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: usuario ? const Radius.circular(4) : const Radius.circular(20),
          ),
          border: usuario
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SelectableText(
          texto,
          style: TextStyle(
            color: usuario
                ? Colors.white
                : colors.onSurface,
            fontSize: 14.5,
            height: 1.45,
            fontWeight: usuario ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _bolhaDigitando(ColorScheme colors, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Color(0xFF0066FF),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _statusDigitando,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ],
        ),
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
                controller: _mensagemController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviarMensagem(),
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
              onPressed: _respondendo ? null : () => _enviarMensagem(),
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
