import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../components/app_modal.dart';
import '../services/background_tracking_service.dart';
import '../services/notificacao_service.dart';
import '../services/auto_notificacao_service.dart';
import '../components/app_snackbar.dart';

class MapPage extends StatefulWidget {
  final Map<String, dynamic>? treinoInicial;
  const MapPage({super.key, this.treinoInicial});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController mapController = MapController();

  LatLng? posicaoAtual;
  List<LatLng> percurso = [];
  StreamSubscription<Position>? positionStream;

  bool corridaIniciada = false;
  bool corridaPausada = false;

  double distanciaTotal = 0.0; // metros
  double ultimaDistanciaSincronizada = 0.0;
  int tempoSegundos = 0;
  Timer? timer;

  int? idCorrida;
  String? erroLocalizacao;

  int paceMedioSegundos = 0;
  int paceAtualSegundos = 0;
  double velocidadeMedia = 0.0;
  int caloriasEstimadas = 0;

  String? idTreinoVinculado;
  String? tituloTreinoVinculado;
  double? distanciaMetaTreinoKm;
  double distanciaBaseMetros = 0.0;
  int tempoBaseSegundos = 0;
  bool metaAtingidaNotificada = false;

  // Filtragem e estabilização de GPS
  double acuraciaAtual = 0.0;
  LatLng? ultimoPontoValido;
  DateTime? ultimoPontoTempo;
  bool seguirUsuario = true;
  double currentZoom = 17.0;

  @override
  void initState() {
    super.initState();
    pegarLocalizacaoInicial();
    _inicializarTreinoVinculado();
    restaurarCorridaAtiva();
  }

