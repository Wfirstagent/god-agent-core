import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isAuth = false;
  List msgs = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    isAuth = prefs.getBool('is_auth') ?? false;
    String? s = prefs.getString('msgs');
    if (s != null) {
      var decoded = json.decode(s);
      for (var i in decoded) {
        msgs.add(Map<String, String>.from(i));
      }
    }
  } catch (e) {}
  runApp(GodAgentApp(isAuth: isAuth, msgs: msgs));
}

class GodAgentApp extends StatelessWidget {
  final bool isAuth;
  final List msgs;
  const GodAgentApp({Key? key, required this.isAuth, required this.msgs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFFE0E0E0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE0E0E0),
          surface: Color(0xFF171717),
        ),
      ),
      home: ChatScreen(isAuth: isAuth, initialMsgs: msgs),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final bool isAuth;
  final List initialMsgs;
  const ChatScreen({Key? key, required this.isAuth, required this.initialMsgs}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  late bool _authorized;
  late List messages;

  @override
  void initState() {
    super.initState();
    _authorized = widget.isAuth;
    messages = List.from(widget.initialMsgs);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('msgs', json.encode(messages));
    } catch (e) {}
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add({"sender": "user", "text": text.trim()});
      _msgController.clear();
      messages.add({"sender": "agent", "text": "Hello bhai! Main aapka Obsidian AI Agent hoon. Sab kuch makkhan chal raha hai aur task staging pipeline ready hai."});
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorized) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 16),
                const Text("Enter Secure Console Passcode", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF171717),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    hintText: "Passcode...",
                    hintStyle: const TextStyle(color: Colors.white38),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E0E0),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    if (_passController.text.trim() == "74882242959122690239") {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_auth', true);
                      setState(() => _authorized = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Incorrect Passcode!")),
                      );
                    }
                  },
                  child: const Text("Unlock Console", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        elevation: 0,
        title: const Text("Obsidian AI Agent", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final isUser = m["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2E2E2E) : const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF000000),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: "Message AI Agent...",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFE0E0E0)),
                      onPressed: () => _send(_msgController.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
