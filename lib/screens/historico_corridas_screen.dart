import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';
import 'detalhes_corrida_screen.dart';

class HistoricoCorridasScreen extends StatefulWidget {
  final LatLng? posicaoAtleta;

  const HistoricoCorridasScreen({
    super.key,
    this.posicaoAtleta,
  });

  @override
  State<HistoricoCorridasScreen> createState() => _HistoricoCorridasScreenState();
}

class _HistoricoCorridasScreenState extends State<HistoricoCorridasScreen> {
  bool _carregando = true;
  String? _erro;
  List<dynamic> _todasCorridas = [];
  String _filtroStatus = "todas"; // todas, finalizada, ativa
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = "";

  @override
  void initState() {
    super.initState();
    _carregarCorridas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarCorridas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await Api.listarCorridas();
      if (!mounted) return;

      setState(() {
        _todasCorridas = lista;
        _carregando = false;
        _erro = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = "Não foi possível carregar o histórico de corridas.";
      });
    }
  }

  List<dynamic> get _corridasFiltradas {
    return _todasCorridas.where((c) {
      final status = (c["status"] ?? "finalizada").toString().toLowerCase();

      // Filtro de Status
      if (_filtroStatus == "finalizada" && status != "finalizada" && status != "concluido") {
        return false;
      }
      if (_filtroStatus == "ativa" && status != "ativa" && status != "em_andamento") {
        return false;
      }

      // Filtro de Busca por Data
      if (_termoBusca.isNotEmpty) {
        final dataStr = AppDateUtils.formatarData(c["iniciado_em"]).toLowerCase();
        final distStr = ((double.tryParse(c["distancia_metros"]?.toString() ?? "0") ?? 0) / 1000).toStringAsFixed(2);
        if (!dataStr.contains(_termoBusca.toLowerCase()) && !distStr.contains(_termoBusca)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _formatarPace(dynamic paceRaw) {
    if (paceRaw == null) return "-";
    final totalSeg = int.tryParse(paceRaw.toString()) ?? 0;
    if (totalSeg <= 0) return "-";
    final min = totalSeg ~/ 60;
    final seg = totalSeg % 60;
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} /km";
  }

  String _formatarTempo(dynamic tempoRaw) {
    if (tempoRaw == null) return "0s";
    final totalSeg = int.tryParse(tempoRaw.toString()) ?? 0;
    if (totalSeg <= 0) return "0s";
    final h = totalSeg ~/ 3600;
    final m = (totalSeg % 3600) ~/ 60;
    final s = totalSeg % 60;

    if (h > 0) return "${h}h ${m}m";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  Future<void> _abrirDetalhes(Map<String, dynamic> corrida) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesCorridaScreen(
          corrida: corrida,
          posicaoAtleta: widget.posicaoAtleta,
        ),
      ),
    );

    if (!mounted) return;

    if (resultado == true) {
      // Corrida foi excluída
      _carregarCorridas();
    } else if (resultado is Map && resultado["acao"] == "exibir_no_mapa") {
      // Usuário pediu para exibir no mapa principal
      Navigator.pop(context, resultado);
    }
  }

  Future<void> _excluirCorrida(int id) async {
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Excluir Corrida?",
      message: "Esta corrida será removida permanentemente do seu histórico.",
      confirmText: "Sim, Excluir",
      cancelText: "Cancelar",
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      confirmButtonColor: const Color(0xFFEF4444),
      isDestructive: true,
    );

    if (confirmar == true && mounted) {
      final sucesso = await Api.deletarCorrida(id);
      if (!mounted) return;
      if (sucesso) {
        AppSnackBar.sucesso(context, "Corrida excluída com sucesso.", titulo: "Excluída");
        _carregarCorridas();
      } else {
        AppSnackBar.erro(context, "Não foi possível excluir a corrida.", titulo: "Erro");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgScaffold = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    // Cálculos de Resumo Geral
    double somaDistanciaMetros = 0;
    int somaTempoSegundos = 0;
    for (final c in _todasCorridas) {
      somaDistanciaMetros += double.tryParse(c["distancia_metros"]?.toString() ?? "0") ?? 0;
      somaTempoSegundos += int.tryParse(c["tempo_segundos"]?.toString() ?? "0") ?? 0;
    }
    final totalKm = somaDistanciaMetros / 1000.0;
    final totalHoras = somaTempoSegundos ~/ 3600;
    final totalMinutos = (somaTempoSegundos % 3600) ~/ 60;

    final listaExibida = _corridasFiltradas;

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        title: const Text(
          "Histórico de Corridas",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        centerTitle: false,
        backgroundColor: bgScaffold,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _carregarCorridas,
            tooltip: "Atualizar",
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarCorridas,
        color: const Color(0xFF0066FF),
        child: _carregando
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0066FF)),
              )
            : _erro != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 54, color: colors.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            _erro!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurface, fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _carregarCorridas,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Tentar Novamente"),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // CARD DE RESUMO GLOBAL DE ATIVIDADES
                      if (_todasCorridas.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066FF), Color(0xFF0044CC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "Seu Desempenho Total",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _resumoItem(
                                      label: "Corridas",
                                      valor: "${_todasCorridas.length}",
                                      icone: Icons.flag_rounded,
                                    ),
                                  ),
                                  Container(width: 1, height: 32, color: Colors.white24),
                                  Expanded(
                                    child: _resumoItem(
                                      label: "Distância Total",
                                      valor: "${totalKm.toStringAsFixed(1)} km",
                                      icone: Icons.straighten_rounded,
                                    ),
                                  ),
                                  Container(width: 1, height: 32, color: Colors.white24),
                                  Expanded(
                                    child: _resumoItem(
                                      label: "Tempo Total",
                                      valor: totalHoras > 0 ? "${totalHoras}h ${totalMinutos}m" : "${totalMinutos}m",
                                      icone: Icons.timer_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // BARRA DE PESQUISA
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _buscaController,
                          onChanged: (v) => setState(() => _termoBusca = v),
                          decoration: InputDecoration(
                            hintText: "Buscar corrida por data ou km...",
                            hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded, color: colors.onSurfaceVariant),
                            suffixIcon: _termoBusca.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _buscaController.clear();
                                      setState(() => _termoBusca = "");
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      // CHIPS DE FILTRO (TODAS, CONCLUÍDAS, EM ANDAMENTO)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filtroChip("Todas", "todas", _todasCorridas.length),
                            const SizedBox(width: 8),
                            _filtroChip(
                              "Concluídas",
                              "finalizada",
                              _todasCorridas.where((c) {
                                final s = (c["status"] ?? "").toString().toLowerCase();
                                return s == "finalizada" || s == "concluido";
                              }).length,
                            ),
                            const SizedBox(width: 8),
                            _filtroChip(
                              "Em andamento",
                              "ativa",
                              _todasCorridas.where((c) {
                                final s = (c["status"] ?? "").toString().toLowerCase();
                                return s == "ativa" || s == "em_andamento";
                              }).length,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // LISTAGEM DE CORRIDAS
                      if (listaExibida.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.map_outlined,
                                  size: 48,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _termoBusca.isNotEmpty
                                    ? "Nenhuma corrida encontrada para '$_termoBusca'."
                                    : "Nenhuma corrida gravada ainda.",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _termoBusca.isNotEmpty
                                    ? "Tente buscar por outro termo ou data."
                                    : "Inicie uma corrida pelo mapa para começar a gravar seu trajeto e métricas em tempo real!",
                                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066FF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                ),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.navigation_rounded, size: 18),
                                label: const Text("Ir para o Mapa"),
                              ),
                            ],
                          ),
                        )
                      else
                        ...listaExibida.map((corrida) {
                          final idRaw = corrida["id"] ?? corrida["id_corrida"];
                          final id = int.tryParse(idRaw?.toString() ?? "") ?? 0;
                          final distMetros = double.tryParse(corrida["distancia_metros"]?.toString() ?? "0") ?? 0.0;
                          final distKm = distMetros / 1000.0;
                          final tempoSeg = int.tryParse(corrida["tempo_segundos"]?.toString() ?? "0") ?? 0;
                          final paceSeg = int.tryParse(corrida["pace_medio_segundos"]?.toString() ?? "0") ?? 0;
                          final velMedia = double.tryParse(corrida["velocidade_media"]?.toString() ?? "0") ?? 0.0;
                          final status = corrida["status"]?.toString() ?? "finalizada";
                          final bool isFinalizada = status.toLowerCase() == "finalizada" || status.toLowerCase() == "concluido";
                          final dataStr = AppDateUtils.formatarData(corrida["iniciado_em"]);
                          final calorias = (distKm * 62).round();
                          final totalPontos = int.tryParse(corrida["total_pontos"]?.toString() ?? "0") ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => _abrirDetalhes(corrida),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // CABEÇALHO DO CARD (DATA + STATUS + EXCLUIR)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.timeline_rounded,
                                                    color: Color(0xFF0066FF),
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        dataStr,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14.5,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(
                                                        totalPontos > 0
                                                            ? "$totalPontos coordenadas GPS gravadas"
                                                            : "Sem coordenadas de rota",
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          color: totalPontos > 0
                                                              ? colors.onSurfaceVariant
                                                              : const Color(0xFFF59E0B),
                                                          fontWeight: totalPontos > 0
                                                              ? FontWeight.normal
                                                              : FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: (isFinalizada ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                                      .withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  isFinalizada ? "Concluída" : "Ativa",
                                                  style: TextStyle(
                                                    color: isFinalizada ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: Icon(Icons.more_vert_rounded, color: colors.onSurfaceVariant, size: 20),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                onSelected: (val) {
                                                  if (val == "excluir") {
                                                    _excluirCorrida(id);
                                                  } else if (val == "detalhes") {
                                                    _abrirDetalhes(corrida);
                                                  }
                                                },
                                                itemBuilder: (_) => [
                                                  PopupMenuItem(
                                                    value: "detalhes",
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          totalPontos > 0 ? Icons.map_rounded : Icons.info_outline_rounded,
                                                          size: 18,
                                                          color: const Color(0xFF0066FF),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Text(totalPontos > 0 ? "Ver Trajeto" : "Ver Detalhes"),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: "excluir",
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                                        SizedBox(width: 10),
                                                        Text("Excluir", style: TextStyle(color: Color(0xFFEF4444))),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // DESTAQUE DA DISTÂNCIA
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            distKm.toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0066FF),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            "km",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0066FF),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),
                                      Divider(
                                        height: 1,
                                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                      ),
                                      const SizedBox(height: 12),

                                      // MÉTRICAS EM LINHA (TEMPO, PACE, VELOCIDADE, KCAL) - TOTALMENTE RESPONSIVO
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _metricaCard(
                                              label: "Duração",
                                              valor: _formatarTempo(tempoSeg),
                                              icone: Icons.timer_outlined,
                                              colors: colors,
                                            ),
                                          ),
                                          Expanded(
                                            child: _metricaCard(
                                              label: "Pace Médio",
                                              valor: _formatarPace(paceSeg),
                                              icone: Icons.speed_rounded,
                                              colors: colors,
                                            ),
                                          ),
                                          Expanded(
                                            child: _metricaCard(
                                              label: "Velocidade",
                                              valor: velMedia > 0 ? "${velMedia.toStringAsFixed(1)} km/h" : "-",
                                              icone: Icons.bolt_rounded,
                                              colors: colors,
                                            ),
                                          ),
                                          Expanded(
                                            child: _metricaCard(
                                              label: "Calorias",
                                              valor: "$calorias kcal",
                                              icone: Icons.local_fire_department_rounded,
                                              colors: colors,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // BOTÃO VER TRAJETO NO MAPA
                                      SizedBox(
                                        width: double.infinity,
                                        height: 42,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _abrirDetalhes(corrida),
                                          icon: Icon(
                                            totalPontos > 0 ? Icons.map_rounded : Icons.info_outline_rounded,
                                            size: 18,
                                          ),
                                          label: Text(
                                            totalPontos > 0 ? "Ver Trajeto no Mapa" : "Ver Detalhes da Corrida",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF0066FF),
                                            side: const BorderSide(color: Color(0xFF0066FF), width: 1.4),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }

  Widget _resumoItem({
    required String label,
    required String valor,
    required IconData icone,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valor,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _filtroChip(String label, String valor, int quantidade) {
    final selecionado = _filtroStatus == valor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _filtroStatus = valor),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFF0066FF)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF0066FF)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selecionado ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: selecionado ? Colors.white.withValues(alpha: 0.25) : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$quantidade",
                style: TextStyle(
                  color: selecionado ? Colors.white : const Color(0xFF0066FF),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricaCard({
    required String label,
    required String valor,
    required IconData icone,
    required ColorScheme colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 12, color: colors.onSurfaceVariant),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 10.5, color: colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valor,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colors.onSurface),
          ),
        ),
      ],
    );
  }
}
