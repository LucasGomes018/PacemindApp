import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/api.dart';
import '../utils/date_utils.dart';
import '../components/app_modal.dart';
import '../components/app_snackbar.dart';

class DetalhesCorridaScreen extends StatefulWidget {
  final Map<String, dynamic> corrida;
  final LatLng? posicaoAtleta;

  const DetalhesCorridaScreen({
    super.key,
    required this.corrida,
    this.posicaoAtleta,
  });

  @override
  State<DetalhesCorridaScreen> createState() => _DetalhesCorridaScreenState();
}

class _DetalhesCorridaScreenState extends State<DetalhesCorridaScreen> {
  final MapController _mapController = MapController();
  bool _carregandoTrajeto = true;
  String? _erroTrajeto;
  List<LatLng> _pontosTrajeto = [];
  LatLng? _posicaoAtleta;
  bool _painelExpandido = true;

  @override
  void initState() {
    super.initState();
    _posicaoAtleta = widget.posicaoAtleta;
    _obterLocalizacaoAtleta();
    _buscarTrajeto();
  }

  Future<void> _obterLocalizacaoAtleta() async {
    try {
      if (_posicaoAtleta == null) {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null && mounted) {
          setState(() {
            _posicaoAtleta = LatLng(pos.latitude, pos.longitude);
          });
        }
      }

      final posCur = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 3),
      );
      if (mounted) {
        setState(() {
          _posicaoAtleta = LatLng(posCur.latitude, posCur.longitude);
        });

        // Se a corrida não possui pontos de trajeto gravados, centraliza na posição real do atleta
        if (_pontosTrajeto.isEmpty && !_carregandoTrajeto) {
          _mapController.move(_posicaoAtleta!, 16.0);
        }
      }
    } catch (_) {}
  }

  Future<void> _buscarTrajeto() async {
    final idRaw = widget.corrida["id"] ?? widget.corrida["id_corrida"];
    final id = int.tryParse(idRaw?.toString() ?? "");
    if (id == null) {
      setState(() {
        _carregandoTrajeto = false;
        _erroTrajeto = "Identificador de corrida inválido.";
      });
      return;
    }

    try {
      final lista = await Api.buscarTrajeto(id);
      if (!mounted) return;

      final pontos = <LatLng>[];
      for (final item in lista) {
        final lat = double.tryParse(item["latitude"]?.toString() ?? "");
        final lng = double.tryParse(item["longitude"]?.toString() ?? "");
        if (lat != null && lng != null) {
          pontos.add(LatLng(lat, lng));
        }
      }

      setState(() {
        _pontosTrajeto = pontos;
        _carregandoTrajeto = false;
        if (pontos.isEmpty) {
          _erroTrajeto = "Esta corrida foi concluída sem coordenadas de trajeto via GPS.";
        }
      });

      // Enquadra a câmera imediatamente e agenda reforço de 350ms para garantir enquadramento total
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pontosTrajeto.isNotEmpty) {
          _enquadrarPercurso();
        } else if (_posicaoAtleta != null) {
          _mapController.move(_posicaoAtleta!, 16.0);
        }
      });

      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _pontosTrajeto.isNotEmpty) {
          _enquadrarPercurso();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoTrajeto = false;
        _erroTrajeto = "Não foi possível carregar o trajeto desta corrida.";
      });
    }
  }

  void _enquadrarPercurso() {
    if (!mounted) return;

    if (_pontosTrajeto.isEmpty) {
      if (_posicaoAtleta != null) {
        _mapController.move(_posicaoAtleta!, 16.0);
      }
      return;
    }

    try {
      if (_pontosTrajeto.length == 1) {
        _mapController.move(_pontosTrajeto.first, 15.5);
        return;
      }

      final bounds = LatLngBounds.fromPoints(_pontosTrajeto);

      // Calcula a extensão física real em metros do trajeto
      final distMetros = Geolocator.distanceBetween(
        bounds.south,
        bounds.west,
        bounds.north,
        bounds.east,
      );

      // Evita o "zoom gigante" caso o percurso seja minúsculo ou de teste parado (< 50 metros)
      if (distMetros < 50.0) {
        _mapController.move(bounds.center, 16.0);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: EdgeInsets.only(
              top: 80,
              bottom: _painelExpandido ? 250 : 120,
              left: 36,
              right: 36,
            ),
            maxZoom: 16.0,
          ),
        );
      }
    } catch (_) {
      // Se falhou (render box ainda calculando tamanho), tenta após o frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pontosTrajeto.isEmpty) return;
        try {
          final bounds = LatLngBounds.fromPoints(_pontosTrajeto);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: EdgeInsets.only(
                top: 80,
                bottom: _painelExpandido ? 250 : 120,
                left: 36,
                right: 36,
              ),
              maxZoom: 16.0,
            ),
          );
        } catch (_) {}
      });
    }
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

    if (h > 0) return "${h}h ${m}m ${s}s";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  Future<void> _confirmarExcluir() async {
    final idRaw = widget.corrida["id"] ?? widget.corrida["id_corrida"];
    final id = int.tryParse(idRaw?.toString() ?? "");
    if (id == null) return;

    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Excluir Corrida?",
      message: "Esta corrida e todos os pontos do trajeto serão removidos permanentemente.",
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
        Navigator.pop(context, true); // Retorna true para atualizar lista
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

    final distMetros = double.tryParse(widget.corrida["distancia_metros"]?.toString() ?? "0") ?? 0.0;
    final distKm = distMetros / 1000.0;
    final tempoSeg = int.tryParse(widget.corrida["tempo_segundos"]?.toString() ?? "0") ?? 0;
    final paceSeg = int.tryParse(widget.corrida["pace_medio_segundos"]?.toString() ?? "0") ?? 0;
    final velMedia = double.tryParse(widget.corrida["velocidade_media"]?.toString() ?? "0") ?? 0.0;
    final status = widget.corrida["status"]?.toString() ?? "finalizada";
    final bool isFinalizada = status.toLowerCase() == "finalizada" || status.toLowerCase() == "concluido";
    final dataInicioStr = AppDateUtils.formatarData(widget.corrida["iniciado_em"]);
    final dataFimStr = widget.corrida["finalizado_em"] != null
        ? AppDateUtils.formatarData(widget.corrida["finalizado_em"])
        : null;

    final calorias = (distKm * 62).round();

    final cardBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);

    // Centro inicial seguro: rota gravada -> posição do atleta -> fallback Brasil
    final LatLng defaultCenter = _pontosTrajeto.isNotEmpty
        ? _pontosTrajeto.first
        : (_posicaoAtleta ?? const LatLng(-15.7801, -47.9292));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // MAPA INTERATIVO COM O TRAJETO DA CORRIDA
          Positioned.fill(
            child: FlutterMap(
              key: ValueKey("map_track_${_pontosTrajeto.length}"),
              mapController: _mapController,
              options: MapOptions(
                initialCenter: defaultCenter,
                initialZoom: 15.5,
                initialCameraFit: _pontosTrajeto.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(_pontosTrajeto),
                        padding: EdgeInsets.only(
                          top: 80,
                          bottom: _painelExpandido ? 250 : 120,
                          left: 36,
                          right: 36,
                        ),
                        maxZoom: 16.0,
                      )
                    : null,
                onMapReady: () {
                  _enquadrarPercurso();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.pacemind.app",
                ),

                // LINHA DUPLA DO PERCURSO (GLOW + VIBRANT BLUE)
                if (_pontosTrajeto.length > 1) ...[
                  PolylineLayer(
                    polylines: [
                      // Efeito Glow / Halo luminoso
                      Polyline(
                        points: _pontosTrajeto,
                        strokeWidth: 9,
                        color: const Color(0xFF0066FF).withValues(alpha: 0.32),
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                      // Linha de Trajetória Principal
                      Polyline(
                        points: _pontosTrajeto,
                        strokeWidth: 5.5,
                        color: const Color(0xFF0066FF),
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),
                ],

                // MARCADORES DE LARGADA, CHEGADA OU POSIÇÃO ATUAL
                MarkerLayer(
                  markers: [
                    // Marcador de Início (Largada)
                    if (_pontosTrajeto.isNotEmpty)
                      Marker(
                        point: _pontosTrajeto.first,
                        width: 38,
                        height: 38,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),

                    // Marcador de Fim (Chegada)
                    if (_pontosTrajeto.length > 1)
                      Marker(
                        point: _pontosTrajeto.last,
                        width: 38,
                        height: 38,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_score_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                    // Marcador da Posição do Atleta (quando não há trajeto gravado)
                    if (_pontosTrajeto.isEmpty && _posicaoAtleta != null)
                      Marker(
                        point: _posicaoAtleta!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // OVERLAY DE CARREGAMENTO / ALERTA SEM TRAJETO
          if (_carregandoTrajeto)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 80,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0066FF)),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Carregando trajeto GPS...",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_pontosTrajeto.isEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 76,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D1F10) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _erroTrajeto ?? "Esta corrida não possui rota gravada via GPS. Exibindo sua localização atual.",
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // HEADER SUPERIOR FLUTUANTE (VOLTAR + TÍTULO + AÇÕES)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFF0066FF).withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: "Voltar",
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Trajeto da Corrida",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isFinalizada ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isFinalizada ? "Concluída" : "Em andamento",
                                    style: TextStyle(
                                      color: isFinalizada ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              dataInicioStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _confirmarExcluir,
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                        tooltip: "Excluir corrida",
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BOTÃO FLUTUANTE LATERAL (RE-ENQUADRAR TRAJETO)
          Positioned(
            right: 18,
            bottom: _painelExpandido ? 280 : 120,
            child: FloatingActionButton.small(
              heroTag: "fit_track",
              elevation: 4,
              backgroundColor: cardBg,
              foregroundColor: const Color(0xFF0066FF),
              onPressed: _enquadrarPercurso,
              tooltip: _pontosTrajeto.isNotEmpty ? "Enquadrar trajeto completo" : "Centralizar em mim",
              child: Icon(
                _pontosTrajeto.isNotEmpty ? Icons.fit_screen_rounded : Icons.my_location_rounded,
                size: 20,
              ),
            ),
          ),

          // PAINEL INFERIOR RESPONSIVO E COLAPSÁVEL DE ESTATÍSTICAS
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFF0066FF).withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ALÇA DE CONTROLE DO PAINEL (TOQUE PARA EXPANDIR / RECOLHER)
                      InkWell(
                        onTap: () => setState(() => _painelExpandido = !_painelExpandido),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (!_painelExpandido) ...[
                        // BARRA COMPACTA QUANDO COLAPSADO
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${distKm.toStringAsFixed(2)} km  •  ${_formatarTempo(tempoSeg)}  •  ${_formatarPace(paceSeg)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => setState(() => _painelExpandido = true),
                                icon: const Icon(Icons.expand_less_rounded, size: 18),
                                label: const Text("Detalhes", style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),

                        // GRID PRINCIPAL DE MÉTRICAS (DESTAQUE)
                        Row(
                          children: [
                            // DISTÂNCIA TOTAL
                            Expanded(
                              child: _cardMetricaDestaque(
                                icone: Icons.straighten_rounded,
                                label: "Distância",
                                valor: "${distKm.toStringAsFixed(2)} km",
                                cor: const Color(0xFF0066FF),
                                colors: colors,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // TEMPO TOTAL
                            Expanded(
                              child: _cardMetricaDestaque(
                                icone: Icons.timer_outlined,
                                label: "Duração",
                                valor: _formatarTempo(tempoSeg),
                                cor: const Color(0xFF10B981),
                                colors: colors,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // MÉTRICAS SECUNDÁRIAS (PACE, VELOCIDADE, CALORIAS, PONTOS)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _metricaItem(
                                label: "Pace Médio",
                                valor: _formatarPace(paceSeg),
                                icone: Icons.speed_rounded,
                                cor: const Color(0xFF0066FF),
                                colors: colors,
                              ),
                            ),
                            _divisorVertical(isDark),
                            Expanded(
                              child: _metricaItem(
                                label: "Velocidade",
                                valor: velMedia > 0 ? "${velMedia.toStringAsFixed(1)} km/h" : "-",
                                icone: Icons.bolt_rounded,
                                cor: const Color(0xFFF59E0B),
                                colors: colors,
                              ),
                            ),
                            _divisorVertical(isDark),
                            Expanded(
                              child: _metricaItem(
                                label: "Calorias",
                                valor: "$calorias kcal",
                                icone: Icons.local_fire_department_rounded,
                                cor: Colors.deepOrangeAccent,
                                colors: colors,
                              ),
                            ),
                            _divisorVertical(isDark),
                            Expanded(
                              child: _metricaItem(
                                label: "Pontos GPS",
                                valor: "${_pontosTrajeto.length}",
                                icone: Icons.place_rounded,
                                cor: const Color(0xFF10B981),
                                colors: colors,
                              ),
                            ),
                          ],
                        ),

                        if (dataFimStr != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule_rounded, size: 13, color: colors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                "Concluída em $dataFimStr",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),

                        // BOTÃO DE PROJETAR NO MAPA PRINCIPAL
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _pontosTrajeto.isNotEmpty
                                ? () {
                                    Navigator.pop(context, {
                                      "acao": "exibir_no_mapa",
                                      "corrida": widget.corrida,
                                      "pontos": _pontosTrajeto,
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.explore_rounded, size: 18),
                            label: Text(
                              _pontosTrajeto.isNotEmpty
                                  ? "Projetar no Mapa Principal"
                                  : "Sem trajeto para projetar",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isDark ? Colors.white10 : Colors.black12,
                              disabledForegroundColor: colors.onSurfaceVariant,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardMetricaDestaque({
    required IconData icone,
    required String label,
    required String valor,
    required Color cor,
    required ColorScheme colors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 18, color: cor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valor,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricaItem({
    required String label,
    required String valor,
    required IconData icone,
    required Color cor,
    required ColorScheme colors,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 12, color: cor),
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

  Widget _divisorVertical(bool isDark) {
    return Container(
      width: 1,
      height: 22,
      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
    );
  }


}
