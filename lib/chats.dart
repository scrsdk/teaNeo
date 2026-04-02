import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'api.dart';
import 'main.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  List<dynamic> _myChats = [];
  bool _isLoadingChats = true;
  Set<String> _pinnedChatUsers = {}; // Локальный список закрепленных чатов

  @override
  void initState() {
    super.initState();
    _loadMyChats();
    _searchCtrl.addListener(_onSearchInputChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchInputChanged);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchInputChanged() {
    _onSearchChanged(_searchCtrl.text);
  }

  Future<void> _loadMyChats() async {
    final chats = await Api.getChats();
    if (mounted) {
      setState(() {
        _myChats = chats;
        _isLoadingChats = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults = [];
          });
        }
        _loadMyChats();
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      final results = await Api.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  Widget _buildChatItem(String username, String subtitle, String lastSender, int isRead, String time, int unreadCount, Color avatarColor, int verifyStatus, {bool isFavorite = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPinned = _pinnedChatUsers.contains(username);
    final bool isVerified = verifyStatus == 1 || verifyStatus == '1';
    
    return Dismissible(
      key: ValueKey(username + (isFavorite ? "_fav" : "")),
      direction: isFavorite ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.destructiveRed,
        child: const Icon(CupertinoIcons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Удалить чат?'),
            content: Text('Вы действительно хотите удалить переписку с $username?'),
            actions: [
              CupertinoDialogAction(child: const Text('Нет'), onPressed: () => Navigator.pop(context, false)),
              CupertinoDialogAction(isDestructiveAction: true, child: const Text('Да'), onPressed: () async {
                await Api.deleteChat(username);
                _loadMyChats();
                if (context.mounted) Navigator.pop(context, true);
              }),
            ],
          ),
        );
      },
      child: InkWell(
        onTap: () {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => ChatScreen(username: username))).then((_) {
            _loadMyChats(); // Обновляем непрочитанные после возврата
          });
        },
        onLongPress: () {
          if (isFavorite) return;
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              title: Text('Действия с $username'),
              actions: [
                CupertinoActionSheetAction(
                  child: Text(isPinned ? 'Открепить чат' : 'Закрепить чат'), 
                  onPressed: () {
                    setState(() {
                      if (isPinned) _pinnedChatUsers.remove(username);
                      else _pinnedChatUsers.add(username);
                    });
                    Navigator.pop(context);
                  }
                ),
                CupertinoActionSheetAction(child: const Text('Добавить в контакты'), onPressed: () async {
                  await Api.addContact(username);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавлено в контакты', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                  }
                }),
                CupertinoActionSheetAction(isDestructiveAction: true, child: const Text('Удалить чат'), onPressed: () async {
                  await Api.deleteChat(username);
                  _loadMyChats();
                  if (context.mounted) Navigator.pop(context);
                }),
              ],
              cancelButton: CupertinoActionSheetAction(child: const Text('Отмена'), onPressed: () => Navigator.pop(context)),
            ),
          );
        },
        child: Container(
          color: isPinned ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: avatarColor,
                child: isFavorite ? const Icon(CupertinoIcons.bookmark_fill, color: Colors.white) : Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              username, 
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black, 
                                fontSize: 17, 
                                fontWeight: FontWeight.w600
                              )
                            ),
                            if (isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF0A84FF), size: 16),
                              ),
                            if (isPinned)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(CupertinoIcons.pin_fill, color: Colors.grey, size: 14),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            if (!isFavorite && lastSender != username && lastSender != '') 
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  isRead == 1 ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.check_mark,
                                  size: 14,
                                  color: isRead == 1 ? Colors.lightBlueAccent : Colors.grey,
                                ),
                              ),
                            if (time.isNotEmpty) Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _isSearching ? const Color(0xFF0A84FF) : Colors.grey, fontSize: 15)),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0A84FF),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Сортировка: сначала закрепленные, потом остальные
    List<dynamic> sortedChats = List.from(_myChats);
    sortedChats.sort((a, b) {
      bool aPinned = _pinnedChatUsers.contains(a['username']);
      bool bPinned = _pinnedChatUsers.contains(b['username']);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        centerTitle: true,
        title: Text(
          _isLoadingChats ? 'Обновление...' : 'Чаты', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 22, 
            color: isDark ? Colors.white : Colors.black
          )
        )
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Шире (меньше padding по бокам)
            child: AriaTextField(
              hint: 'Поиск',
              controller: _searchCtrl,
              prefixIcon: CupertinoIcons.search,
            ),
          ),
          Expanded(
            child: _searchCtrl.text.isEmpty
                ? ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: sortedChats.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildChatItem('Избранное', 'Сохраненные сообщения', '', 1, '', 0, const Color(0xFF0A84FF), 0, isFavorite: true);
                final chat = sortedChats[index - 1];
                return _buildChatItem(
                  chat['username'] ?? '', 
                  chat['last_message'] ?? '', 
                  chat['last_sender'] ?? '',
                  chat['is_read'] ?? 0,
                  chat['time'] ?? '', 
                  chat['unread'] ?? 0, 
                  Colors.primaries[index % Colors.primaries.length],
                  chat['verify'] ?? 0
                );
              },
            )
                : _isSearching ? const Center(child: CupertinoActivityIndicator()) : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return _buildChatItem(user['username'] ?? '?', user['phone'] ?? 'Нет номера', '', 1, '', 0, Colors.primaries[index % Colors.primaries.length], user['verify'] ?? 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
