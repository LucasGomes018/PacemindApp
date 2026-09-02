import 'package:flutter/material.dart';

class RecentWorkoutsCard extends StatelessWidget {
  final List treinos;

  const RecentWorkoutsCard({
    super.key,
    required this.treinos,
  });

  IconData _icon(String tipo) {
    tipo = tipo.toLowerCase();

    if (tipo.contains("corrida")) return Icons.directions_run;
    if (tipo.contains("bike")) return Icons.directions_bike;
    if (tipo.contains("caminhada")) return Icons.directions_walk;
    if (tipo.contains("muscul")) return Icons.fitness_center;

    return Icons.sports;
  }

  Color _color(String tipo) {
    tipo = tipo.toLowerCase();

    if (tipo.contains("corrida")) return Colors.blue;
    if (tipo.contains("bike")) return Colors.green;
    if (tipo.contains("muscul")) return Colors.orange;
    if (tipo.contains("caminhada")) return Colors.teal;

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final concluidos = treinos
        .where((treino) => (treino["status"] ?? "")
            .toString()
            .toLowerCase() ==
        "concluido")
        .toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Icon(
                Icons.history,
                color: Color(0xFF0066FF),
              ),
              SizedBox(width: 8),
              Text(
                "Últimos Treinos",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Color(0xFF0066FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (concluidos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text(
                "Nenhum treino concluído encontrado.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ...concluidos.take(5).map((treino) {
            final tipo = (treino["tipo"] ?? "").toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _color(tipo).withValues(alpha: .12),
                    child: Icon(
                      _icon(tipo),
                      color: _color(tipo),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          (treino["data"] ?? "").toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${treino["distancia_km"] ?? 0} km",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066FF),
                    ),
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