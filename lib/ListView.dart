import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListPage(),
    );
  }
}

class ListPage extends StatelessWidget {
  final List<Map<String, dynamic>> itemList = [
    {'title': 'Item 1', 'icon': Icons.shopping_cart},
    {'title': 'Item 2', 'icon': Icons.local_pizza},
    {'title': 'Item 3', 'icon': Icons.movie},
    {'title': 'Item 4', 'icon': Icons.music_note},
    {'title': 'Item 5', 'icon': Icons.book},
    // Tambahkan item lain sesuai kebutuhan
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Page'),
      ),
      body: ListView.builder(
        itemCount: itemList.length,
        itemBuilder: (context, index) {
          final item = itemList[index];
          return ListTile(
            leading: Icon(item['icon']),
            title: Text(item['title']),
            // Tambahkan bagian lain dari ListTile sesuai kebutuhan
          );
        },
      ),
    );
  }
}