import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notificacao_service.dart';
import '../core/api.dart';

/// 🧠 MOTOR INTELIGENTE DE NOTIFICAÇÕES AUTOMÁTICAS DO PACEMIND
/// Cobre todas as possibilidades de notificações esportivas, clínicas e motivacionais:
/// 1. Lembretes diários agendados (treino matinal, check-in de bem-estar, sono regenerador).
/// 2. Notificação instantânea pós-treino (resumo de km, tempo e pace).
/// 3. Lembrete automático pós-treino de hidratação e reposição nutricional (20 min após a corrida).
/// 4. Celebração automática de meta semanal batida ou quase batida.
/// 5. Alertas de sobrecarga e risco de overtraining (razão aguda:crônica ACWR).
/// 6. Alertas de fadiga elevada e dor muscular pós-check-in diário.
/// 7. Lembretes de provas/eventos esportivos e consultas médicas da agenda.
/// 8. Lembrete semanal do questionário de controle respiratório (ACQ-5).
/// 9. Sincronização automática contínua de notificações do banco para push no celular.
class AutoNotificacaoService {
  static bool _inicializado = false;
  static Timer? _timerSincronizacao;

  /// Inicializa o motor de notificações automáticas, canais e agendamentos diários
  static Future<void> inicializar() async {
    if (_inicializado) return;

    try {
      await NotificacaoService.inicializar();
      _inicializado = true;

      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool("notificacoes") ?? true)) return;

      await _configurarLembretesDiarios();

      // Executa verificação silenciosa inicial com o backend e sincroniza push
      executarChecagemInteligente();

