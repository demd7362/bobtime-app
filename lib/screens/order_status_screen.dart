import 'package:bobtime/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderStatusScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orders;

  const OrderStatusScreen({super.key, required this.orders});

  @override
  _OrderStatusScreenState createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  bool isAdmin = false;
  bool isEmpty = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _checkIfOrdersEmpty();
  }

  void _checkIfOrdersEmpty() {
    setState(() {
      isEmpty = widget.orders.isEmpty;
    });
  }

  Future<void> _checkAdminRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('userRole');
    setState(() {
      isAdmin = role == '관리자';
    });
  }

  Future<void> _showPaymentInfo() async {
    dynamic response = await ApiService.get(context, '/api/v1/user/admin-info');
    final adminName = response['data']?['name'];
    String text;
    if (adminName == null) {
      text = '관리자가 정해지지 않았습니다.';
    } else {
      text = '$adminName 님에게 입금 후 상태 변경 바랍니다.';
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('입금 정보'),
          content: Text(text),
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

  Future<void> _showUnpaidAmount() async {
    try {
      final response =
          await ApiService.get(context, '/api/v1/order/unpaid-info');
      final unpaidInfo = response['data'];

      if (unpaidInfo != null) {
        final totalAmount = unpaidInfo['totalAmount'];
        final unpaidEachDate = unpaidInfo['unpaidEachDate'];
        final unpaidEachUser = unpaidInfo['unpaidEachUser'];

        final formattedAmount = NumberFormat('#,###').format(totalAmount);
        final text = '총 $formattedAmount원 미납되었습니다.';

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('미납금 조회'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text),
                  SizedBox(height: 16),
                  Text('일자별 미납금:'),
                  ...unpaidEachDate.entries.map((entry) {
                    final date = entry.key;
                    final amount = entry.value;
                    final formattedAmount =
                        NumberFormat('#,###').format(amount);
                    return Text('$date: $formattedAmount원');
                  }).toList(),
                  SizedBox(height: 16),
                  Text('사용자별 미납금:'),
                  ...unpaidEachUser.entries.map((entry) {
                    final userName = entry.key;
                    final amount = entry.value;
                    final formattedAmount =
                        NumberFormat('#,###').format(amount);
                    return Text('$userName: $formattedAmount원');
                  }).toList(),
                ],
              ),
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
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('미납금 조회'),
              content: Text('미납금 정보를 가져오는 데 실패했습니다.'),
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
    } catch (e) {
      print('미납금 조회 중 오류 발생: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('미납금 조회'),
            content: Text('미납금 정보를 가져오는 중 오류가 발생했습니다.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('주문 현황'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showPaymentInfo,
          ),
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.money),
              onPressed: _showUnpaidAmount,
            ),
        ],
      ),
      body: isEmpty
          ? Center(
              child: Text(
                '아직 아무도 주문하지 않았네요!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : ListView.builder(
              itemCount: widget.orders.length,
              itemBuilder: (context, index) {
                final order = widget.orders[index];
                final name = order['user']['name'] ?? '알 수 없는 주문자';
                print('order here index:$index, item $order');
                return ListTile(
                  title: Text(name),
                  subtitle: Text(order['productName'] ?? '알 수 없는 도시락'),
                  trailing: order['productName'] != '먹지 않음'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              order['paid'] ? '입금 완료' : '미입금',
                              style: TextStyle(
                                color:
                                    order['paid'] ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Switch(
                              value: order['paid'] ?? false,
                              onChanged: (value) async {
                                dynamic response = await ApiService.patch(
                                    context,
                                    '/api/v1/order/toggle-paid/${order['num']}');
                                setState(() {
                                  order['paid'] = value;
                                });

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(response['message']['title']),
                                      content:
                                          Text(response['message']['content']),
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
                              },
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
    );
  }
}
