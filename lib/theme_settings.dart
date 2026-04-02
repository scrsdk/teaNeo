import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Для themeNotifier

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

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
          'Оформление', 
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildThemeOption(
              context, 
              'Темная тема', 
              CupertinoIcons.moon_fill, 
              ThemeMode.dark,
              isDark
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context, 
              'Светлая тема', 
              CupertinoIcons.sun_max_fill, 
              ThemeMode.light,
              !isDark
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon, ThemeMode mode, bool isSelected) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () async {
        themeNotifier.value = mode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_dark_mode', mode == ThemeMode.dark);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A84FF) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0A84FF) : Colors.grey),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF0A84FF)),
          ],
        ),
      ),
    );
  }
}
