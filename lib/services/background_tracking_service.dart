import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';

class BackgroundTrackingService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        foregroundServiceNotificationId: 888,
        initialNotificationTitle: "PaceMind",
        initialNotificationContent: "Monitorando corrida...",
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
  }

  static Future<void> start(int idCorrida) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool("gpsSegundoPlano") ?? true)) return;

    final service = FlutterBackgroundService();

    await service.startService();
    service.invoke("startRun", {"idCorrida": idCorrida});
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();

    service.invoke("stopRun");
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  StreamSubscription<Position>? positionStream;

  int? idCorrida;

  // Proteção: caso o serviço seja acionado sem uma corrida ativa (ex: reinício do sistema),
  // encerra a si mesmo se não receber o evento 'startRun' ou se não houver corrida ativa persistida.
  Timer(const Duration(seconds: 4), () async {
    if (idCorrida == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final corridaAtiva = prefs.getBool('corrida_ativa') ?? false;
        if (!corridaAtiva) {
          await positionStream?.cancel();
          service.stopSelf();
        }
      } catch (_) {
        service.stopSelf();
      }
    }
  });

  service.on("startRun").listen((event) {
    idCorrida = event?["idCorrida"];

    positionStream?.cancel();

    late final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        forceLocationManager: false,
        intervalDuration: const Duration(milliseconds: 1000),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 1,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      );
    }

    positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position pos) async {
          if (idCorrida == null) return;
          // Ignora leituras com precisão excessivamente ruim para não distorcer a rota
          if (pos.accuracy > 35.0) return;

          try {
            await Api.salvarPosicao(
              idCorrida: idCorrida!,
              latitude: pos.latitude,
              longitude: pos.longitude,
              precisao: pos.accuracy,
            );
          } catch (_) {}
        });
  });

  service.on("stopRun").listen((event) async {
    await positionStream?.cancel();

    service.stopSelf();
  });
}
