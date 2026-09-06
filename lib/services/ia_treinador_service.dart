import 'dart:math';
import '../core/api.dart';

/// Contexto de dados reais agregados do atleta para alimentar a PaceMind IA.
class ContextoAtleta {
  final String nome;
  final double kmSemana;
  final double metaSemanalKm;
  final int treinosSemana;
  final int paceReferenciaSegundos;
  final String statusFadiga;
  final double acwr;
  final List<dynamic> metas;
  final List<dynamic> treinosRecentes;
  final List<dynamic> eventosInscritos;

  ContextoAtleta({
    required this.nome,
    required this.kmSemana,
    required this.metaSemanalKm,
    required this.treinosSemana,
    required this.paceReferenciaSegundos,
    required this.statusFadiga,
    required this.acwr,
    required this.metas,
    required this.treinosRecentes,
    required this.eventosInscritos,
  });

  String formatarPace(int segundos) {
    if (segundos <= 0) return "não configurado";
    final min = segundos ~/ 60;
    final seg = segundos % 60;
    return "$min'${seg.toString().padLeft(2, '0')}\"/km";
  }
}

/// Motor próprio inteligente da PaceMind IA.
/// Funciona 100% offline (sem chaves de API externas), analisando dados reais
/// e retornando listas de mensagens fracionadas para conversa fluida e humana.
class IaTreinadorService {
  ContextoAtleta? _contextoCache;
  DateTime? _ultimoCarregamento;

  /// Atualiza ou carrega os dados reais do usuário a partir dos endpoints do app.
  Future<ContextoAtleta> obterContextoAtualizado({bool forcar = false}) async {
    final agora = DateTime.now();
    if (!forcar &&
        _contextoCache != null &&
        _ultimoCarregamento != null &&
        agora.difference(_ultimoCarregamento!).inMinutes < 2) {
      return _contextoCache!;
    }

    String nome = "Atleta";
    int paceRef = 0;
    double metaSemanal = 30.0;
    double kmSemana = 0.0;
    int treinosSemana = 0;
    String statusFadiga = "Equilibrada";
    double acwr = 1.0;
    List<dynamic> metas = [];
    List<dynamic> treinos = [];
    List<dynamic> inscricoes = [];

    // 1. Perfil
    try {
      final perfil = await Api.getProfile();
      nome = perfil["nome_usuario"] ?? perfil["nome"] ?? "Atleta";
      paceRef = int.tryParse(perfil["pace_referencia_segundos"]?.toString() ?? "0") ?? 0;
      metaSemanal = double.tryParse(perfil["objetivo_semanal_km"]?.toString() ?? "30") ?? 30.0;
    } catch (_) {
      try {
        final me = await Api.me();
        nome = me["nome_usuario"] ?? me["nome"] ?? "Atleta";
      } catch (_) {}
    }

    // 2. Dashboard
    try {
      final dash = await Api.getDashboard();
      final resumo = dash["resumo"] ?? {};
      kmSemana = double.tryParse(resumo["total_km"]?.toString() ?? "0") ?? 0.0;
      treinosSemana = int.tryParse(resumo["total_treinos"]?.toString() ?? "0") ?? 0;
    } catch (_) {}

    // 3. Overtraining
    try {
      final ot = await Api.getOvertraining();
      if (ot["status"] != null) {
        statusFadiga = ot["status"].toString();
      }
      if (ot["acwr"] != null) {
        acwr = double.tryParse(ot["acwr"].toString()) ?? 1.0;
      }
    } catch (_) {}

    // 4. Metas
    try {
      metas = await Api.listarMetas();
    } catch (_) {}

    // 5. Treinos Concluídos
    try {
      treinos = await Api.listarTreinosConcluidos();
    } catch (_) {}

    // 6. Inscrições em Eventos
    try {
      inscricoes = await Api.minhasInscricoes();
    } catch (_) {}

    _contextoCache = ContextoAtleta(
      nome: nome,
      kmSemana: kmSemana,
      metaSemanalKm: metaSemanal,
      treinosSemana: treinosSemana,
      paceReferenciaSegundos: paceRef,
      statusFadiga: statusFadiga,
      acwr: acwr,
      metas: metas,
      treinosRecentes: treinos,
      eventosInscritos: inscricoes,
    );

    _ultimoCarregamento = agora;
    return _contextoCache!;
  }

