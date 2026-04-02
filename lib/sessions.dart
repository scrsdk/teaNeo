import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  String myPhone = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myPhone = prefs.getString('my_phone') ?? 'Неизвестно';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Устройства и сессии', 
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSessionCard(
            context,
            'Текущий сеанс',
            'Этот смартфон',
            'Online',
            isCurrent: true
          ),
          const SizedBox(height: 24),
          Text(
            'АКТИВНЫЕ СЕССИИ',
            style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSessionCard(
            context,
            'Android 13',
            'Chrome Browser',
            'Был в сети: сегодня 12:40'
          ),
          const SizedBox(height: 12),
          _buildSessionCard(
            context,
            'Windows 11',
            'Desktop App',
            'Был в сети: вчера 20:15'
          ),
          const SizedBox(height: 30),
          CupertinoButton(
            child: const Text('Завершить все другие сеансы', style: TextStyle(color: CupertinoColors.systemRed)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, String device, String info, String status, {bool isCurrent = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Icon(
            isCurrent ? CupertinoIcons.device_phone_portrait : CupertinoIcons.desktopcomputer,
            size: 30,
            color: isCurrent ? const Color(0xFF0A84FF) : Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  info,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFF0A84FF) : Colors.grey,
                    fontSize: 12
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
