import 'package:flutter/material.dart';
import 'stat_card.dart';

class DashboardStats extends StatelessWidget {
  final double kmSemana;
  final int tempo; // Segundos totais
  final int carga;
  final int treinos;
  final double? ritmoMedioSegundos;
  final Map<String, dynamic>? comparacao;

  const DashboardStats({
    super.key,
    required this.kmSemana,
    required this.tempo,
    required this.carga,
    required this.treinos,
    this.ritmoMedioSegundos,
    this.comparacao,
  });

  String _formatarTempoInteligente(int tempoRaw) {
    if (tempoRaw <= 0) return "0m";

    // Proteção defensiva: caso uma API antiga tenha retornado horas fracionadas ou inteiras (ex: 2 para 2h)
    int segundos = tempoRaw;
    if (segundos < 120 && kmSemana > 1.0) {
      segundos = tempoRaw * 3600;
    }

    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;
    final segsRestantes = segundos % 60;

    if (horas > 0) {
      return "${horas}h ${minutos.toString().padLeft(2, '0')}m";
    }

    if (minutos > 0) {
      return "${minutos}m ${segsRestantes > 0 ? '${segsRestantes.toString().padLeft(2, '0')}s' : ''}".trim();
    }

    return "${segsRestantes}s";
  }

  String _formatarPace(double? segundos) {
    if (segundos == null || segundos <= 0) return "--:--";
    final minutos = segundos ~/ 60;
    final segs = (segundos % 60).round();
    return "$minutos:${segs.toString().padLeft(2, '0')} /km";
  }

  String? _obterSubtituloKm() {
    if (comparacao == null) return null;
    final evolucao = comparacao!["evolucao_percentual"];
    if (evolucao == null) return null;

    final val = int.tryParse(evolucao.toString()) ?? 0;
    if (val > 0) return "+$val% vs ant.";
    if (val < 0) return "$val% vs ant.";
    return "Igual ant.";
  }

  Color? _obterCorSubtituloKm() {
    if (comparacao == null) return null;
    final evolucao = comparacao!["evolucao_percentual"];
    if (evolucao == null) return null;

    final val = int.tryParse(evolucao.toString()) ?? 0;
    if (val > 0) return const Color(0xFF10B981);
    if (val < 0) return const Color(0xFFF59E0B);
    return null;
  }

  String _obterStatusCarga(int valorCarga) {
    if (valorCarga <= 0) return "Descanso";
    if (valorCarga < 150) return "Carga Leve";
    if (valorCarga <= 350) return "Carga Ótima 🔥";
    return "Carga Alta ⚠️";
  }

  Color _obterCorStatusCarga(int valorCarga) {
    if (valorCarga <= 0) return const Color(0xFF94A3B8);
    if (valorCarga < 150) return const Color(0xFF38BDF8);
    if (valorCarga <= 350) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final crossAxisCount = isTablet ? 4 : 2;
        // Razão dinâmica para evitar overflow em telas pequenas
        final aspectRatio = isTablet ? 1.6 : 1.38;

        final subtituloKm = _obterSubtituloKm();
        final corSubtituloKm = _obterCorSubtituloKm();
        final paceTexto = (ritmoMedioSegundos != null && ritmoMedioSegundos! > 0)
            ? _formatarPace(ritmoMedioSegundos)
            : null;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: [
            // 1. Quilometragem
            StatCard(
              icon: Icons.directions_run_rounded,
              title: "Distância",
              value: "${kmSemana.toStringAsFixed(1)} km",
              subtitle: subtituloKm,
              subtitleColor: corSubtituloKm,
              color: const Color(0xFF0066FF),
              gradientColors: const [Color(0xFF0066FF), Color(0xFF00C6FF)],
            ),

            // 2. Tempo Total em Movimento
            StatCard(
              icon: Icons.timer_outlined,
              title: "Tempo Ativo",
              value: _formatarTempoInteligente(tempo),
              subtitle: treinos > 0 ? "$treinos treino${treinos > 1 ? 's' : ''}" : "Sem treinos",
              subtitleColor: const Color(0xFFF59E0B),
              color: const Color(0xFFF59E0B),
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),

            // 3. Pace Médio ou Carga
            StatCard(
              icon: Icons.speed_rounded,
              title: "Pace Médio",
              value: paceTexto ?? "--:--",
              subtitle: (ritmoMedioSegundos != null && ritmoMedioSegundos! > 0) ? "Ritmo da semana" : "Pace não calc.",
              subtitleColor: const Color(0xFF10B981),
              color: const Color(0xFF10B981),
              gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
            ),

            // 4. Carga de Treino
            StatCard(
              icon: Icons.local_fire_department_rounded,
              title: "Carga (RPE)",
              value: "$carga pts",
              subtitle: _obterStatusCarga(carga),
              subtitleColor: _obterCorStatusCarga(carga),
              color: const Color(0xFFEF4444),
              gradientColors: const [Color(0xFFEF4444), Color(0xFFF87171)],
            ),
          ],
        );
      },
    );
  }
}