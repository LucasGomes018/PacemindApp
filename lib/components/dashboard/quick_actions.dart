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

  Widget botao({
    required IconData icon,
    required String titulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 115,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: cor,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
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
        const Text(
          "Ações rápidas",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            botao(
              icon: Icons.play_arrow_rounded,
              titulo: "Iniciar\nCorrida",
              cor: Colors.green,
              onTap: iniciarCorrida,
            ),

            const SizedBox(width: 14),

            botao(
              icon: Icons.fitness_center,
              titulo: "Meus\nTreinos",
              cor: Colors.blue,
              onTap: abrirTreinos,
            ),

            const SizedBox(width: 14),

            botao(
              icon: Icons.refresh,
              titulo: "Atualizar",
              cor: Colors.orange,
              onTap: atualizar,
            ),
          ],
        ),
      ],
    );
  }
}