import 'dart:math';
import '../core/api.dart';
import '../utils/date_utils.dart';

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

/// Metadados de ação executada pelo agente da IA.
class AcaoAgente {
  final String
  tipo; // 'treino_criado', 'meta_criada', 'corrida_salva', 'teste_salvo'
  final String titulo;
  final String descricao;
  final String? rotaNavegacao;
  final String? textoBotao;
  final Map<String, dynamic>? dados;

  AcaoAgente({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    this.rotaNavegacao,
    this.textoBotao,
    this.dados,
  });
}

/// Resposta combinada com lista de mensagens conversacionais e ação de agente opcional.
class RespostaIa {
  final List<String> mensagens;
  final AcaoAgente? acao;

  RespostaIa({required this.mensagens, this.acao});
}

/// Motor local de respostas e ações do treinador PaceMind.
class IaTreinadorService {
  IaTreinadorService({ContextoAtleta? contextoInicial}) {
    _contextoCache = contextoInicial;
    if (contextoInicial != null) _ultimoCarregamento = DateTime.now();
  }

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
      paceRef =
          int.tryParse(perfil["pace_referencia_segundos"]?.toString() ?? "0") ??
          0;
      metaSemanal =
          double.tryParse(perfil["objetivo_semanal_km"]?.toString() ?? "30") ??
          30.0;
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
      treinosSemana =
          int.tryParse(resumo["total_treinos"]?.toString() ?? "0") ?? 0;
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
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };

    acentos.forEach((chave, valor) {
      limpo = limpo.replaceAll(chave, valor);
    });

    limpo = limpo.replaceAll(RegExp(r'[^\w\s]'), ' ');
    limpo = limpo.replaceAll(RegExp(r'\s+'), ' ');
    return limpo;
  }

  bool _tem(String texto, List<String> termos) {
    final textoCompleto = ' ${texto.trim()} ';
    for (var termo in termos) {
      final tNorm = _normalizar(termo);
      if (textoCompleto.contains(' $tNorm ') ||
          textoCompleto.contains(' ${tNorm}s ')) {
        return true;
      }
    }
    return false;
  }

  /// Processa a pergunta do usuário e devolve uma LISTA sequencial de mensagens (retrocompatibilidade).
  Future<List<String>> processarPergunta(String perguntaOriginal) async {
    final resposta = await processarComandoOuPergunta(perguntaOriginal);
    return resposta.mensagens;
  }

  /// Processa comandos executáveis de agente ou perguntas gerais, retornando resposta enriquecida.
  Future<RespostaIa> processarComandoOuPergunta(String perguntaOriginal) async {
    final ctx = await obterContextoAtualizado();
    final p = _normalizar(perguntaOriginal);

    // =========================================================================
    // ⚡ 1. COMANDOS DE AGENTE (AÇÕES NO APLICATIVO)
    // =========================================================================

    // A) COMANDO: CRIAR / AGENDAR TREINO
    final isComandoTreino =
        _tem(p, [
          "criar treino",
          "crie um treino",
          "cria um treino",
          "agendar treino",
          "agende um treino",
          "agenda um treino",
          "planejar treino",
          "planeje um treino",
          "planeja um treino",
          "novo treino",
          "adicionar treino",
          "adiciona um treino",
          "prescrever treino",
          "prescreva um treino",
          "cadastrar treino",
          "cadastre um treino",
          "coloque um treino",
          "coloca um treino",
          "montar treino",
          "monte um treino",
          "monta um treino",
          "gerar treino",
          "gere um treino",
          "gera um treino",
          "quero um treino",
          "quero treinar",
          "passa um treino",
          "me passa um treino",
          "programe um treino",
          "programar treino",
          "fazer um treino",
          "faca um treino",
          "faz um treino",
          "sugira um treino",
          "sugestao de treino",
        ]) ||
        (p.contains("treino") &&
            (p.contains("amanha") || p.contains("hoje") || p.contains("km")));

    if (isComandoTreino &&
        !_tem(p, [
          "salvar corrida",
          "salve uma corrida",
          "salve meu treino",
          "corri hoje",
          "registre meu treino",
        ])) {
      return await _executarComandoCriarTreino(p, perguntaOriginal, ctx);
    }

    // B) COMANDO: CRIAR / ESTABELECER META
    final isComandoMeta = _tem(p, [
      "criar meta",
      "crie uma meta",
      "cria uma meta",
      "nova meta",
      "adicionar meta",
      "adiciona uma meta",
      "estabelecer meta",
      "estabeleca uma meta",
      "estabelece uma meta",
      "cadastrar meta",
      "cadastre uma meta",
      "cadastra uma meta",
      "minha meta vai ser",
      "definir meta",
      "defina uma meta",
      "definir uma meta",
      "crie meta",
      "cria meta",
      "bota uma meta",
      "coloque uma meta",
      "coloca uma meta",
      "quero uma meta",
      "planejar meta",
      "planeje uma meta",
      "nova meta de",
      "meta de",
    ]);

    if (isComandoMeta) {
      return await _executarComandoCriarMeta(p, perguntaOriginal, ctx);
    }

    // C) COMANDO: SALVAR EXECUÇÃO / REGISTRAR CORRIDA
    if (_tem(p, [
      "salvar execucao",
      "salvar corrida",
      "salve uma corrida",
      "salve meu treino",
      "registre meu treino",
      "registre uma corrida",
      "corri hoje",
      "terminei uma corrida",
      "salvar treino concluido",
      "registrar execucao",
      "fiz um treino de",
      "registre a corrida",
      "salva minha corrida",
      "salve minha corrida",
      "guardar corrida",
    ])) {
      return await _executarComandoSalvarCorrida(p, perguntaOriginal, ctx);
    }

    // D) COMANDO: SALVAR TESTE FÍSICO
    if (_tem(p, [
      "salvar teste",
      "salve o teste",
      "registre meu teste",
      "fiz o teste de 3km",
      "fiz o teste de sprint",
      "salvar teste de corrida",
      "guardar teste",
    ])) {
      return await _executarComandoSalvarTeste(p, perguntaOriginal, ctx);
    }

    // =========================================================================
    // 🧠 2. CONVERSAÇÃO E CONHECIMENTO CIENTÍFICO EXPANDIDO (100%)
    // =========================================================================

    // Cumprimentos
    if (_tem(p, [
      "ola",
      "oi",
      "e ai",
      "opa",
      "bom dia",
      "boa tarde",
      "boa noite",
      "hello",
      "como vai",
      "tudo bem",
    ])) {
      return RespostaIa(mensagens: _responderSaudacao(ctx));
    }

    // Apresentação e Capacidades de Agente
    if (_tem(p, [
      "quem e voce",
      "o que voce faz",
      "como voce funciona",
      "o que voce pode fazer",
      "me ajude",
      "seus comandos",
      "o que sabe",
    ])) {
      return RespostaIa(
        mensagens: [
          "Olá, ${ctx.nome}! Eu sou a PaceMind IA, seu treinador inteligente e agente autônomo de corrida e saúde esportiva.",
          "Minha base local cobre temas comuns de corrida, treinamento, recuperação e nutrição esportiva. Também estou integrado ao app e posso executar algumas ações por você.",
          "Você pode me pedir:\n• \"Crie um treino de 8km para amanhã\"\n• \"Crie uma meta de 60km este mês\"\n• \"Salvar corrida de 6km em 30 minutos hoje\"\n• \"Analise meus treinos e fadiga\"\n• Dúvidas sobre temas comuns de corrida.",
          "Qual é o seu objetivo de treino agora?",
        ],
      );
    }

    // Análise de Dados e Métricas Atuais
    if (_tem(p, [
      "analise meus dados",
      "analise meus treinos",
      "meus dados",
      "meu resumo",
      "como estao meus treinos",
      "minha semana",
      "minha evolucao",
      "minha performance",
      "quanto corri",
      "como estou",
    ])) {
      return RespostaIa(mensagens: _responderAnaliseDados(ctx));
    }

    // Aquecimento e volta à calma
    if (_tem(p, [
      "aquecimento",
      "desaquecer",
      "volta a calma",
      "educativos de corrida",
    ])) {
      return RespostaIa(mensagens: _responderAquecimento());
    }

    // Ritmo, Pace, VDOT e Velocidade
    if (_tem(p, [
      "pace",
      "ritmo",
      "baixar tempo",
      "correr mais rapido",
      "melhorar velocidade",
      "pace medio",
      "pace ideal",
      "o que e pace",
      "ritmo de prova",
      "acelerar",
      "vdot",
      "jack daniels",
    ])) {
      return RespostaIa(mensagens: _responderPace(ctx, p));
    }

    // Treinos Intervalados, Tiros, Fartlek e VO2 Máximo
    if (_tem(p, [
      "tiro",
      "intervalado",
      "fartlek",
      "vo2",
      "velocidade",
      "pista",
      "hiit",
    ])) {
      return RespostaIa(mensagens: _responderTiros());
    }

    // Longão e Resistência Aeróbica
    if (_tem(p, [
      "longao",
      "treino longo",
      "corrida longa",
      "resistencia",
      "quantos km no longo",
      "volume semanal",
    ])) {
      return RespostaIa(mensagens: _responderLongao(ctx));
    }

    // Descanso, Sono, Regeneração e Supercompensação
    if (_tem(p, [
      "descanso",
      "recuperacao",
      "recuperar",
      "sono",
      "dormir",
      "cansado",
      "regenerativo",
      "supercompensacao",
    ])) {
      return RespostaIa(mensagens: _responderDescanso(ctx));
    }

    // Dores, Lesões, Inflamações e Cuidados
    if (_tem(p, [
      "dor",
      "doendo",
      "canelite",
      "joelho",
      "canela",
      "panturrilha",
      "pe",
      "fascite",
      "lesao",
      "fisgada",
      "inflamacao",
      "alongar",
      "alongamento",
      "aquiles",
      "tendao",
      "tendinite",
      "banda iliotibial",
      "trato iliotibial",
    ])) {
      return RespostaIa(mensagens: _responderDores(ctx, p));
    }

    // Overtraining, Fadiga e Carga ACWR
    if (_tem(p, [
      "overtraining",
      "acwr",
      "sobrecarga",
      "estafa",
      "excesso de treino",
      "carga aguda",
      "carga cronica",
    ])) {
      return RespostaIa(mensagens: _responderOvertraining(ctx));
    }

    // Metas e Planejamento
    if (_tem(p, ["meta", "metas", "objetivo", "atingir meta"])) {
      return RespostaIa(mensagens: _responderMetas(ctx));
    }

    // Eventos, Provas, Maratonas e Estratégia de Prova
    if (_tem(p, [
      "evento",
      "eventos",
      "prova",
      "corrida de rua",
      "maratona",
      "meia maratona",
      "5k",
      "10k",
      "21k",
      "42k",
      "muro dos 30",
      "split negativo",
    ])) {
      return RespostaIa(mensagens: _responderEventos(ctx, p));
    }

    // Nutrição, Hidratação, Carbo-loading e Eletrólitos
    if (_tem(p, [
      "comer",
      "comida",
      "alimentacao",
      "nutricao",
      "jejum",
      "gel",
      "carbo",
      "carboidrato",
      "agua",
      "hidratacao",
      "creatina",
      "whey",
      "pre treino",
      "pos treino",
      "eletrolitos",
      "sodio",
      "suplemento",
      "cafeina",
      "beterraba",
      "nitrato",
      "hiponatremia",
    ])) {
      return RespostaIa(mensagens: _responderNutricao());
    }

    // Respiração, Asma e Saúde Pulmonar
    if (_tem(p, [
      "respirar",
      "respiracao",
      "falta de ar",
      "asma",
      "pulmao",
      "ar",
      "nariz ou boca",
      "ofegante",
      "bombinha",
      "acq",
      "espirometria",
      "vef1",
      "cvf",
      "broncoespasmo",
    ])) {
      return RespostaIa(mensagens: _responderRespiracao(ctx));
    }

    // Frequência Cardíaca, Zonas e Limiar de Lactato
    if (_tem(p, [
      "frequencia cardiaca",
      "batimento",
      "bpm",
      "zonas",
      "zona 2",
      "zona 4",
      "limiar",
      "cardio",
      "lactato",
      "maffetone",
      "maf",
    ])) {
      return RespostaIa(mensagens: _responderZonasCardiacas());
    }

    // Cadência, Passada e Biomecânica
    if (_tem(p, [
      "cadencia",
      "passada",
      "passos por minuto",
      "spm",
      "mecanica",
      "postura",
      "aterrissagem",
      "overstriding",
      "pisada",
      "pronada",
      "supinada",
      "neutra",
    ])) {
      return RespostaIa(mensagens: _responderCadencia());
    }

    // Tênis, Placa de Carbono e Equipamentos
    if (_tem(p, [
      "tenis",
      "calcado",
      "drop",
      "placa de carbono",
      "amortecimento",
      "relogio",
      "gps",
      "garmin",
      "meia",
      "pebax",
      "espuma",
    ])) {
      return RespostaIa(mensagens: _responderEquipamentos());
    }

    // Subidas, Ladeiras e Trail Running
    if (_tem(p, [
      "subida",
      "ladeira",
      "inclinacao",
      "altimetria",
      "trail",
      "morro",
      "descida",
    ])) {
      return RespostaIa(mensagens: _responderAltimetria());
    }

    // Atividades aeróbicas complementares
    if (_tem(p, [
      "treino cruzado",
      "treino complementar",
      "bike",
      "bicicleta",
      "ciclismo",
      "natacao",
      "eliptico",
    ])) {
      return RespostaIa(mensagens: _responderTreinoCruzado());
    }

    // Musculação e Treino de Força para Corredores
    if (_tem(p, [
      "musculacao",
      "academia",
      "forca",
      "fortalecimento",
      "peso",
      "agachamento",
      "pliometria",
      "core",
    ])) {
      return RespostaIa(mensagens: _responderMusculacao());
    }

    // Mulher Atleta & Ciclo Menstrual
    if (_tem(p, [
      "ciclo menstrual",
      "menstruacao",
      "menstrual",
      "hormonio",
      "mulher",
      "gravidez",
    ])) {
      return RespostaIa(mensagens: _responderMulherAtleta());
    }

    // Clima: Calor, Frio e Chuva
    if (_tem(p, [
      "calor",
      "quente",
      "frio",
      "chuva",
      "chovendo",
      "sol",
      "umidade",
      "clima",
      "temperatura",
    ])) {
      return RespostaIa(mensagens: _responderClima());
    }

    // Iniciantes: Do 0 aos 5k
    if (_tem(p, [
      "iniciante",
      "comecar",
      "comecando",
      "do zero",
      "sedentario",
      "primeiros 5k",
    ])) {
      return RespostaIa(mensagens: _responderIniciantes());
    }

    // Motivação e Consistência
    if (_tem(p, [
      "preguica",
      "desanimado",
      "sem vontade",
      "motivacao",
      "desistir",
      "dificil",
      "consistencia",
      "foco",
    ])) {
      return RespostaIa(mensagens: _responderMotivacao(ctx));
    }

    // Agradecimento
    if (_tem(p, [
      "obrigado",
      "obrigada",
      "valeu",
      "show",
      "top",
      "muito bom",
      "otimo",
      "maravilha",
      "perfeito",
      "excelente",
    ])) {
      return RespostaIa(
        mensagens: [
          "Fico muito feliz em ajudar, ${ctx.nome}! Estou sempre aqui para apoiar a sua evolução a cada quilômetro.",
          "Se quiser planejar novos treinos, definir metas ou esclarecer qualquer dúvida, é só me chamar!",
        ],
      );
    }

    // Despedida
    if (_tem(p, [
      "tchau",
      "ate mais",
      "ate logo",
      "vou correr",
      "vou treinar",
      "fui",
    ])) {
      return RespostaIa(
        mensagens: [
          "Excelente treino e ótima corrida, ${ctx.nome}!",
          "Mantenha uma postura elegante, respiração ritmada e hidrate-se bem. Depois venha me contar como foi a sessão!",
        ],
      );
    }

    // Resposta Técnica Geral & Contextualizada
    return RespostaIa(
      mensagens: _responderConhecimentoGeral(ctx, perguntaOriginal),
    );
  }

  // =========================================================================
  // ⚡ 3. EXECUTORES DE AÇÕES DE AGENTE
  // =========================================================================

  Future<RespostaIa> _executarComandoCriarTreino(
    String pNorm,
    String original,
    ContextoAtleta ctx,
  ) async {
    double distancia = 5.0;
    int tempoMin = 30;
    String tipo = "Rodagem";

    // 1. Extrair distância (ex: 5km, 8.5 km, 10k, 21k, meia maratona, maratona)
    if (pNorm.contains("meia maratona") ||
        pNorm.contains("21k") ||
        pNorm.contains("21 km")) {
      distancia = 21.1;
    } else if (pNorm.contains("maratona") ||
        pNorm.contains("42k") ||
        pNorm.contains("42 km")) {
      distancia = 42.2;
    } else {
      final regKm = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*(?:km|k|quilometros|quilômetros)?',
      );
      final matches = regKm.allMatches(pNorm);
      for (var m in matches) {
        final val = double.tryParse(m.group(1)!.replaceAll(',', '.'));
        if (val != null && val > 0 && val <= 100) {
          // Evita capturar anos como 2026
          if (val != 2024 && val != 2025 && val != 2026) {
            distancia = val;
            break;
          }
        }
      }
    }

    // 2. Extrair tempo ou estimar realisticamente
    final regTempo = RegExp(r'(\d+)\s*(?:min|minutos)');
    final matchTempo = regTempo.firstMatch(pNorm);
    if (matchTempo != null) {
      tempoMin = int.tryParse(matchTempo.group(1)!) ?? 30;
    } else {
      if (ctx.paceReferenciaSegundos > 0) {
        tempoMin = ((distancia * ctx.paceReferenciaSegundos) / 60).round();
      } else {
        tempoMin = (distancia * 5.5).round();
      }
    }
    if (tempoMin < 5) tempoMin = 30;

    // 3. Extrair modalidade/tipo de treino
    if (pNorm.contains("tiro") ||
        pNorm.contains("intervalado") ||
        pNorm.contains("velocidade")) {
      tipo = "Intervalado / Tiros";
    } else if (pNorm.contains("longao") || pNorm.contains("longo")) {
      tipo = "Longão Aeróbico";
    } else if (pNorm.contains("regenerativo") ||
        pNorm.contains("recuperacao") ||
        pNorm.contains("leve")) {
      tipo = "Regenerativo";
    } else if (pNorm.contains("ritmo") ||
        pNorm.contains("tempo run") ||
        pNorm.contains("limiar")) {
      tipo = "Treino de Ritmo";
    } else if (pNorm.contains("fartlek")) {
      tipo = "Fartlek";
    } else if (pNorm.contains("subida") ||
        pNorm.contains("ladeira") ||
        pNorm.contains("morro")) {
      tipo = "Subidas / Força";
    }

    // 4. Extrair data
    final hoje = DateTime.now();
    DateTime dataAlvo = hoje.add(const Duration(days: 1)); // Padrão: amanhã
    if (pNorm.contains("hoje")) {
      dataAlvo = hoje;
    } else if (pNorm.contains("depois de amanha")) {
      dataAlvo = hoje.add(const Duration(days: 2));
    } else if (pNorm.contains("amanha")) {
      dataAlvo = hoje.add(const Duration(days: 1));
    }

    // Formato ISO YYYY-MM-DD para o banco PostgreSQL
    final dataBanco = AppDateUtils.paraDataPura(dataAlvo);
    final dataExibicao = AppDateUtils.formatarData(dataAlvo);

    try {
      await Api.criarTreinoCompleto(
        tipo: tipo,
        distanciaKm: distancia,
        tempoSegundos: tempoMin * 60,
        data: dataBanco,
        status: "planejado",
        sensacao: 6,
        observacoes: "Prescrito e agendado pelo PaceMind IA Treinador.",
      );

      final acao = AcaoAgente(
        tipo: "treino_criado",
        titulo: "Treino Criado com Sucesso!",
        descricao:
            "$tipo de ${distancia % 1 == 0 ? distancia.toInt() : distancia.toStringAsFixed(1)} km registrado para $dataExibicao.",
        rotaNavegacao: "/treinos",
        textoBotao: "Ver Minha Planilha",
      );

      final distFormatada =
          "${distancia % 1 == 0 ? distancia.toInt() : distancia.toStringAsFixed(1)} km";

      return RespostaIa(
        mensagens: [
          "⚡ Entendido perfeitamente, ${ctx.nome}! Como seu treinador agente, já prescrevi e registrei o treino diretamente na sua planilha:",
          "🏃 Modalidade: $tipo\n📏 Distância: $distFormatada\n⏱️ Duração Estimada: $tempoMin minutos\n📅 Data Prevista: $dataExibicao",
          "O treino já está gravado na aba de Treinos. Quando calçar o tênis, basta dar o play no mapa ou acompanhar a sua execução!",
        ],
        acao: acao,
      );
    } catch (e) {
      return RespostaIa(
        mensagens: [
          "Tentei agendar o seu treino de ${distancia.toStringAsFixed(1)} km, mas ocorreu uma oscilação na resposta do servidor.",
          "Você também pode cadastrá-lo com um toque no botão (+) na aba de Treinos!",
        ],
      );
    }
  }

  Future<RespostaIa> _executarComandoCriarMeta(
    String pNorm,
    String original,
    ContextoAtleta ctx,
  ) async {
    double valor = 50.0;
    String tipo = "km"; // 'km', 'tempo', 'treinos'
    String titulo = "Meta de Corrida";

    // 1. Verificar se é meta de treinos/sessões
    final regTreinos = RegExp(
      r'(\d+)\s*(?:treinos|treino|corridas|corrida|sessoes|sessões|dias)',
    );
    final matchTreinos = regTreinos.firstMatch(pNorm);

    // 2. Verificar se é meta de tempo
    final regTempo = RegExp(r'(\d+)\s*(?:minutos|minuto|min|horas|hora|h)\b');
    final matchTempo = regTempo.firstMatch(pNorm);

    // 3. Verificar se é meta de quilometragem (km)
    final regKm = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:km|k|quilometros|quilômetros)?',
    );

    if (matchTreinos != null &&
        (pNorm.contains("treino") ||
            pNorm.contains("sessao") ||
            pNorm.contains("dia"))) {
      tipo = "treinos";
      valor = double.tryParse(matchTreinos.group(1)!) ?? 12.0;
      titulo = "Concluir ${valor.toInt()} Treinos";
    } else if (matchTempo != null &&
        (pNorm.contains("minuto") ||
            pNorm.contains("hora") ||
            pNorm.contains("tempo"))) {
      tipo = "tempo";
      valor = double.tryParse(matchTempo.group(1)!) ?? 120.0;
      if (pNorm.contains("hora") && valor < 100) {
        valor = valor * 60; // Converte horas para minutos
      }
      titulo = "Treinar ${valor.toInt()} Minutos";
    } else {
      // Padrão: Quilometragem (km)
      tipo = "km";
      final matches = regKm.allMatches(pNorm);
      bool encontrou = false;
      for (var m in matches) {
        final val = double.tryParse(m.group(1)!.replaceAll(',', '.'));
        if (val != null &&
            val > 0 &&
            val != 2024 &&
            val != 2025 &&
            val != 2026) {
          valor = val;
          encontrou = true;
          break;
        }
      }
      if (!encontrou) {
        valor = 60.0; // Padrão inteligente
      }

      final kmStr = valor % 1 == 0
          ? valor.toInt().toString()
          : valor.toStringAsFixed(1);
      if (pNorm.contains("mes") || pNorm.contains("mensal")) {
        titulo = "Correr $kmStr km no Mês";
      } else if (pNorm.contains("semana") || pNorm.contains("semanal")) {
        titulo = "Correr $kmStr km na Semana";
      } else {
        titulo = "Correr $kmStr km";
      }
    }

    try {
      await Api.criarMeta(titulo: titulo, objetivo: valor, tipo: tipo);

      final valorFormatado = tipo == "km"
          ? "${valor % 1 == 0 ? valor.toInt() : valor.toStringAsFixed(1)} km"
          : tipo == "tempo"
          ? "${valor.toInt()} min"
          : "${valor.toInt()} treinos";

      final acao = AcaoAgente(
        tipo: "meta_criada",
        titulo: "Nova Meta Cadastrada!",
        descricao: "$titulo com objetivo de $valorFormatado.",
        rotaNavegacao: "/metas",
        textoBotao: "Ver Minhas Metas",
      );

      return RespostaIa(
        mensagens: [
          "🎯 Ação executada com sucesso, ${ctx.nome}! Criei a sua nova meta esportiva no PaceMind:",
          "🏆 Título: $titulo\n🎯 Alvo: $valorFormatado\n📊 Tipo: ${tipo == 'km' ? 'Quilometragem (km)' : tipo.toUpperCase()}",
          "A partir de agora, cada corrida registrada atualiza automaticamente a sua barra de progresso rumo a essa conquista!",
        ],
        acao: acao,
      );
    } catch (e) {
      return RespostaIa(
        mensagens: [
          "Tentei salvar sua meta de $titulo, mas houve uma falha de conexão com o banco de dados.",
          "Você pode cadastrá-la diretamente na aba de Metas clicando em 'Nova Meta'!",
        ],
      );
    }
  }

  Future<RespostaIa> _executarComandoSalvarCorrida(
    String pNorm,
    String original,
    ContextoAtleta ctx,
  ) async {
    double distancia = 5.0;
    int tempoMin = 30;
    int sensacao = 7;

    final regKm = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:km|k|quilometros)');
    final matchKm = regKm.firstMatch(pNorm);
    if (matchKm != null) {
      distancia =
          double.tryParse(matchKm.group(1)!.replaceAll(',', '.')) ?? 5.0;
    }

    final regTempo = RegExp(r'(\d+)\s*(?:min|minutos)');
    final matchTempo = regTempo.firstMatch(pNorm);
    if (matchTempo != null) {
      tempoMin = int.tryParse(matchTempo.group(1)!) ?? 30;
    }

    final regSensacao = RegExp(r'(?:sensacao|esforco|nota)\s*(\d+)');
    final matchSensacao = regSensacao.firstMatch(pNorm);
    if (matchSensacao != null) {
      sensacao = int.tryParse(matchSensacao.group(1)!)?.clamp(1, 10) ?? 7;
    }

    final hoje = DateTime.now();
    final dataBanco = AppDateUtils.paraDataPura(hoje);
    final dataExibicao = AppDateUtils.formatarData(hoje);

    final tempoSeg = tempoMin * 60;
    final paceSeg = distancia > 0 ? (tempoSeg / distancia).round() : 0;
    final paceTexto = ctx.formatarPace(paceSeg);

    try {
      await Api.criarTreinoCompleto(
        tipo: "Corrida de Rua",
        distanciaKm: distancia,
        tempoSegundos: tempoSeg,
        data: dataBanco,
        sensacao: sensacao,
        status: "concluido",
        observacoes: "Registrado e salvo pelo PaceMind IA Treinador.",
      );

      final acao = AcaoAgente(
        tipo: "corrida_salva",
        titulo: "Corrida Salva com Sucesso!",
        descricao:
            "${distancia.toStringAsFixed(1)} km em $tempoMin min • Pace $paceTexto",
        rotaNavegacao: "/execucoes",
        textoBotao: "Ver Histórico de Corridas",
      );

      return RespostaIa(
        mensagens: [
          "✅ Corrida registrada e salva com sucesso no seu histórico, ${ctx.nome}!",
          "📊 Detalhes da Sessão:\n• Distância: ${distancia.toStringAsFixed(1)} km\n• Tempo Total: $tempoMin minutos\n• Pace Médio: $paceTexto\n• Nível de Esforço: $sensacao/10\n• Data: $dataExibicao",
          "Essa sessão já entrou no cálculo da sua quilometragem semanal e no seu monitoramento de fadiga (ACWR)!",
        ],
        acao: acao,
      );
    } catch (e) {
      return RespostaIa(
        mensagens: [
          "Não consegui sincronizar essa corrida agora devido à conexão.",
          "Você pode salvá-la pela tela de Execuções ou usando o rastreamento GPS na aba do Mapa!",
        ],
      );
    }
  }

  Future<RespostaIa> _executarComandoSalvarTeste(
    String pNorm,
    String original,
    ContextoAtleta ctx,
  ) async {
    String tipo = "3km";
    double segundos = 720; // 12 min

    if (pNorm.contains("sprint") ||
        pNorm.contains("20m") ||
        pNorm.contains("velocidade maxima")) {
      tipo = "sprint_20m";
      segundos = 3.2;
    }

    final regMin = RegExp(r'(\d+)\s*(?:min|minutos)');
    final regSeg = RegExp(r'(\d+)\s*(?:s|seg|segundos)');

    final mMin = regMin.firstMatch(pNorm);
    final mSeg = regSeg.firstMatch(pNorm);

    if (tipo == "3km") {
      final min = mMin != null ? int.parse(mMin.group(1)!) : 12;
      final seg = mSeg != null ? int.parse(mSeg.group(1)!) : 0;
      segundos = (min * 60 + seg).toDouble();
    } else {
      final seg = mSeg != null ? double.parse(mSeg.group(1)!) : 3.2;
      segundos = seg;
    }

    try {
      await Api.salvarTeste(
        tipoTeste: tipo,
        tempoSegundos: segundos,
        observacoes: "Registrado pelo PaceMind IA Treinador.",
      );

      final acao = AcaoAgente(
        tipo: "teste_salvo",
        titulo: "Teste Físico Registrado!",
        descricao:
            "Teste de ${tipo == '3km' ? '3 km' : 'Sprint 20m'} registrado com sucesso.",
        rotaNavegacao: "/testes",
        textoBotao: "Ver Meus Testes",
      );

      return RespostaIa(
        mensagens: [
          "⚡ Teste físico registrado com sucesso, ${ctx.nome}!",
          "Com esses dados, o PaceMind atualiza a sua capacidade aeróbica e as suas zonas personalizadas de ritmo.",
        ],
        acao: acao,
      );
    } catch (e) {
      return RespostaIa(
        mensagens: [
          "Tentei salvar seu teste, mas houve uma oscilação na rede. Você pode salvá-lo pela aba de Testes Físicos no menu!",
        ],
      );
    }
  }

  // =========================================================================
  // 4. Módulos locais de respostas especializadas
  // =========================================================================

  List<String> _responderSaudacao(ContextoAtleta ctx) {
    final hora = DateTime.now().hour;
    String periodo = (hora >= 5 && hora < 12)
        ? "Bom dia"
        : (hora >= 12 && hora < 18)
        ? "Boa tarde"
        : "Boa noite";

    List<String> msgs = ["$periodo, ${ctx.nome}! Que bom ter você aqui."];

    if (ctx.kmSemana > 0) {
      msgs.add(
        "Você já acumulou ${ctx.kmSemana.toStringAsFixed(1)} km nesta semana em ${ctx.treinosSemana} sessões.",
      );
    } else {
      msgs.add(
        "Sua semana esportiva está pronta! Sua meta cadastrada é de ${ctx.metaSemanalKm.toStringAsFixed(0)} km.",
      );
    }

    msgs.add(
      "Como posso te ajudar hoje? Você pode tirar dúvidas sobre fisiologia, nutrição e recuperação, ou me pedir: \"Crie um treino de 6km\" ou \"Crie uma meta de 50km\"!",
    );

    return msgs;
  }

  List<String> _responderAnaliseDados(ContextoAtleta ctx) {
    final pctMeta = ctx.metaSemanalKm > 0
        ? ((ctx.kmSemana / ctx.metaSemanalKm) * 100).round()
        : 0;
    final paceTexto = ctx.formatarPace(ctx.paceReferenciaSegundos);

    List<String> msgs = [
      "Analisei agora mesmo os seus registros recentes no PaceMind, ${ctx.nome}:",
      "📊 Volume da Semana: ${ctx.kmSemana.toStringAsFixed(1)} km de ${ctx.metaSemanalKm.toStringAsFixed(0)} km planejados ($pctMeta% concluído) em ${ctx.treinosSemana} treinos.\n⏱️ Pace de Referência: $paceTexto.\n⚡ Índice ACWR de Carga: ${ctx.acwr.toStringAsFixed(2)} - Status: ${ctx.statusFadiga}.",
    ];

    if (ctx.statusFadiga.toLowerCase().contains("alto")) {
      msgs.add(
        "⚠️ O status de fadiga do app está elevado. Use-o junto com sono, dor e percepção de esforço para decidir se precisa reduzir a carga ou descansar.",
      );
    } else if (pctMeta >= 100) {
      msgs.add(
        "🎉 Parabéns! Você já atingiu 100% da sua meta semanal. Mantenha um volume controlado até o fim do ciclo semanal para não desgastar a musculatura.",
      );
    } else {
      final faltam = (ctx.metaSemanalKm - ctx.kmSemana).clamp(0.0, 999.0);
      msgs.add(
        "💪 Você está em excelente progressão! Faltam apenas ${faltam.toStringAsFixed(1)} km para fechar sua meta semanal. Se quiser, me peça para agendar seu próximo treino!",
      );
    }

    return msgs;
  }

  List<String> _responderPace(ContextoAtleta ctx, String p) {
    final paceTexto = ctx.formatarPace(ctx.paceReferenciaSegundos);

    List<String> msgs = [
      "Para melhorar o ritmo com segurança, combine corridas leves, recuperação suficiente e doses apropriadas de trabalho intenso. A proporção depende do seu histórico, objetivo e resposta ao treino.",
      "As rodagens fáceis devem permitir conversar em frases. Ajuste o esforço ao calor, ao terreno e à recuperação; não transforme cada sessão em um teste.",
    ];

    if (ctx.paceReferenciaSegundos > 0) {
      msgs.add(
        "Seu pace de referência cadastrado é $paceTexto. Ele só deve orientar ritmos de treino quando vier de um teste recente e comparável; não é, por si só, uma prescrição para todas as sessões.",
      );
    } else {
      msgs.add(
        "Para personalizar ritmos, cadastre um pace de referência recente no perfil ou registre um teste físico no app. Sem esse dado, use principalmente a percepção de esforço.",
      );
    }

    msgs.add(
      "Se quiser, posso explicar como estruturar uma sessão leve, intervalada ou de ritmo. Dor persistente, fadiga fora do normal ou queda de desempenho pedem ajuste da carga.",
    );

    return msgs;
  }

  List<String> _responderTiros() {
    return [
      "Os treinos intervalados (ou tiros) são o estímulo mais potente para elevar seu VO2 Máximo e aumentar a capacidade de tamponamento e clearance de lactato sanguíneo!",
      "Protocolo recomendado para corredores amadores e intermediários:\n• Aquecimento: 10 a 15 min de trote leve (Z1/Z2) + educativos de corrida.\n• Bloco principal: 6 a 8 repetições de 400m em ritmo de tiro (Z4/Z5) com 1min30s de recuperação ativa caminhando.\n• Desaquecimento: 5 a 10 min de trote regenerativo.",
      "Programe sessões intensas considerando sua experiência e recuperação. Não há um intervalo único adequado a todos; evite empilhar estímulos fortes quando ainda estiver fatigado.",
    ];
  }

  List<String> _responderLongao(ContextoAtleta ctx) {
    return [
      "O longão pode desenvolver resistência, mas a distância e o esforço adequados dependem do seu histórico, objetivo e recuperação.",
      "Muitas pessoas fazem a maior parte dos longões em esforço confortável, conseguindo conversar. Reduza o ritmo ou caminhe se o esforço subir além do planejado.",
      "Não há um limite percentual semanal que sirva para todos. Aumente a carga gradualmente e evite elevar distância e intensidade ao mesmo tempo. Quer que eu agende um treino?",
    ];
  }

  List<String> _responderDescanso(ContextoAtleta ctx) {
    List<String> msgs = [
      "O descanso não é o oposto do treino: é o período biológico exato em que o corpo sofre supercompensação e constrói novas fibras e vasos sanguíneos mais fortes!",
    ];

    if (ctx.statusFadiga.toLowerCase().contains("alto")) {
      msgs.add(
        "Seu status de fadiga no app está elevado (ACWR: ${ctx.acwr.toStringAsFixed(2)}). Use esse indicador junto com sono, dor e sensação de esforço; reduza a carga se também estiver se sentindo mal.",
      );
    } else {
      msgs.add(
        "Pernas pesadas, sono ruim ou esforço incomum podem justificar descanso ou uma sessão mais leve. A decisão deve considerar como você está se sentindo, não apenas um número.",
      );
    }

    msgs.add(
      "Priorize sono suficiente e regular; a necessidade varia entre pessoas. Persistência de fadiga ou queda de desempenho merece atenção e ajuste da carga.",
    );

    return msgs;
  }

  List<String> _responderDores(ContextoAtleta ctx, String p) {
    return [
      "Não consigo diagnosticar a causa de uma dor por mensagem. Dor na canela, joelho, pé ou tendão pode ter causas diferentes e precisa ser avaliada no contexto dos seus sintomas e histórico.",
      "Interrompa ou reduza a atividade se a dor for forte, piorar durante a corrida, alterar sua passada ou vier com inchaço. Não tente compensar com exercícios ou analgésicos sem orientação.",
      "Procure avaliação de um profissional de saúde se a dor persistir, voltar repetidamente ou limitar atividades diárias. Dor no peito, desmaio, incapacidade de apoiar o membro ou inchaço súbito exigem atendimento imediato.",
    ];
  }

  List<String> _responderOvertraining(ContextoAtleta ctx) {
    return [
      "Overtraining (síndrome do sobretreinamento) ocorre quando o volume ou intensidade de treino superam cronicamente a capacidade de regeneração celular do atleta.",
      "No PaceMind, monitoramos a relação ACWR (carga aguda dividida pela crônica). Seu valor atual é de ${ctx.acwr.toStringAsFixed(2)} (${ctx.statusFadiga}).",
      "Observe tendências junto com sintomas como sono ruim, irritabilidade, perda de apetite e queda persistente de desempenho. O ACWR é apenas um indicador de carga: isoladamente não diagnostica sobretreinamento nem garante ausência de lesão.",
    ];
  }

  List<String> _responderMetas(ContextoAtleta ctx) {
    if (ctx.metas.isEmpty) {
      return [
        "Notei que você ainda não tem metas ativas cadastradas no PaceMind!",
        "Definir metas é o catalisador da consistência esportiva. Você pode criar metas por distância em km (ex: 80km no mês), tempo ou número de treinos.",
        "Quer criar uma agora? Diga simplesmente: \"Crie uma meta de 80km este mês\" que eu cadastro imediatamente para você!",
      ];
    }

    final total = ctx.metas.length;
    final concluidas = ctx.metas.where((m) => m["concluida"] == true).length;
    final primeira = ctx.metas.first;
    final tipoFormatado =
        primeira["tipo"]?.toString().toLowerCase() == "km" ||
            primeira["tipo"]?.toString().toLowerCase() == "distancia"
        ? "${primeira["objetivo"]} km"
        : "${primeira["objetivo"]} ${primeira["tipo"]}";

    return [
      "Você tem $total metas cadastradas no PaceMind, das quais $concluidas já foram conquistadas!",
      "Seu foco atual é: \"${primeira["titulo"]}\" com alvo de $tipoFormatado.",
      "Quer adicionar outra meta ou ajustar a atual? Basta me mandar uma mensagem como \"Crie uma meta de 100km\"!",
    ];
  }

  List<String> _responderEventos(ContextoAtleta ctx, String p) {
    if (_tem(p, [
      "maratona",
      "meia maratona",
      "21k",
      "42k",
      "estrategia de prova",
      "ritmo de prova",
      "taper",
      "polimento",
    ])) {
      return [
        "Planeje o ritmo a partir de treinos e provas recentes, não apenas do tempo desejado. Comece de forma controlada e aumente o esforço na parte final somente se ainda estiver bem; largar rápido costuma cobrar um preço alto.",
        "Em provas longas, ensaie alimentação, hidratação e equipamentos nos treinos. Não experimente produtos no dia. Necessidades de líquidos e carboidratos variam com duração, clima, percurso e características pessoais.",
        "Na semana da prova, evite compensar treinos perdidos ou testar algo novo. A redução de volume e os estímulos restantes dependem da distância, do histórico de treino e do plano individual.",
      ];
    }

    if (ctx.eventosInscritos.isNotEmpty) {
      return [
        "Excelente! Você já tem inscrições ativas nos eventos do PaceMind!",
        "Antes da prova, o polimento costuma reduzir a carga para favorecer a recuperação, mas duração e volume dependem da distância e do plano individual.",
        "Regra de ouro: no dia da prova, não invente nada novo. Use roupas e tênis já testados e o mesmo café da manhã dos seus treinos longos!",
      ];
    }

    return [
      "Participar de provas de corrida é uma experiência incrível que coroa todo o seu esforço!",
      "Aqui no PaceMind, na aba de Eventos, você encontra provas de 5 km, 10 km, Meia Maratona e desafios abertos com inscrições diretamente pelo aplicativo.",
      "Para 5 km ou 10 km, comece os primeiros quilômetros com ritmo controlado e acelere progressivamente na segunda metade (estratégia de split negativo)!",
    ];
  }

  List<String> _responderNutricao() {
    return [
      "Para treinos longos, planeje carboidratos e líquidos conforme duração, intensidade, clima e tolerância gastrointestinal; teste a estratégia em treino, nunca pela primeira vez na prova.",
      "Não há uma quantidade única de água ou sal adequada para todos, e excesso de líquidos também pode ser perigoso. Sede, condições ambientais e sua taxa de suor ajudam a orientar a reposição.",
      "Em caso de condição médica, uso de medicamentos, restrições alimentares ou dúvidas sobre suplementos, converse com nutricionista ou profissional de saúde. A IA não substitui orientação individual.",
    ];
  }

  List<String> _responderRespiracao(ContextoAtleta ctx) {
    return [
      "A respiração tende a acompanhar a intensidade: em esforço leve, tente manter um ritmo confortável; em esforço intenso, é normal respirar mais rápido. Não existe uma cadência respiratória única obrigatória.",
      "Se houver asma ou sintomas respiratórios, siga o plano definido com seu profissional de saúde. Aquecimento pode ajudar algumas pessoas, mas não substitui tratamento ou medicação prescrita.",
      "Interrompa o exercício e procure atendimento se sentir dor no peito, desmaio, falta de ar intensa ou chiado que não melhora conforme seu plano médico.",
    ];
  }

  List<String> _responderZonasCardiacas() {
    return [
      "As zonas organizam o esforço, mas seus limites variam conforme o método. Percentuais genéricos da frequência cardíaca máxima podem errar bastante para uma pessoa específica.",
      "Sem limiares medidos, use também a percepção de esforço e o teste da fala: em uma corrida fácil, normalmente é possível conversar. Calor, fadiga, medicamentos e sensores imprecisos alteram a frequência cardíaca.",
      "Para zonas personalizadas, prefira dados recentes de teste e orientação profissional; não trate um número isolado como diagnóstico ou garantia de intensidade.",
    ];
  }

  List<String> _responderCadencia() {
    return [
      "A cadência é o número total de passos que você dá por minuto (SPM - steps per minute).",
      "Não existe um número ideal universal: cadência varia com velocidade, altura, experiência e terreno. Evite mudar sua passada só para alcançar uma meta fixa do relógio.",
      "Se houver uma razão técnica para ajustar a passada, faça mudanças pequenas e graduais, de preferência com orientação. Aumentar a cadência não garante prevenção de lesões por si só.",
    ];
  }

  List<String> _responderEquipamentos() {
    return [
      "O equipamento ideal de corrida equilibra proteção articular, conforto e propósito do treino:",
      "• Tênis de Rodagem Diária (Daily Trainers): amortecimento generoso e durabilidade (600 a 800 km de vida útil).\n• Tênis de Performance / Placa de Carbono: rigidez torcional que aumenta o retorno de energia elástica. Deixe-os para treinos de ritmo e provas.\n• Meias Técnicas de Poliamida: evite meias 100% algodão, pois retêm umidade e provocam bolhas por atrito.",
      "Revezar entre dois modelos diferentes durante a semana dissipa as forças em diferentes pontos da musculatura do pé!",
    ];
  }

  List<String> _responderAltimetria() {
    return [
      "Treinar em subidas é considerado 'musculação disfarçada de corrida'!",
      "Dicas fundamentais para aclives:\n• Diminua o tamanho da passada e aumente a cadência dos pés.\n• Incline o tronco ligeiramente para a frente a partir do tornozelo, nunca dobrando a cintura.\n• Mantenha o olhar cerca de 5 metros à frente e não olhe para os seus pés.\n• Nas descidas, evite frear com o calcanhar: aterrissar com o mediopé poupa seus joelhos!",
    ];
  }

  List<String> _responderAquecimento() {
    return [
      "Antes de correr, comece alguns minutos bem leve e deixe o esforço subir gradualmente. Para uma sessão intensa, acrescente mobilidade dinâmica e, se já estiver habituado, acelerações curtas e progressivas.",
      "Adapte o aquecimento à sessão, ao clima e ao seu corpo; ele não precisa ser um treino adicional. Alongamento estático não substitui a preparação progressiva para correr.",
      "Ao terminar, reduza o ritmo ou caminhe até a respiração normalizar. Dor no peito, tontura ou falta de ar incomum são sinais para interromper o exercício e procurar avaliação.",
    ];
  }

  List<String> _responderTreinoCruzado() {
    return [
      "Bicicleta, elíptico e natação podem manter parte do estímulo aeróbico com menos impacto, mas não reproduzem completamente as adaptações específicas da corrida.",
      "Use a atividade complementar de acordo com seu objetivo e recuperação. Se ela for adicionada sem reduzir outra carga, o estresse total da semana também aumenta.",
      "Ao substituir corrida por dor ou lesão, não use o treino cruzado para mascarar sintomas: a causa da dor e o retorno à corrida devem ser avaliados por um profissional quando persistirem.",
    ];
  }

  List<String> _responderMusculacao() {
    return [
      "O treino de força pode complementar a corrida e ajudar na capacidade de produzir força. Exercícios e progressão devem considerar experiência, equipamento disponível e histórico de lesões.",
      "Exemplos de movimentos que podem ser adaptados: agachamentos, afundos, elevação de panturrilha e exercícios de tronco. Comece com carga controlada e técnica confortável.",
      "A frequência e a proximidade com os treinos de corrida dependem da carga total e da sua recuperação; evite iniciar um programa intenso de uma vez.",
    ];
  }

  List<String> _responderMulherAtleta() {
    return [
      "A fisiologia feminina na corrida tem particularidades incríveis associadas às oscilações hormonais do ciclo menstrual:",
      "Sintomas e respostas ao ciclo variam muito entre pessoas e entre ciclos. Ajuste o treino conforme como se sente, sem presumir que uma fase específica melhora ou piora seu desempenho.",
      "Sangramento intenso, fadiga persistente, alterações do ciclo ou dúvidas sobre gravidez e exercício devem ser discutidos com um profissional de saúde. Exames de ferro só devem ser interpretados com orientação clínica.",
    ];
  }

  List<String> _responderClima() {
    return [
      "As condições climáticas alteram drasticamente a demanda fisiológica da corrida:",
      "• Calor e Umidade: o débito cardíaco precisa se dividir entre oxigenar os músculos e bombear sangue para a pele dissipar calor. Seu pace naturalmente subirá 15 a 30 segundos/km para a mesma frequência cardíaca. Não brigue com o relógio!\n• Frio: excelente para performance metabólica, mas exige aquecimento articular mais longo para climatizar os brônquios e evitar broncoespasmo induzido por ar seco.\n• Chuva: use boné com aba para desviar a água dos olhos, passe vaselina em regiões de atrito (virilha, mamilos) e seque bem os tênis na sombra após o treino.",
    ];
  }

  List<String> _responderIniciantes() {
    return [
      "Começar a correr é uma das melhores decisões para o seu coração, cérebro e metabolismo!",
      "Comece com sessões leves de corrida e caminhada, se necessário, e inclua dias de recuperação. Aumente duração e frequência aos poucos conforme sua resposta; não existe um percentual semanal que seja seguro para todos.",
      "Mantenha um esforço que permita conversar e pare se surgir dor ou mal-estar. Se tiver uma condição de saúde ou estiver retomando após lesão, converse com um profissional antes de iniciar.",
    ];
  }

  List<String> _responderMotivacao(ContextoAtleta ctx) {
    final frases = [
      "\"A motivação faz você começar, mas é o hábito e a consistência que te levam até a linha de chegada.\"",
      "\"Não existe treino ruim: ruim é o treino que você deixou de fazer.\"",
      "\"A corrida é você contra você mesmo. Cada quilômetro vencido é uma vitória pessoal da sua mente.\"",
      "\"Corpo são, mente sã: a corrida é a terapia em movimento que organiza seus pensamentos.\"",
    ];
    final frase = frases[Random().nextInt(frases.length)];

    return [
      "Eu entendo perfeitamente, ${ctx.nome}. A mente sempre tenta economizar energia e criar desculpas antes de amarrar o tênis!",
      "Se estiver bem e apenas sem vontade, experimente começar com cinco minutos leves e reavalie como se sente. Você não precisa continuar se estiver com dor, doente ou excessivamente cansado.",
      "$frase\n\nVamos lá! Que tal dar o primeiro passo agora?",
    ];
  }

  List<String> _responderConhecimentoGeral(
    ContextoAtleta ctx,
    String pergunta,
  ) {
    return [
      "Ainda não tenho uma resposta específica para essa pergunta na minha base local, ${ctx.nome}; prefiro não inventar uma orientação.",
      "Consigo ajudar com ritmo e zonas, tipos de treino, provas, aquecimento, recuperação, equipamentos, nutrição esportiva e análise dos seus dados. Tente reformular a pergunta ou indique qual desses assuntos se aproxima mais.",
      "Para questões de saúde, lesões, medicamentos ou alimentação clínica, procure um profissional qualificado.",
    ];
  }
}