      // Configura sincronização periódica a cada 90 segundos enquanto o app estiver em execução
      _timerSincronizacao?.cancel();
      _timerSincronizacao = Timer.periodic(const Duration(seconds: 90), (_) {
        sincronizarNotificacoesPush();
      });
    } catch (e) {
      debugPrint("[AutoNotificacaoService] Erro ao inicializar: $e");
    }
  }

  static Future<void> atualizarPreferencia(bool ativa) async {
    if (!ativa) {
      _timerSincronizacao?.cancel();
      _timerSincronizacao = null;
      await NotificacaoService.cancelarTodas();
      return;
    }

    await NotificacaoService.inicializar();
    await _configurarLembretesDiarios();
    await executarChecagemInteligente();
    _timerSincronizacao?.cancel();
    _timerSincronizacao = Timer.periodic(const Duration(seconds: 90), (_) {
      sincronizarNotificacoesPush();
    });
  }

  /// ⏰ 1. Configura os lembretes diários recorrentes no dispositivo
  static Future<void> _configurarLembretesDiarios() async {
    // 07:30 - Lembrete Matinal de Treino do Dia
    await NotificacaoService.agendarNotificacaoDiaria(
      id: 101,
      titulo: "🏃 Bom dia, corredor!",
      corpo:
          "Abra o PaceMind para conferir seu treino planejado de hoje e preparar o tênis.",
      hora: 7,
      minuto: 30,
      canal: 'lembretes',
    );

    // 08:30 - Lembrete Diário de Check-in de Bem-Estar e Prontidão
    await NotificacaoService.agendarNotificacaoDiaria(
      id: 102,
      titulo: "❤️ Como você acordou hoje?",
      corpo:
          "Faça seu check-in diário de energia, sono e dores para calcular sua prontidão de treino.",
      hora: 8,
      minuto: 30,
      canal: 'lembretes',
    );

    // 21:30 - Lembrete Noturno de Descanso e Sono Reparador
    await NotificacaoService.agendarNotificacaoDiaria(
      id: 103,
      titulo: "🌙 Hora de desacelerar",
      corpo:
          "O sono de qualidade é onde ocorrem as principais adaptações musculares do treino. Durma bem!",
      hora: 21,
      minuto: 30,
      canal: 'lembretes',
    );
  }

  /// 🤖 2. Executa a checagem inteligente com o backend e projeta alertas locais sem duplicar
  static Future<void> executarChecagemInteligente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool("notificacoes") ?? true)) return;

      // 1. O backend avalia as regras esportivas e insere no banco caso haja novidade
      await Api.verificarNotificacoesAutomaticas();
    } catch (e) {
      debugPrint("[AutoNotificacaoService] Erro na checagem inteligente: $e");
    }

    // 2. A sincronização lê as notificações não lidas e projeta no push de forma unificada e sem duplicações
    await sincronizarNotificacoesPush();
  }

  /// 🛡️ Registra uma notificação disparada localmente para que o polling do banco não a duplique
  static Future<void> registrarNotificacaoLocalEnviada(
    String titulo,
    String corpo, {
    String? idStr,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enviadasList =
          prefs.getStringList('push_notificacoes_enviadas') ?? [];
      final Set<String> enviadasSet = enviadasList.toSet();

      if (idStr != null && idStr.isNotEmpty) {
        enviadasSet.add(idStr);
      }
      final chaveConteudo = "${titulo.trim()}_${corpo.trim()}";
      enviadasSet.add(chaveConteudo);

      final listFinal = enviadasSet.toList();
      if (listFinal.length > 250) {
        listFinal.removeRange(0, listFinal.length - 250);
      }
      await prefs.setStringList('push_notificacoes_enviadas', listFinal);
    } catch (_) {}
  }

  /// 📲 3. Sincroniza notificações não lidas da API e projeta como Push na barra do Android (com deduplicação estrita)
  static Future<void> sincronizarNotificacoesPush() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool("notificacoes") ?? true)) return;
      final token = prefs.getString("token");
      if (token == null || token.isEmpty) return;

      final enviadasList =
          prefs.getStringList('push_notificacoes_enviadas') ?? [];
      final Set<String> enviadasSet = enviadasList.toSet();

      final notificacoes = await Api.listarNotificacoes();
      if (notificacoes.isEmpty) return;

      bool houveEnvio = false;

      // Pega as notificações não lidas mais recentes (até 5)
      final naoLidas = notificacoes
          .where((n) => n['lida'] != true)
          .take(5)
          .toList();

      for (final n in naoLidas) {
        final idStr = (n['id_notificacao'] ?? '').toString();
        final titulo = (n['titulo'] ?? '').toString().trim();
        final corpo = (n['mensagem'] ?? '').toString().trim();
        final chaveConteudo = "${titulo}_$corpo";

        // 🛡️ Filtro Antiduplicação: pula se o ID ou se o conteúdo exato já tiverem sido notificados
        if (idStr.isNotEmpty && enviadasSet.contains(idStr)) continue;
        if (chaveConteudo.isNotEmpty && enviadasSet.contains(chaveConteudo)) {
          continue;
        }

        final tipo = (n['tipo'] ?? '').toString().toLowerCase();
        String canal = 'lembretes';
        if (tipo.contains('alerta') || tipo.contains('overtraining')) {
          canal = 'alertas';
        } else if (tipo.contains('meta')) {
          canal = 'metas';
        } else if (tipo.contains('treino') || tipo.contains('corrida')) {
          canal = 'treinos';
        }

        final int notifId = int.tryParse(idStr) ?? (1000 + enviadasSet.length);

        await NotificacaoService.mostrarNotificacao(
          id: notifId,
          titulo: titulo.isNotEmpty ? titulo : 'PaceMind',
          corpo: corpo,
          canal: canal,
        );

        if (idStr.isNotEmpty) enviadasSet.add(idStr);
        if (chaveConteudo.isNotEmpty) enviadasSet.add(chaveConteudo);
        houveEnvio = true;
      }

      if (houveEnvio) {
        final listFinal = enviadasSet.toList();
        if (listFinal.length > 250) {
          listFinal.removeRange(0, listFinal.length - 250);
        }
        await prefs.setStringList('push_notificacoes_enviadas', listFinal);
      }
    } catch (e) {
      debugPrint(
        "[AutoNotificacaoService] Erro ao sincronizar notificações push: $e",
      );
    }
  }

  /// 🏁 4. Disparada automaticamente ao concluir qualquer corrida ou treino
  static Future<void> notificarTreinoConcluido({
    required double distanciaKm,
    required int tempoSegundos,
    int? ritmoMedioSegundos,
    int? paceMedioSegundos,
    int? fcMedia,
  }) async {
    final paceEfetivo = paceMedioSegundos ?? ritmoMedioSegundos;
    final paceStr = paceEfetivo != null
        ? _formatarPace(paceEfetivo)
        : "--'--\"";
    final tempoStr = _formatarTempo(tempoSegundos);
    final tituloPush = "🏁 Treino Concluído com Sucesso!";
    final corpoPush =
        "${distanciaKm.toStringAsFixed(2)} km em $tempoStr • Pace $paceStr/km${fcMedia != null ? ' • FC $fcMedia bpm' : ''}. Excelente trabalho!";
    final tituloApi = "Treino Concluído 🏁";
    final msgApi =
        "Você completou ${distanciaKm.toStringAsFixed(2)} km em $tempoStr com ritmo de $paceStr/km.";

    // 1. Notificação imediata de celebração do treino
    await NotificacaoService.mostrarNotificacao(
      id: 201,
      titulo: tituloPush,
      corpo: corpoPush,
      canal: 'treinos',
    );

    // Registra chaves antiduplicação para evitar que o polling do banco reenvie
    await registrarNotificacaoLocalEnviada(tituloPush, corpoPush);
    await registrarNotificacaoLocalEnviada(tituloApi, msgApi);

    // Salva na central de notificações da API
    Api.criarNotificacao(
      titulo: tituloApi,
      mensagem: msgApi,
      tipo: "treino",
    ).catchError((_) => {});

    // 2. Agenda automaticamente o Lembrete de Hidratação para 20 minutos depois
    final horaHidratacao = DateTime.now().add(const Duration(minutes: 20));
    await NotificacaoService.agendarNotificacao(
      id: 202,
      titulo: "💧 Hora de Hidratar e Repor Nutrientes!",
      corpo:
          "Excelente treino de ${distanciaKm.toStringAsFixed(2)} km há pouco! Beba água e consuma fontes de carboidrato e proteína para acelerar a recuperação muscular.",
      dataHora: horaHidratacao,
      canal: 'lembretes',
    );

    // 3. Dispara checagem em background para ver se bateu metas ou gerou alertas
    Future.delayed(const Duration(seconds: 2), () {
      executarChecagemInteligente();
    });
  }

  /// 🏆 5. Celebração automática quando a Meta Semanal é batida
  static Future<void> notificarMetaBatida({
    required double metaKm,
    required double totalKm,
  }) async {
    final tituloPush = "🏆 Meta Semanal Conquistada!";
    final corpoPush =
        "Parabéns! Você atingiu sua meta semanal de ${metaKm.toStringAsFixed(1)} km (${totalKm.toStringAsFixed(1)} km percorridos). Continue assim!";
    final tituloApi = "Meta Semanal Batida! 🏆";
    final msgApi =
        "Você completou com sucesso sua meta semanal de ${metaKm.toStringAsFixed(1)} km!";

    await NotificacaoService.mostrarNotificacao(
      id: 301,
      titulo: tituloPush,
      corpo: corpoPush,
      canal: 'metas',
    );

    await registrarNotificacaoLocalEnviada(tituloPush, corpoPush);
    await registrarNotificacaoLocalEnviada(tituloApi, msgApi);

    Api.criarNotificacao(
      titulo: tituloApi,
      mensagem: msgApi,
      tipo: "meta",
    ).catchError((_) => {});
  }

  /// ⚠️ 6. Alerta automático de risco de overtraining / sobrecarga
  static Future<void> notificarAlertaOvertraining(double acwr) async {
    final titulo = "⚠️ Alerta Fisiológico: Sobrecarga Aguda";
    final corpo =
        "Sua razão de carga aguda:crônica atingiu ${acwr.toStringAsFixed(2)} (zona de sobrecarga). Reduza a intensidade e priorize repouso para evitar lesões.";

    await NotificacaoService.mostrarNotificacao(
      id: 401,
      titulo: titulo,
      corpo: corpo,
      canal: 'alertas',
    );

    await registrarNotificacaoLocalEnviada(titulo, corpo);
  }

  /// 🛡️ 7. Alerta automático após Check-in Diário de Bem-Estar (se prontidão baixa ou dor)
  static Future<void> notificarCheckinWellness({
    required int prontidao,
    required bool acordouComDor,
    String? localDor,
  }) async {
    if (prontidao < 55 || acordouComDor) {
      final motivo = acordouComDor
          ? "Queixa de dor muscular${localDor != null && localDor.isNotEmpty ? ' ($localDor)' : ''}"
          : "Índice de prontidão moderado a baixo ($prontidao/100)";

      final titulo = "⚠️ Alerta de Recuperação: $motivo";
      final corpo =
          "Sua recuperação física precisa de atenção hoje. Sugerimos trocar o treino intenso por um trote regenerativo leve em Zona 1/2 ou descanso total.";

      await NotificacaoService.mostrarNotificacao(
        id: 402,
        titulo: titulo,
        corpo: corpo,
        canal: 'alertas',
      );

      await registrarNotificacaoLocalEnviada(titulo, corpo);
    }
  }

  /// 📅 8. Agenda lembrete de compromisso da Agenda
  static Future<void> agendarLembreteAgenda({
    required int id,
    required String titulo,
    required DateTime dataInicio,
    required String tipo,
  }) async {
    final agora = DateTime.now();

    // Se for prova, lembra 1 dia antes às 18:00
    if (tipo.toLowerCase().contains("prova") ||
        tipo.toLowerCase().contains("evento")) {
      final diaAnterior = dataInicio.subtract(const Duration(days: 1));
      final horaLembrete = DateTime(
        diaAnterior.year,
        diaAnterior.month,
        diaAnterior.day,
        18,
        0,
      );

      if (horaLembrete.isAfter(agora)) {
        await NotificacaoService.agendarNotificacao(
          id: id,
          titulo: "🏁 Sua prova é amanhã: $titulo!",
          corpo:
              "Prepare seu uniforme, número de peito, hidrate-se bem e garanta uma ótima noite de sono.",
          dataHora: horaLembrete,
          canal: 'lembretes',
        );
      }
    } else {
      // Outros compromissos: avisa 1 hora antes
      final horaLembrete = dataInicio.subtract(const Duration(hours: 1));
      if (horaLembrete.isAfter(agora)) {
        await NotificacaoService.agendarNotificacao(
          id: id,
          titulo: "⏰ Lembrete de Compromisso: $titulo",
          corpo:
              "Seu compromisso está marcado para às ${dataInicio.hour.toString().padLeft(2, '0')}:${dataInicio.minute.toString().padLeft(2, '0')}.",
          dataHora: horaLembrete,
          canal: 'lembretes',
        );
      }
    }
  }

  /// 🧪 9. Utilitário completo para testar notificações push na tela
  static Future<void> testarNotificacao({required String tipo}) async {
    await NotificacaoService.inicializar();

    switch (tipo) {
      case 'imediata':
        await NotificacaoService.mostrarNotificacao(
          id: 901,
          titulo: "🔔 PaceMind: Push Ativo!",
          corpo:
              "Se você está vendo este banner no topo do seu celular, as notificações push estão funcionando 100%!",
          canal: 'treinos',
        );
        break;

      case 'agendada':
        final dataAgendada = DateTime.now().add(const Duration(seconds: 5));
        await NotificacaoService.agendarNotificacao(
          id: 902,
          titulo: "⏱️ Push Agendado (5s) Funcionando!",
          corpo:
              "O agendador do PaceMind disparou com sucesso em segundo plano!",
          dataHora: dataAgendada,
          canal: 'lembretes',
        );
        break;

      case 'meta':
        await NotificacaoService.mostrarNotificacao(
          id: 903,
          titulo: "🏆 Meta Semanal Conquistada!",
          corpo:
              "Parabéns! Você atingiu sua meta semanal planejada. Excelente consistência e volume!",
          canal: 'metas',
        );
        break;

      case 'alerta':
        await NotificacaoService.mostrarNotificacao(
          id: 904,
          titulo: "⚠️ Alerta Fisiológico de Sobrecarga",
          corpo:
              "Sua razão de carga aguda:crônica (ACWR) atingiu 1.55. Sugerimos repouso ativo ou treino regenerativo hoje.",
          canal: 'alertas',
        );
        break;

      case 'hidratacao':
        await NotificacaoService.mostrarNotificacao(
          id: 905,
          titulo: "💧 Hora de Hidratar e Recuperar!",
          corpo:
              "Beba água e consuma nutrientes para restaurar seus estoques de energia e acelerar a recuperação muscular.",
          canal: 'lembretes',
        );
        break;
    }
  }

  // --- Funções Auxiliares de Formatação ---
  static String _formatarTempo(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;
    final segs = segundos % 60;

    if (horas > 0) {
      return "${horas}h ${minutos.toString().padLeft(2, '0')}m";
    }
    return "${minutos}m ${segs.toString().padLeft(2, '0')}s";
  }

  static String _formatarPace(int paceSegundos) {
    final minutos = paceSegundos ~/ 60;
    final segs = paceSegundos % 60;
    return "$minutos'${segs.toString().padLeft(2, '0')}\"";
  }
}
