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

// Глобальний нотифікатор для зміни теми (Першочергово — Світла)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

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
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('uk', 'UA'),
            Locale('en', 'US'),
          ],
          locale: const Locale('uk', 'UA'),
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
  int _currentIndex = 1; 
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
                Text("РОЛЬ: ${widget.role.toUpperCase()}", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.black45, fontSize: 12)),
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
    final typeDescController = TextEditingController();
    
    bool componentSeating = false;
    bool componentMenu = false;
    bool componentStaffCall = false;

    int currentDialogPage = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 10),
              Text(
                "OVL-DLG-NEW-CATEGORY (СТОРІНКА $currentDialogPage/2)", 
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)
              ),
            ],
          ),
          content: SizedBox(
            width: 340,
            child: currentDialogPage == 1 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("СТОРІНКА 1: ОСНОВНА ІНФОРМАЦІЯ", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: typeNameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "1- НАЗВА КАТЕГОРІЇ",
                        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: typeDescController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "2- ОПИС КАТЕГОРІЇ",
                        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("СТОРІНКА 2: ОБЕРІТЬ КОМПОНЕНТИ", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Icon(Icons.grid_on_outlined, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Розсадка (Графічна карта залу)", style: TextStyle(fontSize: 13))),
                        ],
                      ),
                      value: componentSeating,
                      activeColor: isDark ? Colors.white : Colors.black,
                      checkColor: isDark ? Colors.black : Colors.white,
                      onChanged: (val) => setDialogState(() => componentSeating = val ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Icon(Icons.restaurant_menu, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Menu (Наповнення у стилі Glovo)", style: TextStyle(fontSize: 13))),
                        ],
                      ),
                      value: componentMenu,
                      activeColor: isDark ? Colors.white : Colors.black,
                      checkColor: isDark ? Colors.black : Colors.white,
                      onChanged: (val) => setDialogState(() => componentMenu = val ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Icon(Icons.notifications_active_outlined, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Кнопка виклику (Прив'язка до Аташе)", style: TextStyle(fontSize: 13))),
                        ],
                      ),
                      value: componentStaffCall,
                      activeColor: isDark ? Colors.white : Colors.black,
                      checkColor: isDark ? Colors.black : Colors.white,
                      onChanged: (val) => setDialogState(() => componentStaffCall = val ?? false),
                    ),
                  ],
                ),
          ),
          actions: [
            if (currentDialogPage == 1)
              TextButton(
                onPressed: () {
                  if (typeNameController.text.trim().isNotEmpty) {
                    setDialogState(() => currentDialogPage = 2);
                  }
                },
                child: Text("ДАЛІ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              )
            else ...[
              TextButton(
                onPressed: () => setDialogState(() => currentDialogPage = 1),
                child: Text("НАЗАД", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
              ),
              TextButton(
                onPressed: () async {
                  String name = typeNameController.text.trim();
                  String desc = typeDescController.text.trim();
                  if (name.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('event_types').add({
                      'name': name,
                      'description': desc,
                      'has_seating': componentSeating,
                      'has_menu': componentMenu,
                      'has_staff_call': componentStaffCall,
                    });
                    onTypeCreated(name); 
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: Text("ЗБЕРЕГТИ КАТЕГОРІЮ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Future<bool> _askToConfirmDelete(BuildContext context, bool isDark) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("УВАГА", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        content: const Text("Точно видалити?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("НІ", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ТАК", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  void _showEditEventDialog(BuildContext context, DocumentSnapshot eventDoc) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
    
    final titleController = TextEditingController(text: data['title']?.toString() ?? "");
    final descriptionController = TextEditingController(text: data['description']?.toString() ?? ""); 
    
    String rawDuration = "2";
    if (data['duration'] != null) {
      rawDuration = data['duration'].toString().replaceAll(" god.", "").trim();
    }
    final durationController = TextEditingController(text: rawDuration);
    
    String? selectedType = data['type']?.toString();
    DateTime? selectedDate;
    if (data['date'] != null && data['date'] is Timestamp) {
      selectedDate = (data['date'] as Timestamp).toDate();
    }
    
    TimeOfDay? selectedTime;
    if (data['time'] != null && data['time'].toString().contains(":")) {
      try {
        final parts = data['time'].toString().split(":");
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }

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
                      Text("РЕДАГУВАННЯ ЗАХОДУ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        onPressed: () async {
                          bool sure = await _askToConfirmDelete(context, isDark);
                          if (sure) {
                            await eventDoc.reference.delete();
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
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
                              hint: Text("ОБЕРІТЬ КАТЕГОРІЮ", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black26, fontSize: 14)),
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
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
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
                      
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
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
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), 
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
                      onPressed: () async {
                        if (titleController.text.isNotEmpty && selectedType != null && selectedDate != null) {
                          String enteredDuration = durationController.text.trim();
                          if (enteredDuration.isEmpty) enteredDuration = "2";
                          String formattedDuration = "$enteredDuration god.";

                          await eventDoc.reference.update({
                            'title': titleController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'type': selectedType,
                            'date': Timestamp.fromDate(selectedDate!),
                            'time': selectedTime != null ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}" : "Не вказано",
                            'duration': formattedDuration,
                          });
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text("ЗБЕРЕГТИ ЗМІНИ", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  void _showAddEventDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEventWizardPage()),
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
            stream: FirebaseFirestore.instance.collection('events').orderBy('date').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    "НЕМАЄ ЗАХОДІВ", 
                    style: TextStyle(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black12, letterSpacing: 4, fontSize: 16)
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 100, bottom: 120, left: 16, right: 16),
                itemCount: docs.length,
                itemBuilder: (context, idx) {
                  var data = docs[idx].data() as Map<String, dynamic>;
                  String title = data['title'] ?? "Без назви";
                  String type = (data['type'] ?? "Загальний").toString().toUpperCase();
                  String time = data['time'] ?? "00:00";
                  String duration = data['duration'] ?? "2 god.";
                  
                  String dateStr = "";
                  if (data['date'] != null && data['date'] is Timestamp) {
                    DateTime dt = (data['date'] as Timestamp).toDate();
                    dateStr = "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}";
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: InkWell(
                      onTap: isAdmin ? () => _showEditEventDialog(context, docs[idx]) : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateStr, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(time, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
                              Text(duration, style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(type, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                const SizedBox(height: 4),
                                Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 15, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class CreateEventWizardPage extends StatefulWidget {
  const CreateEventWizardPage({super.key});

  @override
  State<CreateEventWizardPage> createState() => _CreateEventWizardPageState();
}

class _CreateEventWizardPageState extends State<CreateEventWizardPage> {
  int _step = 1;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: "2");
  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  Map<String, dynamic>? _selectedSeatingTemplate; 

  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: dynamicBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "СТВОРЕННЯ ЗАХОДУ (КРОК $_step/2)", 
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _step == 1 ? _buildStep1(isDark) : _buildStep2(isDark),
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("КРОК 1: ОСНОВНІ ДАНІ ТА КАТЕГОРІЯ", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _titleController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: "Назва заходу", 
            labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38)
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _descriptionController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: "Короткий опис заходу", 
            labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black38)
          ),
        ),
        const SizedBox(height: 25),
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
            return DropdownButtonFormField<String>(
              dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
              value: _selectedCategory,
              hint: Text("ОБЕРІТЬ КАТЕГОРІЮ", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.24) : Colors.black26, fontSize: 14)),
              items: items,
              onChanged: (val) => setState(() => _selectedCategory = val),
            );
          },
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black12),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                  locale: const Locale('uk', 'UA'),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Text(_selectedDate == null ? "ОБРАТИ ДАТУ" : "${_selectedDate!.day}.${_selectedDate!.month}", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black12),
              onPressed: () async {
                TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) setState(() => _selectedTime = picked);
              },
              child: Text(_selectedTime == null ? "ОБРАТИ ЧАС" : _selectedTime!.format(context), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white24 : Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16)
            ),
            onPressed: () {
              if (_titleController.text.isNotEmpty && _selectedCategory != null && _selectedDate != null) {
                setState(() => _step = 2);
              }
            },
            child: const Text("ДАЛІ (ВИБІР РОЗСАДКИ)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("КРОК 2: МОДУЛЬ РОЗСАДКИ ТА СХЕМ ЗАЛУ", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedSeatingTemplate == null ? "ШАБЛОН СХЕМИ НЕ ОБРАНО" : "ОБРАНО ШАБЛОН: ${_selectedSeatingTemplate!['name'].toString().toUpperCase()}",
                style: TextStyle(fontWeight: FontWeight.bold, color: _selectedSeatingTemplate == null ? Colors.amber : Colors.green, fontSize: 13)
              ),
              if (_selectedSeatingTemplate != null) ...[
                const SizedBox(height: 6),
                Text("Елементів залу: ${(_selectedSeatingTemplate!['elements'] as List).length}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        Text("ОБЕРІТЬ НАЯВНИЙ ШАБЛОН:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black45)),
        const SizedBox(height: 10),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('seating_templates').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            var templates = snapshot.data!.docs;
            if (templates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text("Немає створених шаблонів розсадки. Створіть свій перший шаблон!", style: TextStyle(fontSize: 12, color: Colors.grey)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              itemBuilder: (ctx, i) {
                var tData = templates[i].data() as Map<String, dynamic>;
                bool isThis = _selectedSeatingTemplate?['id'] == templates[i].id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tData['name'] ?? 'Без назви', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                  // ФІКС ПОМИЛКИ 1: Змінено неіснуючий Icons.circle_outline на стандартний Icons.circle
                  trailing: isThis ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.circle, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      _selectedSeatingTemplate = {
                        'id': templates[i].id,
                        'name': tData['name'],
                        'elements': tData['elements'] ?? []
                      };
                    });
                  },
                );
              },
            );
          },
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        const SizedBox(height: 10),

        Center(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black,
              side: BorderSide(color: isDark ? Colors.white38 : Colors.black38)
            ),
            icon: const Icon(Icons.developer_board),
            label: const Text("СТВОРИТИ НОВИЙ ШАБЛОН РОЗСАДКИ"),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeatingConstructorPage()),
              );
              setState(() {}); 
            },
          ),
        ),

        const SizedBox(height: 60),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16)
            ),
            onPressed: () async {
              String name = _titleController.text.trim();
              String desc = _descriptionController.text.trim();
              String duration = "${_durationController.text.trim()} god.";
              
              if (name.isNotEmpty && _selectedCategory != null && _selectedDate != null) {
                await FirebaseFirestore.instance.collection('events').add({
                  'title': name,
                  'description': desc,
                  'type': _selectedCategory,
                  'date': Timestamp.fromDate(_selectedDate!),
                  'time': _selectedTime != null ? "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}" : "Не вказано",
                  'duration': duration,
                  'active': true,
                  'seating_template_id': _selectedSeatingTemplate?['id'] ?? '',
                });
                if (mounted) {
                  Navigator.pop(context); 
                }
              }
            },
            child: const Text("ФІНАЛІЗУВАТИ ТА СТВОРИТИ ЗАХІД", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}

