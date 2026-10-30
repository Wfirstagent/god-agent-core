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
    if (s != null) msgs = json.decode(s);
  } catch (e) {}
  runApp(MyApp(isAuth: isAuth, msgs: msgs));
}

class MyApp extends StatelessWidget {
  final bool isAuth;
  final List msgs;
  const MyApp({Key? key, required this.isAuth, required this.msgs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF10A37F),
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
      messages.add({"sender": "agent", "text": "Hello bhai! Main aapka ChatGPT-style AI Agent hoon. Sab kuch makkhan chal raha hai!"});
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorized) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 64, color: Color(0xFF10A37F)),
                const SizedBox(height: 16),
                const Text("Enter Passcode", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10A37F)),
                  onPressed: () async {
                    if (_passController.text.trim() == "74882242959122690239") {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_auth', true);
                      setState(() => _authorized = true);
                    }
                  },
                  child: const Text("Unlock", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        title: const Text("ChatGPT Obsidian Agent", style: TextStyle(fontSize: 15)),
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
                      color: isUser ? const Color(0xFF10A37F) : const Color(0xFF212121),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "Message ChatGPT Agent...", border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF10A37F)),
                    onPressed: () => _send(_msgController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
