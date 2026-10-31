import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isAuth = false;
  List initialAsk = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    isAuth = prefs.getBool('is_auth') ?? false;
    String? s = prefs.getString('ask_msgs');
    if (s != null) {
      var decoded = json.decode(s);
      for (var i in decoded) {
        initialAsk.add(Map<String, String>.from(i));
      }
    }
  } catch (e) {}
  runApp(GodAgentApp(isAuth: isAuth, initialAsk: initialAsk));
}

class GodAgentApp extends StatelessWidget {
  final bool isAuth;
  final List initialAsk;
  const GodAgentApp({Key? key, required this.isAuth, required this.initialAsk}) : super(key: key);

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
      home: ChatScreen(isAuth: isAuth, initialAsk: initialAsk),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final bool isAuth;
  final List initialAsk;
  const ChatScreen({Key? key, required this.isAuth, required this.initialAsk}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  
  late bool _authorized;
  late List askMessages;
  
  // Task Staging Workflow variables
  List stagedTasks = [];
  bool awaitingFinalConfirmation = false;

  @override
  void initState() {
    super.initState();
    _authorized = widget.isAuth;
    askMessages = List.from(widget.initialAsk);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ask_msgs', json.encode(askMessages));
    } catch (e) {}
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    String trimmed = text.trim();
    String lower = trimmed.toLowerCase();

    setState(() {
      askMessages.add({"sender": "user", "text": trimmed});
      _msgController.clear();
    });
    await _save();

    String reply = "";

    if (awaitingFinalConfirmation) {
      if (lower.contains("final") || lower.contains("kar do") || lower.contains("bej do") || lower.contains("suru kar") || lower.contains("haan")) {
        awaitingFinalConfirmation = false;
        String allTasks = stagedTasks.join(", ");
        stagedTasks.clear();
        reply = "🚀 **Task Staging Finalized!** Saare tasks ($allTasks) successfully agent core ko dispatch kar diye gaye hain. Background execution shuru ho raha hai.";
      } else if (lower.contains("hata") || lower.contains("remove")) {
        reply = "Theek hai, kaun sa task hatana hai uska naam batayiye? Current staged tasks: ${stagedTasks.join(', ')}";
      } else {
        stagedTasks.add(trimmed);
        reply = "📝 Maine aapka point note kar liya hai. Total staged tasks: [${stagedTasks.join(', ')}]. Kya isme kuch aur add karna hai, ya ab main **'Final kar do'** bolun?";
      }
    } else if (lower.contains("naya kaam") || lower.contains("new task") || lower.contains("task dena hai") || lower.contains("discuss")) {
      awaitingFinalConfirmation = true;
      stagedTasks.clear();
      reply = "🎯 Theek hai bhai! Pehle hum aaram se discuss kar lete hain. Aap apne points ya tasks ek-ek karke batayiye, aur jab sab kuch final ho jaye tab **'Final kar do'** ya **'Bej do'** boliyega!";
    } else if (lower.contains("apple") || lower.contains("meaning") || lower.contains("kya hai")) {
      reply = "Apple ek fruit bhi hai aur ek tech company (Apple Inc.) ka naam bhi hai. Baaki bataiye, aapko iske alawa aur kya janna hai?";
    } else if (lower.contains("hi") || lower.contains("hello") || lower.contains("hlo") || lower.contains("hey") || lower.contains("bhai")) {
      reply = "Hello bhai! Main aapka Obsidian AI Agent hoon. Aap mujhse normal baat bhi kar sakte hain aur naye tasks discuss karne ke liye **'naya kaam'** bol sakte hain.";
    } else {
      reply = "Maine aapki baat suni aur samajhi: '$trimmed'. Agar aapko ise agent ke liye task ke taur par fix karna hai toh **'naya kaam'** boliye!";
    }

    setState(() {
      askMessages.add({"sender": "agent", "text": reply});
    });
    await _save();
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
        title: const Text("Obsidian AI Agent (Staging Core)", style: TextStyle(fontSize: 15, color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: askMessages.length,
              itemBuilder: (context, index) {
                final m = askMessages[index];
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
                          hintText: "Message AI Agent or type 'naya kaam'...",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFE0E0E0)),
                      onPressed: () => _sendMessage(_msgController.text),
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
