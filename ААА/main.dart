import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
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
          // Підключаємо делегати для роботи української мови в календарі
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('uk', 'UA'),
            Locale('en', 'US'),
          ],
          locale: const Locale('uk', 'UA'), // Основна локалізація за замовчуванням
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            canvasColor: const Color(0xFFF5F5F7),
            primaryColor: Colors.black,
            hintColor: Colors.black.withOpacity(0.38),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            canvasColor: Colors.black,
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
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _currentIndex > 0) {
        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && _currentIndex < 2) {
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

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
                if (context.mounted) {
                  Navigator.pop(context); 
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
                }
              }
            },
            child: Text("ЗБЕРЕГТИ ТА ПЕРЕЗАЙТИ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, child) {
          bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("СВІТЛИЙ РЕЖИМ", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.black87)),
                    Switch(
                      activeColor: isDark ? Colors.white : Colors.black,
                      value: currentMode == ThemeMode.light,
                      onChanged: (value) {
                        themeNotifier.value = value ? ThemeMode.light : ThemeMode.dark;
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);
        
        List<Widget> screens = [];

        if (widget.role == 'admin') {
          screens = [
            const AdminScreen(), 
            const EventsScreen(isAdmin: true), 
            const AdminTypesScreen()
          ];
        } else if (widget.role == 'attache') {
          screens = [
            Scaffold(
              backgroundColor: dynamicBg,
              body: Center(child: Text("ЧЕКІН", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black12))),
            ), 
            const EventsScreen(isAdmin: false), 
            const AttacheScreen()
          ];
        } else {
          screens = [
            Scaffold(
              backgroundColor: dynamicBg,
              body: Center(child: Text("КВИТОК", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black12))),
            ),
            const EventsScreen(isAdmin: false),
            ResidentScreen(
              name: widget.userData?['name'] ?? '', 
              userCode: widget.userCode,
              onOpenSettings: () => _showProfileBottomSheet(context),
            ),
          ];
        }

        return KeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Theme(
            data: isDark 
                ? ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black, canvasColor: Colors.black)
                : ThemeData.light().copyWith(scaffoldBackgroundColor: const Color(0xFFF5F5F7), canvasColor: const Color(0xFFF5F5F7)),
            child: Scaffold(
              backgroundColor: dynamicBg,
              body: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    children: screens,
                  ),
                  
                  if (widget.role != 'resident')
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: Icon(Icons.person_outline, color: isDark ? Colors.white.withOpacity(0.24) : Colors.black26, size: 28),
                        onPressed: () => _showProfileBottomSheet(context),
                      ),
                    ),

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
          ),
        );
      },
    );
  }
}

class EventsScreen extends StatelessWidget {
  final bool isAdmin;
  const EventsScreen({super.key, required this.isAdmin});