  Future<void> _inicializarTreinoVinculado() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.treinoInicial != null) {
      final id = (widget.treinoInicial!["id_treino"] ?? widget.treinoInicial!["id"])?.toString();
      final tipo = (widget.treinoInicial!["tipo"] ?? "Treino").toString();
      final distMeta = double.tryParse((widget.treinoInicial!["distancia_km"] ?? "0").toString()) ?? 0.0;
      final distAtual = double.tryParse((widget.treinoInicial!["distancia_atual_km"] ?? "0").toString()) ?? 0.0;
      final tempoAnt = int.tryParse((widget.treinoInicial!["tempo_segundos"] ?? "0").toString()) ?? 0;

      if (id != null) {
        final titulo = distMeta > 0 ? "$tipo (${distMeta.toStringAsFixed(1)} km)" : tipo;
        if (mounted) {
          setState(() {
            idTreinoVinculado = id;
            tituloTreinoVinculado = titulo;
            distanciaMetaTreinoKm = distMeta > 0 ? distMeta : null;
            distanciaBaseMetros = distAtual * 1000.0;
            tempoBaseSegundos = tempoAnt;
            if (!corridaIniciada) {
              distanciaTotal = distanciaBaseMetros;
              tempoSegundos = tempoBaseSegundos;
              caloriasEstimadas = ((distanciaTotal / 1000.0) * 62).round();
            }
          });
        }
        await prefs.setString("id_treino_ativo", id);
        await prefs.setString("titulo_treino_ativo", titulo);
        await prefs.setDouble("distancia_meta_treino_km", distMeta);
        await prefs.setDouble("distancia_atual_treino_km", distAtual);
        await prefs.setInt("tempo_treino_segundos", tempoAnt);
        return;
      }
    }

    final idSalvo = prefs.getString("id_treino_ativo");
    final tituloSalvo = prefs.getString("titulo_treino_ativo");
    final distMetaSalva = prefs.getDouble("distancia_meta_treino_km");
    final distAtualSalva = prefs.getDouble("distancia_atual_treino_km") ?? 0.0;
    final tempoSalvo = prefs.getInt("tempo_treino_segundos") ?? 0;

    if (idSalvo != null && mounted) {
      setState(() {
        idTreinoVinculado = idSalvo;
        tituloTreinoVinculado = tituloSalvo;
        distanciaMetaTreinoKm = (distMetaSalva != null && distMetaSalva > 0) ? distMetaSalva : null;
        distanciaBaseMetros = distAtualSalva * 1000.0;
        tempoBaseSegundos = tempoSalvo;
        if (!corridaIniciada) {
          distanciaTotal = distanciaBaseMetros;
          tempoSegundos = tempoBaseSegundos;
          caloriasEstimadas = ((distanciaTotal / 1000.0) * 62).round();
        }
      });
    }
  }

  Future<void> desvincularTreino() async {
    setState(() {
      idTreinoVinculado = null;
      tituloTreinoVinculado = null;
      distanciaMetaTreinoKm = null;
      distanciaBaseMetros = 0.0;
      tempoBaseSegundos = 0;
      if (!corridaIniciada) {
        distanciaTotal = 0.0;
        tempoSegundos = 0;
        caloriasEstimadas = 0;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("id_treino_ativo");
    await prefs.remove("titulo_treino_ativo");
    await prefs.remove("distancia_meta_treino_km");
    await prefs.remove("distancia_atual_treino_km");
    await prefs.remove("tempo_treino_segundos");
    if (mounted) {
      AppSnackBar.info(
        context,
        "Treino desvinculado. Você pode correr livremente.",
        titulo: "Treino Livre",
      );
    }
  }

  Future<void> restaurarCorridaAtiva() async {
    final prefs = await SharedPreferences.getInstance();
    final corridaAtiva = prefs.getBool("corrida_ativa") ?? false;
    final inicio = DateTime.tryParse(prefs.getString("corrida_iniciada_em") ?? "");
    final idSalvo = prefs.getInt("id_corrida_ativa");

    final idSalvoTreino = prefs.getString("id_treino_ativo");
    final titSalvoTreino = prefs.getString("titulo_treino_ativo");
    final distMetaSalva = prefs.getDouble("distancia_meta_treino_km");
    final distAtualSalva = prefs.getDouble("distancia_atual_treino_km") ?? 0.0;
    final tempoSalvo = prefs.getInt("tempo_treino_segundos") ?? 0;

    if (idSalvoTreino != null && idTreinoVinculado == null && mounted) {
      setState(() {
        idTreinoVinculado = idSalvoTreino;
        tituloTreinoVinculado = titSalvoTreino;
        distanciaMetaTreinoKm = (distMetaSalva != null && distMetaSalva > 0) ? distMetaSalva : null;
        distanciaBaseMetros = distAtualSalva * 1000.0;
        tempoBaseSegundos = tempoSalvo;
      });
    }

    if (!corridaAtiva || inicio == null || idSalvo == null || !mounted) return;

    setState(() {
      corridaIniciada = true;
      idCorrida = idSalvo;
      idTreinoVinculado = prefs.getString("id_treino_ativo");
      tituloTreinoVinculado = prefs.getString("titulo_treino_ativo");
      tempoSegundos = tempoBaseSegundos + DateTime.now().difference(inicio).inSeconds;
    });

    _iniciarTimer();
    _iniciarStreamGps();
  }

  Future<void> pegarLocalizacaoInicial() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => erroLocalizacao = "Ative a localização para usar o mapa.");
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => erroLocalizacao = "Permita o acesso à localização para exibir o mapa.");
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (!mounted) return;

      setState(() {
        posicaoAtual = LatLng(pos.latitude, pos.longitude);
        acuraciaAtual = pos.accuracy;
        erroLocalizacao = null;
      });

      _iniciarStreamGps();
    } catch (_) {
      if (mounted) {
        setState(() => erroLocalizacao = "Não foi possível obter sua localização.");
      }
    }
  }

  void _iniciarStreamGps() {
    positionStream?.cancel();

    late final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Notifica a cada leitura do sensor sem corte por distância
        forceLocationManager: false,
        intervalDuration: const Duration(milliseconds: 500), // Alta frequência: streaming a cada 500ms
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_processarNovaPosicao);
  }

  /// Filtro inteligente de sinal GPS em tempo real:
  /// 1. Rejeita leituras com precisão excessivamente degradada (> 35 metros).
  /// 2. Filtro anti-teletransporte / salto espúrio (> 15 m/s ou ~54 km/h e > 15m).
  /// 3. Filtro de ruído em repouso: evita nós de coordenadas quando parado no semáforo,
  ///    mas registra continuamente cada passo real em movimento (>= 0.7m ou velocidade de deslocamento).
  bool _posicaoValida(Position pos) {
    if (pos.accuracy > 35.0) {
      return false;
    }

    if (ultimoPontoValido == null || ultimoPontoTempo == null) {
      return true;
    }

    final agora = DateTime.now();
    final novoPonto = LatLng(pos.latitude, pos.longitude);

    final distMetros = Geolocator.distanceBetween(
      ultimoPontoValido!.latitude,
      ultimoPontoValido!.longitude,
      novoPonto.latitude,
      novoPonto.longitude,
    );

    final dtSegundos = agora.difference(ultimoPontoTempo!).inMilliseconds / 1000.0;

    // Filtro de velocidade impossível para corrida a pé (> 15 m/s ou ~54 km/h com salto > 15m)
    if (dtSegundos > 0.1 && (distMetros / dtSegundos) > 15.0 && distMetros > 15.0) {
      return false;
    }

    // Identifica se a pessoa está em movimento real
    final bool velocidadeValida = !pos.speed.isNaN && !pos.speed.isNegative;
    final bool emMovimento = (velocidadeValida && pos.speed >= 0.35) || distMetros >= 0.8;

    // Se estiver praticamente parado em repouso estático, descarta oscilações milimétricas (< 0.7m)
    if (!emMovimento && distMetros < 0.7) {
      return false;
    }

    return true;
  }

  void _processarNovaPosicao(Position pos) {
    if (pos.accuracy > 40.0) return;

    final agora = DateTime.now();
    final novoPonto = LatLng(pos.latitude, pos.longitude);

    if (!mounted) return;

    setState(() {
      posicaoAtual = novoPonto;
      acuraciaAtual = pos.accuracy;
    });

    if (seguirUsuario) {
      try {
        mapController.move(novoPonto, currentZoom);
      } catch (_) {}
    }

    // Se a corrida não começou ou está pausada, não adiciona ao percurso nem à distância
    if (!corridaIniciada || corridaPausada) {
      return;
    }

    if (!_posicaoValida(pos)) {
      return;
    }

    double deltaDist = 0.0;
    if (ultimoPontoValido != null && ultimoPontoTempo != null) {
      deltaDist = Geolocator.distanceBetween(
        ultimoPontoValido!.latitude,
        ultimoPontoValido!.longitude,
        novoPonto.latitude,
        novoPonto.longitude,
      );

      // Pace instantâneo: aproveita o Doppler de velocidade direto do GPS para máxima estabilidade
      if (!pos.speed.isNaN && !pos.speed.isNegative && pos.speed > 0.4) {
        paceAtualSegundos = (1000.0 / pos.speed).round();
      } else {
        final dt = agora.difference(ultimoPontoTempo!).inMilliseconds / 1000.0;
        if (dt > 0 && deltaDist > 0) {
          paceAtualSegundos = (dt / (deltaDist / 1000.0)).round();
        } else {
          paceAtualSegundos = 0;
        }
      }
    }

    setState(() {
      percurso.add(novoPonto);
      distanciaTotal += deltaDist;
      ultimoPontoValido = novoPonto;
      ultimoPontoTempo = agora;

      // Estimativa: ~62 kcal por km para um atleta médio
      caloriasEstimadas = ((distanciaTotal / 1000.0) * 62).round();

      if (distanciaTotal > 0 && tempoSegundos > 0) {
        paceMedioSegundos = (tempoSegundos / (distanciaTotal / 1000.0)).round();
        velocidadeMedia = (distanciaTotal / 1000.0) / (tempoSegundos / 3600.0);
      }
    });

    // Salva posição no backend de forma assíncrona para não travar a fluidez da UI
    if (idCorrida != null) {
      Api.salvarPosicao(
        idCorrida: idCorrida!,
        latitude: pos.latitude,
        longitude: pos.longitude,
        precisao: pos.accuracy,
      ).catchError((_) {});
    }

    // Notifica uma vez quando atinge 100% da meta planejada enquanto corre
    if (distanciaMetaTreinoKm != null && distanciaMetaTreinoKm! > 0) {
      final distKm = distanciaTotal / 1000.0;
      if (distKm >= (distanciaMetaTreinoKm! * 0.999) && !metaAtingidaNotificada) {
        metaAtingidaNotificada = true;
        const tituloMeta = "Meta Atingida! 🎉";
        final corpoMeta = "Você completou os ${distanciaMetaTreinoKm!.toStringAsFixed(1)} km do treino planejado. Parabéns!";
        AutoNotificacaoService.registrarNotificacaoLocalEnviada(tituloMeta, corpoMeta);
        NotificacaoService.mostrarNotificacao(
          id: 205,
          titulo: tituloMeta,
          corpo: corpoMeta,
          canal: 'metas',
        );
      }
    }

    // 🔄 Sincroniza progresso automaticamente com o treino vinculado a cada ~200m
    if (corridaIniciada && !corridaPausada && idTreinoVinculado != null) {
      if ((distanciaTotal - ultimaDistanciaSincronizada) >= 200) {
        ultimaDistanciaSincronizada = distanciaTotal;
        Api.atualizarTreinoParcial(
          idTreino: idTreinoVinculado!,
          distanciaAtualKm: distanciaTotal / 1000.0,
          tempoSegundos: tempoSegundos,
          status: "em_andamento",
          idCorrida: idCorrida,
        );
      }
    }
  }

  void _iniciarTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (corridaIniciada && !corridaPausada) {
        setState(() {
          tempoSegundos++;
        });
      }
    });
  }

  Future<void> escolherTreino() async {
    final treinos = await Api.buscarTreinosPlanejados();
    if (!mounted) return;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final resultado = await AppModal.showBottomSheet<Map<String, dynamic>>(
      context: context,
      title: "Vincular a um Treino",
      subtitle: "Selecione um treino da planilha para atualizar seu progresso",
      icon: Icons.fitness_center_rounded,
      builder: (sheetCtx, scrollController) {
        if (treinos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "Nenhum treino planejado ou em andamento encontrado.",
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          );
        }
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: treinos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final treino = treinos[index];
            final id = (treino["id_treino"] ?? treino["id"])?.toString() ?? "";
            final tipo = (treino["tipo"] ?? "Treino").toString();
            final distMeta = double.tryParse((treino["distancia_km"] ?? "0").toString()) ?? 0.0;
            final distAtual = double.tryParse((treino["distancia_atual_km"] ?? "0").toString()) ?? 0.0;
            final tempoAnt = int.tryParse((treino["tempo_segundos"] ?? "0").toString()) ?? 0;
            final status = (treino["status"] ?? "planejado").toString();

            final progresso = distMeta > 0 ? (distAtual / distMeta).clamp(0.0, 1.0) : 0.0;
            final pct = (progresso * 100).toInt();

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.pop(sheetCtx, {
                  "id": id,
                  "titulo": "$tipo (${distMeta.toStringAsFixed(1)} km)",
                  "distancia_meta_km": distMeta,
                  "distancia_atual_km": distAtual,
                  "tempo_segundos": tempoAnt,
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: status == "em_andamento"
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF))
                            .withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        status == "em_andamento" ? Icons.play_arrow_rounded : Icons.directions_run_rounded,
                        color: status == "em_andamento" ? const Color(0xFFF59E0B) : const Color(0xFF0066FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tipo,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                              if (status == "em_andamento") ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "Em Andamento",
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            distAtual > 0
                                ? "${distAtual.toStringAsFixed(2)} / ${distMeta.toStringAsFixed(1)} km ($pct%)"
                                : "${distMeta.toStringAsFixed(1)} km planejados",
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: distAtual > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      floatingAction: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            side: const BorderSide(color: Color(0xFF0066FF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            "Continuar sem vincular",
            style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );

    if (resultado != null) {
      final meta = resultado["distancia_meta_km"] as double?;
      final distAtual = (resultado["distancia_atual_km"] as double?) ?? 0.0;
      final tempoAnt = (resultado["tempo_segundos"] as int?) ?? 0;

      setState(() {
        idTreinoVinculado = resultado["id"];
        tituloTreinoVinculado = resultado["titulo"];
        distanciaMetaTreinoKm = (meta != null && meta > 0) ? meta : null;
        distanciaBaseMetros = distAtual * 1000.0;
        tempoBaseSegundos = tempoAnt;
        if (!corridaIniciada) {
          distanciaTotal = distanciaBaseMetros;
          tempoSegundos = tempoBaseSegundos;
          caloriasEstimadas = ((distanciaTotal / 1000.0) * 62).round();
        }
      });
      final prefs = await SharedPreferences.getInstance();
      if (idTreinoVinculado != null) {
        await prefs.setString("id_treino_ativo", idTreinoVinculado!);
        await prefs.setString("titulo_treino_ativo", tituloTreinoVinculado!);
        if (meta != null) await prefs.setDouble("distancia_meta_treino_km", meta);
        await prefs.setDouble("distancia_atual_treino_km", distAtual);
        await prefs.setInt("tempo_treino_segundos", tempoAnt);

        if (mounted) {
          final msg = distAtual > 0
              ? "Treino \"$tituloTreinoVinculado\" retomado! (${distAtual.toStringAsFixed(2)} km já feitos)"
              : "Treino \"$tituloTreinoVinculado\" vinculado à corrida!";
          AppSnackBar.treino(
            context,
            msg,
            titulo: distAtual > 0 ? "Retomando Treino 🏃" : "Treino Vinculado 🏃",
          );
        }
      }
    }
  }

  Future<bool> garantirLocalizacaoSegundoPlano() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      if (!mounted) return false;
      await _pedirAcesso(
        titulo: "Ative a localização",
        mensagem:
            "A localização do aparelho está desligada. Ative-a para iniciar e continuar o rastreamento da corrida.",
        abrirConfiguracoes: Geolocator.openLocationSettings,
      );
      final servicoReativado = await Geolocator.isLocationServiceEnabled();
      final permissaoAtualizada = await Geolocator.checkPermission();
      return servicoReativado && permissaoAtualizada == LocationPermission.always;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.always) return true;

    if (!mounted) return false;
    await _pedirAcesso(
      titulo: "Permita localização em segundo plano",
      mensagem:
          "Para registrar sua corrida com a tela bloqueada ou enquanto usa outros apps, escolha \"Permitir o tempo todo\" nas permissões.",
      abrirConfiguracoes: Geolocator.openAppSettings,
    );

    final permissaoAtualizada = await Geolocator.checkPermission();
    return permissaoAtualizada == LocationPermission.always;
  }

  Future<bool> _pedirAcesso({
    required String titulo,
    required String mensagem,
    required Future<bool> Function() abrirConfiguracoes,
  }) async {
    final abrir = await AppModal.showConfirmDialog(
      context: context,
      title: titulo,
      message: mensagem,
      confirmText: "Abrir configurações",
      cancelText: "Agora não",
      icon: Icons.location_on_rounded,
      iconColor: const Color(0xFF0066FF),
      confirmButtonColor: const Color(0xFF0066FF),
    );

    if (abrir == true) {
      await abrirConfiguracoes();
      return true;
    }
    return false;
  }

  void iniciarCorrida() async {
    if (!await garantirLocalizacaoSegundoPlano()) return;
    if (!mounted) return;

    if (posicaoAtual == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 2),
        );
        posicaoAtual = LatLng(pos.latitude, pos.longitude);
        acuraciaAtual = pos.accuracy;
      } catch (_) {}
    }

    percurso.clear();
    // Continua de onde parou caso seja a retomada de um treino vinculado
    distanciaTotal = distanciaBaseMetros;
    tempoSegundos = tempoBaseSegundos;
    paceMedioSegundos = 0;
    paceAtualSegundos = 0;
    velocidadeMedia = 0;
    caloriasEstimadas = ((distanciaTotal / 1000.0) * 62).round();
    ultimoPontoValido = posicaoAtual;
    ultimoPontoTempo = DateTime.now();
    metaAtingidaNotificada = false;

    if (posicaoAtual != null) {
      percurso.add(posicaoAtual!);
    }

    late final Map<String, dynamic> corrida;
    try {
      corrida = await Api.iniciarCorrida();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.erro(
        context,
        "Não foi possível iniciar a corrida. Verifique sua conexão.",
        titulo: "Falha ao Iniciar",
      );
      return;
    }

    idCorrida = corrida["id"];
    if (idCorrida == null) {
      if (mounted) {
        AppSnackBar.erro(
          context,
          "A corrida não recebeu um identificador válido.",
          titulo: "Erro na Corrida",
        );
      }
      return;
    }

    if (idTreinoVinculado != null) {
      try {
        await Api.iniciarTreino(idTreinoVinculado!);
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("corrida_ativa", true);
    await prefs.setInt("id_corrida_ativa", idCorrida!);
    await prefs.setString("corrida_iniciada_em", DateTime.now().toIso8601String());
    if (idTreinoVinculado != null) {
      await prefs.setString("id_treino_ativo", idTreinoVinculado!);
      if (tituloTreinoVinculado != null) {
        await prefs.setString("titulo_treino_ativo", tituloTreinoVinculado!);
      }
    } else {
      await prefs.remove("id_treino_ativo");
      await prefs.remove("titulo_treino_ativo");
    }

    try {
      await BackgroundTrackingService.start(idCorrida!);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      corridaIniciada = true;
      corridaPausada = false;
      seguirUsuario = true;
    });

    _iniciarTimer();
    _iniciarStreamGps();

    const tituloPush = "Corrida em andamento 🏃";
    const corpoPush = "PaceMind monitorando seu trajeto em tempo real.";
    const tituloApi = "Corrida iniciada 🏃";
    const msgApi = "Seu treino começou com GPS ativo. Boa corrida!";

    await AutoNotificacaoService.registrarNotificacaoLocalEnviada(tituloPush, corpoPush);
    await AutoNotificacaoService.registrarNotificacaoLocalEnviada(tituloApi, msgApi);

    Api.criarNotificacao(
      titulo: tituloApi,
      mensagem: msgApi,
      tipo: "treino",
    ).catchError((_) => {});

    await NotificacaoService.mostrarNotificacao(
      id: 200,
      titulo: tituloPush,
      corpo: corpoPush,
      canal: 'treinos',
    );
  }

  void alternarPausa() {
    if (!corridaIniciada) return;
    setState(() {
      corridaPausada = !corridaPausada;
      if (!corridaPausada) {
        // Ao retomar, atualiza a referência temporal e espacial para evitar saltos falsos
        ultimoPontoTempo = DateTime.now();
        if (posicaoAtual != null) {
          ultimoPontoValido = posicaoAtual;
        }
      }
    });

    if (idTreinoVinculado != null) {
      Api.atualizarTreinoParcial(
        idTreino: idTreinoVinculado!,
        distanciaAtualKm: distanciaTotal / 1000.0,
        tempoSegundos: tempoSegundos,
        status: "em_andamento",
        idCorrida: idCorrida,
      );
    }
  }

  Future<void> confirmarFinalizarCorrida() async {
    final distKm = (distanciaTotal / 1000).toStringAsFixed(2);
    final tempo = formatarTempo();

    final bool atingiuMeta = distanciaMetaTreinoKm != null &&
        distanciaMetaTreinoKm! > 0 &&
        (distanciaTotal / 1000.0) >= (distanciaMetaTreinoKm! * 0.99);

    final String tituloDialog = (idTreinoVinculado != null && !atingiuMeta)
        ? "Pausar e Salvar Treino?"
        : "Encerrar Corrida?";

    final String mensagem = (idTreinoVinculado != null && !atingiuMeta && distanciaMetaTreinoKm != null)
        ? "Você percorreu $distKm de ${distanciaMetaTreinoKm!.toStringAsFixed(1)} km em $tempo.\n\nComo a meta ainda não foi atingida (100%), seu progresso será salvo e o treino ficará pausado para você continuar quando quiser."
        : "Você percorreu $distKm km em $tempo.\nDeseja salvar e concluir este treino?";

    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: tituloDialog,
      message: mensagem,
      confirmText: (idTreinoVinculado != null && !atingiuMeta) ? "Sim, Salvar Progresso" : "Sim, Concluir",
      cancelText: "Continuar Correndo",
      icon: (idTreinoVinculado != null && !atingiuMeta) ? Icons.pause_circle_rounded : Icons.stop_rounded,
      iconColor: (idTreinoVinculado != null && !atingiuMeta) ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
      confirmButtonColor: (idTreinoVinculado != null && !atingiuMeta) ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
      isDestructive: atingiuMeta || idTreinoVinculado == null,
    );

    if (confirmar == true) {
      pararCorrida();
    }
  }

  void pararCorrida() async {
    timer?.cancel();
    positionStream?.cancel();

    if (distanciaTotal > 0 && tempoSegundos > 0) {
      paceMedioSegundos = (tempoSegundos / (distanciaTotal / 1000)).round();
      velocidadeMedia = (distanciaTotal / 1000) / (tempoSegundos / 3600);
    }

    final distCorridaKm = distanciaTotal / 1000.0;
    final bool atingiuMeta = distanciaMetaTreinoKm != null &&
        distanciaMetaTreinoKm! > 0 &&
        distCorridaKm >= (distanciaMetaTreinoKm! * 0.99);

    if (idCorrida != null) {
      try {
        await Api.finalizarCorrida(
          idCorrida: idCorrida!,
          distanciaMetros: distanciaTotal,
          tempoSegundos: tempoSegundos,
          paceMedioSegundos: paceMedioSegundos,
          velocidadeMedia: velocidadeMedia,
        );
      } catch (_) {}

      if (idTreinoVinculado != null) {
        if (atingiuMeta) {
          // 🎉 Treino 100% CONCLUÍDO!
          try {
            await Api.finalizarTreino(
              idTreino: idTreinoVinculado!,
              tempoSegundos: tempoSegundos,
              distanciaKm: distanciaMetaTreinoKm!,
              distanciaAtualKm: distCorridaKm,
              idCorrida: idCorrida,
              status: "concluido",
            );
          } catch (_) {}

          await AutoNotificacaoService.notificarTreinoConcluido(
            distanciaKm: distCorridaKm,
            tempoSegundos: tempoSegundos,
            paceMedioSegundos: paceMedioSegundos,
          );
        } else {
          // ⏸️ Treino INCOMPLETO (PAUSADO para continuar em outro dia)
          // NÃO marca como concluído! Salva como 'em_andamento'
          try {
            await Api.atualizarTreinoParcial(
              idTreino: idTreinoVinculado!,
              distanciaAtualKm: distCorridaKm,
              tempoSegundos: tempoSegundos,
              status: "em_andamento",
              idCorrida: idCorrida,
            );
          } catch (_) {}

          distanciaBaseMetros = distanciaTotal;
          tempoBaseSegundos = tempoSegundos;
        }
      } else {
        try {
          // Corrida avulsa sem treino vinculado
          final hojeIso = DateTime.now().toIso8601String().substring(0, 10);
          await Api.criarTreinoCompleto(
            tipo: "Corrida GPS",
            distanciaKm: distanciaTotal / 1000,
            tempoSegundos: tempoSegundos,
            data: hojeIso,
            sensacao: 6,
            status: "concluido",
            observacoes: "Corrida gravada via GPS no PaceMind.",
            idCorrida: idCorrida,
          );
        } catch (_) {}

        await AutoNotificacaoService.notificarTreinoConcluido(
          distanciaKm: distCorridaKm,
          tempoSegundos: tempoSegundos,
          paceMedioSegundos: paceMedioSegundos,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("corrida_ativa");
    await prefs.remove("id_corrida_ativa");
    await prefs.remove("corrida_iniciada_em");

    if (atingiuMeta || idTreinoVinculado == null) {
      await prefs.remove("id_treino_ativo");
      await prefs.remove("titulo_treino_ativo");
      await prefs.remove("distancia_meta_treino_km");
      await prefs.remove("distancia_atual_treino_km");
      await prefs.remove("tempo_treino_segundos");
    } else {
      // Salva progresso parcial para manter o treino vinculado para a próxima sessão
      await prefs.setDouble("distancia_atual_treino_km", distCorridaKm);
      await prefs.setInt("tempo_treino_segundos", tempoSegundos);
    }
    await BackgroundTrackingService.stop();

    if (!mounted) return;

    final idTreinoSalvoAinda = idTreinoVinculado;
    setState(() {
      corridaIniciada = false;
      corridaPausada = false;
      if (atingiuMeta) {
        idTreinoVinculado = null;
        tituloTreinoVinculado = null;
        distanciaMetaTreinoKm = null;
        distanciaBaseMetros = 0.0;
        tempoBaseSegundos = 0;
      }
    });

    if (idTreinoSalvoAinda != null && !atingiuMeta) {
      AppSnackBar.aviso(
        context,
        "Progresso salvo: ${distCorridaKm.toStringAsFixed(2)} de ${distanciaMetaTreinoKm?.toStringAsFixed(1) ?? ''} km. O treino continuará de onde parou quando você quiser!",
        titulo: "Treino Pausado ⏸️",
      );
    } else if (atingiuMeta) {
      AppSnackBar.sucesso(
        context,
        "Parabéns! 100% da meta de ${distCorridaKm.toStringAsFixed(2)} km atingida com sucesso!",
        titulo: "Treino Concluído 🎉",
      );
    }

    // Reinicia o stream do GPS para visualização casual
    _iniciarStreamGps();
  }

  String formatarTempo() {
    final horas = tempoSegundos ~/ 3600;
    final minutos = (tempoSegundos % 3600) ~/ 60;
    final segundos = tempoSegundos % 60;

    if (horas > 0) {
      return "${horas.toString().padLeft(2, '0')}:"
          "${minutos.toString().padLeft(2, '0')}:"
          "${segundos.toString().padLeft(2, '0')}";
    }

    return "${minutos.toString().padLeft(2, '0')}:"
        "${segundos.toString().padLeft(2, '0')}";
  }

  String formatarPace(int segundos) {
    if (segundos <= 0 || segundos > 3600) return "--'--\"";
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  Widget _badgeSinalGps() {
    Color cor;
    String texto;
    IconData icone;

    if (acuraciaAtual <= 0) {
      cor = Colors.grey;
      texto = "GPS...";
      icone = Icons.gps_not_fixed_rounded;
    } else if (acuraciaAtual <= 10) {
      cor = const Color(0xFF10B981);
      texto = "GPS Forte";
      icone = Icons.gps_fixed_rounded;
    } else if (acuraciaAtual <= 20) {
      cor = const Color(0xFF0066FF);
      texto = "GPS Bom";
      icone = Icons.gps_fixed_rounded;
    } else {
      cor = const Color(0xFFF59E0B);
      texto = "GPS Fraco";
      icone = Icons.gps_not_fixed_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: cor),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeStatusCorrida() {
    if (!corridaIniciada) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0066FF).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run_rounded, size: 14, color: Color(0xFF0066FF)),
            SizedBox(width: 5),
            Text(
              "Pronto para Iniciar",
              style: TextStyle(
                color: Color(0xFF0066FF),
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
    }

    if (corridaPausada) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_rounded, size: 14, color: Colors.amber),
            SizedBox(width: 5),
            Text(
              "Pausado",
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill_rounded, size: 14, color: Color(0xFF10B981)),
          SizedBox(width: 5),
          Text(
            "Em Andamento",
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (posicaoAtual == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_searching_rounded,
                    size: 48,
                    color: Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  erroLocalizacao ?? "Localizando satélites GPS...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Certifique-se de estar em local aberto para máxima precisão.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                if (erroLocalizacao != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: pegarLocalizacaoInicial,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Tentar novamente"),
                  )
                else
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF0066FF)),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final cardBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.95);

    return Scaffold(
      body: Stack(
        children: [
          // MAPA INTERATIVO
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: posicaoAtual!,
              initialZoom: currentZoom,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && seguirUsuario) {
                  setState(() => seguirUsuario = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.pacemind.app",
              ),

              // ROTA PERCORRIDA (LINHA DUPLA COM EFEITO GLOW)
              PolylineLayer(
                polylines: [
                  if (percurso.length > 1) ...[
                    // Linha de fundo / brilho (Glow)
                    Polyline(
                      points: percurso,
                      strokeWidth: 9,
                      color: const Color(0xFF0066FF).withValues(alpha: 0.28),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    // Linha principal de percurso
                    Polyline(
                      points: percurso,
                      strokeWidth: 5.5,
                      color: const Color(0xFF0066FF),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ],
              ),

              // MARCADORES: INÍCIO E ATLETA
              MarkerLayer(
                markers: [
                  // Marcador de Início (Largada)
                  if (percurso.isNotEmpty)
                    Marker(
                      point: percurso.first,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                  // Marcador do Atleta (Pulsante e Moderno)
                  Marker(
                    point: posicaoAtual!,
                    width: 42,
                    height: 42,
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // HUD SUPERIOR DE MÉTRICAS (GLASSMORPHISM)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFF0066FF).withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOPO DO HUD: Status + GPS Signal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _badgeStatusCorrida(),
                          _badgeSinalGps(),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // CRONÔMETRO CENTRAL (DESTAQUE)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 24,
                            color: corridaPausada
                                ? Colors.amber
                                : (corridaIniciada ? const Color(0xFF10B981) : colors.onSurfaceVariant),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatarTempo(),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (tituloTreinoVinculado != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.flag_rounded, size: 14, color: Color(0xFF0066FF)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Treino: $tituloTreinoVinculado",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0066FF),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!corridaIniciada) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: desvincularTreino,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0066FF)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (distanciaMetaTreinoKm != null && distanciaMetaTreinoKm! > 0) ...[
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (_) {
                                    final distKm = distanciaTotal / 1000.0;
                                    final progresso = (distKm / distanciaMetaTreinoKm!).clamp(0.0, 1.0);
                                    final pct = (progresso * 100).toInt();
                                    final bool batida = pct >= 100;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${distKm.toStringAsFixed(2)} / ${distanciaMetaTreinoKm!.toStringAsFixed(1)} km",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              batida ? "100% (Meta Concluída!)" : "$pct%",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: batida ? const Color(0xFF10B981) : const Color(0xFF0066FF),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progresso,
                                            minHeight: 5,
                                            backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              batida ? const Color(0xFF10B981) : const Color(0xFF0066FF),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: 12),

                      // MÉTRICAS COMPLEMENTARES: Distância, Pace Médio, Calorias
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _metricaHud(
                            icone: Icons.straighten_rounded,
                            label: "Distância",
                            valor: "${(distanciaTotal / 1000).toStringAsFixed(2)} km",
                            cor: const Color(0xFF0066FF),
                            colors: colors,
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                          _metricaHud(
                            icone: Icons.speed_rounded,
                            label: "Pace Médio",
                            valor: formatarPace(paceMedioSegundos),
                            cor: const Color(0xFF10B981),
                            colors: colors,
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                          _metricaHud(
                            icone: Icons.local_fire_department_rounded,
                            label: "Calorias",
                            valor: "$caloriasEstimadas kcal",
                            cor: Colors.deepOrangeAccent,
                            colors: colors,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BOTÕES FLUTUANTES LATERAIS (SEGUIR ATLETA E ZOOM)
          Positioned(
            right: 18,
            bottom: MediaQuery.paddingOf(context).bottom + 215,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão Centralizar / Seguir Atleta
                FloatingActionButton.small(
                  heroTag: "center_user",
                  elevation: 4,
                  backgroundColor: seguirUsuario ? const Color(0xFF0066FF) : cardBg,
                  foregroundColor: seguirUsuario ? Colors.white : colors.onSurface,
                  onPressed: () {
                    setState(() => seguirUsuario = true);
                    if (posicaoAtual != null) {
                      mapController.move(posicaoAtual!, currentZoom);
                    }
                  },
                  tooltip: "Centralizar no atleta",
                  child: Icon(
                    seguirUsuario ? Icons.my_location_rounded : Icons.location_searching_rounded,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 10),

                // Zoom In
                FloatingActionButton.small(
                  heroTag: "zoom_in",
                  elevation: 4,
                  backgroundColor: cardBg,
                  foregroundColor: colors.onSurface,
                  onPressed: () {
                    currentZoom = (mapController.camera.zoom + 1).clamp(3.0, 19.0);
                    mapController.move(mapController.camera.center, currentZoom);
                  },
                  tooltip: "Aproximar",
                  child: const Icon(Icons.add_rounded, size: 22),
                ),
                const SizedBox(height: 10),

                // Zoom Out
                FloatingActionButton.small(
                  heroTag: "zoom_out",
                  elevation: 4,
                  backgroundColor: cardBg,
                  foregroundColor: colors.onSurface,
                  onPressed: () {
                    currentZoom = (mapController.camera.zoom - 1).clamp(3.0, 19.0);
                    mapController.move(mapController.camera.center, currentZoom);
                  },
                  tooltip: "Afastar",
                  child: const Icon(Icons.remove_rounded, size: 22),
                ),
              ],
            ),
          ),

          // DOCK INFERIOR DE AÇÕES
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 22,
            left: 16,
            right: 16,
            child: !corridaIniciada
                ? Row(
                    children: [
                      // Botão Vincular Treino
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: cardBg,
                          foregroundColor: const Color(0xFF0066FF),
                          padding: const EdgeInsets.all(16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        onPressed: escolherTreino,
                        tooltip: "Vincular a treino da planilha",
                        icon: const Icon(Icons.fitness_center_rounded, size: 24),
                      ),
                      const SizedBox(width: 12),

                      // Botão Iniciar Corrida
                      Expanded(
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: iniciarCorrida,
                            icon: const Icon(Icons.play_arrow_rounded, size: 28),
                            label: const Text(
                              "Iniciar Corrida",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Botão Pausar / Retomar
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: alternarPausa,
                            icon: Icon(
                              corridaPausada ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 24,
                            ),
                            label: Text(
                              corridaPausada ? "Retomar" : "Pausar",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: corridaPausada
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                              foregroundColor: corridaPausada
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Botão Finalizar Corrida
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: confirmarFinalizarCorrida,
                            icon: const Icon(Icons.stop_rounded, size: 24),
                            label: const Text(
                              "Finalizar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metricaHud({
    required IconData icone,
    required String label,
    required String valor,
    required Color cor,
    required ColorScheme colors,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 13, color: cor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
