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

/// Metadados de ação executada pelo agente da IA.
class AcaoAgente {
  final String tipo; // 'treino_criado', 'meta_criada', 'corrida_salva', 'teste_salvo'
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

/// Motor Inteligente e Agente Autônomo da PaceMind IA.
/// Conhecimento esportivo e geral expandido para responder a qualquer dúvida,
/// além de interpretar e executar comandos do usuário diretamente no app.
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
    // ⚡ COMANDOS DE AGENTE (AÇÕES NO APLICATIVO)
    // =========================================================================

    // 1. COMANDO: CRIAR / AGENDAR TREINO
    if (_tem(p, [
      "criar treino", "crie um treino", "agendar treino", "agende um treino",
      "planejar treino", "planeje um treino", "novo treino", "adicionar treino",
      "prescrever treino", "cadastrar treino", "coloque um treino"
    ])) {
      return await _executarComandoCriarTreino(p, perguntaOriginal, ctx);
    }

    // 2. COMANDO: CRIAR META
    if (_tem(p, [
      "criar meta", "crie uma meta", "nova meta", "adicionar meta",
      "estabelecer meta", "cadastrar meta", "minha meta vai ser",
      "definir meta", "crie meta"
    ])) {
      return await _executarComandoCriarMeta(p, perguntaOriginal, ctx);
    }

    // 3. COMANDO: SALVAR EXECUÇÃO / REGISTRAR CORRIDA
    if (_tem(p, [
      "salvar execucao", "salvar corrida", "salve uma corrida", "salve meu treino",
      "registre meu treino", "registre uma corrida", "corri hoje", "terminei uma corrida",
      "salvar treino concluido", "registrar execucao", "fiz um treino de"
    ])) {
      return await _executarComandoSalvarCorrida(p, perguntaOriginal, ctx);
    }

    // 4. COMANDO: SALVAR TESTE FÍSICO
    if (_tem(p, [
      "salvar teste", "salve o teste", "registre meu teste", "fiz o teste de 3km",
      "fiz o teste de sprint", "salvar teste de corrida"
    ])) {
      return await _executarComandoSalvarTeste(p, perguntaOriginal, ctx);
    }

    // =========================================================================
    // 🧠 PERGUNTAS & CONHECIMENTO EXPANDIDO
    // =========================================================================

    // Cumprimentos
    if (_tem(p, ["ola", "oi", "e ai", "opa", "bom dia", "boa tarde", "boa noite", "hello", "como vai"])) {
      return RespostaIa(mensagens: _responderSaudacao(ctx));
    }

    // Apresentação e Capacidades de Agente
    if (_tem(p, ["quem e voce", "o que voce faz", "como voce funciona", "o que voce pode fazer", "me ajude", "seus comandos"])) {
      return RespostaIa(mensagens: [
        "Olá, ${ctx.nome}! Eu sou a PaceMind IA, seu assistente e agente inteligente de corrida e saúde esportiva.",
        "Além de responder a qualquer dúvida de treinos, fisiologia, nutrição e bem-estar, eu posso agir diretamente no app por você! Experimente me pedir:",
        "• \"Crie um treino de 8km para amanhã\"\n• \"Crie uma meta de 60km esse mês\"\n• \"Salvar corrida de 6km em 30 minutos hoje\"\n• \"Analise meus treinos e fadiga\"",
        "Como posso transformar seu treino hoje?"
      ]);
    }

    // Análise de Dados
    if (_tem(p, [
      "analise meus dados", "analise meus treinos", "meus dados", "meu resumo",
      "como estao meus treinos", "minha semana", "minha evolucao", "minha performance"
    ])) {
      return RespostaIa(mensagens: _responderAnaliseDados(ctx));
    }

    // Ritmo, Pace e Velocidade
    if (_tem(p, [
      "pace", "ritmo", "baixar tempo", "correr mais rapido", "melhorar velocidade",
      "pace medio", "pace ideal", "o que e pace", "ritmo de prova", "acelerar"
    ])) {
      return RespostaIa(mensagens: _responderPace(ctx, p));
    }

    // Intervalados, Tiros e VO2 Máx
    if (_tem(p, ["tiro", "intervalado", "fartlek", "vo2", "velocidade", "pista"])) {
      return RespostaIa(mensagens: _responderTiros());
    }

