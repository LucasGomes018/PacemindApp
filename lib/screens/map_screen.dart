import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/notificacao_service.dart';
import '../services/background_tracking_service.dart';
import '../core/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();

  LatLng? posicaoAtual;

  List<LatLng> percurso = [];

  StreamSubscription<Position>? positionStream;

  bool corridaIniciada = false;

  double distanciaTotal = 0;

  int tempoSegundos = 0;

  Timer? timer;

  int? idCorrida;
  String? erroLocalizacao;

  int paceMedioSegundos = 0;

  double velocidadeMedia = 0;

  String? idTreinoVinculado;

  @override
  void initState() {
    super.initState();
    pegarLocalizacaoInicial();
    restaurarCorridaAtiva();
  }

  Future<void> restaurarCorridaAtiva() async {
    final prefs = await SharedPreferences.getInstance();
    final corridaAtiva = prefs.getBool("corrida_ativa") ?? false;
    final inicio = DateTime.tryParse(
      prefs.getString("corrida_iniciada_em") ?? "",
    );
    final idSalvo = prefs.getInt("id_corrida_ativa");

    if (!corridaAtiva || inicio == null || idSalvo == null || !mounted) return;

    setState(() {
      corridaIniciada = true;
      idCorrida = idSalvo;
      idTreinoVinculado = prefs.getString("id_treino_ativo");
      tempoSegundos = DateTime.now().difference(inicio).inSeconds;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => tempoSegundos++);
    });
  }

  Future<void> pegarLocalizacaoInicial() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(
            () => erroLocalizacao = "Ative a localização para usar o mapa.",
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(
            () => erroLocalizacao =
                "Permita o acesso à localização para exibir o mapa.",
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        posicaoAtual = LatLng(pos.latitude, pos.longitude);
        erroLocalizacao = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => erroLocalizacao = "Não foi possível obter sua localização.",
        );
      }
    }
  }

  Future<void> escolherTreino() async {
    final treinos = await Api.buscarTreinosPlanejados();

    if (!mounted) return;

    final resultado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * .72,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                width: 55,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF0066FF),
                  size: 34,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                "Escolha um treino",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Selecione um treino planejado para vincular à corrida.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: treinos.isEmpty
                    ? Center(
                        child: Text(
                          "Nenhum treino planejado encontrado.",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: treinos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, index) {
                          final treino = treinos[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              Navigator.pop(context, treino["id_treino"]);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0066FF,
                                      ).withValues(alpha: .12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.directions_run,
                                      color: Color(0xFF0066FF),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          treino["tipo"],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          "${treino["distancia_km"]} km",
                                          style: const TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    side: const BorderSide(color: Color(0xFF0066FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Continuar sem treino",
                    style: TextStyle(color: Color(0xFF0066FF)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    idTreinoVinculado = resultado;
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
      return servicoReativado &&
          permissaoAtualizada == LocationPermission.always;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.always) return true;

    if (!mounted) return false;
    await _pedirAcesso(
      titulo: "Permita a localização em segundo plano",
      mensagem:
          "Para continuar registrando sua corrida quando o aplicativo estiver fechado ou em segundo plano, escolha a opção \"Sempre\" nas permissões de localização.",
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
    final abrir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Agora não"),
            ),
            FilledButton.icon(
              onPressed: () async {
                await abrirConfiguracoes();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              icon: const Icon(Icons.settings_rounded),
              label: const Text("Abrir configurações"),
            ),
          ],
        );
      },
    );

    return abrir ?? false;
  }

  void iniciarCorrida() async {
    if (!await garantirLocalizacaoSegundoPlano()) return;
    if (!mounted) return;

    percurso.clear();
    distanciaTotal = 0;
    tempoSegundos = 0;
    paceMedioSegundos = 0;
    velocidadeMedia = 0;

    final vincular = await showDialog<bool>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.link,
                    color: Color(0xFF0066FF),
                    size: 36,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Vincular treino",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Deseja associar esta corrida a um treino planejado?\n\nAssim o PaceMind atualizará automaticamente o progresso do treino.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          side: const BorderSide(color: Color(0xFF0066FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "Agora não",
                          style: TextStyle(color: Color(0xFF0066FF)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text("Vincular"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (vincular == true) {
      await escolherTreino();
    }

    if (idTreinoVinculado != null) {
      try {
        await Api.iniciarTreino(idTreinoVinculado!);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível iniciar o treino.")),
        );
        return;
      }
    }

    late final Map<String, dynamic> corrida;
    try {
      corrida = await Api.iniciarCorrida();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível iniciar a corrida.")),
      );
      return;
    }

    idCorrida = corrida["id"];
    if (idCorrida == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A corrida não recebeu um identificador."),
          ),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("corrida_ativa", true);
    await prefs.setInt("id_corrida_ativa", idCorrida!);
    await prefs.setString(
      "corrida_iniciada_em",
      DateTime.now().toIso8601String(),
    );
    if (idTreinoVinculado != null) {
      await prefs.setString("id_treino_ativo", idTreinoVinculado!);
    } else {
      await prefs.remove("id_treino_ativo");
    }
    try {
      await BackgroundTrackingService.start(idCorrida!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "O rastreamento em segundo plano não foi ativado. A corrida continuará nesta tela.",
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      corridaIniciada = true;
    });

    Api.criarNotificacao(
      titulo: "Corrida iniciada",
      mensagem: "Seu treino começou. Boa corrida 🏃",
    );

    // 🔔 NOTIFICAÇÃO
    await NotificacaoService.mostrarNotificacao(
      titulo: "Corrida iniciada 🏃",
      corpo: "Tracking em tempo real ativado",
    );

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        tempoSegundos++;
      });
    });

    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((Position pos) async {
          final novaPosicao = LatLng(pos.latitude, pos.longitude);

          if (!mounted) return;
          setState(() {
            posicaoAtual = novaPosicao;
            percurso.add(novaPosicao);

            if (percurso.length > 1) {
              distanciaTotal += Geolocator.distanceBetween(
                percurso[percurso.length - 2].latitude,
                percurso[percurso.length - 2].longitude,
                percurso.last.latitude,
                percurso.last.longitude,
              );
            }
          });

          if (idCorrida != null) {
            await Api.salvarPosicao(
              idCorrida: idCorrida!,
              latitude: pos.latitude,
              longitude: pos.longitude,
              precisao: pos.accuracy,
            );
          }

          mapController.move(novaPosicao, 17);
        });
  }

  void pararCorrida() async {
    timer?.cancel();
    positionStream?.cancel();

    Api.criarNotificacao(
      titulo: "Corrida finalizada",
      mensagem:
          "Você correu ${(distanciaTotal / 1000).toStringAsFixed(2)} km em ${formatarTempo()}",
    );

    if (distanciaTotal > 0 && tempoSegundos > 0) {
      paceMedioSegundos = (tempoSegundos / (distanciaTotal / 1000)).round();

      velocidadeMedia = (distanciaTotal / 1000) / (tempoSegundos / 3600);
    }

    if (idCorrida != null) {
      await Api.finalizarCorrida(
        idCorrida: idCorrida!,
        distanciaMetros: distanciaTotal,
        tempoSegundos: tempoSegundos,
        paceMedioSegundos: paceMedioSegundos,
        velocidadeMedia: velocidadeMedia,
      );

      if (idTreinoVinculado != null) {
        await Api.finalizarTreino(
          idTreino: idTreinoVinculado!,
          tempoSegundos: tempoSegundos,
          distanciaKm: distanciaTotal / 1000,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("corrida_ativa");
    await prefs.remove("id_corrida_ativa");
    await prefs.remove("corrida_iniciada_em");
    await prefs.remove("id_treino_ativo");
    await BackgroundTrackingService.stop();

    setState(() {
      corridaIniciada = false;
    });

    idTreinoVinculado = null;

    // 🔔 NOTIFICAÇÃO
    await NotificacaoService.mostrarNotificacao(
      titulo: "Corrida finalizada 🏁",
      corpo:
          "Distância: ${(distanciaTotal / 1000).toStringAsFixed(2)} km • Tempo: ${formatarTempo()}",
    );
  }

  String formatarTempo() {
    final horas = tempoSegundos ~/ 3600;
    final minutos = (tempoSegundos % 3600) ~/ 60;
    final segundos = tempoSegundos % 60;

    return "${horas.toString().padLeft(2, '0')}:"
        "${minutos.toString().padLeft(2, '0')}:"
        "${segundos.toString().padLeft(2, '0')}";
  }

  Widget _camadaMapa() {
    final tiles = TileLayer(
      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
      userAgentPackageName: "com.pacemind.app",
    );

    return tiles;
  }

  @override
  void dispose() {
    timer?.cancel();
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (posicaoAtual == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_rounded, size: 52),
                const SizedBox(height: 12),
                Text(
                  erroLocalizacao ?? "Obtendo sua localização...",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (erroLocalizacao != null)
                  FilledButton.icon(
                    onPressed: pegarLocalizacaoInicial,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Tentar novamente"),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,

            options: MapOptions(initialCenter: posicaoAtual!, initialZoom: 17),

            children: [
              _camadaMapa(),

              PolylineLayer(
                polylines: [
                  Polyline(
                    points: percurso,
                    strokeWidth: 20,
                    color: Colors.black.withValues(alpha: 0.2),
                  ),

                  Polyline(
                    points: percurso,
                    strokeWidth: 10,
                    color: Colors.blue,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: posicaoAtual!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // PAINEL
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  Text(
                    formatarTempo(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "${(distanciaTotal / 1000).toStringAsFixed(2)} km",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 53, 67, 73),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTÃO
          Positioned(
            bottom: 130,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 60,

              child: ElevatedButton(
                onPressed: corridaIniciada ? pararCorrida : iniciarCorrida,

                style: ElevatedButton.styleFrom(
                  backgroundColor: corridaIniciada ? Colors.red : Colors.green,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: Text(
                  corridaIniciada ? "Parar corrida" : "Iniciar corrida",

                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
