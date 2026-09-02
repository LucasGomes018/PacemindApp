import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api.dart';

class BackgroundTrackingService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        foregroundServiceNotificationId: 888,
        initialNotificationTitle: "PaceMind",
        initialNotificationContent: "Monitorando corrida...",
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  static Future<void> start(int idCorrida) async {
    final service = FlutterBackgroundService();

    service.invoke("startRun", {"idCorrida": idCorrida});

    service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();

    service.invoke("stopRun");
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  StreamSubscription<Position>? positionStream;

  int? idCorrida;

  service.on("startRun").listen((event) {
    idCorrida = event?["idCorrida"];

    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((Position pos) async {
          if (idCorrida == null) return;

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