  /// Normaliza texto para facilitar a detecção semântica de intenções.
  String _normalizar(String texto) {
    String limpo = texto.toLowerCase().trim();
    const acentos = {
      'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n',
    };

    acentos.forEach((chave, valor) {
      limpo = limpo.replaceAll(chave, valor);
    });

    limpo = limpo.replaceAll(RegExp(r'[^\w\s]'), ' ');
    limpo = limpo.replaceAll(RegExp(r'\s+'), ' ');
    return limpo;
  }

  bool _tem(String texto, List<String> termos) {
    for (var termo in termos) {
      final tNorm = _normalizar(termo);
      if (texto.contains(tNorm)) return true;
    }
    return false;
  }

  /// Processa a pergunta do usuário e devolve uma LISTA sequencial de mensagens
  /// com estilo conversacional humano e dados reais injetados.
  Future<List<String>> processarPergunta(String perguntaOriginal) async {
    final ctx = await obterContextoAtualizado();
    final p = _normalizar(perguntaOriginal);

    // 1. Saudações e Cumprimentos
    if (_tem(p, ["ola", "oi", "e ai", "opa", "bom dia", "boa tarde", "boa noite", "fala ai", "hello", "como vai"])) {
      return _responderSaudacao(ctx);
    }

    // 2. Apresentação e Identidade da IA
    if (_tem(p, ["quem e voce", "o que voce faz", "como voce funciona", "qual seu papel", "sua funcao", "me ajude", "o que voce pode fazer"])) {
      return [
        "Olá, ${ctx.nome}! Eu sou a PaceMind IA, seu assistente e treinador inteligente de corrida e bem-estar no app.",
        "Eu analiso os seus dados de treinos, quilometragem acumulada, zonas de ritmo, controle de fadiga e metas para te dar orientações sob medida.",
        "Você pode me perguntar sobre como baixar seu pace, como organizar sua semana, orientações para provas, recuperação de dores ou pedir uma análise completa do seu momento atual! O que gostaria de explorar hoje?"
      ];
    }

    // 3. Análise Detalhada dos Dados do Usuário
    if (_tem(p, [
      "analise meus dados", "analise meus treinos", "meus dados", "meu resumo",
      "como estao meus treinos", "como estou indo", "minha semana", "meu desempenho",
      "minha evolucao", "minha performance", "ver meus treinos", "analisar dados"
    ])) {
      return _responderAnaliseDados(ctx);
    }

    // 4. Ritmo e Pace
    if (_tem(p, [
      "pace", "ritmo", "baixar tempo", "correr mais rapido", "melhorar velocidade",
      "pace medio", "pace ideal", "o que e pace", "ritmo de prova", "acelerar"
    ])) {
      return _responderPace(ctx, p);
    }

    // 5. Planejamento Semanal e Estrutura de Treino
    if (_tem(p, [
      "organizar semana", "quantos dias correr", "planilha", "volume semanal",
      "planejamento", "como treinar essa semana", "quantos km correr", "rotina de treino"
    ])) {
      return _responderPlanejamento(ctx);
    }

    // 6. Treinos de Tiro e Intervalados
    if (_tem(p, ["tiro", "intervalado", "fartlek", "treino de velocidade", "tiros de", "pista"])) {
      return [
        "Os treinos intervalados (ou tiros) são o principal estímulo para elevar seu consumo máximo de oxigênio (VO2 máx) e te ensinar a tolerar ritmos mais fortes.",
        "Uma estrutura clássica para quem quer evoluir com segurança é:\n• Aquecimento: 10 a 15 min de trote leve (Z1/Z2) + educativos.\n• Parte principal: 6 a 8 repetições de 400m fortes (Z4) com 1 min e 30s de caminhada ou trote suave de recuperação.\n• Desaquecimento: 5 a 10 min de trote muito leve.",
        "Importante: nunca faça treinos de tiro em dias consecutivos e garanta que sua musculatura esteja descansada antes de começar!"
      ];
    }

    // 7. Treino Longo / Longão
    if (_tem(p, ["longao", "treino longo", "corrida longa", "distancia longa", "quantos km no longo"])) {
      return [
        "O longão é o pilar da resistência aeróbica e da adaptação do corpo para queimar gordura como combustível!",
        "A regra de ouro é manter o ritmo estritamente conversacional (Zona 2), onde você consiga falar frases inteiras sem ficar ofegante.",
        "Em termos de volume, o longão idealmente não deve ultrapassar de 30% a 35% do volume total que você corre na semana inteira. Isso protege suas articulações contra lesões por sobrecarga."
      ];
    }

    // 8. Descanso, Recuperação e Sono
    if (_tem(p, [
      "descanso", "recuperacao", "recuperar", "sono", "dormir", "estou cansado",
      "posso correr hoje", "devo descansar", "regenerativo", "fadiga"
    ])) {
      return _responderDescanso(ctx);
    }

    // 9. Dores, Lesões e Cuidados Fisiológicos
    if (_tem(p, [
      "dor", "doendo", "canelite", "joelho", "canela", "panturrilha", "pe",
      "fascite", "lesao", "fisgada", "inflamacao", "alongar", "alongamento"
    ])) {
      return _responderDores(ctx, p);
    }

    // 10. Overtraining e Carga de Treino (ACWR)
    if (_tem(p, ["overtraining", "acwr", "sobrecarga", "estafa", "excesso de treino", "carga de treino"])) {
      return _responderOvertraining(ctx);
    }

    // 11. Metas do Aplicativo
    if (_tem(p, ["meta", "metas", "objetivo", "atingir meta", "bater meta"])) {
      return _responderMetas(ctx);
    }

    // 12. Eventos, Provas e Corridas de Rua
    if (_tem(p, ["evento", "eventos", "prova", "corrida de rua", "maratona", "meia maratona", "5k", "10k", "21k", "42k"])) {
      return _responderEventos(ctx, p);
    }

    // 13. Alimentação, Nutrição e Hidratação
    if (_tem(p, [
      "comer", "comida", "alimentacao", "nutricao", "jejum", "gel", "carbo",
      "carboidrato", "agua", "hidratacao", "pos treino", "pre treino", "o que comer"
    ])) {
      return _responderNutricao();
    }

    // 14. Respiração, Asma e Saúde Pulmonar (Diferencial PaceMind)
    if (_tem(p, [
      "respirar", "respiracao", "falta de ar", "asma", "pulmao", "ar",
      "nariz ou boca", "ofegante", "asfixia", "bombinha", "acq"
    ])) {
      return _responderRespiracao(ctx);
    }

    // 15. Frequência Cardíaca e Zonas de Treino
    if (_tem(p, [
      "frequencia cardiaca", "batimento", "bpm", "zonas", "zona 2", "zona 4",
      "limiar", "cardio", "coracao acelerado"
    ])) {
      return _responderZonasCardiacas();
    }

    // 16. Motivação, Cansaço Mental e Preguiça
    if (_tem(p, [
      "preguica", "desanimado", "sem vontade", "motivacao", "desistir",
      "dificil", "nao quero correr", "chovendo", "chuva", "frio", "consistencia"
    ])) {
      return _responderMotivacao(ctx);
    }

    // 17. Tênis e Equipamentos
    if (_tem(p, [
      "tenis", "calcado", "drop", "placa de carbono", "amortecimento",
      "meia", "roupa", "relogio", "gps", "equipamento"
    ])) {
      return [
        "A escolha do tênis ideal deve priorizar conforto e o tipo de treino que você pretende realizar.",
        "Para o dia a dia e rodagens longas, prefira modelos com bom amortecimento e estabilidade. Deixe modelos com placa de carbono apenas para treinos específicos de ritmo e dias de prova.",
        "Dica prática: revezar entre dois pares diferentes de tênis durante a semana aumenta a durabilidade do calçado e ajuda a variar pequenos estímulos nos músculos e tendões dos pés!"
      ];
    }

    // 18. Agradecimento e Elogios
    if (_tem(p, ["obrigado", "obrigada", "valeu", "show", "top", "muito bom", "otimo", "maravilha", "perfeito", "ajudou muito"])) {
      return [
        "Fico muito feliz em ajudar, ${ctx.nome}! Estar ao seu lado na evolução dos seus treinos é o meu propósito.",
        "Lembre-se: a consistência nos dias comuns constrói as grandes conquistas no dia da prova! Se precisar de qualquer outra orientação ou ajuste na planilha, estou sempre por aqui. Bom treino!"
      ];
    }

    // 19. Despedida
    if (_tem(p, ["tchau", "ate mais", "ate logo", "vou correr", "vou treinar", "fui"])) {
      return [
        "Boa corrida e excelente treino, ${ctx.nome}!",
        "Mantenha uma boa postura, cuide da respiração e hidrate-se bem. Depois me conte como foi!"
      ];
    }

    // 20. Resposta Contextual Inteligente com Sugestões (Fallback)
    return _responderFallback(ctx, perguntaOriginal);
  }

