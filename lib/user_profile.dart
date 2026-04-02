import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';
import 'api.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final String? phone;
  final String? bio;
  final String? photoUrl;

  const UserProfileScreen({
    super.key, 
    required this.username, 
    this.phone, 
    this.bio,
    this.photoUrl
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isVerified = false;
  String? _phone;
  String? _bio;
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    String myName = prefs.getString('my_username') ?? '';
    
    if (widget.username == myName) {
      setState(() {
        _isVerified = prefs.getBool('my_verify') ?? false;
        _phone = widget.phone;
        _bio = widget.bio;
        _photoUrl = widget.photoUrl;
        _isLoading = false;
      });
    } else {
      // Для других пользователей получаем данные с сервера (нужен метод get_profile)
      final profile = await Api.getUserProfile(widget.username);
      if (mounted) {
        setState(() {
          _isVerified = profile['verify'] == 1 || profile['verify'] == '1';
          _phone = profile['phone'];
          _bio = profile['bio'];
          _photoUrl = profile['photo'];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isFavorite = widget.username == 'Избранное';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading 
        ? const Center(child: CupertinoActivityIndicator())
        : Stack(
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0A84FF),
                      const Color(0xFF0A84FF).withValues(alpha: 0.3),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.left_chevron, color: Colors.white, size: 22),
                            ),
                          ),
                          const Text(
                            'Профиль',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty) 
                        ? NetworkImage(_photoUrl!) 
                        : null,
                      child: (_photoUrl == null || _photoUrl!.isEmpty) 
                        ? Text(
                            widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 50, color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.username,
                          style: TextStyle(
                            fontSize: 26, 
                            fontWeight: FontWeight.bold, 
                            color: isDark ? Colors.white : Colors.black
                          ),
                        ),
                        if (_isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF0A84FF), size: 26),
                          ),
                      ],
                    ),
                    
                    if (!isFavorite && _phone != null && _phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _phone!,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),

                    const SizedBox(height: 10),
                    if (!isFavorite && widget.username != 'Избранное')
                      const Text('в сети 5 мин. назад', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 14)),

                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            context, 
                            CupertinoIcons.info, 
                            'О себе', 
                            _bio ?? 'Информация отсутствует'
                          ),
                          
                          if (widget.username != 'Избранное')
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context, 
                                    CupertinoPageRoute(builder: (_) => ChatScreen(username: widget.username))
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A84FF),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Написать сообщение',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isDark ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0A84FF)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, 
              fontSize: 16
            ),
          ),
        ],
      ),
    );
  }
}
