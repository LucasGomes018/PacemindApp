import 'package:flutter/material.dart';

class WeeklyGoalCard extends StatelessWidget {
  final double kmAtual;
  final double? metaKm;
  final dynamic meta;
  final VoidCallback? onCriarMeta;
  final VoidCallback? onVerMetas;

  const WeeklyGoalCard({
    super.key,
    required this.kmAtual,
    this.metaKm,
    this.meta,
    this.onCriarMeta,
    this.onVerMetas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool temMeta = meta != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 14,
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
              "Meta:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Color(0xFF0066FF),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Nenhuma meta criada",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Defina seu objetivo semanal de corrida para acompanhar seus treinos e quilômetros em tempo real.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCriarMeta,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    "Criar Meta",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
    final titulo = meta["titulo"]?.toString() ?? "Meta da Semana";
    final tipo = (meta["tipo"]?.toString().toLowerCase() ?? "km");
    final objetivo = double.tryParse(meta["objetivo"]?.toString() ?? "30") ?? 30.0;
    final objetivoSeguro = objetivo <= 0 ? 30.0 : objetivo;

    // A meta já pega a quilometragem dos treinos se for do tipo 'km'
    final progressoSalvo = double.tryParse(meta["progresso"]?.toString() ?? "0") ?? 0.0;
    final double progressoEfetivo = (tipo == "km")
        ? (kmAtual > progressoSalvo ? kmAtual : progressoSalvo)
        : progressoSalvo;

    final progressoNormalizado = (progressoEfetivo / objetivoSeguro).clamp(0.0, 1.0);
    final porcentagem = (progressoNormalizado * 100).round();
    final faltam = (objetivoSeguro - progressoEfetivo).clamp(0.0, objetivoSeguro);
    final bool concluida = meta["concluida"] == true || faltam <= 0;

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

    return InkWell(
      onTap: onVerMetas,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tipo.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0066FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                formatarValor(progressoEfetivo),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                "$porcentagem%",
                style: TextStyle(
                  color: concluida ? const Color(0xFF10B981) : const Color(0xFF0066FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progressoNormalizado),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: animatedProgress,
                  minHeight: 12,
                  backgroundColor: colors.onSurface.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    concluida ? const Color(0xFF10B981) : const Color(0xFF0066FF),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Objetivo: ${formatarValor(objetivoSeguro)}",
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    concluida
                        ? "🎉 Meta atingida!"
                        : "Faltam ${formatarValor(faltam)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: concluida ? const Color(0xFF10B981) : colors.onSurface,
                      fontSize: 13,
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