  // ==========================================
  // RESPOSTAS ESPECIALIZADAS MODULARES
  // ==========================================

  List<String> _responderSaudacao(ContextoAtleta ctx) {
    final hora = DateTime.now().hour;
    String periodo = "Olá";
    if (hora >= 5 && hora < 12) {
      periodo = "Bom dia";
    } else if (hora >= 12 && hora < 18) {
      periodo = "Boa tarde";
    } else {
      periodo = "Boa noite";
    }

    List<String> msgs = [
      "$periodo, ${ctx.nome}! Que bom ter você aqui.",
    ];

    if (ctx.kmSemana > 0) {
      msgs.add(
        "Vi aqui no PaceMind que você já acumulou ${ctx.kmSemana.toStringAsFixed(1)} km nesta semana em ${ctx.treinosSemana} sessões.",
      );
    } else {
      msgs.add(
        "Sua semana de treinos está pronta para começar! A meta semanal cadastrada é de ${ctx.metaSemanalKm.toStringAsFixed(0)} km.",
      );
    }

    msgs.add(
      "Como posso te ajudar hoje? Quer revisar seu ritmo, analisar a fadiga, traçar metas ou tirar dúvidas sobre sua preparação?",
    );

    return msgs;
  }

  List<String> _responderAnaliseDados(ContextoAtleta ctx) {
    List<String> msgs = [];

    // Mensagem 1: Resumo geral da semana
    msgs.add(
      "Analisei agora mesmo os seus registros recentes no aplicativo, ${ctx.nome}. Vamos ao seu raio-x esportivo:",
    );

    // Mensagem 2: Métricas de volume e pace
    final pctMeta = ctx.metaSemanalKm > 0
        ? ((ctx.kmSemana / ctx.metaSemanalKm) * 100).round()
        : 0;
    final paceTexto = ctx.formatarPace(ctx.paceReferenciaSegundos);

    msgs.add(
      "📊 Volume da Semana: ${ctx.kmSemana.toStringAsFixed(1)} km realizados de ${ctx.metaSemanalKm.toStringAsFixed(0)} km planejados ($pctMeta% concluído) em ${ctx.treinosSemana} treinos.\n⏱️ Pace de Referência: $paceTexto.\n⚡ Índice de Carga (ACWR): ${ctx.acwr.toStringAsFixed(2)} - Nível de Fadiga: ${ctx.statusFadiga}.",
    );

    // Mensagem 3: Recomendação clínica/desportiva com base na carga
    if (ctx.acwr > 1.4) {
      msgs.add(
        "⚠️ Atenção ao seu índice de carga aguda: você está com uma intensidade acima do habitual (zona de sobrecarga). Minha recomendação técnica para os próximos dias é priorizar rodagens muito leves em Zona 1 ou até mesmo um dia completo de descanso passivo.",
      );
    } else if (pctMeta >= 100) {
      msgs.add(
        "🎉 Parabéns! Você já atingiu 100% da sua meta semanal de quilometragem. Se ainda for correr, mantenha um volume controlado para não gerar desgaste desnecessário.",
      );
    } else {
      final faltam = (ctx.metaSemanalKm - ctx.kmSemana).clamp(0.0, 999.0);
      msgs.add(
        "💪 Você está em uma faixa de progressão segura! Faltam apenas ${faltam.toStringAsFixed(1)} km para fechar sua meta semanal. Mantenha essa regularidade!",
      );
    }

    return msgs;
  }

