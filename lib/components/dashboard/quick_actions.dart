import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback iniciarCorrida;
  final VoidCallback abrirTreinos;
  final VoidCallback atualizar;
  final VoidCallback? abrirMetas;

  const QuickActions({
    super.key,
    required this.iniciarCorrida,
    required this.abrirTreinos,
    required this.atualizar,
    this.abrirMetas,
  });

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : primaryColor.withValues(alpha: 0.15),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : primaryColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Ações Rápidas",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: Color(0xFF0066FF),
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Atalhos",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: _actionTile(
                    context: context,
                    icon: Icons.play_arrow_rounded,
                    title: "GPS",
                    gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                    primaryColor: const Color(0xFF10B981),
                    onTap: iniciarCorrida,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionTile(
                    context: context,
                    icon: Icons.calendar_month_rounded,
                    title: "Treinos",
                    gradientColors: const [Color(0xFF0066FF), Color(0xFF00C6FF)],
                    primaryColor: const Color(0xFF0066FF),
                    onTap: abrirTreinos,
                  ),
                ),
                if (abrirMetas != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionTile(
                      context: context,
                      icon: Icons.flag_rounded,
                      title: "Metas",
                      gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      primaryColor: const Color(0xFF8B5CF6),
                      onTap: abrirMetas!,
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: _actionTile(
                    context: context,
                    icon: Icons.sync_rounded,
                    title: "Sincronizar",
                    gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    primaryColor: const Color(0xFFF59E0B),
                    onTap: atualizar,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
