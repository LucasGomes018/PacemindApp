import 'package:flutter/material.dart';

class RecomendacaoParecer {
  final String statusGeral;
  final String badgeTexto;
  final Color corStatus;
  final String corHexStatus;
  final String diagnosticoCarga;
  final String avaliacaoRespiratoria;
  final String prescricaoVelocidade;
  final List<String> diretrizesPraticas;

  const RecomendacaoParecer({
    required this.statusGeral,
    required this.badgeTexto,
    required this.corStatus,
    required this.corHexStatus,
    required this.diagnosticoCarga,
    required this.avaliacaoRespiratoria,
    required this.prescricaoVelocidade,
    required this.diretrizesPraticas,
  });
}

class RecomendacaoParecerService {
  /// Formata segundos em mm:ss min/km
  static String formatarPace(dynamic segundos) {
    if (segundos == null) return "-";
    final total = int.tryParse(segundos.toString()) ?? 0;
    if (total <= 0) return "-";
    final min = total ~/ 60;
    final seg = total % 60;
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} min/km";
  }

  /// Gera um parecer técnico totalmente baseado nos dados reais do atleta.
  static RecomendacaoParecer gerar({
    required Map<String, dynamic>? user,
    required Map<String, dynamic>? dashboard,
    required Map<String, dynamic>? overtraining,
    required dynamic ultimoACQ5,
    required dynamic ultimoMiniAQLQ,
    required dynamic ultimo3km,
  }) {
    // 1. Extração de Métricas do Atleta
    final nomeAtleta = user?["nome_usuario"]?.toString().trim() ?? "Atleta";
    final paceRefSeg = user?["pace_referencia_segundos"];
    final metaSemanalKm = double.tryParse(user?["objetivo_semanal_km"]?.toString() ?? "0") ?? 0.0;

    final resumo = dashboard?["resumo"] ?? {};
    final kmTotal = double.tryParse(resumo["total_km"]?.toString() ?? "0") ?? 0.0;
    final ritmoMedioSeg = int.tryParse(resumo["ritmo_medio"]?.toString() ?? "0") ?? 0;
    final totalTreinos = int.tryParse(resumo["total_treinos"]?.toString() ?? "0") ?? 0;
    final acwr = double.tryParse(overtraining?["acwr"]?.toString() ?? "1.0") ?? 1.0;

    // ACQ-5
    double? acq5Score;
    String? acq5Classificacao;
    if (ultimoACQ5 != null) {
      acq5Score = double.tryParse(ultimoACQ5["pontuacao_media"]?.toString() ?? "");
      acq5Classificacao = ultimoACQ5["classificacao"]?.toString();
    }

    // MiniAQLQ
    double? aqlqScore;
    if (ultimoMiniAQLQ != null) {
      aqlqScore = double.tryParse(ultimoMiniAQLQ["pontuacao_media"]?.toString() ?? "");
    }

    // Teste 3km
    double? vvo2max;
    double? vo2max;
    if (ultimo3km != null) {
      vvo2max = double.tryParse(ultimo3km["vvo2max_kmh"]?.toString() ?? "");
      vo2max = double.tryParse(ultimo3km["vo2max_estimado"]?.toString() ?? "");
    }

    // 2. Análise do Status Geral & Cores
    String statusGeral;
    String badgeTexto;
    Color corStatus;
    String corHexStatus;

    final bool asmaNaoControlada = acq5Score != null && acq5Score > 1.5;
    final bool asmaParcial = acq5Score != null && acq5Score > 0.75 && acq5Score <= 1.5;
    final bool riscoSobrecarga = acwr > 1.5;
    final bool atencaoSobrecarga = acwr >= 1.3 && acwr <= 1.5;
    final bool subtreinamento = acwr < 0.8;

    if (asmaNaoControlada) {
      statusGeral = "Atenção Respiratória Crítica";
      badgeTexto = "Sintomas de Asma Ativos";
      corStatus = const Color(0xFFEF4444); // Vermelho
      corHexStatus = "#EF4444";
    } else if (riscoSobrecarga) {
      statusGeral = "Alto Risco de Sobrecarga de Treino";
      badgeTexto = "ACWR Excessivo (>1.5x)";
      corStatus = const Color(0xFFEF4444); // Vermelho
      corHexStatus = "#EF4444";
    } else if (asmaParcial || atencaoSobrecarga) {
      statusGeral = "Atenção e Monitoramento Necessários";
      badgeTexto = asmaParcial ? "Asma Parcialmente Controlada" : "Carga no Limite Superior";
      corStatus = const Color(0xFFF59E0B); // Âmbar
      corHexStatus = "#F59E0B";
    } else if (subtreinamento) {
      statusGeral = "Fase de Recuperação ou Descondicionamento";
      badgeTexto = "Volume Agudo Reduzido";
      corStatus = const Color(0xFF3B82F6); // Azul
      corHexStatus = "#3B82F6";
    } else {
      statusGeral = "Treinamento Otimizado & Seguro";
      badgeTexto = "Zona Ideal (Sweet Spot)";
      corStatus = const Color(0xFF10B981); // Verde
      corHexStatus = "#10B981";
    }

    // 3. Diagnóstico de Carga & Volume
    final String diagnosticoCarga;
    if (riscoSobrecarga) {
      diagnosticoCarga =
          "$nomeAtleta apresenta um índice de carga agudo/crônico (ACWR) de ${acwr.toStringAsFixed(2)}x, indicando elevação perigosa e desproporcional do esforço nas últimas semanas em relação ao histórico crônico. Este cenário quadruplica a probabilidade de lesões musculares e hiper-reatividade das vias aéreas.";
    } else if (atencaoSobrecarga) {
      diagnosticoCarga =
          "$nomeAtleta registra índice ACWR de ${acwr.toStringAsFixed(2)}x (faixa de atenção: 1.3x a 1.5x). A carga de treinamento está próxima ao teto adaptativo e requer estabilização imediata para evitar sobretreinamento.";
    } else if (subtreinamento) {
      diagnosticoCarga =
          "$nomeAtleta apresenta índice ACWR de ${acwr.toStringAsFixed(2)}x, caracterizando uma fase de redução aguda de carga (deloading, pós-prova ou retorno recente aos treinos). A capacidade crônica está preservada, permitindo progressão suave.";
    } else {
      diagnosticoCarga =
          "$nomeAtleta mantém um índice ACWR equilibrado de ${acwr.toStringAsFixed(2)}x, situando-se com precisão na zona ideal de adaptação fisiológica (Sweet Spot: 0.8x a 1.3x). O estímulo atual promove evolução consistente com baixo risco biomecânico.";
    }

    // 4. Avaliação Respiratória e Asma
    final String avaliacaoRespiratoria;
    if (acq5Score != null) {
      if (acq5Score <= 0.75) {
        avaliacaoRespiratoria =
            "Controle Respiratório Otimizado: O teste ACQ-5 mais recente registrou ${acq5Score.toStringAsFixed(2)} pontos ($acq5Classificacao). As vias aéreas estão plenamente controladas, liberando o atleta para sessões de alta intensidade com aquecimento prévio.";
      } else if (acq5Score <= 1.5) {
        avaliacaoRespiratoria =
            "Atenção Respiratória Moderada: O teste ACQ-5 apontou ${acq5Score.toStringAsFixed(2)} pontos ($acq5Classificacao). O atleta apresenta sintomas ocasionais de tosse, dispneia ou aperto no peito, exigindo aquecimento mais longo e monitoramento rigoroso.";
      } else {
        avaliacaoRespiratoria =
            "ALERTA CLÍNICO RESPIRATÓRIO: O teste ACQ-5 registrou ${acq5Score.toStringAsFixed(2)} pontos ($acq5Classificacao). Há evidência clara de sintomas respiratórios ativos no esforço diário. Exercícios exaustivos estão contraindicados até controle médico.";
      }
    } else {
      avaliacaoRespiratoria =
          "Nenhuma avaliação recente do questionário ACQ-5 foi localizada. Recomenda-se registrar os sintomas respiratórios no aplicativo para ajustar as cargas e evitar broncoespasmo.";
    }

    // 5. Prescrição de Velocidade e Zonas
    final String prescricaoVelocidade;
    if (vvo2max != null && vvo2max > 0) {
      final z2Min = (vvo2max * 0.65).toStringAsFixed(1);
      final z2Max = (vvo2max * 0.75).toStringAsFixed(1);
      final z4Min = (vvo2max * 0.90).toStringAsFixed(1);
      final z5Min = (vvo2max * 0.98).toStringAsFixed(1);
      final vo2Txt = vo2max != null && vo2max > 0 ? " (VO2max estimado em ${vo2max.toStringAsFixed(1)} ml/kg/min)" : "";
      prescricaoVelocidade =
          "Prescrição Individualizada baseada no Teste de 3km (vVO2max: ${vvo2max.toStringAsFixed(1)} km/h$vo2Txt): Rodagens e treinos base (Zona 2) devem ser realizados entre $z2Min e $z2Max km/h. Treinos de ritmo/limiar (Zona 3/4) entre $z4Min km/h e tiros de velocidade (Zona 5) a partir de $z5Min km/h.";
    } else if (paceRefSeg != null && (int.tryParse(paceRefSeg.toString()) ?? 0) > 0) {
      final segRef = int.parse(paceRefSeg.toString());
      final paceZ2Min = formatarPace(segRef + 60);
      final paceZ2Max = formatarPace(segRef + 90);
      prescricaoVelocidade =
          "Prescrição com base no Pace de Referência (${formatarPace(segRef)}): Rodagens leves e treinos regenerativos devem ser cumpridos entre $paceZ2Min e $paceZ2Max para manter o controle ventilatório estável.";
    } else {
      prescricaoVelocidade =
          "Recomenda-se realizar o Teste de Campo de 3km no PaceMind para calibrar a velocidade aeróbica máxima (vVO2max) e calcular com exatidão as zonas de frequência cardíaca e ritmo.";
    }

    // 6. Diretrizes Práticas e Objetivas (Bullets personalizados)
    final List<String> diretrizes = [];

    // Diretriz 1: Distribuição de Volume e Treinos
    if (riscoSobrecarga) {
      diretrizes.add(
        "Intervenção de Carga: Reduzir imediatamente o volume semanal em 25% a 35% e eliminar treinos intervalados na próxima semana para reequilibrar o ACWR abaixo de 1.3x.",
      );
    } else if (atencaoSobrecarga) {
      diretrizes.add(
        "Estabilização de Volume: Manter a mesma quilometragem da semana anterior, sem aumentos de volume, priorizando descanso adequado entre as sessões.",
      );
    } else if (subtreinamento) {
      diretrizes.add(
        "Progressão Gradual: Incrementar a quilometragem semanal em no máximo 10% a 15%, priorizando rodagens contínuas em terreno plano para reconstruir a base.",
      );
    } else {
      diretrizes.add(
        "Manutenção do Sweet Spot: Manter 80% do volume semanal em Zonas 1 e 2 (conversacionais) e 20% em treinos de ritmo ou intervalados moderados.",
      );
    }

    // Diretriz 2: Cuidados Respiratórios com base no ACQ-5 e MiniAQLQ
    if (asmaNaoControlada) {
      diretrizes.add(
        "Conduta Respiratória Restritiva: Suspender tiros e treinos de alta intensidade. Realizar apenas caminhadas ou trotes leves (<Zona 2) e agendar consulta médica para ajuste medicamentoso.",
      );
    } else if (asmaParcial) {
      diretrizes.add(
        "Precauções em Vias Aéreas: Realizar aquecimento gradual obrigatório de 15 minutos em Zona 1 antes de qualquer esforço. Evitar treinos ao ar livre em dias de baixa umidade (<30%) ou alta poluição.",
      );
    } else if (acq5Score != null && acq5Score <= 0.75) {
      diretrizes.add(
        "Treinos Fortes Liberados: Controle respiratório comprovado. Treinos de repetições e subidas estão liberados, mantendo 10 minutos de aquecimento dinâmico.",
      );
    } else {
      diretrizes.add(
        "Monitoramento de Sintomas: Responder semanalmente ao ACQ-5 no aplicativo para permitir a validação médica contínua das intensidades prescritas.",
      );
    }

    // Diretriz 3: Meta de Quilometragem e Ritmo
    if (metaSemanalKm > 0) {
      if (kmTotal >= metaSemanalKm) {
        diretrizes.add(
          "Meta Semanal Atingida: Total de ${kmTotal.toStringAsFixed(1)} km superou o alvo planejado de ${metaSemanalKm.toStringAsFixed(0)} km. Recomenda-se não exceder mais de 10% do objetivo para preservar a integridade articular.",
        );
      } else {
        final faltam = (metaSemanalKm - kmTotal).clamp(0.0, 999.0);
        diretrizes.add(
          "Acompanhamento da Meta: Concluídos ${kmTotal.toStringAsFixed(1)} km da meta semanal de ${metaSemanalKm.toStringAsFixed(0)} km (faltam ${faltam.toStringAsFixed(1)} km). Distribua o restante sem acumular dois treinos longos em dias consecutivos.",
        );
      }
    } else if (totalTreinos > 0 && ritmoMedioSeg > 0) {
      diretrizes.add(
        "Consistência Registrada: Com $totalTreinos treinos registrados e ritmo médio de ${formatarPace(ritmoMedioSeg)}, atente-se para que as rodagens leves não sejam executadas em ritmo de prova.",
      );
    }

    // Diretriz 4: Segurança Médica
    if (aqlqScore != null && aqlqScore < 4.5) {
      diretrizes.add(
        "Qualidade de Vida: O score MiniAQLQ (${aqlqScore.toStringAsFixed(2)}/7.0) reflete impacto nas atividades diárias. Priorize hidratação frequente e respiração nasal ritmada.",
      );
    } else {
      diretrizes.add(
        "Sinais de Alerta: Caso sinta sibilância (chiado no peito), tosse seca persistente ou tontura durante o treino, interrompa a atividade imediatamente e siga o plano de ação médica.",
      );
    }

    return RecomendacaoParecer(
      statusGeral: statusGeral,
      badgeTexto: badgeTexto,
      corStatus: corStatus,
      corHexStatus: corHexStatus,
      diagnosticoCarga: diagnosticoCarga,
      avaliacaoRespiratoria: avaliacaoRespiratoria,
      prescricaoVelocidade: prescricaoVelocidade,
      diretrizesPraticas: diretrizes,
    );
  }
}
