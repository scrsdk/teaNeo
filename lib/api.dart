import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const String baseUrl = 'http://q97902ug.beget.tech/api.php';
  static const Map<String, String> headers = {
    "User-Agent": "Mozilla/5.0",
    "Content-Type": "application/x-www-form-urlencoded",
  };

  // ОБНОВЛЕНИЕ СТАТУСА (ОНЛАЙН)
  static Future<void> updateOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String myUser = prefs.getString('my_username') ?? '';
    if (myUser.isNotEmpty) {
      await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'update_status', 'username': myUser});
    }
  }

  // ПОМЕТИТЬ СООБЩЕНИЯ КАК ПРОЧИТАННЫЕ
  static Future<void> markAsRead(String otherUsername) async {
    final prefs = await SharedPreferences.getInstance();
    String myUser = prefs.getString('my_username') ?? '';
    await http.post(Uri.parse(baseUrl), headers: headers, body: {
      'action': 'read_messages', 
      'my_username': myUser,
      'other_username': otherUsername
    });
  }

  // ПОЛУЧИТЬ СТАТУС ПОЛЬЗОВАТЕЛЯ
  static Future<Map<String, dynamic>> getUserStatus(String target) async {
    try {
      final res = await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'get_user_status', 'target': target});
      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error'};
    }
  }

  // ПОЛУЧИТЬ ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ
  static Future<Map<String, dynamic>> getUserProfile(String username) async {
    try {
      final res = await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'get_profile', 'username': username});
      final data = jsonDecode(res.body);
      return data['status'] == 'success' ? data['data'] : {};
    } catch (e) {
      return {};
    }
  }

  // ПРОВЕРКА: СУЩЕСТВУЕТ ЛИ ПОЛЬЗОВАТЕЛЬ?
  static Future<Map<String, dynamic>> checkUser(String phone) async {
    try {
      final res = await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'check_user', 'phone': phone});
      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error'};
    }
  }

  // ВХОД / РЕГИСТРАЦИЯ
  static Future<String?> auth(String phone, String username, String password) async {
    try {
      final response = await http.post(Uri.parse(baseUrl), headers: headers, body: {
        'action': 'auth', 'phone': phone, 'username': username, 'password': password,
      });
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('my_username', data['user']['username']);
        await prefs.setString('my_phone', data['user']['phone']);
        await prefs.setString('my_photo', data['user']['photo'] ?? '');
        await prefs.setBool('my_verify', (data['user']['verify'] == 1 || data['user']['verify'] == '1'));
        return null;
      } else {
        return data['message'];
      }
    } catch (e) {
      return "Ошибка сети";
    }
  }

  static Future<List<dynamic>> getChats() async {
    final prefs = await SharedPreferences.getInstance();
    String myUser = prefs.getString('my_username') ?? '';
    final res = await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'get_chats', 'username': myUser});
    return jsonDecode(res.body)['data'] ?? [];
  }

  static Future<List<dynamic>> getMessages(String receiver) async {
    final prefs = await SharedPreferences.getInstance();
    String myUser = prefs.getString('my_username') ?? '';
    final res = await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'get_messages', 'sender': myUser, 'receiver': receiver});
    return jsonDecode(res.body)['data'] ?? [];
  }

  static Future<void> deleteMessage(int messageId) async {
    await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'delete_message', 'id': messageId.toString()});
  }

  static Future<void> sendMessage(String receiver, String text, {int? replyToId}) async {
    final prefs = await SharedPreferences.getInstance();
    String myUser = prefs.getString('my_username') ?? '';

    Map<String, String> body = {'action': 'send_message', 'sender': myUser, 'receiver': receiver, 'message': text};
    if (replyToId != null) body['reply_to_id'] = replyToId.toString();

    await http.post(Uri.parse(baseUrl), headers: headers, body: body);
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final res = await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'search', 'query': query});
    return jsonDecode(res.body)['data'] ?? [];
  }

  static Future<List<dynamic>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    String myUser = prefs.getString('my_username') ?? '';
    final res = await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'get_contacts', 'owner': myUser});
    return jsonDecode(res.body)['data'] ?? [];
  }

  static Future<void> addContact(String contactUsername) async {
    final prefs = await SharedPreferences.getInstance();
    String myUser = prefs.getString('my_username') ?? '';
    await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'add_contact', 'owner': myUser, 'contact': contactUsername});
  }

  static Future<void> deleteChat(String targetUsername) async {
    final prefs = await SharedPreferences.getInstance();
    String myUser = prefs.getString('my_username') ?? '';
    await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'delete_chat', 'user': myUser, 'target': targetUsername});
  }

  static Future<void> editMessage(int messageId, String newText) async {
    await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'edit_message', 'id': messageId.toString(), 'text': newText});
  }

  static Future<void> togglePinMessage(int messageId, bool pin) async {
    await http.post(Uri.parse(baseUrl), headers: headers, body: {'action': 'toggle_pin', 'id': messageId.toString(), 'is_pinned': pin ? '1' : '0'});
  }

  static Future<String?> updateProfile(String newUsername, String bio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String oldUsername = prefs.getString('my_username') ?? '';

      final res = await http.post(Uri.parse(baseUrl), headers: headers, body: {
        'action': 'update_profile',
        'old_username': oldUsername,
        'new_username': newUsername,
        'bio': bio,
      });
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        await prefs.setString('my_username', newUsername);
        await prefs.setString('my_bio', bio);
        return null;
      } else {
        return data['message'];
      }
    } catch (e) {
      return "Ошибка сети";
    }
  }

  static Future<String?> uploadPhoto(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String username = prefs.getString('my_username') ?? '';

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['action'] = 'upload_photo';
      request.fields['username'] = username;
      request.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        String photoUrl = data['url'];
        await prefs.setString('my_photo', photoUrl);
        return null;
      } else {
        return data['message'];
      }
    } catch (e) {
      return "Ошибка при загрузке фото";
    }
  }
}