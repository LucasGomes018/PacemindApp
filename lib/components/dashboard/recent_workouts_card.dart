import 'package:flutter/material.dart';
import '../../utils/date_utils.dart';

class RecentWorkoutsCard extends StatelessWidget {
  final List treinos;
  final VoidCallback? onVerTodos;
  final Function(dynamic treino)? onTreinoTap;

  const RecentWorkoutsCard({
    super.key,
    required this.treinos,
    this.onVerTodos,
    this.onTreinoTap,
  });

  IconData _icon(String tipo) {
    final normalized = tipo.toLowerCase();
    if (normalized.contains("corrida") || normalized.contains("run")) return Icons.directions_run_rounded;
    if (normalized.contains("bike") || normalized.contains("cicl")) return Icons.directions_bike_rounded;
    if (normalized.contains("caminhada") || normalized.contains("walk")) return Icons.directions_walk_rounded;
    if (normalized.contains("muscul") || normalized.contains("força")) return Icons.fitness_center_rounded;
    return Icons.sports_score_rounded;
  }

  Color _color(String tipo) {
    final normalized = tipo.toLowerCase();
    if (normalized.contains("corrida") || normalized.contains("run")) return const Color(0xFF0066FF);
    if (normalized.contains("bike") || normalized.contains("cicl")) return const Color(0xFF10B981);
    if (normalized.contains("muscul") || normalized.contains("força")) return const Color(0xFFEF4444);
    if (normalized.contains("caminhada") || normalized.contains("walk")) return const Color(0xFF06B6D4);
    return const Color(0xFF8B5CF6);
  }

  String _formatarTempo(dynamic segundosRaw) {
    final total = int.tryParse(segundosRaw?.toString() ?? "0") ?? 0;
    if (total <= 0) return "--";
    final horas = total ~/ 3600;
    final minutos = (total % 3600) ~/ 60;
    final segs = total % 60;
    if (horas > 0) return "${horas}h ${minutos.toString().padLeft(2, '0')}m";
    return "${minutos}m ${segs.toString().padLeft(2, '0')}s";
  }

  String _formatarPace(dynamic ritmoRaw) {
    final total = double.tryParse(ritmoRaw?.toString() ?? "0")?.round() ?? 0;
    if (total <= 0) return "--";
    return "${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}/km";
  }

  Widget _sensacaoPill(dynamic sensacaoRaw, bool isDark) {
    final val = int.tryParse(sensacaoRaw?.toString() ?? "0") ?? 0;
    if (val <= 0) return const SizedBox.shrink();

    String label = "RPE $val";
    Color cor = const Color(0xFF10B981);
    if (val >= 8) {
      label = "Intenso";
      cor = const Color(0xFFEF4444);
    } else if (val >= 5) {
      label = "Moderado";
      cor = const Color(0xFFF59E0B);
    } else {
      label = "Leve";
      cor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final recentes = treinos.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com título e "Ver todos"
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
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF0066FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Últimos Treinos",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              if (onVerTodos != null && recentes.isNotEmpty)
                TextButton(
                  onPressed: onVerTodos,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Ver histórico",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0066FF)),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (recentes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_run_rounded,
                        size: 32,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Nenhum treino concluído nesta semana",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Inicie uma corrida pelo GPS ou adicione uma planilha para ver suas atividades aqui.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ...recentes.map((treino) {
            final tipo = (treino["tipo"] ?? "Corrida").toString();
            final cor = _color(tipo);
            final km = double.tryParse((treino["distancia_km"] ?? treino["km"] ?? "0").toString()) ?? 0.0;
            final dataStr = AppDateUtils.formatarData(treino["data"]);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTreinoTap?.call(treino),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Ícone com fundo temático da modalidade
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cor.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_icon(tipo), color: cor, size: 22),
                        ),

                        const SizedBox(width: 12),

                        // Detalhes do Treino
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      tipo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _sensacaoPill(treino["sensacao"], isDark),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dataStr,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 13, color: colors.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatarTempo(treino["tempo_segundos"]),
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.speed_rounded, size: 13, color: colors.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatarPace(treino["ritmo_medio_segundos"]),
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Distância em destaque
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${km.toStringAsFixed(1)} km",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFF0066FF),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Feito",
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