    // Longão e Resistência Aeróbica
    if (_tem(p, ["longao", "treino longo", "corrida longa", "resistencia", "quantos km no longo"])) {
      return RespostaIa(mensagens: _responderLongao(ctx));
    }

    // Descanso, Recuperação e Sono
    if (_tem(p, ["descanso", "recuperacao", "recuperar", "sono", "dormir", "cansado", "regenerativo"])) {
      return RespostaIa(mensagens: _responderDescanso(ctx));
    }

    // Dores, Lesões e Cuidados Fisiológicos
    if (_tem(p, [
      "dor", "doendo", "canelite", "joelho", "canela", "panturrilha", "pe",
      "fascite", "lesao", "fisgada", "inflamacao", "alongar", "alongamento"
    ])) {
      return RespostaIa(mensagens: _responderDores(ctx, p));
    }

    // Overtraining e Carga ACWR
    if (_tem(p, ["overtraining", "acwr", "sobrecarga", "estafa", "excesso de treino", "carga"])) {
      return RespostaIa(mensagens: _responderOvertraining(ctx));
    }

    // Metas
    if (_tem(p, ["meta", "metas", "objetivo", "atingir meta"])) {
      return RespostaIa(mensagens: _responderMetas(ctx));
    }

    // Eventos e Provas
    if (_tem(p, ["evento", "eventos", "prova", "corrida de rua", "maratona", "meia maratona", "5k", "10k", "21k", "42k"])) {
      return RespostaIa(mensagens: _responderEventos(ctx, p));
    }

    // Nutrição, Hidratação e Suplementação
    if (_tem(p, [
      "comer", "comida", "alimentacao", "nutricao", "jejum", "gel", "carbo",
      "carboidrato", "agua", "hidratacao", "creatina", "whey", "pre treino", "pos treino"
    ])) {
      return RespostaIa(mensagens: _responderNutricao());
    }

    // Respiração, Asma e Saúde Pulmonar
    if (_tem(p, [
      "respirar", "respiracao", "falta de ar", "asma", "pulmao", "ar",
      "nariz ou boca", "ofegante", "bombinha", "acq"
    ])) {
      return RespostaIa(mensagens: _responderRespiracao(ctx));
    }

    // Frequência Cardíaca e Zonas
    if (_tem(p, ["frequencia cardiaca", "batimento", "bpm", "zonas", "zona 2", "zona 4", "limiar", "cardio"])) {
      return RespostaIa(mensagens: _responderZonasCardiacas());
    }

    // Cadência e Mecânica da Passada
    if (_tem(p, ["cadencia", "passada", "passos por minuto", "spm", "mecanica", "postura", "aterrissagem"])) {
      return RespostaIa(mensagens: _responderCadencia());
    }

    // Tênis e Equipamentos
    if (_tem(p, ["tenis", "calcado", "drop", "placa de carbono", "amortecimento", "relogio", "gps", "garmin"])) {
      return RespostaIa(mensagens: _responderEquipamentos());
    }

    // Subidas, Altimetria e Trail
    if (_tem(p, ["subida", "ladeira", "inclinacao", "altimetria", "trail", "morro"])) {
      return RespostaIa(mensagens: _responderAltimetria());
    }

    // Motivação e Mentalidade
    if (_tem(p, ["preguica", "desanimado", "sem vontade", "motivacao", "desistir", "dificil", "chovendo", "frio", "consistencia"])) {
      return RespostaIa(mensagens: _responderMotivacao(ctx));
    }

    // Agradecimento
    if (_tem(p, ["obrigado", "obrigada", "valeu", "show", "top", "muito bom", "otimo", "maravilha", "perfeito"])) {
      return RespostaIa(mensagens: [
        "Fico muito feliz em ajudar, ${ctx.nome}! Estou aqui para impulsionar a sua evolução a cada quilômetro.",
        "Se quiser planejar novos treinos, definir metas ou tirar dúvidas, é só me chamar!"
      ]);
    }

