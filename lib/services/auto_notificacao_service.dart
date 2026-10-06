import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notificacao_service.dart';
import '../core/api.dart';

/// 🧠 MOTOR INTELIGENTE DE NOTIFICAÇÕES DO PACEMIND
/// Oferece um fluxo dinâmico, contextualizado e não repetitivo:
/// 1. Agendamento antecipado de 7 dias com conteúdos distintos para cada dia da semana:
///    - 07:30: Inspiração, metas e foco técnico diário (cadência, respiração, ritmo).
///    - 08:30: Check-in diário de prontidão física e bem-estar (perguntas rotativas).
///    - 21:30: Higiene do sono, síntese muscular e recuperação noturna.
/// 2. Notificação instantânea pós-treino com métricas detalhadas.
/// 3. Lembrete pós-treino de 20 minutos com dicas rotativas de hidratação e reposição.
/// 4. Celebração automática quando a meta semanal for batida.
/// 5. Alertas fisiológicos de sobrecarga (ACWR) e dor muscular.
/// 6. Sincronização segura sem duplicatas e sem spam de push quando o app estiver em primeiro plano.
class AutoNotificacaoService {
  static bool _inicializado = false;
  static bool _checandoEmAndamento = false;
  static bool _sincronizando = false;
  static Timer? _timerSincronizacao;
  static DateTime? _ultimaChecagem;

  // 🏃 POOL DE MENSAGENS MATINAIS (07:30) POR DIA DA SEMANA (1 = Seg, 7 = Dom)
  static final Map<int, Map<String, String>> _mensagensManhaPorDia = {
    1: {
      "titulo": "🏃 Segunda-feira: Planejamento & Foco",
      "corpo":
          "Comece a semana com propósito! Abra o PaceMind para conferir seus treinos planejados e construir sua consistência.",
    },
    2: {
      "titulo": "⚡ Terça-feira: Cadência Eficiente",
      "corpo":
          "Passadas mais curtas e ágeis reduzem o impacto articular nos joelhos. Experimente focar no ritmo dos seus pés hoje!",
    },
    3: {
      "titulo": "🎯 Quarta-feira: Ritmo & Fôlego",
      "corpo":
          "Metade da semana! Que tal incluir variações leves de ritmo para manter o coração forte e a mente afiada?",
    },
    4: {
      "titulo": "🫁 Quinta-feira: Respiração Consciente",
      "corpo":
          "Em corridas moderadas, sincronize o ar com suas passadas (ex: 3 tempos inspirando, 3 expirando) para evitar fadiga.",
    },
    5: {
      "titulo": "🔥 Sexta-feira: Hidratação & Energia",
      "corpo":
          "Fechando os dias úteis com dedicação! Beba água com frequência para preparar a musculatura para o fim de semana.",
    },
    6: {
      "titulo": "🌳 Sábado na Pista: Curta o Percurso!",
      "corpo":
          "Dia clássico de corrida ao ar livre. Mantenha ritmo confortável, sinta o vento e curta cada quilômetro com saúde!",
    },
    7: {
      "titulo": "🧘 Domingo: Equilíbrio & Regeneração",
      "corpo":
          "Descanso também é treino! Um trote muito leve em Zona 1 ou caminhada regenerativa renova suas energias.",
    },
  };

  // ❤️ POOL DE MENSAGENS DE CHECK-IN DE BEM-ESTAR (08:30) POR DIA DA SEMANA
  static final Map<int, Map<String, String>> _mensagensCheckinPorDia = {
    1: {
      "titulo": "❤️ Segunda-feira: Como está sua energia?",
      "corpo":
          "1 minutinho de check-in matinal calibra sua prontidão física para começar a semana com segurança e vigor.",
    },
    2: {
      "titulo": "❤️ Check-in de Sono e Recuperação",
      "corpo":
          "Dormiu bem esta noite? Registre sua percepção de fadiga para sabermos se hoje pede intensidade ou rodagem leve.",
    },
    3: {
      "titulo": "❤️ Monitoramento de Dores Musculares",
      "corpo":
          "Sentiu algum incômodo após os treinos recentes? Registre no check-in para proteger suas articulações e tendões.",
    },
    4: {
      "titulo": "❤️ Termômetro de Prontidão do Dia",
      "corpo":
          "Avalie seu humor, sono e cansaço. Identificar sobrecarga cedo é o melhor escudo contra lesões.",
    },
    5: {
      "titulo": "❤️ Sexta-feira: Como o corpo acordou?",
      "corpo":
          "Antes de planejar o fim de semana, faça seu check-in diário e confira seu parecer fisiológico no PaceMind.",
    },
    6: {
      "titulo": "❤️ Prontidão para a Corrida de Sábado",
      "corpo":
          "Como estão suas pernas hoje? Faça seu check-in rápido antes de calçar o tênis e começar sua atividade.",
    },
    7: {
      "titulo": "❤️ Domingo: Balanço de Bem-Estar",
      "corpo":
          "Como você se sente após a semana de treinos? Registre seu descanso e dores para recalibrar seu volume.",
    },
  };

