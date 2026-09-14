import 'package:flutter/material.dart';

class WeeklyGoalCard extends StatelessWidget {
  final double kmAtual;
  final double? metaKm;
  final dynamic meta;
  final double? objetivoPerfilKm;
  final VoidCallback? onCriarMeta;
  final VoidCallback? onVerMetas;

  const WeeklyGoalCard({
    super.key,
    required this.kmAtual,
    this.metaKm,
    this.meta,
    this.objetivoPerfilKm,
    this.onCriarMeta,
    this.onVerMetas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool temMeta = meta != null || (objetivoPerfilKm != null && objetivoPerfilKm! > 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF0066FF).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: temMeta
          ? _buildComMeta(context, colors, isDark)
          : _buildSemMeta(context, colors, isDark),
    );
  }

  Widget _buildSemMeta(BuildContext context, ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flag_rounded, color: Color(0xFF0066FF), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  "Meta da Semana",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Pendente",
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Text(
                "Defina seu objetivo semanal de corrida para acompanhar seu volume e manter a disciplina.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCriarMeta,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text(
                    "Criar Meta da Semana",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Widget _buildComMeta(BuildContext context, ColorScheme colors, bool isDark) {
    // Extrai dados da meta ativa ou do fallback de perfil
    final String titulo = meta != null
        ? (meta["titulo"]?.toString() ?? "Meta da Semana")
        : "Objetivo Semanal";

    final String tipo = meta != null
        ? (meta["tipo"]?.toString().toLowerCase() ?? "km")
        : "km";

    double objetivo = 30.0;
    if (meta != null) {
      objetivo = double.tryParse(meta["objetivo"]?.toString() ?? "30") ?? 30.0;
    } else if (objetivoPerfilKm != null && objetivoPerfilKm! > 0) {
      objetivo = objetivoPerfilKm!;
    }
    if (objetivo <= 0) objetivo = 30.0;

    double progressoEfetivo = kmAtual;
    if (meta != null && tipo != "km") {
      progressoEfetivo = double.tryParse(meta["progresso"]?.toString() ?? "0") ?? 0.0;
    }

    final progressoNormalizado = (progressoEfetivo / objetivo).clamp(0.0, 1.0);
    final porcentagem = (progressoNormalizado * 100).round();
    final faltam = (objetivo - progressoEfetivo).clamp(0.0, objetivo);
    final bool concluida = progressoEfetivo >= objetivo || (meta != null && meta["concluida"] == true);

    String formatarValor(double v) {
      final f = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      switch (tipo) {
        case "km":
          return "$f km";
        case "tempo":
          return "$f min";
        case "treinos":
          return "$f treinos";
        default:
          return "$f $tipo";
      }
    }

    // Dias restantes na semana
    final agora = DateTime.now();
    final diasRestantes = (7 - agora.weekday) + 1; // contando com hoje
    final kmPorDiaRestante = diasRestantes > 0 ? (faltam / diasRestantes) : faltam;

    return InkWell(
      onTap: onVerMetas,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Meta
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: concluida
                        ? const [Color(0xFF10B981), Color(0xFF059669)]
                        : const [Color(0xFF0066FF), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (concluida ? const Color(0xFF10B981) : const Color(0xFF0066FF))
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  concluida ? Icons.emoji_events_rounded : Icons.flag_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      concluida
                          ? "🎉 Parabéns! Meta semanal superada"
                          : "Faltam ${formatarValor(faltam)} para atingir o objetivo",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: concluida
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (concluida ? const Color(0xFF10B981) : const Color(0xFF0066FF))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$porcentagem%",
                  style: TextStyle(
                    color: concluida ? const Color(0xFF10B981) : const Color(0xFF0066FF),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progresso animada com gradiente
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progressoNormalizado),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: animatedProgress.clamp(0.01, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: concluida
                              ? const [Color(0xFF10B981), Color(0xFF34D399)]
                              : const [Color(0xFF0066FF), Color(0xFF00C6FF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (concluida ? const Color(0xFF10B981) : const Color(0xFF0066FF))
                                .withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Rodapé do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${formatarValor(progressoEfetivo)} de ${formatarValor(objetivo)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!concluida && faltam > 0 && diasRestantes > 1)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "~${kmPorDiaRestante.toStringAsFixed(1)} km/dia restante",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
