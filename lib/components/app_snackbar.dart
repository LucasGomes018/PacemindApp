import 'package:flutter/material.dart';

enum AppSnackBarType {
  sucesso,
  treino,
  aviso,
  erro,
  info,
}

/// 🌟 COMPONENTE CENTRALIZADO E ULTRA-RESPONSIVO DE MENSAGENS FLUTUANTES (SNACKBAR / TOAST)
/// Garante design premium, gradientes dinâmicos, ícones estilizados e perfeita adaptação
/// para qualquer tamanho de tela (smartphones compactos, telas normais e tablets).
class AppSnackBar {
  /// 🟢 Exibe mensagem de sucesso (conclusões, cadastros, salvamentos)
  static void sucesso(
    BuildContext context,
    String mensagem, {
    String? titulo,
    Duration duracao = const Duration(seconds: 3),
    IconData icon = Icons.check_circle_rounded,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      mensagem: mensagem,
      titulo: titulo,
      tipo: AppSnackBarType.sucesso,
      duracao: duracao,
      icon: icon,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// 🏃 Exibe mensagem de treino / corrida (treino vinculado, retomado, metas de km)
  static void treino(
    BuildContext context,
    String mensagem, {
    String? titulo,
    Duration duracao = const Duration(seconds: 3),
    IconData icon = Icons.directions_run_rounded,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      mensagem: mensagem,
      titulo: titulo,
      tipo: AppSnackBarType.treino,
      duracao: duracao,
      icon: icon,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// 🟡 Exibe mensagem de aviso ou pausa (treino pausado, atenção, checagens)
  static void aviso(
    BuildContext context,
    String mensagem, {
    String? titulo,
    Duration duracao = const Duration(seconds: 3),
    IconData icon = Icons.pause_circle_filled_rounded,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      mensagem: mensagem,
      titulo: titulo,
      tipo: AppSnackBarType.aviso,
      duracao: duracao,
      icon: icon,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// 🔴 Exibe mensagem de erro ou falha
  static void erro(
    BuildContext context,
    String mensagem, {
    String? titulo,
    Duration duracao = const Duration(seconds: 4),
    IconData icon = Icons.error_outline_rounded,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      mensagem: mensagem,
      titulo: titulo,
      tipo: AppSnackBarType.erro,
      duracao: duracao,
      icon: icon,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// 🔵 Exibe mensagem informativa geral
  static void info(
    BuildContext context,
    String mensagem, {
    String? titulo,
    Duration duracao = const Duration(seconds: 3),
    IconData icon = Icons.info_outline_rounded,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      mensagem: mensagem,
      titulo: titulo,
      tipo: AppSnackBarType.info,
      duracao: duracao,
      icon: icon,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// 🚀 Método universal para disparar a SnackBar remodelada
  static void show(
    BuildContext context, {
    required String mensagem,
    String? titulo,
    AppSnackBarType tipo = AppSnackBarType.info,
    Duration duracao = const Duration(seconds: 3),
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final config = _obterConfiguracao(tipo, icon);

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        duration: duracao,
        dismissDirection: DismissDirection.horizontal,
        content: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                  minWidth: 280,
                ),
                child: GestureDetector(
                  onTap: () => messenger.hideCurrentSnackBar(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: config.gradiente,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: config.sombraCor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícone com badge translúcido de destaque
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          config.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Texto (Título + Mensagem com quebra automática responsiva)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (titulo != null && titulo.isNotEmpty) ...[
                              Text(
                                titulo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              mensagem,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: (titulo != null && titulo.isNotEmpty)
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                fontSize: 13,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botão de ação opcional (ex: "Desfazer", "Abrir")
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            messenger.hideCurrentSnackBar();
                            onAction();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static _SnackBarConfig _obterConfiguracao(AppSnackBarType tipo, IconData? customIcon) {
    switch (tipo) {
      case AppSnackBarType.sucesso:
        return _SnackBarConfig(
          gradiente: [
            const Color(0xFF047857), // Esmeralda escuro
            const Color(0xFF10B981), // Esmeralda vibrante
          ],
          sombraCor: const Color(0xFF10B981),
          icon: customIcon ?? Icons.check_circle_rounded,
        );

      case AppSnackBarType.treino:
        return _SnackBarConfig(
          gradiente: [
            const Color(0xFF0052CC), // PaceMind Blue profundo
            const Color(0xFF0066FF), // PaceMind Blue vibrante
            const Color(0xFF00A3FF), // Ciano atlético
          ],
          sombraCor: const Color(0xFF0066FF),
          icon: customIcon ?? Icons.directions_run_rounded,
        );

      case AppSnackBarType.aviso:
        return _SnackBarConfig(
          gradiente: [
            const Color(0xFFD97706), // Âmbar
            const Color(0xFFF59E0B), // Laranja
          ],
          sombraCor: const Color(0xFFF59E0B),
          icon: customIcon ?? Icons.pause_circle_filled_rounded,
        );

      case AppSnackBarType.erro:
        return _SnackBarConfig(
          gradiente: [
            const Color(0xFFB91C1C), // Vermelho escuro
            const Color(0xFFEF4444), // Vermelho vibrante
          ],
          sombraCor: const Color(0xFFEF4444),
          icon: customIcon ?? Icons.error_outline_rounded,
        );

      case AppSnackBarType.info:
        return _SnackBarConfig(
          gradiente: [
            const Color(0xFF334155), // Slate escuro
            const Color(0xFF1E293B), // Slate meia-noite
          ],
          sombraCor: const Color(0xFF0066FF),
          icon: customIcon ?? Icons.info_outline_rounded,
        );
    }
  }
}

class _SnackBarConfig {
  final List<Color> gradiente;
  final Color sombraCor;
  final IconData icon;

  const _SnackBarConfig({
    required this.gradiente,
    required this.sombraCor,
    required this.icon,
  });
}
