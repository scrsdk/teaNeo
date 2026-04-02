import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';
import 'edit_profile.dart';
import 'theme_settings.dart';
import 'sessions.dart';
import 'user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String myUsername = "Загрузка...";
  String myPhone = "";
  String myBio = "Нет описания";
  String? myPhotoUrl;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        myUsername = prefs.getString('my_username') ?? 'Неизвестно';
        myPhone = prefs.getString('my_phone') ?? '';
        myBio = prefs.getString('my_bio') ?? 'Укажите информацию о себе';
        myPhotoUrl = prefs.getString('my_photo');
        isVerified = prefs.getBool('my_verify') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        // ЗАПРЕТ ПРОКРУТКИ
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 80),
            
            // АВАТАР
            Center(
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.withValues(alpha: 0.2),
                  backgroundImage: (myPhotoUrl != null && myPhotoUrl!.isNotEmpty) 
                    ? NetworkImage(myPhotoUrl!) 
                    : null,
                  child: (myPhotoUrl == null || myPhotoUrl!.isEmpty) 
                    ? Text(
                        myUsername.isNotEmpty ? myUsername[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 40, 
                          color: Color(0xFF0A84FF), 
                          fontWeight: FontWeight.bold
                        ),
                      )
                    : null,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // USERNAME с галочкой
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  myUsername.toUpperCase(),
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w800, 
                    color: isDark ? Colors.white : Colors.black, 
                    letterSpacing: 1.2
                  ),
                ),
                if (isVerified || myUsername == 'melisov' || myUsername == 'admin')
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF0A84FF), size: 22),
                  ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            Text(
              myPhone,
              style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w400),
            ),
            
            const SizedBox(height: 20),
            
            // КНОПКА ИЗМЕНИТЬ
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                await Navigator.push(context, CupertinoPageRoute(builder: (_) => const EditProfileScreen()));
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.withValues(alpha: 0.2),
                ),
                child: Text(
                  'Изменить',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            _buildSettingsSection([
              _SettingRow(
                icon: CupertinoIcons.person_crop_circle_fill, 
                title: 'Мой профиль', 
                color: CupertinoColors.systemBlue,
                onTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => UserProfileScreen(username: myUsername, phone: myPhone, bio: myBio, photoUrl: myPhotoUrl)));
                },
              ),
              _SettingRow(
                icon: CupertinoIcons.paintbrush_fill, 
                title: 'Оформление', 
                color: CupertinoColors.systemOrange,
                onTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => const ThemeSettingsScreen()));
                },
              ),
              _SettingRow(
                icon: CupertinoIcons.bell_fill, 
                title: 'Уведомления', 
                color: CupertinoColors.systemRed,
              ),
            ]),

            const SizedBox(height: 16),

            _buildSettingsSection([
              _SettingRow(
                icon: CupertinoIcons.device_phone_portrait, 
                title: 'Устройства и сессии', 
                color: CupertinoColors.systemGreen,
                onTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => const SessionsScreen()));
                },
              ),
              _SettingRow(icon: CupertinoIcons.lock_fill, title: 'Конфиденциальность', color: CupertinoColors.systemGrey),
              _SettingRow(
                icon: CupertinoIcons.question_circle_fill, 
                title: 'Помощь', 
                color: CupertinoColors.systemTeal,
              ),
            ]),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _GlassCard(
                color: Colors.red.withValues(alpha: 0.15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(
                    child: Text('Выйти из аккаунта', style: TextStyle(color: CupertinoColors.systemRed, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(List<_SettingRow> rows) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _GlassCard(
        child: Column(
          children: List.generate(rows.length, (index) {
            final row = rows[index];
            return Column(
              children: [
                _buildRow(row),
                if (index != rows.length - 1)
                  const Divider(height: 1, indent: 56, color: Colors.white10),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRow(_SettingRow row) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: row.color, borderRadius: BorderRadius.circular(8)),
        child: Icon(row.icon, color: Colors.white, size: 20),
      ),
      title: Text(row.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17)),
      trailing: Icon(CupertinoIcons.chevron_right, color: isDark ? Colors.white24 : Colors.black26, size: 18),
      onTap: row.onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          CupertinoDialogAction(child: const Text('Отмена'), onPressed: () => Navigator.pop(context, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('Выйти'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }
}

class _SettingRow {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  _SettingRow({required this.icon, required this.title, required this.color, this.onTap});
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  const _GlassCard({required this.child, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onTap: onTap,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: color ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1), width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
