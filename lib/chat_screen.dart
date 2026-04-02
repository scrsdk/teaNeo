import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'api.dart';
import 'user_profile.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  const ChatScreen({super.key, required this.username});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  List<dynamic> _messages = [];
  String _myUsername = '';
  Timer? _timer;

  int? _editingMsgId;
  int? _replyingMsgId;
  String? _actionText;

  @override
  void initState() {
    super.initState();
    _loadMyName();
    _fetchMessages();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchMessages());
    _msgCtrl.addListener(() {
      final typing = _msgCtrl.text.trim().isNotEmpty;
      if (typing != _isTyping) {
        setState(() => _isTyping = typing);
      }
    });
  }

  void _loadMyName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _myUsername = prefs.getString('my_username') ?? '');
  }

  Future<void> _fetchMessages() async {
    final msgs = await Api.getMessages(widget.username);
    if (mounted) {
      setState(() => _messages = msgs.reversed.toList());
      // Помечаем как прочитанные
      if (_messages.any((m) => m['sender'] != _myUsername && (m['is_read'] == 0 || m['is_read'] == '0'))) {
        await Api.markAsRead(widget.username);
      }
    }
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    if (_editingMsgId != null) {
      await Api.editMessage(_editingMsgId!, text);
      _cancelAction();
      _fetchMessages();
    } else {
      final replyId = _replyingMsgId;
      _cancelAction();

      setState(() {
        _messages.insert(0, {
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'sender': _myUsername,
          'message': text,
          'created_at': DateTime.now().toString(),
          'is_pinned': 0,
          'is_edited': 0,
          'is_read': 0,
          'reply_to_id': replyId
        });
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }

      await Api.sendMessage(widget.username, text, replyToId: replyId);
      _fetchMessages();
    }
  }

  void _cancelAction() {
    setState(() {
      _editingMsgId = null;
      _replyingMsgId = null;
      _actionText = null;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFavorite = widget.username == 'Избранное';
    
    final pinnedMsgIndex = _messages.indexWhere((m) => m['is_pinned'] == '1' || m['is_pinned'] == 1);
    final pinnedMessage = pinnedMsgIndex != -1 ? _messages[pinnedMsgIndex] : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // КАСТОМНЫЙ ХЕДЕР
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(CupertinoIcons.left_chevron, color: isDark ? Colors.white : Colors.black, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: isFavorite ? null : () {
                            Navigator.push(context, CupertinoPageRoute(builder: (_) => UserProfileScreen(username: widget.username)));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: isDark ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.username,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    if (widget.username == 'melisov' || widget.username == 'admin')
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF0A84FF), size: 16),
                                      ),
                                  ],
                                ),
                                if (!isFavorite)
                                  const Text('в сети 5 мин. назад', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: isFavorite ? null : () => Navigator.push(context, CupertinoPageRoute(builder: (_) => UserProfileScreen(username: widget.username))),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF0A84FF),
                          child: isFavorite 
                            ? const Icon(CupertinoIcons.bookmark_fill, color: Colors.white, size: 18)
                            : Text(widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  
                  if (pinnedMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: isDark ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.pin_fill, color: Color(0xFF0A84FF), size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Закрепленное сообщение', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 11, fontWeight: FontWeight.bold)),
                                Text(pinnedMessage['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await Api.togglePinMessage(int.parse(pinnedMessage['id'].toString()), false);
                              _fetchMessages();
                            },
                            child: const Icon(CupertinoIcons.xmark, color: Colors.grey, size: 16),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // СООБЩЕНИЯ ИЛИ ЗАГЛУШКА
            Expanded(
              child: _messages.isEmpty 
                ? Center(
                    child: Text(
                      'тут пока ничего нет', 
                      style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 16)
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender'] == _myUsername;
                      final msgId = int.tryParse(msg['id'].toString()) ?? 0;
                      final isRead = msg['is_read'] == 1 || msg['is_read'] == '1';
                      String time = '';
                      if (msg['created_at'] != null && msg['created_at'].toString().length >= 16) {
                        time = msg['created_at'].toString().substring(11, 16);
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            if (details.delta.dx > 10) {
                              setState(() {
                                _replyingMsgId = msgId;
                                _actionText = msg['message'];
                                _editingMsgId = null;
                              });
                              _focusNode.requestFocus();
                            }
                          },
                          onLongPress: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) => CupertinoActionSheet(
                                actions: [
                                  CupertinoActionSheetAction(
                                    child: const Text('Ответить'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _replyingMsgId = msgId;
                                        _actionText = msg['message'];
                                        _editingMsgId = null;
                                      });
                                      _focusNode.requestFocus();
                                    },
                                  ),
                                  CupertinoActionSheetAction(
                                    child: const Text('Закрепить'),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await Api.togglePinMessage(msgId, true);
                                      _fetchMessages();
                                    },
                                  ),
                                  if (isMe)
                                    CupertinoActionSheetAction(
                                      child: const Text('Редактировать'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          _editingMsgId = msgId;
                                          _msgCtrl.text = msg['message'] ?? '';
                                        });
                                        _focusNode.requestFocus();
                                      },
                                    ),
                                  if (isMe)
                                    CupertinoActionSheetAction(
                                      isDestructiveAction: true,
                                      child: const Text('Удалить для всех'),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await Api.deleteMessage(msgId);
                                        _fetchMessages();
                                      },
                                    ),
                                ],
                                cancelButton: CupertinoActionSheetAction(child: const Text('Отмена'), onPressed: () => Navigator.pop(context)),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            margin: EdgeInsets.only(
                              bottom: 8,
                              left: _replyingMsgId == msgId ? 20 : 0,
                            ),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF0A84FF) : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: !isMe && !isDark ? Border.all(color: Colors.grey.withValues(alpha: 0.2)) : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(msg['message'] ?? '', style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black), fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(time, style: TextStyle(color: isMe ? Colors.white54 : Colors.grey, fontSize: 10)),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          isRead ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.check_mark,
                                          size: 12,
                                          color: isRead ? Colors.lightBlueAccent : Colors.white54,
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),

            // ПАНЕЛЬ ВВОДА
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10).copyWith(bottom: 25),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.withValues(alpha: 0.1))),
              ),
              child: Column(
                children: [
                  if (_replyingMsgId != null || _editingMsgId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _editingMsgId != null ? CupertinoIcons.pencil : CupertinoIcons.reply,
                            color: const Color(0xFF0A84FF),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _editingMsgId != null ? 'Редактирование' : 'Ответ',
                                  style: const TextStyle(color: Color(0xFF0A84FF), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _actionText ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _cancelAction,
                            child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey, size: 20),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: isDark ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            focusNode: _focusNode,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'Сообщение',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _sendMessage,
                        child: const Icon(CupertinoIcons.arrow_up_circle_fill, size: 35, color: Color(0xFF0A84FF)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
