import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHeader extends StatelessWidget {
  final String nome;

  const DashboardHeader({
    super.key,
    required this.nome,
  });

  String saudacao() {
    final hora = DateTime.now().hour;

    if (hora < 12) {
      return "Bom dia";
    }

    if (hora < 18) {
      return "Boa tarde";
    }

    return "Boa noite";
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateFormat(
      "EEEE, dd 'de' MMMM",
      "pt_BR",
    ).format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0066FF),
            Color(0xFF4AA3FF),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${saudacao()},",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nome,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hoje,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}