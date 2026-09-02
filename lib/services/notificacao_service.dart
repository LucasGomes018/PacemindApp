import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacaoService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  static Future<void> mostrarNotificacao({
    required String titulo,
    required String corpo,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'corrida_channel',
          'Corridas',
          channelDescription: 'Notificações de corrida',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      titulo,
      corpo,
      details,
    );
  }
}