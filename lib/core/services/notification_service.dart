// Bildirim servisi ilk sürümde devre dışı.
// İleride flutter_local_notifications yeniden eklendiğinde burası
// yeni eklenecek API'ye göre tekrar doldurulacak.

class NotificationService {
  static Future<void> initTimezone() async {}
  static Future<void> init() async {}
  static Future<bool> requestPermission() async => false;
  static Future<void> scheduleDailyReminder() async {}
  static Future<void> cancelDailyReminder() async {}
}
