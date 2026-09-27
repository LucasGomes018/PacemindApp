import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 🔔 SERVIÇO CENTRAL DE NOTIFICAÇÕES LOCAIS E AGENDADAS DO PACEMIND
class NotificacaoService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  /// Cache em memória para evitar push duplicados com o mesmo título e corpo em curto intervalo
  static final Map<String, DateTime> _ultimasNotificacoesExibidas = {};

  /// IDs de canais v2 com Importance.max para garantir banners push flutuantes
  static const String canalTreinos = 'corrida_channel_v2';
  static const String canalMetas = 'metas_channel_v2';
  static const String canalAlertas = 'alertas_channel_v2';
  static const String canalLembretes = 'lembretes_channel_v2';

  /// Inicializa o plugin, configura os fusos horários e cria canais com alta prioridade no Android
  static Future<void> inicializar() async {
    if (_inicializado) return;

    try {
      tz.initializeTimeZones();
      // Define fuso de Brasília como padrão se disponível
      try {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      } catch (_) {}
    } catch (e) {
      debugPrint("Erro ao inicializar timezones: $e");
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("[NotificacaoService] Notificação clicada: ${response.payload}");
      },
    );

    // Configura e registra canais com Importance.max no Android
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidImpl = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImpl != null) {
          // Cria canais explicitamente com prioridade máxima para exibir banners push
          const canais = [
            AndroidNotificationChannel(
              canalTreinos,
              'Treinos e Corridas',
              description: 'Alertas e progresso de treinos em tempo real e metas de distância.',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
              showBadge: true,
            ),
            AndroidNotificationChannel(
              canalMetas,
              'Metas e Conquistas',
              description: 'Notificações de metas semanais batidas e recordes de volume.',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
              showBadge: true,
            ),
            AndroidNotificationChannel(
              canalAlertas,
              'Alertas de Saúde e Sobrecarga',
              description: 'Alertas críticos de sobrecarga (ACWR), dor muscular e fadiga.',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
              showBadge: true,
            ),
            AndroidNotificationChannel(
              canalLembretes,
              'Lembretes Diários e Agenda',
              description: 'Lembretes de treino matinal, hidratação pós-treino e eventos.',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
              showBadge: true,
            ),
          ];

          for (final c in canais) {
            await androidImpl.createNotificationChannel(c);
          }
        }
      } catch (e) {
        debugPrint("[NotificacaoService] Erro ao criar canais Android: $e");
      }
    }

    _inicializado = true;
  }

  /// 📲 Solicita permissões de notificação e de alarmes exatos no Android
  static Future<bool> solicitarPermissoes() async {
    await inicializar();
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final notifConcedida = await androidImpl.requestNotificationsPermission() ?? false;
        try {
          await androidImpl.requestExactAlarmsPermission();
        } catch (_) {}
        return notifConcedida;
      }
    } catch (e) {
      debugPrint("[NotificacaoService] Erro ao solicitar permissões: $e");
    }
    return false;
  }

  /// 🔍 Verifica se as notificações estão ativadas no sistema operacional
  static Future<bool> verificarPermissoesAtivas() async {
    await inicializar();
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final ativas = await androidImpl.areNotificationsEnabled();
        return ativas ?? true;
      }
    } catch (e) {
      debugPrint("[NotificacaoService] Erro ao verificar permissões: $e");
    }
    return true;
  }

  /// Retorna os detalhes do canal Android correspondente com Importance.max e BigTextStyle
  static AndroidNotificationDetails _obterDetalhesCanal(String canal, String titulo, String corpo) {
    String channelId;
    String channelName;
    String channelDesc;

    switch (canal) {
      case 'alertas':
        channelId = canalAlertas;
        channelName = 'Alertas de Saúde e Sobrecarga';
        channelDesc = 'Alertas críticos de sobrecarga (ACWR), dor muscular e fadiga.';
        break;
      case 'metas':
        channelId = canalMetas;
        channelName = 'Metas e Conquistas';
        channelDesc = 'Notificações de metas semanais batidas e novos recordes de volume.';
        break;
      case 'lembretes':
        channelId = canalLembretes;
        channelName = 'Lembretes Diários e Agenda';
        channelDesc = 'Lembretes de treino matinal, check-in de bem-estar e sono.';
        break;
      case 'treinos':
      default:
        channelId = canalTreinos;
        channelName = 'Treinos e Corridas';
        channelDesc = 'Notificações de início, progresso e conclusão de treinos GPS.';
        break;
    }

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        corpo,
        contentTitle: titulo,
        summaryText: 'PaceMind',
      ),
    );
  }

  /// 📢 Exibe notificação push imediata
  static Future<void> mostrarNotificacao({
    int id = 0,
    required String titulo,
    required String corpo,
    String canal = 'treinos',
    String? payload,
  }) async {
    await inicializar();

    // 🛡️ Filtro Antiduplicação: Evita disparar a mesma notificação repetida em menos de 10 segundos
    final chaveUnica = "${titulo.trim()}_${corpo.trim()}";
    final agora = DateTime.now();

    if (_ultimasNotificacoesExibidas.containsKey(chaveUnica)) {
      final ultimaVez = _ultimasNotificacoesExibidas[chaveUnica]!;
      if (agora.difference(ultimaVez).inSeconds < 10) {
        debugPrint("[NotificacaoService] 🚫 Notificação push duplicada suprimida: '$titulo'");
        return;
      }
    }
    _ultimasNotificacoesExibidas[chaveUnica] = agora;
    if (_ultimasNotificacoesExibidas.length > 60) {
      _ultimasNotificacoesExibidas.removeWhere((_, time) => agora.difference(time).inMinutes > 5);
    }

    final androidDetails = _obterDetalhesCanal(canal, titulo, corpo);
    final details = NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        titulo,
        corpo,
        details,
        payload: payload,
      );
      debugPrint("[NotificacaoService] Notificação push exibida com sucesso: id=$id, titulo='$titulo'");
    } catch (e) {
      debugPrint("[NotificacaoService] Erro ao exibir notificação: $e");
    }
  }

  /// ⏰ Agenda uma notificação para um momento específico no futuro
  static Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataHora,
    String canal = 'lembretes',
    String? payload,
  }) async {
    await inicializar();

    final agora = DateTime.now();
    if (dataHora.isBefore(agora)) return;

    final androidDetails = _obterDetalhesCanal(canal, titulo, corpo);
    final details = NotificationDetails(android: androidDetails);

    final scheduledDate = tz.TZDateTime.from(dataHora, tz.local);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        titulo,
        corpo,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint("[NotificacaoService] Notificação agendada para: $scheduledDate (exact)");
    } catch (e) {
      // Fallback para agendamento aproximado caso exact alarm seja restrito pelo SO
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          titulo,
          corpo,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        debugPrint("[NotificacaoService] Notificação agendada (fallback inexact)");
      } catch (err) {
        debugPrint("[NotificacaoService] Falha ao agendar notificação: $err");
      }
    }
  }

  /// 🔄 Agenda uma notificação diária em determinado horário (ex: todos os dias às 07:30)
  static Future<void> agendarNotificacaoDiaria({
    required int id,
    required String titulo,
    required String corpo,
    required int hora,
    required int minuto,
    String canal = 'lembretes',
    String? payload,
  }) async {
    await inicializar();

    final agora = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );

    // Se o horário de hoje já passou, agenda para o dia seguinte
    if (scheduledDate.isBefore(agora)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = _obterDetalhesCanal(canal, titulo, corpo);
    final details = NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        titulo,
        corpo,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint("[NotificacaoService] Notificação diária configurada para $hora:$minuto (id=$id)");
    } catch (e) {
      debugPrint("[NotificacaoService] Erro ao agendar notificação diária ($hora:$minuto): $e");
    }
  }

  /// Cancela uma notificação agendada por ID
  static Future<void> cancelar(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancela todas as notificações agendadas
  static Future<void> cancelarTodas() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}