  List<String> _responderPace(ContextoAtleta ctx, String p) {
    final paceTexto = ctx.formatarPace(ctx.paceReferenciaSegundos);

    List<String> msgs = [
      "O segredo para evoluir o pace sem lesionar não é tentar correr no limite em todos os treinos, mas sim aplicar a polarização de intensidade (regra 80/20).",
      "Isso significa que 80% dos seus quilômetros devem ser em ritmo fácil (Zona 2), onde seu sistema cardiovascular constrói a base capilar e mitocondrial, e apenas 20% em ritmo forte ou de tiro (Zonas 4 e 5).",
    ];

    if (ctx.paceReferenciaSegundos > 0) {
      final paceTiroSegundos = (ctx.paceReferenciaSegundos * 0.90).round();
      final paceLongoSegundos = (ctx.paceReferenciaSegundos * 1.15).round();

      msgs.add(
        "Com base no seu pace de referência de $paceTexto cadastrado no perfil:\n• Rodagens fáceis e longão: em torno de ${ctx.formatarPace(paceLongoSegundos)}.\n• Treinos de ritmo / limiar: próximo a $paceTexto.\n• Tiros de velocidade (400m a 1km): em torno de ${ctx.formatarPace(paceTiroSegundos)}.",
      );
    } else {
      msgs.add(
        "Para calcularmos suas zonas exatas de pace no app, recomendo cadastrar seu pace de referência na tela de Perfil ou registrar um Teste Físico de 3 km na aba de testes!",
      );
    }

    msgs.add(
      "Dica de ouro: aumente a cadência da passada para cerca de 170 a 180 passos por minuto. Isso diminui o impacto no solo e melhora sua velocidade de forma natural!",
    );

    return msgs;
  }

