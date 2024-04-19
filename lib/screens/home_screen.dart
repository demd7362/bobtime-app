import 'package:bobtime/screens/order_status_screen.dart';
import 'package:bobtime/services/api_service.dart';
import 'package:bobtime/services/notification_service.dart';
import 'package:bobtime/utils/date_utils.dart';
import 'package:bobtime/utils/string_utils.dart';
import 'package:bobtime/widgets/order_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, String> _roleMap = {'참여자': 'PARTICIPANT', '관리자': 'ADMIN'};
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  String _userName = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    FlutterLocalNotification.init();
    Future.delayed(const Duration(seconds: 3),
        FlutterLocalNotification.requestNotificationPermission());
    _checkUserInfo();
  }

  void _checkUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('userName');
    String? role = prefs.getString('userRole');

    if (name == null || role == null) {
      await _showUserInfoModal();
    } else {
      setState(() {
        _userName = name;
        _userRole = role;
      });
    }
  }

  Future<void> _showUserInfoModal() async {
    TextEditingController nameController =
        TextEditingController(text: _userName);
    String? selectedRole;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('사용자 정보 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: '이름'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                onChanged: (String? newValue) {
                  selectedRole = newValue;
                },
                items: <String>['참여자', '관리자']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: '역할'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                selectedRole ??= '참여자';
                await prefs.setString('userName', nameController.text);
                await prefs.setString('userRole', selectedRole!);
                dynamic response =
                    await ApiService.post(context, '/api/v1/user/join', body: {
                  'user': {
                    'name': nameController.text,
                    'role': _roleMap[selectedRole]
                  }
                });
                if (is2XXSuccessful(response)) {
                  setState(() {
                    _userName = nameController.text;
                    _userRole = selectedRole ?? '참여자';
                  });
                  Navigator.of(context).pop();
                } else {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(response['message']['title']),
                        content: Text(response['message']['content']),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('확인'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
            colorScheme: ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _selectedDateRange = pickedRange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('밥타임'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
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
              _selectedDateRange.start == _selectedDateRange.end
                  ? '선택한 날짜 ${toPrettyString(_selectedDateRange.start)}'
                  : '선택한 날짜: ${toPrettyString(_selectedDateRange.start)} ~ ${toPrettyString(_selectedDateRange.end)}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _selectDateRange(context),
              child: Text('날짜 선택'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                String formattedStartDate =
                    getFormattedDate(_selectedDateRange.start);
                String formattedEndDate =
                    getFormattedDate(_selectedDateRange.end);
                dynamic response = await ApiService.get(context,
                    '/api/v1/order/orders?start=$formattedStartDate&end=$formattedEndDate');
                List<Map<String, dynamic>> orders =
                    List<Map<String, dynamic>>.from(response['data']);
                print(orders);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OrderStatusScreen(orders: orders)),
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
                        String formattedStartDate =
                            getFormattedDate(_selectedDateRange.start);
                        String formattedEndDate =
                            getFormattedDate(_selectedDateRange.end);
                        int price = extractNumber(selectedOrder);
                        dynamic response = await ApiService.post(context,
                            '/api/v1/order/merge?start=$formattedStartDate&end=$formattedEndDate',
                            body: {
                              'order': {
                                'productName': selectedOrder,
                                'price': price,
                              },
                              'user': {
                                'name': _userName,
                              }
                            });

                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: Text(response['message']['title']),
                              content: Text(response['message']['content']),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: Text('확인'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
              child: Text('도시락 선택'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _showUserInfoModal();
              },
              child: Text('이름 변경'),
            ),
          ],
        ),
      ),
    );
  }
}
