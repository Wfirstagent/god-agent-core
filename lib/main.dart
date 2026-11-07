import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List initialLogs = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    String? logsData = prefs.getString('deven_logs');
    if (logsData != null && logsData.isNotEmpty) {
      var decoded = json.decode(logsData);
      for (var i in decoded) { initialLogs.add(i); }
    }
  } catch (e) {}
  runApp(GodDevenApp(initialLogs: initialLogs));
}

class GodDevenApp extends StatelessWidget {
  final List initialLogs;
  const GodDevenApp({Key? key, required this.initialLogs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'God Deven AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFFE0E0E0),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE0E0E0), surface: Color(0xFF141414)),
      ),
      home: DevenHomeScreen(initialLogs: initialLogs),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DevenHomeScreen extends StatefulWidget {
  final List initialLogs;
  const DevenHomeScreen({Key? key, required this.initialLogs}) : super(key: key);

  @override
  State<DevenHomeScreen> createState() => _DevenHomeScreenState();
}

class _DevenHomeScreenState extends State<DevenHomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  late List chatLogs;
  String apiKey = "";
  bool isCallActive = false;
  String callStatus = "Voice bridge inactive (Configure backend)";

  late AnimationController _voiceAnimation;

  @override
  void initState() {
    super.initState();
    chatLogs = List.from(widget.initialLogs);
    _loadSettings();

    _voiceAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    if (chatLogs.isEmpty) {
      chatLogs.add({"sender": "deven", "text": "Namaste! Main God Deven hoon. Settings me apni Gemini API Key daal aur fast chat shuru kar!"});
    }
  }

  @override
  void dispose() {
    _voiceAnimation.dispose();
    _chatController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('gemini_api_key') ?? '';
      _apiKeyController.text = apiKey;
    });
  }

  Future<void> _saveSettings(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key.trim());
    setState(() {
      apiKey = key.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key saved successfully!')));
  }

  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deven_logs', json.encode(chatLogs));
    } catch (e) {}
  }
  Future<void> _sendDevenMessage(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { chatLogs.add({"sender": "user", "text": query}); _chatController.clear(); });
    await _saveLogs();

    if (apiKey.isEmpty) {
      setState(() { chatLogs.add({"sender": "deven", "text": "Bhai, pehle top-right Settings icon par click karke apni Gemini API key save kar!"}); });
      await _saveLogs();
      return;
    }

    try {
      // Fast and direct v1 endpoint to eliminate 404 errors and lag
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "contents": [{ "parts": [{ "text": "You are God Deven, an advanced AI assistant. Respond in Hinglish/Hindi fast and naturally. User: $query" }] }]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String botReply = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() { chatLogs.add({"sender": "deven", "text": botReply}); });
      } else {
        setState(() { chatLogs.add({"sender": "deven", "text": "API Error (${response.statusCode}): ${response.body}"}); });
      }
    } catch (e) {
      setState(() { chatLogs.add({"sender": "deven", "text": "Network error: $e"}); });
    }
    await _saveLogs();
  }

  void _toggleAICall() {
    setState(() {
      isCallActive = !isCallActive;
      callStatus = isCallActive ? "Connecting..." : "Call Ended";
    });
  }

  void _showSettingsModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text("Gemini API Settings", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gemini API Key:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            onPressed: () {
              _saveSettings(_apiKeyController.text);
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text("God Deven [Fast AI]", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: Colors.greenAccent),
            tooltip: "AI Voice Call",
            onPressed: _toggleAICall,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: "Settings",
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: chatLogs.length,
                  itemBuilder: (context, index) {
                    final m = chatLogs[index];
                    bool isUser = m["sender"] == "user";
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isUser ? const Color(0xFF262626) : const Color(0xFF171717), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                        child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.black,
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: "Message God Deven...", border: InputBorder.none))),
                      IconButton(icon: const Icon(Icons.send, color: Colors.orangeAccent), onPressed: () => _sendDevenMessage(_chatController.text)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isCallActive)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.96),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _voiceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_voiceAnimation.value * 0.2),
                          child: Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E1E1E),
                              border: Border.all(color: Colors.greenAccent, width: 2),
                              boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)],
                            ),
                            child: const Icon(Icons.mic, color: Colors.greenAccent, size: 80),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 35),
                    const Text("God Deven AI Voice", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(callStatus, style: const TextStyle(color: Colors.greenAccent, fontSize: 14)),
                    const SizedBox(height: 6),
                    const Text("WebRTC Backend Required for Audio", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _toggleAICall,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