  // 🌙 POOL DE MENSAGENS NOTURNAS DE RECUPERAÇÃO (21:30) POR DIA DA SEMANA
  static final Map<int, Map<String, String>> _mensagensNoitePorDia = {
    1: {
      "titulo": "🌙 Segunda-feira: Higiene do Sono",
      "corpo":
          "Reduzir luzes fortes e telas 30 minutos antes de deitar potencializa a melatonina e melhora a recuperação.",
    },
    2: {
      "titulo": "🌙 Sono Profundo & Síntese Muscular",
      "corpo":
          "É durante o sono profundo que o corpo repara as microlesões do treino. Priorize uma noite tranquila e revigorante!",
    },
    3: {
      "titulo": "🌙 Desacelerando o Ritmo",
      "corpo":
          "Faça 5 minutos de respiração calma e profunda pelo diafragma para diminuir a frequência cardíaca antes de dormir.",
    },
    4: {
      "titulo": "🌙 Hidratação Noturna Consciente",
      "corpo":
          "Tome um copo de água leve e evite refeições pesadas tarde da noite para não fragmentar seu repouso.",
    },
    5: {
      "titulo": "🌙 Preparação para o Treino de Amanhã",
      "corpo":
          "Uma noite reparadora é o melhor pré-treino para o sábado. Descanse o corpo e a mente para acordar com gás!",
    },
    6: {
      "titulo": "🌙 Recuperação do Longão",
      "corpo":
          "Treinou forte hoje? Priorize 7 a 8 horas de sono contínuo para restabelecer seus estoques de energia.",
    },
    7: {
      "titulo": "🌙 Domingo: Renovação para a Nova Semana",
      "corpo":
          "Dormir cedo no domingo garante mente descansada e corpo pronto para novos desafios. Bons sonhos!",
    },
  };

  // 💧 DICAS ROTATIVAS PÓS-TREINO (20 minutos)
  static final List<Map<String, String>> _dicasPosTreino = [
    {
      "titulo": "💧 Hora da Hidratação e Eletrólitos!",
      "corpo":
          "Excelente corrida! Beba água e reposicione eletrólitos nas próximas 2 horas para acelerar a drenagem de lactato.",
    },
    {
      "titulo": "🍌 Janela Nutricional Pós-Treino",
      "corpo":
          "Consumir uma fonte rápida de carboidratos com proteínas agora ajuda seu corpo a recompor o glicogênio muscular.",
    },
    {
      "titulo": "🧘 Soltura e Alongamento Leve",
      "corpo":
          "Alongue panturrilhas e quadríceps de forma suave sem forçar o limite. Isso alivia a tensão e evita encurtamento.",
    },
    {
      "titulo": "🧊 Pernas Elevadas para Desinchar",
      "corpo":
          "Tente colocar as pernas elevadas por 10 minutos hoje. Isso estimula o retorno venoso e reduz o peso nas pernas.",
    },
  ];

  /// Inicializa o motor de notificações, agenda o ciclo semanal e inicia sincronização
  static Future<void> inicializar() async {
    if (_inicializado) return;

    try {
      await NotificacaoService.inicializar();
      _inicializado = true;

      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool("notificacoes") ?? true)) return;

      // Agenda o ciclo dinâmico dos próximos 7 dias
      await _configurarFluxoSemanalDinamico();

      // Executa checagem inteligente com proteção de concorrência
      executarChecagemInteligente();

