import 'package:bobtime/screens/order_status_screen.dart';
import 'package:bobtime/services/api_service.dart';
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
  DateTime _selectedDate = DateTime.now();
  String _userName = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
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
              '선택한 날짜: ${toPrettyString(_selectedDate)}',
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
                String formattedDate = getFormattedDate(_selectedDate);
                dynamic response = await ApiService.get(
                    context, '/api/v1/order/orders?date=$formattedDate');
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
                        int price = extractNumber(selectedOrder);
                        dynamic response = await ApiService.post(
                            context, '/api/v1/order/merge',
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
                                    if (selectedOrder != '먹지 않음') {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return AlertDialog(
                                            title: Text('입금 확인'),
                                            content: Text('도시락 금액을 입금하셨나요?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                },
                                                child: Text('아니오'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                  await ApiService.patch(
                                                      context,
                                                      '/api/v1/order/paid/$_userName');
                                                },
                                                child: Text('예'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
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
