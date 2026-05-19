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

    bool hasSeating = data['has_seating'] ?? true;
    bool hasMenu = data['has_menu'] ?? false;
    bool hasStaffCall = data['has_staff_call'] ?? false;

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
                  const SizedBox(height: 20),
                  
                  Text("АКТИВНІ МОДУЛІ ЗАХОДУ", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 5),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Графічна карта розсадки залу", style: TextStyle(fontSize: 13)),
                    value: hasSeating,
                    activeColor: isDark ? Colors.white : Colors.black,
                    onChanged: (v) => setDialogState(() => hasSeating = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Меню замовлень (Glovo-style)", style: TextStyle(fontSize: 13)),
                    value: hasMenu,
                    activeColor: isDark ? Colors.white : Colors.black,
                    onChanged: (v) => setDialogState(() => hasMenu = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Модуль виклику персоналу / Аташе", style: TextStyle(fontSize: 13)),
                    value: hasStaffCall,
                    activeColor: isDark ? Colors.white : Colors.black,
                    onChanged: (v) => setDialogState(() => hasStaffCall = v ?? false),
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
                            'time': selectedTime != null 
                                ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}" 
                                : "Не вказано",
                            'duration': formattedDuration,
                            'has_seating': hasSeating,
                            'has_menu': hasMenu,
                            'has_staff_call': hasStaffCall,
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

                  bool explicitSeating = data['has_seating'] ?? true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: InkWell(
                      onTap: () {
                        if (isAdmin) {
                          _showEditEventDialog(context, docs[idx]);
                        } else if (explicitSeating) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InteractiveSeatingPage(eventDocId: docs[idx].id),
                            ),
                          );
                        }
                      },
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
        TextField(
          controller: _titleController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(labelText: "Назва заходу", labelStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black38)),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _descriptionController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(labelText: "Короткий опис", labelStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black38)),
        ),
        const SizedBox(height: 25),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('event_types').snapshots(),
          builder: (context, snapshot) {
            List<DropdownMenuItem<String>> items = [];
            if (snapshot.hasData) {
              items = snapshot.data!.docs.map((d) => DropdownMenuItem<String>(
                value: d['name'].toString(),
                child: Text(d['name'].toString().toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              )).toList();
            }
            return DropdownButtonFormField<String>(
              dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
              value: _selectedCategory,
              hint: Text("ОБЕРІТЬ КАТЕГОРІЮ", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26)),
              items: items,
              onChanged: (val) => setState(() => _selectedCategory = val),
            );
          },
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text("ДАТА", style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black54)),
                subtitle: Text(_selectedDate == null ? "Обрати" : "${_selectedDate!.day}.${_selectedDate!.month}"),
                onTap: () async {
                  DateTime? d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030));
                  if (d != null) setState(() => _selectedDate = d);
                },
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text("ЧАС", style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black54)),
                subtitle: Text(_selectedTime == null ? "Обрати" : _selectedTime!.format(context)),
                onTap: () async {
                  TimeOfDay? t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t != null) setState(() => _selectedTime = t);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(labelText: "Тривалість (годин)", labelStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black38)),
        ),
        const SizedBox(height: 40),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty && _selectedCategory != null && _selectedDate != null) {
                setState(() => _step = 2);
              }
            },
            child: const Text("ПЕРЕЙТИ ДО ШАБЛОНУ РОЗСАДКИ"),
          ),
        )
      ],
    );
  }

  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ОБЕРІТЬ СХЕМУ ЗАЛУ:", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListTile(
          title: const Text("Порожній зал (Створення розсадки з нуля)"),
          leading: Icon(Icons.crop_free, color: isDark ? Colors.white : Colors.black),
          onTap: () => _finalizeEvent(null),
        ),
        const Divider(),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('seating_templates').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            var templates = snapshot.data!.docs;
            if (templates.isEmpty) return const Text("Немає збережених шаблонів схем.");
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              itemBuilder: (context, idx) {
                var tData = templates[idx].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(tData['name'] ?? "Шаблон"),
                  leading: const Icon(Icons.table_bar_outlined),
                  onTap: () => _finalizeEvent(tData['elements']),
                );
              },
            );
          },
        )
      ],
    );
  }

  void _finalizeEvent(dynamic elements) async {
    String formattedDuration = "${_durationController.text.trim()} god.";
    DocumentReference newEventRef = await FirebaseFirestore.instance.collection('events').add({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedCategory,
      'date': Timestamp.fromDate(_selectedDate!),
      'time': _selectedTime != null ? "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}" : "00:00",
      'duration': formattedDuration,
      'has_seating': true,
      'has_menu': false,
      'has_staff_call': false,
      'price_vip': 1000,
      'price_standard': 500,
      'price_budget': 250,
    });

    if (elements != null && elements is List) {
      var seatingCol = newEventRef.collection('seating');
      for (var el in elements) {
        await seatingCol.add(Map<String, dynamic>.from(el));
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class InteractiveSeatingPage extends StatefulWidget {
  final String eventDocId;
  const InteractiveSeatingPage({super.key, required this.eventDocId});

  @override
  State<InteractiveSeatingPage> createState() => _InteractiveSeatingPageState();
}

class _InteractiveSeatingPageState extends State<InteractiveSeatingPage> {
  String _selectedTool = 'select'; 
  String _selectedTier = 'standard'; 
  bool _snapToGrid = true; 
  bool _showPriceSidebar = false; 

  Offset _dragTouchOffset = Offset.zero;

  final _vipPriceController = TextEditingController();
  final _standardPriceController = TextEditingController();
  final _budgetPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentPrices();
  }

  void _loadCurrentPrices() async {
    var doc = await FirebaseFirestore.instance.collection('events').doc(widget.eventDocId).get();
    if (doc.exists) {
      var d = doc.data()!;
      setState(() {
        _vipPriceController.text = (d['price_vip'] ?? 1000).toString();
        _standardPriceController.text = (d['price_standard'] ?? 500).toString();
        _budgetPriceController.text = (d['price_budget'] ?? 250).toString();
      });
    }
  }

  void _savePrices() async {
    await FirebaseFirestore.instance.collection('events').doc(widget.eventDocId).update({
      'price_vip': int.tryParse(_vipPriceController.text) ?? 1000,
      'price_standard': int.tryParse(_standardPriceController.text) ?? 500,
      'price_budget': int.tryParse(_budgetPriceController.text) ?? 250,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ціни успішно збережено!")),
    );
  }

  double _applyGrid(double val) {
    if (!_snapToGrid) return val;
    return (val / 20).round() * 20.0;
  }

  void _addElement(Offset localPosition) async {
    double finalX = _applyGrid(localPosition.dx);
    double finalY = _applyGrid(localPosition.dy);

    await FirebaseFirestore.instance.collection('events').doc(widget.eventDocId).collection('seating').add({
      'type': _selectedTool,
      'tier': _selectedTier,
      'x': finalX,
      'y': finalY,
      'label': '',
      'status': 'free',
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    Color canvasColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFEAEAEA);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("РЕДАКТОР РОЗСАДКИ ЗАЛУ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              Text("СІТКА", style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
              Switch(
                value: _snapToGrid,
                activeColor: isDark ? Colors.white : Colors.black,
                onChanged: (v) => setState(() => _snapToGrid = v),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: "Налаштування цін місць",
            onPressed: () => setState(() => _showPriceSidebar = !_showPriceSidebar),
          )
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 80,
            color: isDark ? const Color(0xFF090909) : Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildToolButton(Icons.pan_tool_alt_outlined, 'select', "Вибір"),
                _buildToolButton(Icons.chair_alt, 'chair', "Крісло"),
                _buildToolButton(Icons.table_restaurant, 'table', "Стіл"),
                _buildToolButton(Icons.supervised_user_circle, 'combined_table', "Стіл+Стільці"),
                const Divider(),
                const SizedBox(height: 10),
                _buildTierButton(Colors.amber, 'vip'),
                _buildTierButton(Colors.blue, 'standard'),
                _buildTierButton(Colors.green, 'budget'),
              ],
            ),
          ),
          
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTapUp: (details) {
                    if (_selectedTool != 'select') {
                      _addElement(details.localPosition);
                    }
                  },
                  child: Container(
                    color: canvasColor,
                    child: CustomPaint(
                      painter: SeatingGridPainter(showGrid: _snapToGrid, isDark: isDark),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('events').doc(widget.eventDocId).collection('seating').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          var items = snapshot.data!.docs;
                          return Stack(
                            children: items.map((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              double itemX = (data['x'] ?? 0.0).toDouble();
                              double itemY = (data['y'] ?? 0.0).toDouble();
                              String type = data['type'] ?? 'chair';
                              String tier = data['tier'] ?? 'standard';

                              Color tierColor = Colors.blue;
                              if (tier == 'vip') tierColor = Colors.amber;
                              if (tier == 'budget') tierColor = Colors.green;

                              Widget elementWidget;
                              double elWidth = 40;
                              double elHeight = 40;

                              if (type == 'table') {
                                elWidth = 60;
                                elHeight = 60;
                                elementWidget = Container(
                                  width: elWidth,
                                  height: elHeight,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black12,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? Colors.white30 : Colors.black45, width: 2),
                                  ),
                                  child: const Center(child: Icon(Icons.table_restaurant, size: 20)),
                                );
                              } else if (type == 'combined_table') {
                                elWidth = 100;
                                elHeight = 100;
                                elementWidget = SizedBox(
                                  width: elWidth,
                                  height: elHeight,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white12 : Colors.black12,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: tierColor, width: 2),
                                        ),
                                        child: const Icon(Icons.restaurant, size: 14),
                                      ),
                                      Positioned(top: 2, child: Icon(Icons.chair_alt, size: 16, color: tierColor)),
                                      Positioned(bottom: 2, child: Icon(Icons.chair_alt, size: 16, color: tierColor)),
                                      Positioned(left: 2, child: Icon(Icons.chair_alt, size: 16, color: tierColor)),
                                      Positioned(right: 2, child: Icon(Icons.chair_alt, size: 16, color: tierColor)),
                                    ],
                                  ),
                                );
                              } else {
                                elementWidget = Icon(Icons.chair_alt, color: tierColor, size: 28);
                              }

                              return Positioned(
                                left: itemX,
                                top: itemY,
                                child: GestureDetector(
                                  onPanStart: (details) {
                                    setState(() {
                                      _dragTouchOffset = details.localPosition;
                                    });
                                  },
                                  onPanUpdate: _selectedTool == 'select' ? (details) async {
                                    RenderBox renderBox = context.findRenderObject() as RenderBox;
                                    Offset globalPos = details.globalPosition;
                                    Offset localCanvasPos = renderBox.globalToLocal(globalPos);

                                    double targetX = _applyGrid(localCanvasPos.dx - 80 - _dragTouchOffset.dx);
                                    double targetY = _applyGrid(localCanvasPos.dy - 56 - _dragTouchOffset.dy);

                                    if (targetX < 0) targetX = 0;
                                    if (targetY < 0) targetY = 0;

                                    await doc.reference.update({'x': targetX, 'y': targetY});
                                  } : null,
                                  onSecondaryTap: () async {
                                    await doc.reference.delete();
                                  },
                                  child: elementWidget,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_showPriceSidebar)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                border: Border(left: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ВСТАНОВЛЕННЯ ЦІН", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _showPriceSidebar = false),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPriceField(_vipPriceController, "Ціна VIP (Amber)", Colors.amber, isDark),
                  const SizedBox(height: 15),
                  _buildPriceField(_standardPriceController, "Ціна Стандарт (Blue)", Colors.blue, isDark),
                  const SizedBox(height: 15),
                  _buildPriceField(_budgetPriceController, "Ціна Бюджет (Green)", Colors.green, isDark),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _savePrices,
                      child: const Text("ЗБЕРЕГТИ ЦІНИ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String toolName, String tooltip) {
    bool isSelected = _selectedTool == toolName;
    bool isDark = themeNotifier.value == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: IconButton(
        icon: Icon(icon, color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey, size: 26),
        tooltip: tooltip,
        onPressed: () => setState(() => _selectedTool = toolName),
      ),
    );
  }

  Widget _buildTierButton(Color color, String tierName) {
    bool isSelected = _selectedTier == tierName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedTier = tierName),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected ? Border.all(color: themeNotifier.value == ThemeMode.dark ? Colors.white : Colors.black, width: 3) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceField(TextEditingController controller, String label, Color indicator, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: indicator, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            suffixText: "грн",
          ),
        ),
      ],
    );
  }
}

