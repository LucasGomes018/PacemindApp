import 'package:flutter/material.dart';

class WeeklyGoalCard extends StatelessWidget {
  final double kmAtual;
  final double metaKm;

  const WeeklyGoalCard({
    super.key,
    required this.kmAtual,
    required this.metaKm,
  });

  @override
  Widget build(BuildContext context) {
    final metaSegura = metaKm <= 0 ? 30.0 : metaKm;
    final progresso = (kmAtual / metaSegura).clamp(0.0, 1.0);
    final porcentagem = (progresso * 100).round();
    final faltam = (metaSegura - kmAtual).clamp(0.0, metaSegura);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_rounded, color: Color(0xFF0066FF)),
              SizedBox(width: 8),
              Text(
                "Meta da Semana",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                "${kmAtual.toStringAsFixed(1)} km",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                "$porcentagem%",
                style: const TextStyle(
                  color: Color(0xFF0066FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progresso),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: animatedProgress,
                  minHeight: 12,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .10),
                  color: const Color(0xFF0066FF),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            "Meta: ${metaSegura.toStringAsFixed(1)} km",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            faltam <= 0
                ? "Meta atingida"
                : "Faltam ${faltam.toStringAsFixed(1)} km",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