  List<String> _responderPlanejamento(ContextoAtleta ctx) {
    return [
      "Para um planejamento semanal equilibrado, ${ctx.nome}, a estrutura mais eficiente para corredores amadores e intermediários é dividir a semana em 3 a 4 estímulos bem definidos:",
      "1. Terça: Rodagem Base (leve a moderada) de 6 a 8 km.\n2. Quinta: Treino de Qualidade (tiros curtos ou ritmo controlado na frequência limiar).\n3. Sábado ou Domingo: Longão Aeróbico (Zona 2) para ganho de resistência.\n4. Dias intercalados: Descanso total ou fortalecimento muscular (core, panturrilha e quadril).",
      "Atualmente você já cumpriu ${ctx.treinosSemana} sessões nesta semana (${ctx.kmSemana.toStringAsFixed(1)} km). O ideal é nunca aumentar o volume total semanal em mais de 10% de uma semana para outra!"
    ];
  }

  List<String> _responderDescanso(ContextoAtleta ctx) {
    List<String> msgs = [
      "O descanso não é a ausência de treino: é a fase biológica em que o corpo realmente assimila o esforço e constrói novos tecidos mais fortes!",
    ];

    if (ctx.statusFadiga.toLowerCase().contains("alto") || ctx.acwr > 1.3) {
      msgs.add(
        "Consultando seus dados de overtraining, seu nível de estresse muscular está elevado hoje. Sim, recomendo fortemente que você tire o dia de hoje para descanso ou faça apenas uma caminhada leve e liberação miofascial.",
      );
    } else {
      msgs.add(
        "Se você estiver sentindo pernas pesadas, sono irregular ou batimentos em repouso mais altos que o normal, dê ouvidos ao seu corpo e opte por descanso ou uma rodagem regenerativa de 20 a 30 minutos.",
      );
    }

    msgs.add(
      "Garanta também pelo menos 7 a 8 horas de sono de qualidade e beba bastante água ao longo do dia para acelerar a drenagem de resíduos metabólicos musculares."
    );

    return msgs;
  }

  List<String> _responderDores(ContextoAtleta ctx, String p) {
    if (p.contains("canelite") || p.contains("canela")) {
      return [
        "A dor na canela (canelite ou periostite medial da tíbia) é muito comum quando há aumento repentino de volume, passada com overstriding (pé caindo muito à frente do corpo) ou falta de força nas panturrilhas.",
        "Conduta imediata:\n1. Aplique gelo no local por 15 a 20 minutos após o treino.\n2. Reduza o volume e evite terrenos duros como asfalto inclinado por alguns dias.\n3. Fortaleça o músculo tibial anterior (levantando a ponta dos pés com o calcanhar no chão) e faça elevação de panturrilha.\n4. Se a dor for pontual e doer mesmo ao caminhar, consulte um médico ortopedista para descartar fratura por estresse.",
        "Como está a intensidade da sua dor agora, ${ctx.nome}?"
      ];
    }

    if (p.contains("joelho")) {
      return [
        "Dores no joelho na corrida geralmente estão associadas à síndrome do trato iliotibial (lateral do joelho) ou dor patelofemoral (frente do joelho).",
        "Geralmente a causa não é o joelho em si, mas fraqueza no glúteo médio e falta de mobilidade no tornozelo e quadril, o que faz o joelho colapsar para dentro na aterrissagem.",
        "Recomendo incluir exercícios de fortalecimento como ponte de glúteo, passadas laterais com elástico e agachamentos unipodais. Se a dor alterar a sua passada, interrompa a corrida imediatamente."
      ];
    }

    return [
      "Atenção a dores no corpo, ${ctx.nome}: é fundamental diferenciar a dor muscular tardia (aquela que surge 24h após um treino forte e é difusa nas duas pernas) de uma dor lesiva (aguda, pontual, assimétrica ou que piora durante o trote).",
      "Se a dor for aguda ou te obrigar a mancar, não treine hoje! Aplique o protocolo de repouso relativo, gelo local e procure orientação fisioterápica ou médica especializada.",
      "Onde exatamente você está sentindo esse incômodo?"
    ];
  }

