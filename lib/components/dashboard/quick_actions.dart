import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback iniciarCorrida;
  final VoidCallback abrirTreinos;
  final VoidCallback atualizar;

  const QuickActions({
    super.key,
    required this.iniciarCorrida,
    required this.abrirTreinos,
    required this.atualizar,
  });

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.14),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar com Gradiente e Sombra
                Container(
                  width: 46,
                  height: 46,
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
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Título
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 3),

                // Subtítulo
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
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
                fontSize: 19,
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

        const SizedBox(height: 14),

        Row(
          children: [
            _actionCard(
              context: context,
              icon: Icons.play_arrow_rounded,
              title: "Corrida",
              subtitle: "Iniciar GPS",
              gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
              primaryColor: const Color(0xFF10B981),
              onTap: iniciarCorrida,
            ),

            const SizedBox(width: 12),

            _actionCard(
              context: context,
              icon: Icons.fitness_center_rounded,
              title: "Treinos",
              subtitle: "Minha rotina",
              gradientColors: const [Color(0xFF0066FF), Color(0xFF00C6FF)],
              primaryColor: const Color(0xFF0066FF),
              onTap: abrirTreinos,
            ),

            const SizedBox(width: 12),

            _actionCard(
              context: context,
              icon: Icons.sync_rounded,
              title: "Sincronizar",
              subtitle: "Atualizar dados",
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
              primaryColor: const Color(0xFFF59E0B),
              onTap: atualizar,
            ),
          ],
        ),
      ],
    );
  }
}