    // Despedida
    if (_tem(p, ["tchau", "ate mais", "ate logo", "vou correr", "vou treinar", "fui"])) {
      return RespostaIa(mensagens: [
        "Boa corrida e excelente treino, ${ctx.nome}!",
        "Mantenha uma postura ereta, respiração ritmada e lembre-se de se hidratar. Depois venha me contar como foi!"
      ]);
    }

    // Fallback Enciclopédico Esportivo & Geral
    return RespostaIa(mensagens: _responderConhecimentoGeral(ctx, perguntaOriginal));
  }

  // =========================================================================
  // EXECUTORES DE AÇÕES DE AGENTE
  // =========================================================================

  Future<RespostaIa> _executarComandoCriarTreino(String pNorm, String original, ContextoAtleta ctx) async {
    double distancia = 5.0;
    int tempoMin = 30;
    String tipo = "Rodagem";
    String dataStr = "";

    // Extrair distância (ex: 5km, 8.5 km, 10 k)
    final regKm = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:km|k|quilometros|quilômetros)');
    final matchKm = regKm.firstMatch(pNorm);
    if (matchKm != null) {
      distancia = double.tryParse(matchKm.group(1)!.replaceAll(',', '.')) ?? 5.0;
    }

    // Extrair tempo (ex: 40 min, 50 minutos)
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

    // Extrair tipo de treino
    if (pNorm.contains("tiro") || pNorm.contains("intervalado") || pNorm.contains("velocidade")) {
      tipo = "Intervalado / Tiros";
    } else if (pNorm.contains("longao") || pNorm.contains("longo")) {
      tipo = "Longão Aeróbico";
    } else if (pNorm.contains("regenerativo") || pNorm.contains("recuperacao")) {
      tipo = "Regenerativo";
    } else if (pNorm.contains("ritmo") || pNorm.contains("tempo run")) {
      tipo = "Treino de Ritmo";
    }

    // Extrair data
    final hoje = DateTime.now();
    DateTime dataAlvo = hoje.add(const Duration(days: 1)); // Padrão: amanhã
    if (pNorm.contains("hoje")) {
      dataAlvo = hoje;
    } else if (pNorm.contains("amanha")) {
      dataAlvo = hoje.add(const Duration(days: 1));
    } else if (pNorm.contains("depois de amanha")) {
      dataAlvo = hoje.add(const Duration(days: 2));
    }

    final dia = dataAlvo.day.toString().padLeft(2, '0');
    final mes = dataAlvo.month.toString().padLeft(2, '0');
    final ano = dataAlvo.year;
    dataStr = "$dia/$mes/$ano";

    try {
      await Api.criarTreinoCompleto(
        tipo: tipo,
        distanciaKm: distancia,
        tempoSegundos: tempoMin * 60,
        data: dataStr,
        status: "planejado",
        observacoes: "Prescrito e agendado pelo PaceMind IA Agente.",
      );

      final acao = AcaoAgente(
        tipo: "treino_criado",
        titulo: "Treino Criado com Sucesso!",
        descricao: "$tipo de ${distancia.toStringAsFixed(1)} km agendado para $dataStr.",
        rotaNavegacao: "/treinos",
        textoBotao: "Ver Treinos Planejados",
      );

      return RespostaIa(
        mensagens: [
          "⚡ Entendido perfeitamente, ${ctx.nome}! Como seu treinador agente, já criei o treino diretamente na sua planilha:",
          "🏃 Modalidade: $tipo\n📏 Distância: ${distancia.toStringAsFixed(1)} km\n⏱️ Duração Estimada: $tempoMin minutos\n📅 Data Prevista: $dataStr",
          "O treino já está salvo e pronto na sua aba de Treinos. Quando realizar a corrida, basta dar o play ou marcá-lo como concluído!"
        ],
        acao: acao,
      );
    } catch (e) {
      return RespostaIa(
        mensagens: [
          "Tentei agendar o seu treino de ${distancia.toStringAsFixed(1)} km, mas ocorreu uma oscilação na conexão com o servidor.",
          "Você pode também criar o treino manualmente tocando no botão (+) na aba de Treinos!",
        ],
      );
    }
  }

  Future<RespostaIa> _executarComandoCriarMeta(String pNorm, String original, ContextoAtleta ctx) async {
    double valor = 50.0;
    String tipo = "distancia";
    String titulo = "Meta de Corrida";

    // Extrair valor numérico
    final regNum = RegExp(r'(\d+(?:[.,]\d+)?)');
    final match = regNum.firstMatch(pNorm);
    if (match != null) {
      valor = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 50.0;
    }

    if (pNorm.contains("treino") || pNorm.contains("sessoes") || pNorm.contains("dias")) {
      tipo = "treinos";
      titulo = "Concluir ${valor.toInt()} Treinos";
    } else if (pNorm.contains("minuto") || pNorm.contains("hora") || pNorm.contains("tempo")) {
      tipo = "tempo";
      titulo = "Treinar ${valor.toInt()} Minutos";
    } else {
      tipo = "distancia";
      titulo = "Correr ${valor.toStringAsFixed(0)} km";
    }

    try {
      await Api.criarMeta(
        titulo: titulo,
        objetivo: valor,
        tipo: tipo,
      );

      final acao = AcaoAgente(
        tipo: "meta_criada",
        titulo: "Nova Meta Cadastrada!",
        descricao: "$titulo com objetivo de $valor ($tipo).",
        rotaNavegacao: "/metas",
        textoBotao: "Ver Minhas Metas",
      );

      return RespostaIa(
        mensagens: [
          "🎯 Ação executada com sucesso, ${ctx.nome}! Criei a sua nova meta esportiva no PaceMind:",
          "🏆 Título: $titulo\n🎯 Alvo: $valor ($tipo)",
          "Cada treino que você concluir a partir de agora atualizará automaticamente o seu percentual de conquista rumo a esse troféu!"
        ],
        acao: acao,
      );
    } catch (e) {
      return RespostaIa(
        mensagens: [
          "Tentei salvar sua meta de $titulo, mas houve uma falha momentânea de comunicação.",
          "Você pode cadastrá-la diretamente na aba de Metas clicando em 'Nova Meta'!",
        ],
      );
    }
  }

  Future<RespostaIa> _executarComandoSalvarCorrida(String pNorm, String original, ContextoAtleta ctx) async {
    double distancia = 5.0;
    int tempoMin = 30;
    int sensacao = 7;

    final regKm = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:km|k|quilometros)');
    final matchKm = regKm.firstMatch(pNorm);
    if (matchKm != null) {
      distancia = double.tryParse(matchKm.group(1)!.replaceAll(',', '.')) ?? 5.0;
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
    final dia = hoje.day.toString().padLeft(2, '0');
    final mes = hoje.month.toString().padLeft(2, '0');
    final ano = hoje.year;
    final dataStr = "$dia/$mes/$ano";

    final tempoSeg = tempoMin * 60;
    final paceSeg = distancia > 0 ? (tempoSeg / distancia).round() : 0;
    final paceTexto = ctx.formatarPace(paceSeg);

    try {
      await Api.criarTreinoCompleto(
        tipo: "Corrida de Rua",
        distanciaKm: distancia,
        tempoSegundos: tempoSeg,
        data: dataStr,
        sensacao: sensacao,
        status: "concluido",
        observacoes: "Registrado e salvo pelo PaceMind IA Agente.",
      );

      final acao = AcaoAgente(
        tipo: "corrida_salva",
        titulo: "Corrida Salva com Sucesso!",
        descricao: "${distancia.toStringAsFixed(1)} km em $tempoMin min • Pace $paceTexto",
        rotaNavegacao: "/execucoes",
        textoBotao: "Ver Histórico de Corridas",
      );

      return RespostaIa(
        mensagens: [
          "✅ Corrida registrada e salva com sucesso no seu histórico, ${ctx.nome}!",
          "📊 Detalhes da Sessão:\n• Distância: ${distancia.toStringAsFixed(1)} km\n• Tempo Total: $tempoMin minutos\n• Pace Médio: $paceTexto\n• Nível de Esforço: $sensacao/10\n• Data: $dataStr",
          "Essa sessão já entrou no cálculo da sua quilometragem semanal e no seu monitoramento de fadiga (ACWR)!"
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

  Future<RespostaIa> _executarComandoSalvarTeste(String pNorm, String original, ContextoAtleta ctx) async {
    String tipo = "3km";
    double segundos = 720; // 12 min

    if (pNorm.contains("sprint") || pNorm.contains("20m") || pNorm.contains("velocidade maxima")) {
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
        observacoes: "Registrado pelo PaceMind IA Agente.",
      );

      final acao = AcaoAgente(
        tipo: "teste_salvo",
        titulo: "Teste Físico Registrado!",
        descricao: "Teste de ${tipo == '3km' ? '3 km' : 'Sprint 20m'} registrado com sucesso.",
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
  // MÓDULOS DE RESPOSTAS ESPECIALIZADAS
  // =========================================================================

  List<String> _responderSaudacao(ContextoAtleta ctx) {
    final hora = DateTime.now().hour;
    String periodo = (hora >= 5 && hora < 12)
        ? "Bom dia"
        : (hora >= 12 && hora < 18) ? "Boa tarde" : "Boa noite";

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
      "Como posso te ajudar hoje? Você pode tirar dúvidas sobre ritmo, recuperação e nutrição, ou me dar comandos como: \"Crie um treino de 6km\" ou \"Crie uma meta de 50km\"!",
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

    if (ctx.acwr > 1.4) {
      msgs.add(
        "⚠️ Atenção ao índice de carga aguda: você está em zona de sobrecarga. Minha recomendação técnica para os próximos dias é priorizar rodagens muito leves em Zona 1 ou descanso passivo.",
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
      "O segredo para evoluir o pace com segurança não é correr no limite em todos os treinos, mas sim aplicar a polarização 80/20.",
      "Cerca de 80% do seu volume semanal deve ser em ritmo fácil (Zona 2), construindo densidade capilar e eficiência mitocondrial, e 20% em ritmo forte ou de tiro (Zonas 4 e 5).",
    ];

    if (ctx.paceReferenciaSegundos > 0) {
      final paceTiro = (ctx.paceReferenciaSegundos * 0.90).round();
      final paceLongo = (ctx.paceReferenciaSegundos * 1.15).round();

      msgs.add(
        "Com seu pace de referência atual de $paceTexto:\n• Rodagens fáceis e longão: em torno de ${ctx.formatarPace(paceLongo)}.\n• Treinos de ritmo / limiar: próximo a $paceTexto.\n• Tiros de velocidade: em torno de ${ctx.formatarPace(paceTiro)}.",
      );
    } else {
      msgs.add(
        "Para calcularmos suas zonas exatas de pace no app, cadastre seu pace de referência na tela de Perfil ou registre um Teste Físico de 3 km na aba de testes!",
      );
    }

    msgs.add(
      "Dica técnica: foque em aumentar a cadência (170-180 passos por minuto) em vez de alongar a passada. Isso reduz o tempo de contato com o solo e previne lesões no joelho e canela!",
    );

    return msgs;
  }

  List<String> _responderTiros() {
    return [
      "Os treinos intervalados (ou tiros) são o estímulo mais potente para elevar seu VO2 Máximo e aumentar a tolerância ao lactato sanguíneo!",
      "Protocolo recomendado para corredores amadores e intermediários:\n• Aquecimento: 10 a 15 min de trote leve (Z1/Z2) + educativos de corrida.\n• Bloco principal: 6 a 8 repetições de 400m em ritmo de tiro (Z4/Z5) com 1min30s de recuperação ativa caminhando.\n• Desaquecimento: 5 a 10 min de trote regenerativo.",
      "Regra de ouro: nunca faça treinos de tiro em dias seguidos e sempre respeite pelo menos 48h de recuperação entre estímulos intensos."
    ];
  }

  List<String> _responderLongao(ContextoAtleta ctx) {
    return [
      "O longão é a base inegociável da resistência muscular e metabólica na corrida!",
      "A regra fundamental é mantê-lo estritamente na Zona 2 (ritmo conversacional). Se você não conseguir falar uma frase inteira sem engolir o ar, diminua o ritmo imediatamente.",
      "Em termos de volume, o longão nunca deve ultrapassar 30% a 35% de toda a quilometragem que você corre na semana inteira. Quer que eu agende o seu próximo longão?"
    ];
  }

  List<String> _responderDescanso(ContextoAtleta ctx) {
    List<String> msgs = [
      "O descanso não é o oposto do treino: é o período biológico exato em que o corpo sofre supercompensação e constrói novas fibras e vasos sanguíneos mais fortes!",
    ];

    if (ctx.statusFadiga.toLowerCase().contains("alto") || ctx.acwr > 1.3) {
      msgs.add(
        "Seu índice de estresse muscular (ACWR: ${ctx.acwr.toStringAsFixed(2)}) está elevado hoje. Recomendo descanso total ou no máximo uma caminhada leve e liberação miofascial com rolo.",
      );
    } else {
      msgs.add(
        "Se sentir pernas pesadas, sono fragmentado ou batimentos de repouso 5 a 7 bpm acima da sua média, opte por um dia de descanso ou uma rodagem regenerativa de 25 minutos.",
      );
    }

    msgs.add(
      "Durma pelo menos 7 a 8 horas por noite. Mais de 90% do hormônio de crescimento (GH) que recupera seus músculos é liberado nas fases profundas do sono!",
    );

    return msgs;
  }

  List<String> _responderDores(ContextoAtleta ctx, String p) {
    if (p.contains("canelite") || p.contains("canela")) {
      return [
        "A dor na canela (periostite medial da tíbia ou canelite) surge por tração excessiva do músculo tibial sobre o periósteo do osso, comum em aumentos súbitos de volume ou passadas pesadas.",
        "Conduta imediata:\n1. Aplique gelo por 15 a 20 minutos no local após as atividades.\n2. Reduza o volume semanal e evite treinos em asfalto inclinado.\n3. Fortaleça o tibial anterior (levantando a ponta dos pés com o calcanhar apoiado no chão) e os flexores dos dedos.\n4. Se a dor persistir em repouso ao caminhar, consulte um ortopedista para descartar fratura por estresse.",
        "Está sentindo dor agora, ${ctx.nome}?"
      ];
    }

    if (p.contains("joelho")) {
      return [
        "Dores no joelho frequentemente decorrem de fraqueza nos abdutores do quadril (glúteo médio), fazendo o joelho sofrer valgo dinâmico a cada aterrissagem.",
        "Protocolo sugerido:\n• Fortaleça glúteo médio e quadril com passadas laterais com elástico, ponte unipodal e agachamento búlgaro.\n• Monitore se a dor é no tendão patelar (frente) ou trato iliotibial (lateral externa).\n• Se alterar a marcha ou te fizer mancar, pare o treino imediatamente!"
      ];
    }

    if (p.contains("fascite") || p.contains("pe") || p.contains("calcanhar")) {
      return [
        "Dor na sola do pé ou calcanhar ao dar os primeiros passos pela manhã é o sinal clássico de fascite plantar.",
        "Conduta preventiva:\n• Role a sola do pé sobre uma bolinha de tênis ou garrafa de água congelada por 10 minutos.\n• Alongue a panturrilha e os dedos dos pés para trás antes de sair da cama.\n• Evite andar descalço em pisos duros por alguns dias."
      ];
    }

    return [
      "Atenção a dores no corpo, ${ctx.nome}: diferencie a Dor Muscular Tardia (dor difusa e simétrica nas duas pernas 24h após um treino forte) de uma dor lesiva (pontual, assimétrica, em tendões ou articulações).",
      "Se for pontual e piorar com o impacto, suspenda a corrida por 48h e aplique compressa fria. Sua longevidade no esporte depende de escutar os sinais do corpo!"
    ];
  }

  List<String> _responderOvertraining(ContextoAtleta ctx) {
    return [
      "Overtraining (síndrome do sobretreinamento) ocorre quando o volume ou intensidade de treino superam cronicamente a capacidade de regeneração celular do atleta.",
      "No PaceMind, monitoramos a relação ACWR (carga aguda dividida pela crônica). Seu valor atual é de ${ctx.acwr.toStringAsFixed(2)} (${ctx.statusFadiga}).",
      "Sinais clássicos de alerta:\n• Frequência cardíaca basal de repouso elevada pela manhã.\n• Perda de apetite, insônia e irritabilidade.\n• Sensação de peso e falta de resposta nas pernas mesmo em treinos leves.\n\nMantenha o índice entre 0.8 e 1.3 para estar na zona ideal de evolução sem risco de lesão!"
    ];
  }

  List<String> _responderMetas(ContextoAtleta ctx) {
    if (ctx.metas.isEmpty) {
      return [
        "Notei que você ainda não tem metas ativas cadastradas no PaceMind!",
        "Definir metas é o catalisador da consistência esportiva. Você pode criar metas por distância (ex: 100km no mês), tempo ou número de treinos.",
        "Quer criar uma agora? Diga simplesmente: \"Crie uma meta de 80km neste mês\" que eu cadastro para você!"
      ];
    }

    final total = ctx.metas.length;
    final concluidas = ctx.metas.where((m) => m["concluida"] == true).length;
    final primeira = ctx.metas.first;

    return [
      "Você tem $total metas cadastradas no PaceMind, das quais $concluidas já foram conquistadas!",
      "Seu foco atual é: \"${primeira["titulo"]}\" com alvo de ${primeira["objetivo"]} (${primeira["tipo"]}).",
      "Quer adicionar outra meta ou ajustar a atual? Basta me mandar uma mensagem!"
    ];
  }

  List<String> _responderEventos(ContextoAtleta ctx, String p) {
    if (ctx.eventosInscritos.isNotEmpty) {
      return [
        "Excelente! Você já tem inscrições ativas nos eventos do PaceMind!",
        "Dica crucial para os dias pré-prova: faça o polimento (tapering). Reduza o volume semanal em 40% a 50%, mas mantenha pequenos estímulos de ritmo para ativar as fibras rápidas.",
        "Regra de ouro: no dia da prova, não invente nada novo. Use roupas e tênis já testados e o mesmo café da manhã dos seus treinos longos!"
      ];
    }

    return [
      "Participar de provas de corrida é uma experiência incrível que coroa todo o seu esforço!",
      "Aqui no PaceMind, na aba de Eventos, você encontra provas de 5 km, 10 km, Meia Maratona e desafios abertos com inscrições diretamente pelo aplicativo.",
      "Para 5 km ou 10 km, comece os primeiros quilômetros com ritmo controlado e acelere progressivamente na segunda metade (estratégia de split negativo)!"
    ];
  }

  List<String> _responderNutricao() {
    return [
      "A alimentação é a engrenagem que financia cada passada e reconstrói suas fibras musculares!",
      "Orientações chave:\n• Pré-treino (60-90 min antes): carboidratos simples e de fácil digestão (banana com aveia, torrada com geleia, tapioca) com baixo teor de gordura e fibra para evitar desconforto gástrico.\n• Intra-treino (corridas acima de 60-75 min): consuma 30g a 40g de carboidrato por hora (gel ou isotônico) e beba cerca de 150ml a 200ml de água a cada 20 minutos.\n• Pós-treino (janela anabólica): combine carboidratos para repor o glicogênio muscular + 20g a 25g de proteína de alto valor biológico para recuperação tecidual.",
      "Mantenha também hidratação ao longo de todo o dia: beba pelo menos 35ml a 40ml de água por quilo de peso corporal!"
    ];
  }

  List<String> _responderRespiracao(ContextoAtleta ctx) {
    return [
      "O controle respiratório no PaceMind é tratado com rigor técnico e clínico, fundamental para eficiência esportiva e controle da asma induzida pelo exercício!",
      "Padrões respiratórios recomendados:\n1. Respire combinando nariz e boca: em intensidades médias e altas, as fossas nasais não fornecem a vazão de oxigênio necessária.\n2. Respiração Diafragmática: projete o abdômen para fora ao inspirar, garantindo enchimento dos alvéolos pulmonares inferiores.\n3. Ritmo 2:2 ou 3:3: inspire durante 2 passos e expire durante 2 passos. Isso harmoniza a frequência cardiorrespiratória.",
      "Para quem tem asma: faça sempre um aquecimento prévio longo e gradual (15 min em Zona 1). Isso climatiza as vias aéreas e evita o broncoespasmo térmico ou osmótico!"
    ];
  }

  List<String> _responderZonasCardiacas() {
    return [
      "As Zonas de Treinamento Cardíaco são a referência fisiológica do seu motor:",
      "• Zona 1 (50-60% FC máx): Recuperação ativa e aquecimento.\n• Zona 2 (60-70% FC máx): Resistência aeróbica fundamental, densidade mitocondrial e oxidação de gorduras. O ritmo conversacional!\n• Zona 3 (70-80% FC máx): Ritmo moderado e sustentável (tempo).\n• Zona 4 (80-90% FC máx): Limiar de lactato. Treinos fortes de ritmo e tiros longos.\n• Zona 5 (90-100% FC máx): Capacidade anaeróbica e sprints máximos.",
      "Cerca de 75% a 80% do seu volume anual de treinos deve residir na Zona 2 para construir uma base cardiovascular sólida e duradoura!"
    ];
  }

  List<String> _responderCadencia() {
    return [
      "A cadência é o número total de passos que você dá por minuto (SPM - steps per minute).",
      "A faixa considerada ideal pela literatura esportiva gira entre 170 e 180 passos por minuto.",
      "Por que ela é tão importante? Uma cadência mais alta impede o 'overstriding' (quando o pé aterrissa muito à frente do centro de gravidade), diminuindo brutalmente o impacto nas articulações do joelho e quadril!"
    ];
  }

  List<String> _responderEquipamentos() {
    return [
      "O equipamento ideal de corrida equilibra proteção articular, conforto e propósito do treino:",
      "• Tênis de Rodagem Diária (Daily Trainers): amortecimento generoso e durabilidade (600 a 800 km de vida útil).\n• Tênis de Performance / Placa de Carbono: rigidez torcional que aumenta o retorno de energia elástica. Deixe-os para treinos de ritmo e provas.\n• Meias Técnicas de Poliamida: evite meias 100% algodão, pois retêm umidade e provocam bolhas por atrito.",
      "Revezar entre dois modelos diferentes durante a semana dissipa as forças em diferentes pontos da musculatura do pé!"
    ];
  }

  List<String> _responderAltimetria() {
    return [
      "Treinar em subidas é considerado 'musculação disfarçada de corrida'!",
      "Dicas fundamentais para aclives:\n• Diminua o tamanho da passada e aumente a cadência dos pés.\n• Incline o tronco ligeiramente para a frente a partir do tornozelo, nunca dobrando a cintura.\n• Mantenha o olhar cerca de 5 metros à frente e não olhe para os seus pés.\n• Use os braços ativamente para gerar momento angular de propulsão!"
    ];
  }

  List<String> _responderMotivacao(ContextoAtleta ctx) {
    final frases = [
      "\"A motivação faz você começar, mas é o hábito e a consistência que te levam até a linha de chegada.\"",
      "\"Não existe treino ruim: ruim é o treino que você deixou de fazer.\"",
      "\"A corrida é você contra você mesmo. Cada quilômetro vencido é uma vitória pessoal da sua mente.\"",
    ];
    final frase = frases[Random().nextInt(frases.length)];

    return [
      "Eu entendo perfeitamente, ${ctx.nome}. A mente sempre tenta economizar energia e criar desculpas antes de amarrar o tênis!",
      "Aplique a Regra dos 5 Minutos: vista a roupa de treino e diga a si mesmo que vai correr apenas 5 minutos. Se ainda quiser parar depois disso, volte para casa. Em mais de 95% das vezes, a endorfina assume o controle e você completa a sessão inteira!",
      "$frase\n\nVamos lá! Que tal dar o primeiro passo agora?"
    ];
  }

  List<String> _responderConhecimentoGeral(ContextoAtleta ctx, String pergunta) {
    return [
      "Entendi o que você trouxe, ${ctx.nome}! Como seu treinador inteligente e assistente esportivo no PaceMind, posso te apoiar em qualquer questão da sua jornada.",
      "Além de tirar dúvidas sobre fisiologia, dores, respiração e ritmo, lembre-se que eu funciono como um agente autônomo. Você pode me mandar comandos como:\n• \"Crie um treino de 5km para amanhã\"\n• \"Crie uma meta de 80km\"\n• \"Salvar corrida de 6km em 32 minutos hoje\"",
      "Como você gostaria de direcionar seu próximo passo agora?"
    ];
  }
}
