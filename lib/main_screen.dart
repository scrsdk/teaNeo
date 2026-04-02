import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'chats.dart';
import 'settings.dart';
import 'contacts.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  final List<Widget> _pages = [const ContactsScreen(), const ChatsScreen(), const SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages), // IndexedStack сохраняет состояние вкладок
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2_fill), label: 'Контакты'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_2_fill), label: 'Чаты'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}