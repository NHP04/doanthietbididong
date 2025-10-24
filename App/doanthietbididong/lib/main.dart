import 'package:flutter/material.dart';
import 'pages/food_menu.dart';
import 'pages/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Danh Mục Món Ăn',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
      routes: {
        '/menu': (context) => const FoodMenu(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
