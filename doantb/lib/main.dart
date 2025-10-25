import 'package:flutter/material.dart';
import 'package:doanthietbididong/Screens/Welcome/welcome_screen.dart';
import 'package:doanthietbididong/constants.dart';

// Import các trang mới của bạn
import 'package:doanthietbididong/pages/home_screen.dart';
import 'package:doanthietbididong/pages/food_menu.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Công Thức Nấu Ăn',
      theme: ThemeData(
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: Colors.white,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              foregroundColor: Colors.white,
              backgroundColor: kPrimaryColor,
              shape: const StadiumBorder(),
              maximumSize: const Size(double.infinity, 56),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: kPrimaryLightColor,
            iconColor: kPrimaryColor,
            prefixIconColor: kPrimaryColor,
            contentPadding: EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              borderSide: BorderSide.none,
            ),
          )),
      // Màn hình bắt đầu của ứng dụng vẫn là WelcomeScreen
      home: const WelcomeScreen(),

      // Thêm các đường dẫn (routes) từ app nội dung vào đây
      routes: {
        '/home': (context) => const HomeScreen(),
        '/menu': (context) => const FoodMenu(),
      },
    );
  }
}