  void _showCreateTypeDialog(BuildContext context, bool isDark, Function(String) onTypeCreated) {
    final typeNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(width: 10),
            Text("НОВИЙ ТИП ЗАХОДУ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: typeNameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: "НАЗВА ТИПУ",
            labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String name = typeNameController.text.trim();
              if (name.isNotEmpty) {
                await FirebaseFirestore.instance.collection('event_types').add({
                  'name': name,
                });
                onTypeCreated(name); 
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text("ЗБЕРЕГТИ ТИП", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController(); 
    final durationController = TextEditingController(text: "2"); // Поле тривалості з дефолтним "2"
    String? selectedType;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text("СТВОРЕННЯ ЗАХОДУ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Назва заходу", 
                      labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38)
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: descriptionController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Короткий опис заходу", 
                      labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38)
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('event_types').snapshots(),
                    builder: (context, snapshot) {
                      List<DropdownMenuItem<String>> items = [];
                      if (snapshot.hasData) {
                        items = snapshot.data!.docs.map((d) {
                          return DropdownMenuItem<String>(
                            value: d['name'].toString(),
                            child: Text(d['name'].toString().toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                          );
                        }).toList();
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
                              value: selectedType,
                              hint: Text("ОБЕРІТЬ ТИП", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black26, fontSize: 14)),
                              items: items,
                              onChanged: (val) => setDialogState(() => selectedType = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.add_box_outlined, color: isDark ? Colors.white70 : Colors.black87),
                            onPressed: () => _showCreateTypeDialog(context, isDark, (newTypeName) {
                              setDialogState(() {
                                selectedType = newTypeName; 
                              });
                            }),
                          )
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  
                  // ЄДИНИЙ РЯДОК ДЛЯ ДАТИ, ЧАСУ ТА ТРИВАЛОСТІ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // БЛОК 1: ДАТА
                      Expanded(
                        flex: 5,
                        child: InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                              locale: const Locale('uk', 'UA'),
                              builder: (context, child) {
                                return Theme(
                                  data: isDark 
                                      ? ThemeData.dark().copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: Colors.white,
                                            onPrimary: Colors.black,
                                            surface: Color(0xFF0A0A0A),
                                            onSurface: Colors.white,
                                          ),
                                        )
                                      : ThemeData.light().copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Colors.black,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black,
                                          ),
                                        ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ДАТА", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: isDark ? Colors.white60 : Colors.black54),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedDate == null 
                                        ? "ОБРАТИ" 
                                        : "${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 35, width: 1, color: isDark ? Colors.white12 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 10)),
                      
                      // БЛОК 2: ЧАС
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setDialogState(() => selectedTime = pickedTime);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ЧАС", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: isDark ? Colors.white60 : Colors.black54),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedTime == null 
                                        ? "ОБРАТИ" 
                                        : selectedTime!.format(context),
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 35, width: 1, color: isDark ? Colors.white12 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 10)),
                      
                      // БЛОК 3: ТРИВАЛІСТЬ
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ТРИВАЛІСТЬ (ГОД)", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 32,
                              child: TextField(
                                controller: durationController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), // Тільки цифри та розділювачі
                                ],
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(top: 6),
                                  hintText: "напр. 2.5",
                                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty && selectedType != null && selectedDate != null) {
                          String enteredDuration = durationController.text.trim();
                          if (enteredDuration.isEmpty) enteredDuration = "2"; // Захист від порожнього поля
                          
                          // Формуємо красивий текст для відображення в списку
                          String formattedDuration = "$enteredDuration god.";

                          FirebaseFirestore.instance.collection('events').add({
                            'title': titleController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'type': selectedType,
                            'date': Timestamp.fromDate(selectedDate!),
                            'time': selectedTime != null ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}" : "Не вказано",
                            'duration': formattedDuration,
                            'active': true,
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("СТВОРЕННЯ ЗАХОДУ", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);

        return Scaffold(
          backgroundColor: dynamicBg,
          floatingActionButton: isAdmin ? Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: FloatingActionButton(
              backgroundColor: isDark ? Colors.white.withOpacity(0.12) : Colors.black12,
              onPressed: () => _showAddEventDialog(context),
              child: Icon(Icons.add, color: isDark ? Colors.white : Colors.black),
            ),
          ) : null,
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var events = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.only(top: 100, bottom: 100),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  var ev = events[index];
                  String dateStr = "";
                  if (ev['date'] != null) {
                    if (ev['date'] is Timestamp) {
                      DateTime dt = (ev['date'] as Timestamp).toDate();
                      dateStr = "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
                    } else {
                      dateStr = ev['date'].toString();
                    }
                  }
                  
                  Map<String, dynamic> data = ev.data() as Map<String, dynamic>;
                  String timeStr = data.containsKey('time') ? " o ${data['time']}" : "";
                  String durationStr = data.containsKey('duration') ? " (${data['duration']})" : "";
                  
                  // Робимо так, щоб префікс типу не вилазив, якщо опис порожній
                  String descStr = data.containsKey('description') && data['description'].toString().isNotEmpty 
                      ? "${data['description'].toString().toUpperCase()} | " 
                      : "";
                  
                  // Змінна typeStr залишається для уникнення видалення коду, але ніде не виводиться в інтерфейс
                  // ignore: unused_local_variable
                  String typeStr = ev['type'] != null ? "[${ev['type'].toString().toUpperCase()}] " : "";
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0E0E0E) : Colors.white,
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12), 
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${ev['title'].toString().toUpperCase()}", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              Text("$descStr$dateStr$timeStr$durationStr", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (isAdmin) IconButton(icon: Icon(Icons.delete_outline, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black26), onPressed: () => ev.reference.delete())
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
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
    try {
      var doc = await FirebaseFirestore.instance.collection('residents').doc(code).get();
      if (doc.exists && mounted) {
        String role = doc.data()?['role'] ?? 'resident';
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainShell(role: role, userData: doc.data(), userCode: code)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Помилка бази: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);
        return Scaffold(
          backgroundColor: dynamicBg,
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
                    keyboardType: TextInputType.number, 
                    onSubmitted: (_) => _login(), 
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
      },
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);
        return Scaffold(
          backgroundColor: dynamicBg,
          body: Padding(
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
          ),
        );
      },
    );
  }
}

class AdminTypesScreen extends StatefulWidget {
  const AdminTypesScreen({super.key});
  @override
  State<AdminTypesScreen> createState() => _AdminTypesScreenState();
}

class _AdminTypesScreenState extends State<AdminTypesScreen> {
  final _typeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);
        return Scaffold(
          backgroundColor: dynamicBg,
          body: Padding(
            padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("КЕРУВАННЯ ТИПАМИ ЗАХОДІВ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _typeController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: "Новий тип заходу",
                          labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white12 : Colors.black12, foregroundColor: isDark ? Colors.white : Colors.black),
                      onPressed: () async {
                        if (_typeController.text.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('event_types').add({
                            'name': _typeController.text.trim(),
                          });
                          _typeController.clear();
                        }
                      },
                      child: const Text("ДОДАТИ"),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('event_types').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      return ListView(
                        children: snapshot.data!.docs.map((d) => ListTile(
                          title: Text(d['name'].toString().toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, letterSpacing: 1, fontSize: 14)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: isDark ? Colors.white.withOpacity(0.24) : Colors.black26),
                            onPressed: () => d.reference.delete(),
                          ),
                        )).toList(),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class ResidentScreen extends StatelessWidget {
  final String name;
  final String userCode;
  final VoidCallback onOpenSettings;

  const ResidentScreen({
    super.key, 
    required this.name, 
    required this.userCode,
    required this.onOpenSettings
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);
        return Scaffold(
          backgroundColor: dynamicBg,
          body: Stack(
            children: [
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
                    Text("КОД: $userCode", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AttacheScreen extends StatelessWidget {
  const AttacheScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);
        return Scaffold(
          backgroundColor: dynamicBg,
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('residents').where('role', isEqualTo: 'resident').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView(
                padding: const EdgeInsets.only(top: 100),
                children: snapshot.data!.docs.map((d) => ListTile(
                  title: Text(d['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                )).toList(),
              );
            },
          ),
        );
      },
    );
  }
}