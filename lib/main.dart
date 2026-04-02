import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Импортируйте ваши экраны
import 'auth.dart';
import 'chats.dart';
import 'contacts.dart';
import 'settings.dart';
import 'api.dart';

// Глобальный провайдер темы
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? savedUsername = prefs.getString('my_username');
  final bool isDarkMode = prefs.getBool('is_dark_mode') ?? true;
  
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  bool isLoggedIn = savedUsername != null && savedUsername.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'My Messenger',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F2F7),
            primaryColor: const Color(0xFF0A84FF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A84FF),
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            primaryColor: const Color(0xFF0A84FF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0A84FF),
              surface: Color(0xFF1C1C1E),
              onSurface: Colors.white,
            ),
          ),
          home: isLoggedIn ? const MainScreen() : const AuthScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  int _totalUnread = 0;
  late PageController _pageController;
  Timer? _statusTimer;

  final List<Widget> _pages = [
    const ContactsScreen(),
    const ChatsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _checkUnread();
    
    // Запускаем обновление статуса онлайн каждые 60 секунд
    Api.updateOnlineStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      Api.updateOnlineStatus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _checkUnread() async {
    final chats = await Api.getChats();
    int count = 0;
    for (var chat in chats) {
      count += (chat['unread'] as int? ?? 0);
    }
    if (mounted) {
      setState(() {
        _totalUnread = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: (isDark ? const Color(0xFF1C1C1E) : Colors.white).withValues(alpha: 0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, CupertinoIcons.person_2_fill, 'Контакты'),
                    _buildNavItem(1, CupertinoIcons.chat_bubble_2_fill, 'Чаты', badge: _totalUnread),
                    _buildNavItem(2, CupertinoIcons.settings, 'Настройки'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badge = 0}) {
    bool isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutQuart,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF0A84FF) : Colors.grey,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0A84FF) : Colors.grey,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    badge > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AriaTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;

  const AriaTextField({
    super.key,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: isDark ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.start,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(prefixIcon, color: Colors.grey, size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(bottom: 12),
        ),
      ),
    );
  }
}