class SeatingGridPainter extends CustomPainter {
  final bool showGrid;
  final bool isDark;
  SeatingGridPainter({required this.showGrid, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid) return;
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06)
      ..strokeWidth = 2;

    for (double x = 0; x < size.width; x += 20) {
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SeatingGridPainter oldDelegate) => oldDelegate.isDark != isDark || oldDelegate.showGrid != showGrid;
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: Center(child: Text("ПАНЕЛЬ АДМІНІСТРАТОРА", style: TextStyle(color: isDark ? Colors.white12 : Colors.black12, letterSpacing: 2))),
    );
  }
}

class AdminTypesScreen extends StatelessWidget {
  const AdminTypesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: Center(child: Text("КАТЕГОРІЇ ЗАХОДІВ", style: TextStyle(color: isDark ? Colors.white12 : Colors.black12, letterSpacing: 2))),
    );
  }
}

class AttacheScreen extends StatelessWidget {
  const AttacheScreen({super.key});
  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: Center(child: Text("ПАНЕЛЬ АТАШЕ", style: TextStyle(color: isDark ? Colors.white12 : Colors.black12, letterSpacing: 2))),
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
    bool isDark = themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, letterSpacing: 4, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("КОД РЕЗИДЕНТА: $userCode", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, letterSpacing: 1)),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.tune, color: isDark ? Colors.white30 : Colors.black26),
              onPressed: onOpenSettings,
            ),
          )
        ],
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
    if (code == "1111") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell(role: 'attache', userCode: "1111")));
      return;
    }
    if (code.isNotEmpty) {
      var doc = await FirebaseFirestore.instance.collection('residents').doc(code).get();
      if (doc.exists && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainShell(role: 'resident', userData: doc.data(), userCode: code)));
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