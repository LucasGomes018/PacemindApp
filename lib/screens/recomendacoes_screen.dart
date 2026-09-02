import 'package:flutter/material.dart';

class RecomendacoesPage extends StatelessWidget {
  const RecomendacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Recomendações",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),

        children: [
          _cardIA(
            icon: Icons.auto_awesome,
            titulo: "Treino recomendado",
            texto:
                "Hoje recomendamos uma corrida leve de 6 km em ritmo confortável.",
            cor: Colors.blue,
          ),

          const SizedBox(height: 16),

          _cardIA(
            icon: Icons.trending_up,
            titulo: "Análise da semana",
            texto:
                "Seu volume aumentou 12% comparado à semana passada. Excelente evolução.",
            cor: Colors.green,
          ),

          const SizedBox(height: 16),

          _cardIA(
            icon: Icons.warning_amber,
            titulo: "Recuperação",
            texto: "Sua carga de treino está alta. Faça um treino leve amanhã.",
            cor: Colors.orange,
          ),

          const SizedBox(height: 16),

          _cardIA(
            icon: Icons.lightbulb,
            titulo: "Dica",
            texto:
                "Inclua exercícios de mobilidade antes das corridas para reduzir risco de lesões.",
            cor: Colors.purple,
          ),

          const SizedBox(height: 16),

          _cardIA(
            icon: Icons.flag,
            titulo: "Meta",
            texto: "Faltam apenas 3 km para completar sua meta semanal.",
            cor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _cardIA({
    required IconData icon,
    required String titulo,
    required String texto,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cor.withValues(alpha: .15),

            child: Icon(icon, color: cor),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  texto,
                  style: const TextStyle(color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
