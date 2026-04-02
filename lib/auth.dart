import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'main.dart';
import 'api.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  int step = 1;
  bool userExists = false;
  String existingUsername = "";
  bool isLoading = false;

  late AnimationController _logoController;

  // Форматирование номера
  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ### ## - ##', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  // Список стран
  final List<Map<String, String>> countries = [
    {'name': 'Россия', 'code': '+7', 'flag': '🇷🇺', 'mask': '+7 (###) ### ## - ##'},
    {'name': 'Казахстан', 'code': '+7', 'flag': '🇰🇿', 'mask': '+7 (###) ### ## - ##'},
    {'name': 'США', 'code': '+1', 'flag': '🇺🇸', 'mask': '+1 (###) ### ####'},
    {'name': 'Беларусь', 'code': '+375', 'flag': '🇧🇾', 'mask': '+375 (##) ### ## ##'},
    {'name': 'Узбекистан', 'code': '+998', 'flag': '🇺🇿', 'mask': '+998 (##) ### ## ##'},
    {'name': 'Германия', 'code': '+49', 'flag': '🇩🇪', 'mask': '+49 #### #######'},
    {'name': 'Украина', 'code': '+380', 'flag': '🇺🇦', 'mask': '+380 (##) ### ## ##'},
  ];

  late Map<String, String> selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = countries[0];
    _phoneCtrl.text = selectedCountry['code']!;
    
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  void _updateMask(Map<String, String> country) {
    setState(() {
      selectedCountry = country;
      maskFormatter.updateMask(mask: country['mask']);
      _phoneCtrl.text = country['code']!;
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _checkPhone() async {
    String phone = _phoneCtrl.text;
    if (phone.length < 5) return; // Минимальная длина с кодом
    setState(() => isLoading = true);

    final result = await Api.checkUser(phone);

    if (mounted) {
      setState(() {
        isLoading = false;
        if (result['status'] == 'success') {
          userExists = result['exists'];
          if (userExists) {
            existingUsername = result['username'];
          }
          step = 2;
        }
      });
    }
  }

  void _login() async {
    if (_passwordCtrl.text.isEmpty) return;
    setState(() => isLoading = true);

    String userToAuth = userExists ? "" : _usernameCtrl.text;
    final errorMsg = await Api.auth(_phoneCtrl.text, userToAuth, _passwordCtrl.text);

    if (mounted) {
      setState(() => isLoading = false);
      if (errorMsg == null) {
        Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const MainScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    }
  }

  void _showCountryPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Выберите страну'),
        actions: countries.map((country) => CupertinoActionSheetAction(
          onPressed: () {
            _updateMask(country);
            Navigator.pop(context);
          },
          child: Text('${country['flag']} ${country['name']} (${country['code']})'),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ЛОГОТИП LUNARI
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: const [Colors.orange, Colors.red, Colors.blue, Colors.orange],
                        stops: [
                          _logoController.value - 0.2,
                          _logoController.value,
                          _logoController.value + 0.2,
                          _logoController.value + 0.4,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
                child: const Text(
                  'LUNARI',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              if (step == 1) ...[
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selectedCountry['flag']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(selectedCountry['name']!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneCtrl,
                  inputFormatters: [maskFormatter],
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: selectedCountry['mask'], 
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true, 
                    fillColor: const Color(0xFF1C1C1E), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(40),
                    color: const Color(0xFF0A84FF),
                    onPressed: isLoading ? null : _checkPhone,
                    child: isLoading 
                      ? const CupertinoActivityIndicator(color: Colors.white) 
                      : const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 32),
                  ),
                )
              ] else ...[
                Text(
                    userExists ? 'С возвращением!' : 'Регистрация',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),

                if (!userExists) ...[
                  TextField(
                    controller: _usernameCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Имя пользователя', 
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true, 
                      fillColor: const Color(0xFF1C1C1E), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Пароль', 
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true, 
                    fillColor: const Color(0xFF1C1C1E), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(40),
                    color: const Color(0xFF0A84FF),
                    onPressed: isLoading ? null : _login,
                    child: isLoading 
                      ? const CupertinoActivityIndicator(color: Colors.white) 
                      : const Icon(CupertinoIcons.check_mark, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => step = 1),
                  child: const Text('Назад', style: TextStyle(color: Colors.grey)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
