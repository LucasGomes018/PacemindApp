import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class Api {
  static const String baseUrl = "https://pacemind-api.vercel.app";

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    print("TOKEN NA API: $token");

    return token;
  }

  static Future<Map<String, dynamic>> getDashboard({DateTime? semana}) async {
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

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> me() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/usuarios/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar usuário");
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      throw Exception("Token não encontrado");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/perfil"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar perfil");
    }

    return jsonDecode(response.body);
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

    print(response.statusCode);
    print(responseData);

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

    return jsonDecode(response.body);
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

  static Future<void> criarNotificacao({
    required String titulo,
    required String mensagem,
    String tipo = "treino",
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    await http.post(
      Uri.parse("$baseUrl/notificacoes"),

      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },

      body: jsonEncode({"titulo": titulo, "mensagem": mensagem, "tipo": tipo}),
    );
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

    print("STATUS INSCRIÇÕES: ${response.statusCode}");
    print("BODY INSCRIÇÕES: ${response.body}");

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

  static Future<List<dynamic>> listarMetas() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/metas"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao listar metas");
    }

    return jsonDecode(response.body);
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
    required int tempoSegundos,
  }) async {
    final token = await _getToken();

    await http.put(
      Uri.parse("$baseUrl/treinos/$idTreino/finalizar"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "distancia_km": distanciaKm,
        "tempo_segundos": tempoSegundos,
      }),
    );
  }

  static Future<List<dynamic>> buscarTreinosPlanejados() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/treinos?status=planejado"),
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
      body: jsonEncode({
        "tipo": tipo,
        "respostas": respostas,
      }),
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
}
