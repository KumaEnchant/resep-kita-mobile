import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background notif: ${message.notification?.title}');
  await _tampilkanNotifLokal(message);
}

Future<void> _tampilkanNotifLokal(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'resep_kita_channel',
    'Resep Kita Notifikasi',
    channelDescription: 'Notifikasi dari Resep Kita',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'Resep Kita',
    message.notification?.body ?? '',
    const NotificationDetails(android: androidDetails),
  );
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final _messaging = FirebaseMessaging.instance;

  Function(Map<String, dynamic>)? onNotifikasiMasuk;

  Future<void> init() async {
    try {
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(android: androidInit),
      );

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Foreground notif: ${message.notification?.title}');
        await _tampilkanNotifLokal(message);

        if (message.notification != null) {
          final notifBaru = {
            'id': message.messageId ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            'judul': message.notification!.title ?? 'Notifikasi',
            'pesan': message.notification!.body ?? '',
            'tipe': message.data['tipe'] ?? 'info',
            'waktu': 'Baru saja',
            'dibaca': false,
          };
          onNotifikasiMasuk?.call(notifBaru);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notif di-tap: ${message.notification?.title}');
      });

      await _daftarkanToken();

      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM token refresh: $newToken');
        await ApiService().simpanFcmToken(newToken);
      });
    } catch (e) {
      debugPrint('FCM init error (aman diabaikan): $e');
    }
  }

  Future<void> _daftarkanToken() async {
    try {
      final token = await getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await ApiService().simpanFcmToken(token);
        debugPrint('✅ FCM token berhasil dikirim ke backend');
      } else {
        debugPrint('⚠️ FCM token null');
      }
    } catch (e) {
      debugPrint('FCM token error (aman diabaikan): $e');
    }
  }

  Future<void> daftarkanTokenSetelahLogin() async {
    await _daftarkanToken();
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      return await _messaging.getToken(
        vapidKey:
            'BHrLCHXoYSfMfWnx7fixR0X_6_7VBb0XajYPvmwjXdljsRAGldv3bLU4zCO4Us1lsd_VOjpvOfZWcbwAtkPl73w',
      );
    }
    return await _messaging.getToken();
  }
}