class SeatingConstructorPage extends StatefulWidget {
  const SeatingConstructorPage({super.key});

  @override
  State<SeatingConstructorPage> createState() => _SeatingConstructorPageState();
}

class _SeatingConstructorPageState extends State<SeatingConstructorPage> {
  final _templateNameController = TextEditingController();
  final List<Map<String, dynamic>> _constructedElements = [];

  void _addElement(String type, {int maxSeats = 1}) {
    setState(() {
      _constructedElements.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type, 
        'max_seats': maxSeats,
        'registered_tickets': 0, 
        'label': type == 'single' 
            ? "Місце ${_constructedElements.length + 1}"
            : type == 'vip' ? "VIP ${_constructedElements.length + 1}" : "Стіл (Max: $maxSeats осіб)",
      });
    });
  }

  void _showAddTableDialog() {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    final countController = TextEditingController(text: "3");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: const Text("КІЛЬКІСТЬ СТІЛЬЦІВ БІЛЯ СТОЛУ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: countController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Наприклад: 3 або 4"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("СКАСУВАТИ")),
          TextButton(
            onPressed: () {
              int val = int.tryParse(countController.text) ?? 3;
              _addElement('table', maxSeats: val);
              Navigator.pop(ctx);
            },
            child: const Text("ДОДАТИ", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: dynamicBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("КОНСТРУКТОР СХЕМИ РОЗСАДКИ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () async {
              String tName = _templateNameController.text.trim();
              if (tName.isNotEmpty && _constructedElements.isNotEmpty) {
                await FirebaseFirestore.instance.collection('seating_templates').add({
                  'name': tName,
                  'elements': _constructedElements,
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("ЗБЕРЕГТИ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _templateNameController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: const InputDecoration(
                labelText: "НАЗВА ШАБЛОНУ ЗАЛУ",
                labelStyle: TextStyle(fontSize: 12),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Wrap(
              spacing: 10,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.chair_alt, size: 16),
                  label: const Text("Одинарне місце"),
                  onPressed: () => _addElement('single'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.table_restaurant, size: 16),
                  label: const Text("+ Стіл з місцями"),
                  onPressed: _showAddTableDialog,
                ),
                ActionChip(
                  avatar: const Icon(Icons.stars, size: 16, color: Colors.amber),
                  label: const Text("VIP місце"),
                  onPressed: () => _addElement('vip'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          Expanded(
            child: _constructedElements.isEmpty 
              ? Center(child: Text("В залі порожньо. Додайте стільці чи столи!", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3
                  ),
                  itemCount: _constructedElements.length,
                  itemBuilder: (ctx, i) {
                    var el = _constructedElements[i];
                    Color cardColor = Colors.grey.withOpacity(0.2);
                    IconData icon = Icons.event_seat;
                    if (el['type'] == 'vip') {
                      cardColor = Colors.amber.withOpacity(0.2);
                      icon = Icons.star;
                    } else if (el['type'] == 'table') {
                      cardColor = Colors.blue.withOpacity(0.2);
                      icon = Icons.blur_circular_rounded;
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8),
                        // ФІКС ПОМИЛКИ 2: Замінено неіснуючий Colors.black10 на Colors.black12
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                          const SizedBox(height: 4),
                          // ФІКС ПОМИЛКИ 3: Замінено неіснуючий CenterAxisAlignment.center на правильний TextAlign.center
                          Text(el['label'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<bool> _askToConfirm(BuildContext context, bool isDark) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("ПІДТВЕРДЖЕННЯ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        content: const Text("Точно видалити?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("НІ", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ТАК", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  void _showAddResidentDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    String selectedRole = 'resident';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("НОВИЙ КОРИСТУВАЧ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "ПІБ",
                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "КОД ДОСТУПУ (УНІКАЛЬНИЙ)",
                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
                value: selectedRole,
                items: [
                  DropdownMenuItem(value: 'resident', child: Text("РЕЗИДЕНТ", style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                  DropdownMenuItem(value: 'attache', child: Text("АТАШЕ", style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                  DropdownMenuItem(value: 'admin', child: Text("АДМІНІСТРАТОР", style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                ],
                onChanged: (val) => setDialogState(() => selectedRole = val ?? 'resident'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String name = nameController.text.trim();
                String code = codeController.text.trim();
                if (name.isNotEmpty && code.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('residents').doc(code).set({
                    'name': name,
                    'role': selectedRole,
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text("СТВОРИТИ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
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
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: FloatingActionButton(
              backgroundColor: isDark ? Colors.white.withOpacity(0.12) : Colors.black12,
              onPressed: () => _showAddResidentDialog(context, isDark),
              child: Icon(Icons.person_add_alt_1, color: isDark ? Colors.white : Colors.black),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('residents').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.only(top: 100, bottom: 120, left: 16, right: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var res = docs[index].data() as Map<String, dynamic>;
                  String code = docs[index].id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(res['name'] ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    subtitle: Text("РОЛЬ: ${(res['role'] ?? '').toString().toUpperCase()} | КОД: $code", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () async {
                        bool sure = await _askToConfirm(context, isDark);
                        if (sure) {
                          await docs[index].reference.delete();
                        }
                      },
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

class AdminTypesScreen extends StatelessWidget {
  const AdminTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);
        
        return Scaffold(
          backgroundColor: dynamicBg,
          body: ListView(
            padding: const EdgeInsets.only(top: 100, bottom: 120, left: 16, right: 16),
            children: [
              Card(
                color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(Icons.category_outlined, color: isDark ? Colors.white : Colors.black, size: 28),
                  title: Text(
                    "КАТЕГОРІЇ", 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)
                  ),
                  subtitle: const Text("Налаштування, створення та редагування категорій заходів", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageCategoriesFullScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // ФІКС ПОМИЛКИ 4: Оскільки у Card немає параметра opacity, обгортаємо Card в Opacity-віджет
              Opacity(
                opacity: 0.5,
                child: Card(
                  color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: const ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Icon(Icons.layers_outlined, size: 28),
                    title: Text("МЕНЕДЖЕР МОДУЛІВ (СКОРО)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class ManageCategoriesFullScreen extends StatelessWidget {
  const ManageCategoriesFullScreen({super.key});

  Future<bool> _askToConfirm(BuildContext context, bool isDark) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("УВАГА", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        content: const Text("Точно видалити категорію?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("НІ", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ТАК", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    Color dynamicBg = isDark ? Colors.black : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: dynamicBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("КЕРУВАННЯ КАТЕГОРІЯМИ", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? Colors.white.withOpacity(0.12) : Colors.black12,
        onPressed: () {
          const EventsScreen(isAdmin: true)._showCreateTypeDialog(context, isDark, (_) {});
        },
        child: Icon(Icons.add, color: isDark ? Colors.white : Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('event_types').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("КАТЕГОРІЙ НЕ ЗНАЙДЕНО", style: TextStyle(color: Colors.grey, letterSpacing: 2)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String name = data['name'] ?? '';
              bool hasSeating = data['has_seating'] ?? false;
              bool hasMenu = data['has_menu'] ?? false;
              bool hasStaff = data['has_staff_call'] ?? false;

              return Card(
                color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                child: ListTile(
                  title: Text(name.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, letterSpacing: 1, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Компоненти: [Розсадка: ${hasSeating ? 'Так' : 'Ні'}] [Меню: ${hasMenu ? 'Так' : 'Ні'}] [Виклик: ${hasStaff ? 'Так' : 'Ні'}]",
                    style: const TextStyle(fontSize: 10, color: Colors.grey)
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () async {
                      bool sure = await _askToConfirm(context, isDark);
                      if (sure) {
                        await docs[index].reference.delete();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
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
              var docs = snapshot.data!.docs;
              return ListView(
                padding: const EdgeInsets.only(top: 100, bottom: 120),
                children: docs.map((d) => ListTile(
                  title: Text(d['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  subtitle: const Text("ЗАКРІПЛЕНИЙ РЕЗИДЕНТ", style: TextStyle(fontSize: 10, color: Colors.grey)),
                )).toList(),
              );
            },
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
  const ResidentScreen({super.key, required this.name, required this.userCode, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark || (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
        return Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.lens_blur_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 28),
                  onPressed: onOpenSettings,
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, letterSpacing: 4, fontSize: 18, fontWeight: FontWeight.bold)),
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _codeController = TextEditingController();

  void _login() async {
    String enteredCode = _codeController.text.trim();
    if (enteredCode.isEmpty) return;

    if (enteredCode == "0000") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell(role: 'admin', userCode: "0000")),
      );
      return;
    }

    var doc = await FirebaseFirestore.instance.collection('residents').doc(enteredCode).get();
    if (doc.exists && mounted) {
      Map<String, dynamic> data = doc.data()!;
      String role = data['role'] ?? 'resident';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainShell(role: role, userData: data, userCode: enteredCode)),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("НЕВІРНИЙ КОД ДОСТУПУ"), backgroundColor: Colors.redAccent),
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