import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Her gün belirlenen saatte "çalışma zamanı" bildirimi.
class Reminder {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _id = 1;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    await _plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    _ready = true;
  }

  /// İzin verilmezse false döner.
  Future<bool> schedule(int hour, int minute) async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? true;
    if (!granted) return false;
    await _plugin.cancel(_id);
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      _id,
      'MBSTS çalışma zamanı',
      'Tekrar kartların ve kısa bir test seni bekliyor. Bugün 15 dakika ayır.',
      at,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gunluk_calisma',
          'Günlük çalışma hatırlatması',
          channelDescription: 'Her gün seçtiğin saatte MBSTS çalışmasını hatırlatır.',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(_id);
  }
}

final reminder = Reminder();

final examDate = DateTime(2027, 4, 4);

int daysToExam([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(examDate.year, examDate.month, examDate.day).difference(DateTime(n.year, n.month, n.day)).inDays;
}
