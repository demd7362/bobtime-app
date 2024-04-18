import 'package:bobtime/services/api_service.dart';
import 'package:flutter/material.dart';

class OrderStatusScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orders;

  const OrderStatusScreen({super.key, required this.orders});

  @override
  _OrderStatusScreenState createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('주문 현황'),
      ),
      body: ListView.builder(
        itemCount: widget.orders.length,
        itemBuilder: (context, index) {
          final order = widget.orders[index];
          final name = order['user']['name'] ?? '알 수 없는 주문자';
          print('order here index:$index, item $order');
          return ListTile(
            title: Text(name),
            subtitle: Text(order['productName'] ?? '알 수 없는 도시락'),
            trailing: Switch(
              value: order['paid'] ?? false,
              onChanged: (value) async {
                dynamic response = await ApiService.patch(
                    context, '/api/v1/order/toggle-paid/${order['num']}');
                setState(() {
                  order['paid'] = value;
                });

                showDialog(
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
              },
            ),
          );
        },
      ),
    );
  }
}
