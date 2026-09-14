import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHeader extends StatelessWidget {
  final String nome;
  final String? fotoUrl;
  final DateTime dataReferencia;
  final DateTime inicioSemana;
  final DateTime fimSemana;
  final bool isSemanaAtual;
  final VoidCallback? onSemanaAnterior;
  final VoidCallback? onProximaSemana;
  final VoidCallback? onSemanaAtual;
  final VoidCallback? onAbrirPerfil;

  const DashboardHeader({
    super.key,
    required this.nome,
    this.fotoUrl,
    required this.dataReferencia,
    required this.inicioSemana,
    required this.fimSemana,
    this.isSemanaAtual = true,
    this.onSemanaAnterior,
    this.onProximaSemana,
    this.onSemanaAtual,
    this.onAbrirPerfil,
  });

  String _saudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return "Bom dia";
    if (hora < 18) return "Boa tarde";
    return "Boa noite";
  }

  String _getIniciais(String nomeCompleto) {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes[0].isEmpty) return "PM";
    if (partes.length == 1) {
      return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return "${partes[0][0]}${partes[1][0]}".toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formatadorDiaMes = DateFormat("dd 'de' MMM", "pt_BR");
    final formatadorExtenso = DateFormat("EEEE, dd 'de' MMMM", "pt_BR");
    final dataExtenso = formatadorExtenso.format(DateTime.now());

    final periodoTexto = isSemanaAtual
        ? "Esta semana • ${formatadorDiaMes.format(inicioSemana)} a ${formatadorDiaMes.format(fimSemana)}"
        : "${formatadorDiaMes.format(inicioSemana)} a ${formatadorDiaMes.format(fimSemana)}";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F1E36), Color(0xFF132B50), Color(0xFF0D3B75)]
              : const [Color(0xFF0052D4), Color(0xFF1E70EB), Color(0xFF4361EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052D4).withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Efeito de iluminação decorativa de fundo
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar + Saudação + Perfil / Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar do atleta com borda
                    GestureDetector(
                      onTap: onAbrirPerfil,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (fotoUrl != null && fotoUrl!.isNotEmpty)
                              ? Image.network(
                                  fotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _avatarIniciais(),
                                )
                              : _avatarIniciais(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Nome e saudação
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _saudacao(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text("👋", style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              nome,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Badge esportivo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFFFFD166), size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Ativo",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Data de hoje
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dataExtenso,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Seletor de Semana Integrado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Botão semana anterior
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: onSemanaAnterior,
                        tooltip: "Semana anterior",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),

                      // Texto do período
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              periodoTexto,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Botão próxima semana (desabilitado se já for semana atual)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: isSemanaAtual ? Colors.white30 : Colors.white,
                          size: 22,
                        ),
                        onPressed: isSemanaAtual ? null : onProximaSemana,
                        tooltip: "Próxima semana",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),

                      // Atalho para voltar para hoje se não estiver na semana atual
                      if (!isSemanaAtual && onSemanaAtual != null)
                        InkWell(
                          onTap: onSemanaAtual,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Hoje",
                              style: TextStyle(
                                color: Color(0xFF0052D4),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarIniciais() {
    return Container(
      color: const Color(0xFF003B99),
      alignment: Alignment.center,
      child: Text(
        _getIniciais(nome),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}