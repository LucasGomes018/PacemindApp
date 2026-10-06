import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class Api {
  static const String baseUrl = "https://pacemind-api.vercel.app";

  // ⚡ MEMÓRIA DE ACESSO INSTANTÂNEO (0ms)
  static Map<String, dynamic>? perfilCache;
  static Map<String, dynamic>? usuarioCache;
  static Map<String, dynamic>? dashboardCache;
  static List<dynamic>? treinosCache;
  static List<dynamic>? metasCache;
  static List<dynamic>? agendaCache;
  static List<dynamic>? notificacoesCache;

  static bool _cacheInicializado = false;
  static bool _precarregando = false;

  // Chaves de armazenamento persistente
  static const String _kCachePerfil = "cache_perfil_v1";
  static const String _kCacheUsuario = "cache_usuario_v1";
  static const String _kCacheDashboard = "cache_dashboard_v1";
  static const String _kCacheTreinos = "cache_treinos_v1";
  static const String _kCacheMetas = "cache_metas_v1";
  static const String _kCacheAgenda = "cache_agenda_v1";
  static const String _kCacheNotificacoes = "cache_notificacoes_v1";

  /// 🚀 Inicializa o cache persistente do disco para a memória na inicialização do app (leva < 5ms)
  static Future<void> inicializarCacheLocal() async {
    if (_cacheInicializado) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      final strPerfil = prefs.getString(_kCachePerfil);
      if (strPerfil != null && strPerfil.isNotEmpty) {
        try {
          perfilCache = jsonDecode(strPerfil);
        } catch (_) {}
      }

      final strUsuario = prefs.getString(_kCacheUsuario);
      if (strUsuario != null && strUsuario.isNotEmpty) {
        try {
          usuarioCache = jsonDecode(strUsuario);
        } catch (_) {}
      }

      final strDash = prefs.getString(_kCacheDashboard);
      if (strDash != null && strDash.isNotEmpty) {
        try {
          dashboardCache = jsonDecode(strDash);
        } catch (_) {}
      }

      final strTreinos = prefs.getString(_kCacheTreinos);
      if (strTreinos != null && strTreinos.isNotEmpty) {
        try {
          treinosCache = jsonDecode(strTreinos);
        } catch (_) {}
      }

      final strMetas = prefs.getString(_kCacheMetas);
      if (strMetas != null && strMetas.isNotEmpty) {
        try {
          metasCache = jsonDecode(strMetas);
        } catch (_) {}
      }

      final strAgenda = prefs.getString(_kCacheAgenda);
      if (strAgenda != null && strAgenda.isNotEmpty) {
        try {
          agendaCache = jsonDecode(strAgenda);
        } catch (_) {}
      }

      final strNotifs = prefs.getString(_kCacheNotificacoes);
      if (strNotifs != null && strNotifs.isNotEmpty) {
        try {
          notificacoesCache = jsonDecode(strNotifs);
        } catch (_) {}
      }

      _cacheInicializado = true;
    } catch (_) {}
  }

  /// 📥 PRÉ-CARREGAMENTO GLOBAL: Baixa em paralelo todos os dados ao abrir o app ou login
  static Future<void> preCarregarDadosGlobais({bool forcarAtualizacao = false}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;
    if (_precarregando) return;
    _precarregando = true;

    try {
      await Future.wait([
        getProfile(forcarAtualizacao: forcarAtualizacao).catchError((_) => <String, dynamic>{}),
        me(forcarAtualizacao: forcarAtualizacao).catchError((_) => <String, dynamic>{}),
        getDashboard(forcarAtualizacao: forcarAtualizacao).catchError((_) => <String, dynamic>{}),
        listarTreinos(forcarAtualizacao: forcarAtualizacao).catchError((_) => []),
        listarMetas(forcarAtualizacao: forcarAtualizacao).catchError((_) => []),
        listarAgenda(forcarAtualizacao: forcarAtualizacao).catchError((_) => []),
        listarNotificacoes(forcarAtualizacao: forcarAtualizacao).catchError((_) => []),
      ]);
    } catch (_) {
    } finally {
      _precarregando = false;
    }
  }

  /// 🧹 Limpa todo o cache em memória e em disco (chamado no logout)
  static Future<void> limparCache() async {
    perfilCache = null;
    usuarioCache = null;
    dashboardCache = null;
    treinosCache = null;
    metasCache = null;
    agendaCache = null;
    notificacoesCache = null;
    _cacheInicializado = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachePerfil);
      await prefs.remove(_kCacheUsuario);
      await prefs.remove(_kCacheDashboard);
      await prefs.remove(_kCacheTreinos);
      await prefs.remove(_kCacheMetas);
      await prefs.remove(_kCacheAgenda);
      await prefs.remove(_kCacheNotificacoes);
    } catch (_) {}
  }

  static Future<void> _salvarCacheLocal(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // --- REVALIDAÇÕES SILENCIOSAS EM BACKGROUND ---
  static void _revalidarDashboard() {
    getDashboard(forcarAtualizacao: true).catchError((_) => <String, dynamic>{});
  }

  static void _revalidarTreinos() {
    listarTreinos(forcarAtualizacao: true).catchError((_) => []);
  }

  static void _revalidarMetas() {
    listarMetas(forcarAtualizacao: true).catchError((_) => []);
  }

  static void _revalidarAgenda() {
    listarAgenda(forcarAtualizacao: true).catchError((_) => []);
  }

  static void _revalidarNotificacoes() {
    listarNotificacoes(forcarAtualizacao: true).catchError((_) => []);
  }

  static void _revalidarPerfil() {
    getProfile(forcarAtualizacao: true).catchError((_) => <String, dynamic>{});
  }

  static void _revalidarUsuario() {
    me(forcarAtualizacao: true).catchError((_) => <String, dynamic>{});
  }

  // --- ENDPOINTS PRINCIPAIS COM SUPORTE A CACHE ---

  static Future<Map<String, dynamic>> getDashboard({
    DateTime? semana,
    bool forcarAtualizacao = false,
  }) async {
    // Para a semana corrente (semana == null), usa retorno instantâneo do cache
    if (semana == null && !forcarAtualizacao && dashboardCache != null) {
      _revalidarDashboard();
      return dashboardCache!;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    String url = "$baseUrl/dashboard";
    if (semana != null) {
      final dataFormatada = semana.toIso8601String();
      url += "?semana=$dataFormatada";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      if (semana == null && dashboardCache != null) return dashboardCache!;
      throw Exception("Erro ao carregar dashboard");
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      if (semana == null && dashboardCache != null) return dashboardCache!;
      throw Exception("Formato inválido do dashboard");
    }

    if (semana == null) {
      dashboardCache = data;
      _salvarCacheLocal(_kCacheDashboard, data);
    }

    return data;
  }

  static Future<List<dynamic>> listarTreinos({bool forcarAtualizacao = false}) async {
    if (!forcarAtualizacao && treinosCache != null && treinosCache!.isNotEmpty) {
      _revalidarTreinos();
      return treinosCache!;
    }

    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/treinos"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      if (treinosCache != null) return treinosCache!;
      throw Exception("Erro ao buscar treinos");
    }

    final data = jsonDecode(response.body);
    if (data is! List) throw Exception("Formato inválido de treinos");

    treinosCache = data;
    _salvarCacheLocal(_kCacheTreinos, data);
    return data;
  }

  static Future<List<dynamic>> listarTreinosConcluidos({bool forcarAtualizacao = false}) async {
    if (!forcarAtualizacao && treinosCache != null && treinosCache!.isNotEmpty) {
      final concluidos = treinosCache!
          .where((t) => (t["status"] ?? "").toString().toLowerCase() == "concluido")
          .toList();
      if (concluidos.isNotEmpty) return concluidos;
    }

    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/treinos?status=concluido"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      if (treinosCache != null) {
        return treinosCache!
            .where((t) => (t["status"] ?? "").toString().toLowerCase() == "concluido")
            .toList();
      }
      throw Exception("Erro ao buscar treinos concluídos");
    }

    final data = jsonDecode(response.body);
    if (data is! List) throw Exception("Formato inválido de treinos");

    return data;
  }

  static Future<Map<String, dynamic>> me({bool forcarAtualizacao = false}) async {
    if (!forcarAtualizacao && usuarioCache != null && usuarioCache!.isNotEmpty) {
      _revalidarUsuario();
      return usuarioCache!;
    }

    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/usuarios/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      if (usuarioCache != null) return usuarioCache!;
      throw Exception("Erro ao buscar usuário");
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      usuarioCache = data;
      _salvarCacheLocal(_kCacheUsuario, data);
      return data;
    }
    return usuarioCache ?? {};
  }

  static Future<Map<String, dynamic>> getProfile({bool forcarAtualizacao = false}) async {
    if (!forcarAtualizacao && perfilCache != null && perfilCache!.isNotEmpty) {
      _revalidarPerfil();
      return perfilCache!;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      if (perfilCache != null) return perfilCache!;
      throw Exception("Token não encontrado");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/perfil"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      if (perfilCache != null) return perfilCache!;
      throw Exception("Erro ao buscar perfil");
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      perfilCache = data;
      _salvarCacheLocal(_kCachePerfil, data);
      return data;
    }
    return perfilCache ?? {};
  }

  static Future<Map<String, dynamic>> uploadFoto(File imagem) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    var request = http.MultipartRequest(
      "PUT",
      Uri.parse("$baseUrl/perfil/foto"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.files.add(
      await http.MultipartFile.fromPath(
        "foto", // 👈 TEM que ser exatamente igual
        imagem.path,
      ),
    );

    final response = await request.send();

    final responseData = await response.stream.bytesToString();

    return jsonDecode(responseData);
  }

  static Future<Map<String, dynamic>> atualizarPerfil({
    String? nome,
    int? pace,
    double? objetivo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.put(
      Uri.parse("$baseUrl/perfil"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "nome_usuario": nome,
        "pace_referencia_segundos": pace,
        "objetivo_semanal_km": objetivo,
      }),
    );

    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data is Map
            ? data["message"] ?? "Erro ao atualizar perfil"
            : "Erro ao atualizar perfil",
      );
    }
    if (data is! Map<String, dynamic>) {
      throw Exception("Resposta inválida ao atualizar perfil");
    }
    return data;
  }

  static Future<Map<String, dynamic>> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.put(
      Uri.parse("$baseUrl/usuarios/senha"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"senha_atual": senhaAtual, "nova_senha": novaSenha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(jsonDecode(response.body)["message"]);
  }

  static Future<Map<String, dynamic>?> criarNotificacao({
    required String titulo,
    required String mensagem,
    String tipo = "treino",
    bool global = false,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/notificacoes"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "titulo": titulo,
          "mensagem": mensagem,
          "tipo": tipo,
          "global": global || tipo == "evento",
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> listarMensagensChat() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/recomendacoes"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao carregar histórico do chat");
    }

    final data = jsonDecode(response.body);
    if (data is! List) throw Exception("Formato inválido do histórico");

    return data;
  }

  static Future<void> salvarMensagemChat({
    required String mensagem,
    required bool enviadaPeloUsuario,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/recomendacoes"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "titulo": enviadaPeloUsuario ? "Pergunta" : "PaceMind IA",
        "mensagem": mensagem,
        "tipo": enviadaPeloUsuario ? "chat_usuario" : "chat_ia",
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Erro ao salvar mensagem do chat");
    }
  }

  static Future<void> deletarRecomendacao(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/recomendacoes/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Não foi possível excluir uma mensagem do histórico");
    }
  }

  // ===============================
  // 🏁 EVENTOS
  // ===============================

  static Future<List<dynamic>> listarEventos() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/eventos"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao listar eventos");
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> buscarEvento(String id) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/eventos/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar evento");
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> criarEvento({
    required String nome,
    required String local,
    required double distanciaKm,
    required String dataEvento,
    required String descricao,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/eventos"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "nome": nome,
        "local": local,
        "distancia_km": distanciaKm,
        "data_evento": dataEvento,
        "descricao": descricao,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Erro ao criar evento");
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> atualizarEvento({
    required String id,
    required String nome,
    required String local,
    required double distanciaKm,
    required String dataEvento,
    required String descricao,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse("$baseUrl/eventos/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "nome": nome,
        "local": local,
        "distancia_km": distanciaKm,
        "data_evento": dataEvento,
        "descricao": descricao,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar evento");
    }

    return jsonDecode(response.body);
  }

  static Future<void> deletarEvento(String id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/eventos/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar evento");
    }
  }

  // ===============================
  // 🏃 INSCRIÇÕES
  // ===============================

  static Future<Map<String, dynamic>> inscreverEvento({
    required String idEvento,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/eventos/inscricao"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"id_evento": idEvento}),
    );

    if (response.statusCode != 201) {
      throw Exception("Erro ao realizar inscrição");
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> listarInscricoes(String id) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/eventos/$id/inscricoes"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }

  static Future<void> cancelarInscricao(String id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/eventos/inscricao/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao cancelar inscrição");
    }
  }

  static Future<List> minhasInscricoes() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/eventos/minhas-inscricoes"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    return data;
  }

  // ===============================
  // 🎯 METAS
  // ===============================

  static Future<List<dynamic>> listarMetas({bool forcarAtualizacao = false}) async {
    if (!forcarAtualizacao && metasCache != null && metasCache!.isNotEmpty) {
      _revalidarMetas();
      return metasCache!;
    }

    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/metas"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      if (metasCache != null) return metasCache!;
      throw Exception("Erro ao listar metas");
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      metasCache = data;
      _salvarCacheLocal(_kCacheMetas, data);
      return data;
    }
    return metasCache ?? [];
  }

  static Future<Map<String, dynamic>> criarMeta({
    required String titulo,
    required double objetivo,
    required String tipo,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/metas"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"titulo": titulo, "objetivo": objetivo, "tipo": tipo}),
    );

    if (response.statusCode != 201) {
      throw Exception("Erro ao criar meta");
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> atualizarProgressoMeta({
    required String id,
    required double progresso,
  }) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse("$baseUrl/metas/$id/progresso"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"progresso": progresso}),
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar progresso");
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> concluirMeta(String id) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse("$baseUrl/metas/$id/concluir"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao concluir meta");
    }

    return jsonDecode(response.body);
  }

  static Future<void> deletarMeta(String id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/metas/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar meta");
    }
  }

  // ===============================
  // 🏃 CORRIDAS GPS
  // ===============================

  static Future<Map<String, dynamic>> iniciarCorrida() async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/corridas/iniciar"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 201) {
      throw Exception("Erro ao iniciar corrida");
    }

    return jsonDecode(response.body);
  }

  static Future<void> salvarPosicao({
    required int idCorrida,
    required double latitude,
    required double longitude,
    double? precisao,
  }) async {
    final token = await _getToken();

    await http.post(
      Uri.parse("$baseUrl/corridas/$idCorrida/posicao"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
        "precisao": precisao,
      }),
    );
  }

  static Future<Map<String, dynamic>> finalizarCorrida({
    required int idCorrida,
    required double distanciaMetros,
    required int tempoSegundos,
    required int paceMedioSegundos,
    required double velocidadeMedia,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse("$baseUrl/corridas/$idCorrida/finalizar"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "distancia_metros": distanciaMetros,
        "tempo_segundos": tempoSegundos,
        "pace_medio_segundos": paceMedioSegundos,
        "velocidade_media": velocidadeMedia,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao finalizar corrida");
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> listarCorridas() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/corridas"),
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> buscarCorrida(int idCorrida) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/corridas/$idCorrida"),
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> buscarTrajeto(int idCorrida) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/corridas/$idCorrida/trajeto"),
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  static Future<void> deletarCorrida(int idCorrida) async {
    final token = await _getToken();

    await http.delete(
      Uri.parse("$baseUrl/corridas/$idCorrida"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  // Treino
  static Future<List<dynamic>> listarTreinosPlanejados() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/treinos?status=planejado"),
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  static Future<void> iniciarTreino(String idTreino) async {
    final token = await _getToken();

    await http.put(
      Uri.parse("$baseUrl/treinos/$idTreino/iniciar"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<void> finalizarTreino({
    required String idTreino,
    required double distanciaKm,
    double? distanciaAtualKm,
    required int tempoSegundos,
    int? sensacao,
    int? fcMedia,
    int? fcMax,
    int? idCorrida,
    String? status,
  }) async {
    final token = await _getToken();

    final body = <String, dynamic>{
      "distancia_km": distanciaKm,
      "distancia_atual_km": distanciaAtualKm ?? distanciaKm,
      "tempo_segundos": tempoSegundos,
    };
    if (sensacao != null) body["sensacao"] = sensacao;
    if (fcMedia != null) body["fc_media"] = fcMedia;
    if (fcMax != null) body["fc_max"] = fcMax;
    if (idCorrida != null) body["id_corrida"] = idCorrida;
    if (status != null) body["status"] = status;

    await http.put(
      Uri.parse("$baseUrl/treinos/$idTreino/finalizar"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
  }

  static Future<void> atualizarTreinoParcial({
    required String idTreino,
    double? distanciaAtualKm,
    int? tempoSegundos,
    String? status,
    int? idCorrida,
  }) async {
    try {
      final token = await _getToken();
      final body = <String, dynamic>{};
      if (distanciaAtualKm != null) {
        body["distancia_atual_km"] = distanciaAtualKm;
      }
      if (tempoSegundos != null) body["tempo_segundos"] = tempoSegundos;
      if (status != null) body["status"] = status;
      if (idCorrida != null) body["id_corrida"] = idCorrida;

      await http.patch(
        Uri.parse("$baseUrl/treinos/$idTreino"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );
    } catch (_) {}
  }

  static Future<List<dynamic>> buscarTreinosPlanejados() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/treinos?status=planejado,em_andamento"),
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  // ===============================
  // 🏃 TESTES FÍSICOS (3KM & SPRINT 20M)
  // ===============================

  static Future<Map<String, dynamic>> salvarTeste({
    required String tipoTeste, // '3km' ou 'sprint_20m'
    required double tempoSegundos,
    String? observacoes,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/testes"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "tipo_teste": tipoTeste,
        "tempo_segundos": tempoSegundos,
        "observacoes": observacoes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Erro ao salvar teste físico");
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> listarTestes() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/testes"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      return [];
    }

    return jsonDecode(response.body);
  }

  static Future<void> deletarTeste(String id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/testes/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar teste");
    }
  }

  // ===============================
  // 🩺 QUESTIONÁRIOS DE ASMA (ACQ-5 & MiniAQLQ)
  // ===============================

  static Future<Map<String, dynamic>> salvarQuestionario({
    required String tipo, // 'acq5' ou 'miniaqlq'
    required Map<String, int> respostas,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/questionarios"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"tipo": tipo, "respostas": respostas}),
    );

    if (response.statusCode != 201) {
      throw Exception("Erro ao salvar questionário");
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> listarQuestionarios() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/questionarios"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      return [];
    }

    return jsonDecode(response.body);
  }

  static Future<void> deletarQuestionario(String id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/questionarios/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar questionário");
    }
  }

  // ===============================
  // ⚡ ZONAS DE TREINO & ANÁLISE
  // ===============================

  static Future<Map<String, dynamic>> getZonasPace() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/zonas/pace"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return {};
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getZonasDistribuicao() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/zonas/distribuicao"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return {};
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getZonasAnalise() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/zonas/analise"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return {};
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getZonasPorSemana() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/zonas/semana"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return [];
    return jsonDecode(response.body);
  }

  // ===============================
  // 🔥 OVERTRAINING & CARGA ACWR
  // ===============================

  static Future<Map<String, dynamic>> getOvertraining() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/analise/overtraining"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return {};
    return jsonDecode(response.body);
  }

  // ===============================
  // 📈 COMPARAÇÕES & HISTÓRICO SEMANAL
  // ===============================

  static Future<Map<String, dynamic>> getComparacaoSemanal() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/resumo/semana/comparacao"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return {};
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getHistoricoSemanal() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/resumo/semana/historico"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return [];
    return jsonDecode(response.body);
  }

  // ===============================
  // 📋 FICHA DO ALUNO
  // ===============================

  static Future<Map<String, dynamic>> getFichaAluno() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/ficha"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return {};
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> salvarFichaAluno(
    Map<String, dynamic> dados,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/ficha"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dados),
    );

    if (response.statusCode == 400) {
      // Se já existe, tenta atualizar
      final putResp = await http.put(
        Uri.parse("$baseUrl/ficha"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(dados),
      );
      if (putResp.statusCode == 200) return jsonDecode(putResp.body);
    }

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Erro ao salvar ficha do aluno");
    }

    return jsonDecode(response.body);
  }

  // ===============================
  // 🔬 EXAMES
  // ===============================

  static Future<List<dynamic>> listarExames() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/exames"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return [];
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> salvarExame(
    Map<String, dynamic> dados,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/exames"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dados),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Erro ao salvar exame");
    }

    return jsonDecode(response.body);
  }

  static Future<void> deletarExame(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/exames/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar exame");
    }
  }

  // ===============================
  // 📑 RELATÓRIOS
  // ===============================

  static Future<List<dynamic>> listarRelatorios() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/relatorios"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return [];
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> salvarRelatorio(
    Map<String, dynamic> dados,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/relatorios"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dados),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Erro ao salvar relatório");
    }

    return jsonDecode(response.body);
  }

  static Future<void> deletarRelatorio(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/relatorios/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar relatório");
    }
  }

  // ===============================
  // 🏃 CRIAR TREINO COMPLETO
  // ===============================

  static Future<Map<String, dynamic>> criarTreinoCompleto({
    required String tipo,
    required double distanciaKm,
    int tempoSegundos = 0,
    required String data,
    double? distanciaAtualKm,
    int? fcMedia,
    int? fcMax,
    int? sensacao,
    String? observacoes,
    String status = "planejado",
    Map<String, int>? tempoZonas,
    int? idCorrida,
    List<Map<String, dynamic>>? splits,
  }) async {
    final token = await _getToken();
    final ritmoMedio = (distanciaKm > 0 && tempoSegundos > 0)
        ? (tempoSegundos / distanciaKm).round()
        : null;

    final body = <String, dynamic>{
      "tipo": tipo,
      "distancia_km": distanciaKm,
      "distancia_atual_km": distanciaAtualKm ?? 0.0,
      "tempo_segundos": tempoSegundos > 0 ? tempoSegundos : null,
      "data": data,
      "ritmo_medio_segundos": ritmoMedio,
      "fc_media": fcMedia,
      "fc_max": fcMax,
      "sensacao": sensacao,
      "observacoes": observacoes,
      "status": status,
    };
    if (idCorrida != null) body["id_corrida"] = idCorrida;
    if (splits != null) body["splits"] = splits;
    if (tempoZonas != null) body["zonas"] = tempoZonas;

    final response = await http.post(
      Uri.parse("$baseUrl/treinos"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Erro ao criar treino: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  // ===============================
  // 👑 ADMINISTRAÇÃO & GESTÃO DE ALUNOS
  // ===============================

  /// Lista todos os usuários cadastrados (exclusivo para admin).
  static Future<List<dynamic>> listarUsuariosAdmin() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/usuarios"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar usuários");
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];
    return data;
  }

  /// Lista todos os perfis cadastrados (exclusivo para admin).
  static Future<List<dynamic>> listarPerfisAdmin() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/perfis"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];
    return data;
  }

  /// Busca os treinos de um aluno específico pelo id_usuario.
  static Future<List<dynamic>> buscarTreinosPorAluno(String idUsuario) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/treinos?id_usuario=$idUsuario"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];
    return data;
  }

  /// Busca a ficha médica/anamnese de um aluno específico pelo id_usuario.
  static Future<Map<String, dynamic>> buscarFichaPorAluno(
    String idUsuario,
  ) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/ficha?id_usuario=$idUsuario"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      return {};
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return {};
    return data;
  }

  /// Exclui um treino pelo ID.
  static Future<void> deletarTreino(dynamic idTreino) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/treinos/$idTreino"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erro ao excluir treino");
    }
  }

  // ===============================
  // 🔔 NOTIFICAÇÕES
  // ===============================

  static Future<List<dynamic>> listarNotificacoes({bool forcarAtualizacao = false}) async {
    if (!forcarAtualizacao && notificacoesCache != null) {
      _revalidarNotificacoes();
      return notificacoesCache!;
    }

    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/notificacoes"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (notificacoesCache != null) return notificacoesCache!;
      throw Exception("Erro ao buscar notificações");
    }

    final data = jsonDecode(response.body);
    if (data is! List) {
      if (notificacoesCache != null) return notificacoesCache!;
      return [];
    }
    notificacoesCache = List<dynamic>.from(data);
    _salvarCacheLocal(_kCacheNotificacoes, notificacoesCache);
    return notificacoesCache!;
  }

  static Future<Map<String, dynamic>> verificarNotificacoesAutomaticas() async {
    final token = await _getToken();
    if (token == null) return {};

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/notificacoes/verificar-automaticas"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {};
      }
    } catch (_) {}
    return {};
  }

  static Future<void> marcarNotificacaoLida(
    dynamic idNotificacao, {
    bool lida = true,
  }) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse("$baseUrl/notificacoes/$idNotificacao"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"lida": lida}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Tenta fallback com rota /lida caso seja versão alternativa
      try {
        await http.patch(
          Uri.parse("$baseUrl/notificacoes/$idNotificacao/lida"),
          headers: {"Authorization": "Bearer $token"},
        );
      } catch (_) {}
    }
  }

  static Future<void> marcarTodasNotificacoesLidas() async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse("$baseUrl/notificacoes"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erro ao marcar notificações como lidas");
    }
  }

  static Future<void> deletarNotificacao(dynamic idNotificacao) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/notificacoes/$idNotificacao"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erro ao deletar notificação");
    }
  }

  static Future<void> limparTodasNotificacoes() async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/notificacoes"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erro ao limpar notificações");
    }
  }

  // ===============================
  // 📅 AGENDA
  // ===============================
  static Future<List<dynamic>> listarAgenda({bool forcarAtualizacao = false}) async {
    if (!forcarAtualizacao && agendaCache != null) {
      _revalidarAgenda();
      return agendaCache!;
    }

    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/agenda"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      if (agendaCache != null) return agendaCache!;
      return [];
    }
    final data = jsonDecode(response.body);
    if (data is! List) {
      if (agendaCache != null) return agendaCache!;
      return [];
    }
    agendaCache = List<dynamic>.from(data);
    _salvarCacheLocal(_kCacheAgenda, agendaCache);
    return agendaCache!;
  }

  static Future<Map<String, dynamic>> criarAgenda({
    required String titulo,
    String? descricao,
    required String dataInicio,
    String? dataFim,
    String? tipo,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/agenda"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "titulo": titulo,
        "descricao": descricao,
        "data_inicio": dataInicio,
        "data_fim": dataFim,
        "tipo": tipo ?? "treino",
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      String msg = "Erro ao criar compromisso na agenda";
      try {
        final err = jsonDecode(response.body);
        if (err is Map && err["message"] != null) {
          msg = err["message"];
        }
      } catch (_) {}
      throw Exception(msg);
    }
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic> && agendaCache != null) {
      agendaCache!.add(data);
      _salvarCacheLocal(_kCacheAgenda, agendaCache);
    }
    return data is Map<String, dynamic> ? data : {};
  }

  static Future<Map<String, dynamic>> atualizarAgenda({
    required String id,
    required String titulo,
    String? descricao,
    required String dataInicio,
    String? dataFim,
    String? tipo,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse("$baseUrl/agenda/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "titulo": titulo,
        "descricao": descricao,
        "data_inicio": dataInicio,
        "data_fim": dataFim,
        "tipo": tipo ?? "treino",
      }),
    );
    if (response.statusCode != 200) {
      String msg = "Erro ao atualizar agenda";
      try {
        final err = jsonDecode(response.body);
        if (err is Map && err["message"] != null) {
          msg = err["message"];
        }
      } catch (_) {}
      throw Exception(msg);
    }
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic> && agendaCache != null) {
      final idx = agendaCache!.indexWhere((it) => (it["id_agenda"] ?? it["id"]).toString() == id);
      if (idx != -1) {
        agendaCache![idx] = data;
      }
      _salvarCacheLocal(_kCacheAgenda, agendaCache);
    }
    return data is Map<String, dynamic> ? data : {};
  }

  static Future<void> deletarAgenda(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/agenda/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao excluir compromisso");
    }
  }

  // ===============================
  // 🤝 PARCEIROS
  // ===============================
  static Future<List<dynamic>> listarParceiros() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/parceiros"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> criarParceiro(
    Map<String, dynamic> dados,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/parceiros"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dados),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Erro ao cadastrar parceiro");
    }
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> atualizarParceiro(
    String id,
    Map<String, dynamic> dados,
  ) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse("$baseUrl/parceiros/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dados),
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar parceiro");
    }
    return jsonDecode(response.body);
  }

  static Future<void> deletarParceiro(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/parceiros/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar parceiro");
    }
  }

  // ===============================
  // ❤️ WELLNESS & RECUPERAÇÃO
  // ===============================
  static Future<List<dynamic>> listarWellness() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/wellness"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> criarWellness(
    Map<String, dynamic> dados,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/wellness"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dados),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Erro ao salvar check-in de wellness");
    }
    return jsonDecode(response.body);
  }

  static Future<void> deletarWellness(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/wellness/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      throw Exception("Erro ao deletar check-in");
    }
  }

  static Future<List<dynamic>> listarRecuperacao() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/recuperacao"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> criarRecuperacao({
    required int qualidadeSono,
    required int fadiga,
    required int estresse,
    required int dorMuscular,
    required bool prontoParaTreinar,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/recuperacao"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "qualidade_sono": qualidadeSono,
        "fadiga": fadiga,
        "estresse": estresse,
        "dor_muscular": dorMuscular,
        "pronto_para_treinar": prontoParaTreinar,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Erro ao salvar recuperação");
    }
    return jsonDecode(response.body);
  }
}
