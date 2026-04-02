import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';
import 'api.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _contacts = [];
  List<dynamic> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchCtrl.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filterContacts);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final data = await Api.getContacts();
    if (mounted) {
      setState(() {
        _contacts = data;
        _filteredContacts = data;
        _isLoading = false;
      });
    }
  }

  void _filterContacts() {
    final query = _searchCtrl.text.toLowerCase();
    if (mounted) {
      setState(() {
        _filteredContacts = _contacts.where((c) {
          final username = c['username'].toString().toLowerCase();
          final phone = c['phone']?.toString().toLowerCase() ?? '';
          return username.contains(query) || phone.contains(query);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Контакты', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 22,
            color: isDark ? Colors.white : Colors.black,
          )
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: AriaTextField(
              hint: 'Поиск', 
              controller: _searchCtrl, 
              prefixIcon: CupertinoIcons.search
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredContacts.isEmpty
                ? Center(child: Text('Нет контактов', style: TextStyle(color: isDark ? Colors.grey : Colors.black54)))
                : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                final String username = contact['username'] ?? 'Unknown';
                final String phone = contact['phone'] ?? '';
                // БЕРЕМ ВЕРИФИКАЦИЮ ИЗ БАЗЫ
                final bool isVerified = contact['verify'] == 1 || contact['verify'] == '1';

                return InkWell(
                  onTap: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => ChatScreen(username: username)));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.primaries[username.length % Colors.primaries.length],
                          backgroundImage: (contact['photo'] != null && contact['photo'] != '') ? NetworkImage(contact['photo']) : null,
                          child: (contact['photo'] == null || contact['photo'] == '') ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)) : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
