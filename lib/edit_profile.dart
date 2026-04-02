import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameCtrl.text = prefs.getString('my_username') ?? '';
      _bioCtrl.text = prefs.getString('my_bio') ?? '';
      _currentPhotoUrl = prefs.getString('my_photo');
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveData() async {
    String newName = _usernameCtrl.text.trim();
    String newBio = _bioCtrl.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя пользователя не может быть пустым')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Загружаем фото, если оно выбрано
    if (_imageFile != null) {
      await Api.uploadPhoto(_imageFile!);
    }

    // 2. Обновляем текстовые данные
    String? error = await Api.updateProfile(newName, newBio);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color sectionColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF0A84FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Редактировать', style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveData,
            child: _isLoading 
              ? const CupertinoActivityIndicator() 
              : const Text('Готово', style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold, fontSize: 17)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // АВАТАР С ВЫБОРОМ
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: sectionColor,
                  backgroundImage: _imageFile != null 
                    ? FileImage(_imageFile!) 
                    : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) : null) as ImageProvider?,
                  child: (_imageFile == null && _currentPhotoUrl == null)
                    ? Icon(CupertinoIcons.person_fill, size: 50, color: const Color(0xFF0A84FF).withValues(alpha: 0.8))
                    : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: const Text('Изменить фото', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 15)),
            ),
            const SizedBox(height: 30),

            _buildInputSection('ИМЯ ПОЛЬЗОВАТЕЛЯ', _usernameCtrl, 'Введите имя...', isDark, sectionColor, borderColor, textColor),
            const SizedBox(height: 20),
            _buildInputSection('О СЕБЕ', _bioCtrl, 'Напишите что-нибудь о себе...', isDark, sectionColor, borderColor, textColor, maxLines: 3),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Это имя будут видеть другие пользователи. Расскажите немного о себе, чтобы людям было проще вас узнать.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(String label, TextEditingController controller, String hint, bool isDark, Color bgColor, Color borderColor, Color textColor, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8),
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(color: borderColor, width: 0.5),
              bottom: BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: textColor, fontSize: 17),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF3A3A3C)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
