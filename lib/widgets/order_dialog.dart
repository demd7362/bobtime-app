import 'package:flutter/material.dart';

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
