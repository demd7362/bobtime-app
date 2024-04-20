import 'dart:io';

import 'package:bobtime/services/api_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static init() async {
    tz.initializeTimeZones();
    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings('@mipmap/logo');

    DarwinInitializationSettings iosInitializationSettings =
        const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> requestNotificationPermission(
      BuildContext context) async {
    // 안드로이드 알림 권한 요청
    if (Platform.isAndroid) {
      final int sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      if (sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (status.isDenied) {
          // 알림 권한이 거부된 경우
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('알림 권한 필요'),
              content:
                  const Text('앱의 알림 권한을 허용해주세요. 앱 설정 화면에서 알림 권한을 활성화할 수 있습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings(); // 앱 설정 화면으로 이동
                  },
                  child: const Text('설정으로 이동'),
                ),
              ],
            ),
          );
        }
      } else {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }
    }

    // IOS 알림 권한 요청
    if (Platform.isIOS) {
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> scheduleNotification(
      int hour, int? minute, int? second) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('channel id', 'channel name',
            channelDescription: 'channel description',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: false);

    const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: DarwinNotificationDetails(badgeNumber: 1));

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute ?? 0, second ?? 0);
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0, '도시락 대금 미지불', '도시락 대금 송금하셨나요?', scheduledDate, notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'notification_payload');
  }

  static void configureSelectNotificationSubject(BuildContext context) {
    flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/logo'),
          iOS: DarwinInitializationSettings(),
        ), onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      if (payload != null && payload == 'notification_payload') {
        final now = DateTime.now();
        final scheduledTime =
            DateTime(now.year, now.month, now.day, 16); // 오후 4시

        if (now.isAfter(scheduledTime)) {
          final response =
              await ApiService.get(context, '/api/v1/order/unpaid-users');
          final users = response['data'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? name = prefs.getString('userName');

          bool isNotificate = users.any((user) => user['name'] == name);

          if (isNotificate) {
            const AndroidNotificationDetails androidNotificationDetails =
                AndroidNotificationDetails('channel id', 'channel name',
                    channelDescription: 'channel description',
                    importance: Importance.max,
                    priority: Priority.max,
                    showWhen: false);

            const NotificationDetails notificationDetails = NotificationDetails(
                android: androidNotificationDetails,
                iOS: DarwinNotificationDetails(badgeNumber: 1));

            await flutterLocalNotificationsPlugin.show(
                0, '도시락 대금 미지불', '도시락 대금 송금하셨나요?', notificationDetails,
                payload: 'notification_payload');
          }
        }
      }
    });
  }
}