  List<String> _responderOvertraining(ContextoAtleta ctx) {
    return [
      "Overtraining (ou síndrome do sobretreinamento) ocorre quando há um descompasso contínuo entre a carga de treino imposta e o tempo de recuperação fornecido ao organismo.",
      "Aqui no PaceMind, monitoramos a relação ACWR (carga aguda das últimas semanas dividida pela carga crônica acumulada). Seu índice atual é de ${ctx.acwr.toStringAsFixed(2)}, indicando uma faixa de fadiga: ${ctx.statusFadiga}.",
      "Principais sinais de alerta:\n• Frequência cardíaca em repouso elevada ao acordar.\n• Sensação de peso constante nas pernas mesmo em treinos fáceis.\n• Irritabilidade, insônia e queda no sistema imunológico.\n\nPara evitar, mantenha o ACWR entre 0.8 e 1.3!"
    ];
  }

  List<String> _responderMetas(ContextoAtleta ctx) {
    if (ctx.metas.isEmpty) {
      return [
        "Notei que você ainda não tem metas ativas cadastradas no PaceMind!",
        "Definir metas claras é comprovadamente o maior estímulo para criar disciplina. Você pode criar metas por distância (ex: 100km no mês), por tempo de corrida ou por número de treinos concluídos.",
        "Deseja acessar a tela de Metas agora para criar o seu primeiro objetivo?"
      ];
    }

    final total = ctx.metas.length;
    final concluidas = ctx.metas.where((m) => m["concluida"] == true).length;
    final primeiraEmAberto = ctx.metas.firstWhere(
      (m) => m["concluida"] != true,
      orElse: () => ctx.metas.first,
    );

    return [
      "Você possui $total metas registradas no PaceMind, das quais $concluidas já foram conquistadas com sucesso!",
      "Seu foco principal no momento é: \"${primeiraEmAberto["titulo"]}\", com objetivo de ${primeiraEmAberto["objetivo"]} (${primeiraEmAberto["tipo"]}).",
      "Para manter o progresso, divida essa meta em pequenas vitórias semanais. Cada treino concluído te deixa mais perto do seu troféu!"
    ];
  }

  List<String> _responderEventos(ContextoAtleta ctx, String p) {
    if (ctx.eventosInscritos.isNotEmpty) {
      return [
        "Sensacional! Você já tem inscrições confirmadas nos eventos do PaceMind!",
        "Na semana anterior à sua prova, faça o famoso 'tapering' (polimento): reduza o volume de treino em cerca de 40% a 50%, mas mantenha pequenos estímulos de ritmo para manter o tônus neuromuscular.",
        "Não invente nada novo no dia da prova: use o tênis com que já treinou, a mesma roupa e a mesma estratégia de café da manhã!"
      ];
    }

    return [
      "Participar de provas e eventos esportivos é uma das melhores experiências do universo da corrida!",
      "Aqui no PaceMind, na aba de Eventos, você encontra provas de 5 km, 10 km, Meia Maratona e desafios abertos com inscrições diretamente pelo app.",
      "Para a sua primeira prova de 5 km ou 10 km, o segredo é não largar no embalo dos atletas mais rápidos: comece os primeiros 2 km abaixo do seu ritmo planejado e acelere progressivamente na segunda metade!"
    ];
  }

