import 'package:flutter/material.dart';
import './chat_screen.dart';

void main() => runApp(HomePage());

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.amberAccent,
        iconTheme: IconThemeData(
          color: Colors.black
        ),
      ),
      home: ChatScreen(),
    );
  }
}