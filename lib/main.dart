import 'package:bobtime/screens/order_status_screen.dart';
import 'package:bobtime/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BobTime',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleNotification(Time(2, 0, 0)); // 오전 2시에 알림 예약
    return Scaffold(
      appBar: AppBar(
        title: Text('BobTime'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'logo.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              '도시락 주문 시스템',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '선택한 날짜: ${_selectedDate.toString().split(' ')[0]}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('날짜 선택'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final orders = [
                  {'name': '홍길동', 'order': '7700원 도시락', 'paid': true},
                  {'name': '김철수', 'order': '9000원 도시락', 'paid': false},
                  {'name': '이영희', 'order': '먹지 않음', 'paid': true},
                ];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderStatusPage(orders: orders),
                  ),
                );
              },
              child: Text('주문 현황'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return OrderDialog(
                      onOrderSelected: (String selectedOrder) async {
                        int price = int.parse(
                            selectedOrder.replaceAll(RegExp(r'[^0-9]'), ''));
                        dynamic response =
                            await ApiService.post('api/v1/order/create', body: {
                          'data': {
                            'productName': selectedOrder,
                            'price': price,
                            'isPaid': false,
                          }
                        });
                        print(response);
                      },
                    );
                  },
                );
              },
              child: Text('도시락 선택'),
            ),
          ],
        ),
      ),
    );
  }
}

void _scheduleNotification(Time time) async {
  final now = DateTime.now();
  final scheduledDate = DateTime(
      now.year, now.month, now.day, time.hour, time.minute, time.second);

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.schedule(
    0,
    '도시락 주문 알림',
    '내일 도시락을 주문할 시간입니다.',
    scheduledDate,
    platformChannelSpecifics,
  );
}

class OrderDialog extends StatelessWidget {
  final Function(String) onOrderSelected;

  const OrderDialog({super.key, required this.onOrderSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('도시락 주문'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('7700원 도시락'),
            onTap: () {
              onOrderSelected('7700원 도시락');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: Text('9000원 도시락'),
            onTap: () {
              onOrderSelected('9000원 도시락');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: Text('먹지 않음'),
            onTap: () {
              onOrderSelected('먹지 않음');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
