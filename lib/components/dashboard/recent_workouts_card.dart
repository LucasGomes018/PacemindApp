import 'package:flutter/material.dart';

class RecentWorkoutsCard extends StatelessWidget {
  final List treinos;

  const RecentWorkoutsCard({super.key, required this.treinos});

  IconData _icon(String tipo) {
    final normalized = tipo.toLowerCase();
    if (normalized.contains("corrida")) return Icons.directions_run;
    if (normalized.contains("bike")) return Icons.directions_bike;
    if (normalized.contains("caminhada")) return Icons.directions_walk;
    if (normalized.contains("muscul")) return Icons.fitness_center;
    return Icons.sports;
  }

  Color _color(String tipo) {
    final normalized = tipo.toLowerCase();
    if (normalized.contains("corrida")) return Colors.blue;
    if (normalized.contains("bike")) return Colors.green;
    if (normalized.contains("muscul")) return Colors.orange;
    if (normalized.contains("caminhada")) return Colors.teal;
    return Colors.grey;
  }

  String _tempo(dynamic segundos) {
    final total = int.tryParse(segundos?.toString() ?? "") ?? 0;
    if (total <= 0) return "Tempo não informado";
    return "${total ~/ 60}min ${(total % 60).toString().padLeft(2, '0')}s";
  }

  String _pace(dynamic segundos) {
    final total = double.tryParse(segundos?.toString() ?? "")?.round() ?? 0;
    if (total <= 0) return "Pace não informado";
    return "Pace ${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')} /km";
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final recentes = treinos.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                "Últimos treinos concluídos",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  "Nenhum treino concluído encontrado.",
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ),
          ...recentes.map((treino) {
            final tipo = (treino["tipo"] ?? "Treino").toString();
            final cor = _color(tipo);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cor.withValues(alpha: .12),
                    child: Icon(_icon(tipo), color: cor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipo,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (treino["data"] ?? "Data não informada").toString(),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${_tempo(treino["tempo_segundos"])}  •  ${_pace(treino["ritmo_medio_segundos"])}",
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${treino["distancia_km"] ?? 0} km",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Concluído",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
