import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyAv0cWrxWEV-FQwjoKKOwxuYf5wusF-wZc",
  authDomain: "nedialkov-brand.firebaseapp.com",
  projectId: "nedialkov-brand",
  storageBucket: "nedialkov-brand.firebasestorage.app",
  messagingSenderId: "344209174163",
  appId: "1:344209174163:web:9aaa3df05e307abd6b2766",
);

// Глобальний нотифікатор для зміни теми (День/Ніч)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const MyApp());
}

// Кастомний ScrollBehavior для підтримки гортання мишкою на ПК
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: AppScrollBehavior(),
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            primaryColor: Colors.black,
            hintColor: Colors.black.withOpacity(0.38),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            primaryColor: Colors.white,
            hintColor: Colors.white.withOpacity(0.24),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final String role;
  final Map<String, dynamic>? userData;
  final String userCode;
  const MainShell({super.key, required this.role, this.userData, required this.userCode});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1; // Запуск на центральній сторінці (Заходи)
  late PageController _pageController;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1); // Початкова сторінка — центр
  }

  @override
  void dispose() {
    _pageController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // Обробка стрілочок на ПК
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _currentIndex > 0) {
        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && _currentIndex < 2) {
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  // Окреме вікно для зміни коду доступу
  void _showChangeCodeDialog(BuildContext context, bool isDark) {
    final newCodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("ЗМІНА КОДУ ДОСТУПУ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        content: TextField(
          controller: newCodeController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "НОВИЙ ЦИФРОВИЙ КОД",
            labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.38) : Colors.black45, fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("СКАСУВАТИ", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
          ),
          TextButton(
            onPressed: () async {
              String newCode = newCodeController.text.trim();
              if (newCode.isNotEmpty) {
                var oldDocRef = FirebaseFirestore.instance.collection('residents').doc(widget.userCode);
                var oldDoc = await oldDocRef.get();
                if (oldDoc.exists) {
                  await FirebaseFirestore.instance.collection('residents').doc(newCode).set(oldDoc.data()!);
                  await oldDocRef.delete();
                }
                Navigator.pop(context); // закрити діалог
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
              }
            },
            child: Text("ЗБЕРЕГТИ ТА ПЕРЕЗАЙТИ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Шторка налаштувань профілю (для адміна/аташе або загальних опцій теми)
  void _showProfileBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("НАЛАШТУВАННЯ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
              const SizedBox(height: 20),
              Text("РОЛЬ: ${widget.role.toUpperCase()}", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.38) : Colors.black45, fontSize: 12)),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              // Перемикач теми день/ніч
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("СВІТЛИЙ РЕЖИМ", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.black87)),
                  Switch(
                    activeColor: isDark ? Colors.white : Colors.black,
                    value: themeNotifier.value == ThemeMode.light,
                    onChanged: (value) {
                      themeNotifier.value = value ? ThemeMode.light : ThemeMode.dark;
                      setModalState(() {
                        isDark = !value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (widget.userCode != "0000") ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("ЗМІНИТИ КОД ДОСТУПУ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white24 : Colors.black26),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangeCodeDialog(context, isDark);
                  },
                ),
              ],
              const Divider(color: Colors.white10),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                  label: const Text("ВИЙТИ З АКАУНТУ", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
                  },
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<Widget> screens = [];

    // Динамічний розподіл екранів залежно від ролі
    if (widget.role == 'admin') {
      screens = [
        const AdminScreen(), 
        const EventsScreen(isAdmin: true), 
        Center(child: Text("СТАТ", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black12)))
      ];
    } else if (widget.role == 'attache') {
      screens = [
        Center(child: Text("ЧЕКІН", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black12))), 
        const EventsScreen(isAdmin: false), 
        const AttacheScreen()
      ];
    } else {
      // КЛІЄНТ: 1 - Квиток, 2 - Заходи, 3 - Профіль
      screens = [
        Center(child: Text("КВИТОК", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black12))),
        const EventsScreen(isAdmin: false),
        ResidentScreen(
          name: widget.userData?['name'] ?? '', 
          points: widget.userData?['points'] ?? 0,
          userCode: widget.userCode,
          onOpenSettings: () => _showProfileBottomSheet(context, isDark),
        ),
      ];
    }

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: screens,
            ),
            
            // Верхня кнопка налаштувань показується тільки для Адміна та Аташе
            if (widget.role != 'resident')
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.person_outline, color: isDark ? Colors.white.withOpacity(0.24) : Colors.black26, size: 28),
                  onPressed: () => _showProfileBottomSheet(context, isDark),
                ),
              ),

            // Навігаційні точки (тире) знизу
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  bool isActive = _currentIndex == index;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      height: 4,
                      width: isActive ? 24 : 4,
                      decoration: BoxDecoration(
                        color: isActive 
                            ? (isDark ? Colors.white : Colors.black) 
                            : (isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventsScreen extends StatelessWidget {
  final bool isAdmin;
  const EventsScreen({super.key, required this.isAdmin});

  void _addEvent(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final title = TextEditingController();
    final price = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title, 
              style: TextStyle(color: isDark ? Colors.white : Colors.black), 
              decoration: InputDecoration(labelText: "Назва заходу", labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38)),
            ),
            TextField(
              controller: price, 
              style: TextStyle(color: isDark ? Colors.white : Colors.black), 
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(labelText: "Вартість (бали)", labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                if (title.text.isNotEmpty) {
                  FirebaseFirestore.instance.collection('events').add({
                    'title': title.text,
                    'price': int.tryParse(price.text) ?? 0,
                    'active': true,
                  });
                  Navigator.pop(context);
                }
              },
              child: Text("СТВОРИТИ", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      floatingActionButton: isAdmin ? Padding(
        padding: const EdgeInsets.only(bottom: 60), 
        child: FloatingActionButton(
          backgroundColor: isDark ? Colors.white.withOpacity(0.12) : Colors.black12,
          onPressed: () => _addEvent(context),
          child: Icon(Icons.add, color: isDark ? Colors.white : Colors.black),
        ),
      ) : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var events = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 100),
            itemCount: events.length,
            itemBuilder: (context, index) {
              var ev = events[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12), 
                  borderRadius: BorderRadius.circular(15)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ev['title'].toString().toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Text("${ev['price']} БАЛІВ", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38, fontSize: 12)),
                    ]),
                    if (isAdmin) IconButton(icon: Icon(Icons.delete_outline, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black26), onPressed: () => ev.reference.delete())
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _codeController = TextEditingController();

  void _login() async {
    String code = _codeController.text.trim();
    if (code == "0000") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell(role: 'admin', userCode: "0000")));
      return;
    }
    var doc = await FirebaseFirestore.instance.collection('residents').doc(code).get();
    if (doc.exists) {
      String role = doc.data()?['role'] ?? 'resident';
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainShell(role: role, userData: doc.data(), userCode: code)));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("NEDIÁLKOV", style: TextStyle(color: isDark ? Colors.white : Colors.black, letterSpacing: 8, fontSize: 20)),
            const SizedBox(height: 40),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                keyboardType: TextInputType.number, // Числова клавіатура на смартфонах
                onSubmitted: (_) => _login(), // Обробка Enter на ПК клавіатурі
                decoration: InputDecoration(
                  hintText: "ВВЕДІТЬ КОД", 
                  hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black26),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _login, 
              child: Text("УВІЙТИ", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _nCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  String _role = 'resident';

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
      child: Column(
        children: [
          TextField(controller: _nCtrl, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(labelText: "ПІБ", labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38))),
          TextField(controller: _cCtrl, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(labelText: "КОД", labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38))),
          Row(children: [
            Radio(value: 'resident', groupValue: _role, onChanged: (v) => setState(() => _role = v!), activeColor: isDark ? Colors.white : Colors.black),
            Text("Клієнт", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            const SizedBox(width: 20),
            Radio(value: 'attache', groupValue: _role, onChanged: (v) => setState(() => _role = v!), activeColor: isDark ? Colors.white : Colors.black),
            Text("Аташе", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ]),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white.withOpacity(0.12) : Colors.black12, foregroundColor: isDark ? Colors.white : Colors.black),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('residents').doc(_cCtrl.text.trim()).set({
                'name': _nCtrl.text.trim(),
                'role': _role,
                'points': _role == 'resident' ? 0 : null,
              });
              _nCtrl.clear(); _cCtrl.clear();
            }, 
            child: const Text("ЗБЕРЕГТИ")
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('residents').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView(children: snapshot.data!.docs.map((d) => ListTile(
                  title: Text(d['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text("${d['role']} - ID: ${d.id}", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38)),
                  trailing: IconButton(icon: Icon(Icons.delete, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12), onPressed: () => d.reference.delete()),
                )).toList());
              },
            ),
          )
        ],
      ),
    );
  }
}

// ЕКРАН КЛІЄНТА (Тепер є повноцінною третьою вкладкою профілю)
class ResidentScreen extends StatelessWidget {
  final String name;
  final dynamic points;
  final String userCode;
  final VoidCallback onOpenSettings;

  const ResidentScreen({
    super.key, 
    required this.name, 
    this.points, 
    required this.userCode,
    required this.onOpenSettings
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Іконка налаштувань у верхньому правому кутку вкладки
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white24 : Colors.black26, size: 26),
              onPressed: onOpenSettings,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("${points ?? 0} БАЛІВ", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54, fontSize: 15)),
                const SizedBox(height: 4),
                Text("КОД: $userCode", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AttacheScreen extends StatelessWidget {
  const AttacheScreen({super.key});
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('residents').where('role', isEqualTo: 'resident').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.only(top: 100),
          children: snapshot.data!.docs.map((d) => ListTile(
            title: Text(d['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            subtitle: Text("БАЛИ: ${d['points']}", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38)),
          )).toList(),
        );
      },
    );
  }
}