      // Configura sincronização periódica a cada 2 minutos enquanto o app estiver aberto
      _timerSincronizacao?.cancel();
      _timerSincronizacao = Timer.periodic(const Duration(minutes: 2), (_) {
        sincronizarNotificacoesPush();
      });
    } catch (e) {
      debugPrint("[AutoNotificacaoService] Erro ao inicializar: $e");
    }
  }

  static Future<void> atualizarPreferencia(bool ativa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notificacoes", ativa);

    if (!ativa) {
      _timerSincronizacao?.cancel();
      _timerSincronizacao = null;
      await NotificacaoService.cancelarTodas();
      return;
    }

    await NotificacaoService.inicializar();
    await _configurarFluxoSemanalDinamico();
    await executarChecagemInteligente();
    _timerSincronizacao?.cancel();
    _timerSincronizacao = Timer.periodic(const Duration(minutes: 2), (_) {
      sincronizarNotificacoesPush();
    });
  }

  /// ⏰ 1. CONFIGURA O FLUXO SEMANAL DINÂMICO DOS PRÓXIMOS 7 DIAS
  /// Cada dia da semana tem mensagens exclusivas agendadas no sistema operacional.
  /// Dessa forma, mesmo com o app fechado por dias, o usuário recebe mensagens variadas e contextuais!
  static Future<void> _configurarFluxoSemanalDinamico() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool("notificacoes") ?? true)) return;

      final agora = DateTime.now();
      final hojeIso = agora.toIso8601String().substring(0, 10);
      final ultimoCheckinHoje =
          prefs.getString("ultimo_checkin_wellness_data") == hojeIso;

      // Limpa IDs de agendamento anteriores (100 a 145) para evitar sobreposição ou mensagens antigas
      for (int id = 100; id <= 145; id++) {
        await NotificacaoService.cancelar(id);
      }

      // Agenda para os próximos 7 dias (0 = hoje, 1 = amanhã, ..., 6)
      for (int i = 0; i < 7; i++) {
        final dataAlvo = agora.add(Duration(days: i));
        final diaSemana = dataAlvo.weekday; // 1 = Seg, 7 = Dom

        // --- 07:30 - Mensagem Matinal de Treino / Dica Técnica ---
        final dataManha = DateTime(
          dataAlvo.year,
          dataAlvo.month,
          dataAlvo.day,
          7,
          30,
        );
        if (dataManha.isAfter(agora)) {
          final msgManha = _mensagensManhaPorDia[diaSemana] ??
              _mensagensManhaPorDia[1]!;
          await NotificacaoService.agendarNotificacao(
            id: 110 + i,
            titulo: msgManha["titulo"]!,
            corpo: msgManha["corpo"]!,
            dataHora: dataManha,
            canal: 'lembretes',
          );
        }

        // --- 08:30 - Check-in Diário de Bem-Estar e Prontidão ---
        final dataCheckin = DateTime(
          dataAlvo.year,
          dataAlvo.month,
          dataAlvo.day,
          8,
          30,
        );
        // Se for hoje e o usuário já fez o check-in, NÃO agenda!
        final deveAgendarCheckin = (i > 0) || !ultimoCheckinHoje;
        if (deveAgendarCheckin && dataCheckin.isAfter(agora)) {
          final msgCheckin = _mensagensCheckinPorDia[diaSemana] ??
              _mensagensCheckinPorDia[1]!;
          await NotificacaoService.agendarNotificacao(
            id: 120 + i,
            titulo: msgCheckin["titulo"]!,
            corpo: msgCheckin["corpo"]!,
            dataHora: dataCheckin,
            canal: 'lembretes',
          );
        }

        // --- 21:30 - Lembrete Noturno de Recuperação e Sono ---
        final dataNoite = DateTime(
          dataAlvo.year,
          dataAlvo.month,
          dataAlvo.day,
          21,
          30,
        );
        if (dataNoite.isAfter(agora)) {
          final msgNoite = _mensagensNoitePorDia[diaSemana] ??
              _mensagensNoitePorDia[1]!;
          await NotificacaoService.agendarNotificacao(
            id: 130 + i,
            titulo: msgNoite["titulo"]!,
            corpo: msgNoite["corpo"]!,
            dataHora: dataNoite,
            canal: 'lembretes',
          );
        }
      }

      debugPrint(
        "[AutoNotificacaoService] Ciclo dinâmico de 7 dias configurado com sucesso!",
      );
    } catch (e) {
      debugPrint("[AutoNotificacaoService] Erro ao agendar ciclo semanal: $e");
    }
  }

  /// Informa que o usuário concluiu o check-in de hoje para cancelar o lembrete pendente
  static Future<void> registrarCheckinRealizadoHoje() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hojeIso = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString("ultimo_checkin_wellness_data", hojeIso);
      // Cancela o lembrete de check-in de hoje (id: 120)
      await NotificacaoService.cancelar(120);
      debugPrint(
        "[AutoNotificacaoService] Check-in de hoje registrado. Lembrete de check-in cancelado.",
      );
    } catch (_) {}
  }

  /// 🤖 2. EXECUTA CHECAGEM INTELIGENTE COM O BACKEND (PROTEGIDO CONTRA CONCORRÊNCIA)
  static Future<void> executarChecagemInteligente() async {
    if (_checandoEmAndamento) return;

    // Debounce de 30 segundos entre checagens para evitar requisições redundantes
    if (_ultimaChecagem != null &&
        DateTime.now().difference(_ultimaChecagem!).inSeconds < 30) {
      return;
    }

    _checandoEmAndamento = true;
    _ultimaChecagem = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool("notificacoes") ?? true)) return;

      // 1. O backend avalia as regras esportivas e insere no banco caso haja novidade
      await Api.verificarNotificacoesAutomaticas();
    } catch (e) {
      debugPrint("[AutoNotificacaoService] Erro na checagem inteligente: $e");
    } finally {
      _checandoEmAndamento = false;
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

      final hojeIso = DateTime.now().toIso8601String().substring(0, 10);
      enviadasSet.add("${hojeIso}_${titulo.trim().toLowerCase()}");
      enviadasSet.add("${titulo.trim()}_${corpo.trim()}");

      final listFinal = enviadasSet.toList();
      if (listFinal.length > 300) {
        listFinal.removeRange(0, listFinal.length - 300);
      }
      await prefs.setStringList('push_notificacoes_enviadas', listFinal);
    } catch (_) {}
  }

  /// 📲 3. SINCRONIZAÇÃO INTELIGENTE DE PUSH (COM SUPRESSÃO DE REDUNDÂNCIAS)
  static Future<void> sincronizarNotificacoesPush() async {
    if (_sincronizando) return;
    _sincronizando = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool("notificacoes") ?? true)) return;
      final token = prefs.getString("token");
      if (token == null || token.isEmpty) return;

      // Se o app já está em primeiro plano na tela, não dispara banners intrusivos na barra do celular
      // para notificações de rotina, mantendo a central de notificações limpa e sem poluição
      final bool appEmPrimeiroPlano =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

      final enviadasList =
          prefs.getStringList('push_notificacoes_enviadas') ?? [];
      final Set<String> enviadasSet = enviadasList.toSet();

      final notificacoes = await Api.listarNotificacoes();
      if (notificacoes.isEmpty) return;

      bool houveEnvio = false;
      final hojeIso = DateTime.now().toIso8601String().substring(0, 10);

      // Pega as notificações não lidas mais recentes (até 5)
      final naoLidas = notificacoes
          .where((n) => n['lida'] != true)
          .take(5)
          .toList();

      for (final n in naoLidas) {
        final idStr = (n['id_notificacao'] ?? '').toString();
        final titulo = (n['titulo'] ?? '').toString().trim();
        final corpo = (n['mensagem'] ?? '').toString().trim();
        final chaveConteudoHoje = "${hojeIso}_${titulo.toLowerCase()}";
        final chaveExata = "${titulo}_$corpo";

        // 🛡️ Filtro Antiduplicação Estrito:
        if (idStr.isNotEmpty && enviadasSet.contains(idStr)) continue;
        if (chaveConteudoHoje.isNotEmpty &&
            enviadasSet.contains(chaveConteudoHoje)) {
          continue;
        }
        if (chaveExata.isNotEmpty && enviadasSet.contains(chaveExata)) {
          continue;
        }

        final tipo = (n['tipo'] ?? '').toString().toLowerCase();

        // Check-in matinal já é coberto pelos lembretes locais inteligentes do celular
        if (tipo.contains('sistema') &&
            (titulo.toLowerCase().contains('check-in') ||
                titulo.toLowerCase().contains('bem-estar'))) {
          // Marca como processada para não duplicar com o agendador local
          if (idStr.isNotEmpty) enviadasSet.add(idStr);
          enviadasSet.add(chaveConteudoHoje);
          houveEnvio = true;
          continue;
        }

        // Se o app está aberto na cara do usuário, não exibe banners no topo para notificações que não sejam alertas críticos
        if (appEmPrimeiroPlano && !tipo.contains('alerta')) {
          if (idStr.isNotEmpty) enviadasSet.add(idStr);
          enviadasSet.add(chaveConteudoHoje);
          houveEnvio = true;
          continue;
        }

        String canal = 'lembretes';
        if (tipo.contains('alerta') || tipo.contains('overtraining')) {
          canal = 'alertas';
        } else if (tipo.contains('meta')) {
          canal = 'metas';
        } else if (tipo.contains('treino') || tipo.contains('corrida')) {
          canal = 'treinos';
        }

        // Gera um ID determinístico a partir do hash do UUID para o Android
        final int notifId = idStr.isNotEmpty
            ? ((idStr.hashCode.abs() % 80000) + 10000)
            : (2000 + enviadasSet.length);

        await NotificacaoService.mostrarNotificacao(
          id: notifId,
          titulo: titulo.isNotEmpty ? titulo : 'PaceMind',
          corpo: corpo,
          canal: canal,
        );

        if (idStr.isNotEmpty) enviadasSet.add(idStr);
        enviadasSet.add(chaveConteudoHoje);
        enviadasSet.add(chaveExata);
        houveEnvio = true;
      }

      if (houveEnvio) {
        final listFinal = enviadasSet.toList();
        if (listFinal.length > 300) {
          listFinal.removeRange(0, listFinal.length - 300);
        }
        await prefs.setStringList('push_notificacoes_enviadas', listFinal);
      }
    } catch (e) {
      debugPrint(
        "[AutoNotificacaoService] Erro ao sincronizar notificações push: $e",
      );
    } finally {
      _sincronizando = false;
    }
  }

  /// 🏁 4. DISPARADA AUTOMATICAMENTE AO CONCLUIR QUALQUER CORRIDA OU TREINO
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

    // 1. Notificação imediata de celebração do treino no celular
    await NotificacaoService.mostrarNotificacao(
      id: 201,
      titulo: tituloPush,
      corpo: corpoPush,
      canal: 'treinos',
    );

    // Registra chaves antiduplicação de imediato
    await registrarNotificacaoLocalEnviada(tituloPush, corpoPush);
    await registrarNotificacaoLocalEnviada(tituloApi, msgApi);

    // Salva na central de notificações da API e captura o ID retornado
    try {
      final notifCriada = await Api.criarNotificacao(
        titulo: tituloApi,
        mensagem: msgApi,
        tipo: "treino",
      );
      final idCriado = notifCriada?["id_notificacao"]?.toString();
      if (idCriado != null && idCriado.isNotEmpty) {
        await registrarNotificacaoLocalEnviada(
          tituloApi,
          msgApi,
          idStr: idCriado,
        );
      }
    } catch (_) {}

    // 2. Agenda automaticamente o Lembrete de Hidratação/Nutrição para 20 minutos depois (com pool variado)
    final dicaEscolhida =
        _dicasPosTreino[DateTime.now().second % _dicasPosTreino.length];
    final horaHidratacao = DateTime.now().add(const Duration(minutes: 20));
    await NotificacaoService.agendarNotificacao(
      id: 202,
      titulo: dicaEscolhida["titulo"]!,
      corpo: dicaEscolhida["corpo"]!,
      dataHora: horaHidratacao,
      canal: 'lembretes',
    );

    // 3. Dispara checagem em background para ver se bateu metas ou gerou alertas
    Future.delayed(const Duration(seconds: 2), () {
      executarChecagemInteligente();
    });
  }

  /// 🏆 5. CELEBRAÇÃO AUTOMÁTICA QUANDO A META SEMANAL É BATIDA
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

    try {
      final notifCriada = await Api.criarNotificacao(
        titulo: tituloApi,
        mensagem: msgApi,
        tipo: "meta",
      );
      final idCriado = notifCriada?["id_notificacao"]?.toString();
      if (idCriado != null && idCriado.isNotEmpty) {
        await registrarNotificacaoLocalEnviada(
          tituloApi,
          msgApi,
          idStr: idCriado,
        );
      }
    } catch (_) {}
  }

  /// ⚠️ 6. ALERTA AUTOMÁTICO DE RISCO DE OVERTRAINING / SOBRECARGA
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

  /// 🛡️ 7. ALERTA AUTOMÁTICO APÓS CHECK-IN DIÁRIO DE BEM-ESTAR
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

  /// 📅 8. AGENDA LEMBRETES DE COMPROMISSO (1 semana antes, 1 dia antes e no dia)
  static Future<void> agendarLembreteAgenda({
    required int id,
    required String titulo,
    required DateTime dataInicio,
    required String tipo,
  }) async {
    final agora = DateTime.now();
    if (dataInicio.isBefore(agora)) return;

    final baseId = (id.abs() % 100000);
    final idSemana = (baseId * 10) + 1;
    final idVespera = (baseId * 10) + 2;
    final idDia = (baseId * 10) + 3;

    final horaFormatada =
        "${dataInicio.hour.toString().padLeft(2, '0')}:${dataInicio.minute.toString().padLeft(2, '0')}";
    final dataFormatada =
        "${dataInicio.day.toString().padLeft(2, '0')}/${dataInicio.month.toString().padLeft(2, '0')}";

    // 1️⃣ UMA SEMANA ANTES (7 dias antes, se marcado com intervalo longo)
    final diferencaTotalDias = dataInicio.difference(agora).inDays;
    if (diferencaTotalDias >= 7) {
      final horaSemanaAntes = DateTime(
        dataInicio.year,
        dataInicio.month,
        dataInicio.day - 7,
        9, // Às 09:00 da manhã de 7 dias antes
        0,
      );

      if (horaSemanaAntes.isAfter(agora)) {
        await NotificacaoService.agendarNotificacao(
          id: idSemana,
          titulo: "📅 Em 1 semana: $titulo",
          corpo:
              "Você tem $tipo agendado para $dataFormatada às $horaFormatada. Mantenha seu planejamento!",
          dataHora: horaSemanaAntes,
          canal: 'lembretes',
        );
      }
    }

    // 2️⃣ UM DIA ANTES (Véspera)
    final diaAnterior = dataInicio.subtract(const Duration(days: 1));
    final horaVespera = DateTime(
      diaAnterior.year,
      diaAnterior.month,
      diaAnterior.day,
      18, // Às 18:00 da véspera
      0,
    );

    // Se já passou das 18h da véspera, tenta 24h antes
    final horaEfetivaVespera = horaVespera.isAfter(agora)
        ? horaVespera
        : dataInicio.subtract(const Duration(hours: 24));

    if (horaEfetivaVespera.isAfter(agora)) {
      await NotificacaoService.agendarNotificacao(
        id: idVespera,
        titulo: "⏰ Amanhã: $titulo!",
        corpo: tipo.toLowerCase().contains("prova") ||
                tipo.toLowerCase().contains("evento")
            ? "Sua prova é amanhã às $horaFormatada! Prepare seu uniforme, hidratação e garanta uma boa noite de sono."
            : "Lembrete: você tem $tipo amanhã às $horaFormatada. Organize seus materiais!",
        dataHora: horaEfetivaVespera,
        canal: 'lembretes',
      );
    }

    // 3️⃣ NO DIA DO COMPROMISSO
    DateTime horaNoDia;
    if (dataInicio.hour <= 9) {
      horaNoDia = dataInicio.subtract(const Duration(hours: 1));
    } else {
      horaNoDia = DateTime(
        dataInicio.year,
        dataInicio.month,
        dataInicio.day,
        8,
        0,
      );
    }

    if (horaNoDia.isAfter(agora)) {
      await NotificacaoService.agendarNotificacao(
        id: idDia,
        titulo: "🔔 Hoje: $titulo",
        corpo:
            "Seu compromisso de $tipo está marcado para hoje às $horaFormatada.",
        dataHora: horaNoDia,
        canal: 'lembretes',
      );
    }
  }

  /// Cancela os lembretes agendados de um compromisso
  static Future<void> cancelarLembreteAgenda(int id) async {
    final baseId = (id.abs() % 100000);
    await NotificacaoService.cancelar((baseId * 10) + 1);
    await NotificacaoService.cancelar((baseId * 10) + 2);
    await NotificacaoService.cancelar((baseId * 10) + 3);
  }

  /// 🧪 9. TESTADOR DE NOTIFICAÇÕES
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
