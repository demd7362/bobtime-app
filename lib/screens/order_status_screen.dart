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
  bool showNotEating = true;
  Map<String, Map<String, int>> orderCountByDateAndProduct = {};
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _checkIfOrdersEmpty();
    _groupOrdersByDateAndProduct();
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

  void _groupOrdersByDateAndProduct() {
    for (var order in widget.orders) {
      final createdAt = order['createdAt'];
      final productName = order['productName'];

      if (createdAt != null && productName != null) {
        final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(createdAt));

        if (!orderCountByDateAndProduct.containsKey(date)) {
          orderCountByDateAndProduct[date] = {};
        }

        orderCountByDateAndProduct[date]
            ?.update(productName, (count) => count + 1, ifAbsent: () => 1);
      }
    }
  }

  void _showOrdersByDate(String date) {
    setState(() {
      selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredOrders = selectedDate == null
        ? widget.orders
        : widget.orders
            .where((order) =>
                order['createdAt'] != null &&
                DateFormat('yyyy-MM-dd')
                        .format(DateTime.parse(order['createdAt'])) ==
                    selectedDate)
            .toList();

    // 먹지 않음 주문 필터링
    if (!showNotEating) {
      filteredOrders = filteredOrders
          .where((order) => order['productName'] != '먹지 않음')
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('주문 현황'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showPaymentInfo,
          ),
          IconButton(
            icon: Icon(Icons.money),
            onPressed: _showUnpaidAmount,
          ),
          IconButton(
            icon: Icon(showNotEating ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                showNotEating = !showNotEating;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: orderCountByDateAndProduct.entries.map((entry) {
                final date = entry.key;
                final countByProduct = entry.value;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => _showOrdersByDate(date),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    child: Column(
                      children: [
                        Text(date),
                        SizedBox(height: 8),
                        ...countByProduct.entries.map((productEntry) {
                          final productName = productEntry.key;
                          final count = productEntry.value;
                          return Text('$productName: $count개');
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '$selectedDate 주문 현황',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: isEmpty
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
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final name = order['user']['name'] ?? '알 수 없는 주문자';
                      final createdAt = order['createdAt'];
                      final formattedDate = createdAt != null
                          ? DateFormat('yyyy-MM-dd')
                              .format(DateTime.parse(createdAt))
                          : '날짜 정보 없음';

                      return ListTile(
                        title: Row(
                          children: [
                            Text(name),
                            SizedBox(width: 8),
                            Text(
                              '($formattedDate)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(order['productName'] ?? '알 수 없는 도시락'),
                        trailing: order['productName'] != '먹지 않음'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    order['paid'] ? '입금 완료' : '미입금',
                                    style: TextStyle(
                                      color: order['paid']
                                          ? Colors.green
                                          : Colors.red,
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
                                            title: Text(
                                                response['message']['title']),
                                            content: Text(
                                                response['message']['content']),
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
          ),
        ],
      ),
    );
  }
}