  List<String> _responderNutricao() {
    return [
      "A alimentação é o combustível das suas passadas! O que você ingere antes e depois do treino faz uma diferença gigantesca no rendimento e na recuperação muscular.",
      "• Antes do treino (1 a 2 horas antes): carboidratos de fácil digestão (banana com aveia, torrada com geleia, tapioca) e pouca gordura ou fibra para não causar desconforto gástrico.\n• Durante treinos acima de 60-75 minutos: 30g a 40g de carboidrato por hora (gel de carboidrato ou bebida isotônica) e água a cada 2 a 3 km.\n• Pós-treino imediato: combinação de carboidrato para repor glicogênio + proteína (ovos, iogurte, whey protein ou refeição completa) para recuperar as fibras musculares.",
      "Nunca teste suplementos ou alimentos desconhecidos no dia de um evento ou longão!"
    ];
  }

  List<String> _responderRespiracao(ContextoAtleta ctx) {
    return [
      "O PaceMind tem uma atenção clínica especial para a respiração e saúde respiratória, inclusive no controle da asma induzida pelo esforço físico!",
      "Dicas fundamentais de padrão respiratório na corrida:\n1. Respire tanto pelo nariz quanto pela boca: em ritmos de corrida, o nariz sozinho não fornece oxigênio suficiente.\n2. Busque ritmo respiratório ritmado (ex: 2 passos inspirando, 2 passos expirando).\n3. Use respiração diafragmática (expandindo o abdômen ao inspirar) em vez de uma respiração torácica rasa e curta.",
      "Para quem tem asma: faça sempre um aquecimento gradual de pelo menos 10 a 15 minutos em Zona 1. Isso prepara os brônquios suavemente e previne o broncoespasmo induzido pelo exercício. Se usar medicação de alívio prescrita pelo seu médico, tenha-a sempre consigo!"
    ];
  }

  List<String> _responderZonasCardiacas() {
    return [
      "As zonas de frequência cardíaca são a bússola fisiológica do seu treino:",
      "• Zona 1 (50-60% FC máx): Regenerativo e aquecimento.\n• Zona 2 (60-70% FC máx): Base aeróbica e queima eficiente de gordura. Ritmo confortável em que você consegue conversar.\n• Zona 3 (70-80% FC máx): Ritmo moderado e sustentável.\n• Zona 4 (80-90% FC máx): Limiar de lactato. Treinos fortes de ritmo e intervalados longos.\n• Zona 5 (90-100% FC máx): Esforço máximo e tiros curtos de sprint.",
      "Seus treinos devem ser majoritariamente distribuídos na Zona 2 para que seu coração aumente o volume de ejeção sistólica sem desgaste excessivo!"
    ];
  }

  List<String> _responderMotivacao(ContextoAtleta ctx) {
    final frases = [
      "\"A motivação faz você começar, mas é o hábito e a consistência que te levam até a linha de chegada.\"",
      "\"Não existe treino ruim, ruim é o treino que você deixou de fazer.\"",
      "\"A corrida é você contra você mesmo. Cada quilômetro vencido é uma vitória pessoal.\"",
    ];
    final fraseEscolhida = frases[Random().nextInt(frases.length)];

    return [
      "Eu entendo perfeitamente, ${ctx.nome}. Tem dias em que colocar o tênis parece a tarefa mais pesada do mundo!",
      "Aqui vai uma técnica psicológica testada por atletas de elite: faça o acordo dos 5 minutos. Diga a si mesmo que vai sair para trotar apenas 5 minutos. Se ainda quiser parar depois disso, tudo bem. Na imensa maioria das vezes, após aquecer o corpo, a endorfina toma conta e você conclui a sessão inteira!",
      "$fraseEscolhida\n\nVamos lá! Que tal colocar a roupa agora e dar o primeiro passo?"
    ];
  }

  List<String> _responderFallback(ContextoAtleta ctx, String pergunta) {
    return [
      "Entendi o que você trouxe, ${ctx.nome}. Como seu treinador inteligente no PaceMind, posso te orientar em vários aspectos da sua jornada esportiva.",
      "Com base nos seus dados atuais (${ctx.kmSemana.toStringAsFixed(1)} km nesta semana e fadiga ${ctx.statusFadiga}), podemos aprofundar em tópicos como:\n• Como baixar ou controlar seu pace nos treinos;\n• Organização da sua planilha de treinos da semana;\n• Dicas de recuperação, dores e prevenção de lesões;\n• Preparação para provas de 5k, 10k, 21k ou maratona;\n• Controle respiratório e zonas de frequência cardíaca.",
      "Sobre qual desses temas você gostaria de conversar agora?"
    ];
  }
}
