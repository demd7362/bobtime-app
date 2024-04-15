import 'package:flutter/material.dart';

class OrderStatusPage extends StatefulWidget {
  final List<Map<String, dynamic>> orders;

  const OrderStatusPage({super.key, required this.orders});

  @override
  _OrderStatusPageState createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
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
          return ListTile(
            title: Text(order['name']),
            subtitle: Text(order['order']),
            trailing: Switch(
              value: order['paid'],
              onChanged: (value) {
                setState(() {
                  order['paid'] = value;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
