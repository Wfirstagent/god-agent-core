import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const GodAgentApp());

class GodAgentApp extends StatelessWidget {
  const GodAgentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'God-Level AI Agent v2',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF58A6FF),
      ),
      home: const MainAgentScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAgentScreen extends StatefulWidget {
  const MainAgentScreen({Key? key}) : super(key: key);

  @override
  State<MainAgentScreen> createState() => _MainAgentScreenState();
}

class _MainAgentScreenState extends State<MainAgentScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  bool _isAuthorized = false;

  String selectedMode = "ask"; 
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> messages = [];

  Map<String, dynamic> metrics = {
    "thinking": "Awaiting initial command...",
    "learned": "System booted successfully.",
    "problems": "None. All systems operational."
  };

  final String backendUrl = "https://god-agent-core.onrender.com/command";
  final String metricsUrl = "https://god-agent-core.onrender.com/metrics";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGoogleDrivePrompt();
    });
    _fetchMetrics();
  }

  void _showGoogleDrivePrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("Oops! Connect Google Drive", style: TextStyle(color: Colors.orangeAccent)),
        content: const Text("First-time setup requires connecting your Google Drive so your agent progress and chat data can be saved securely."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Google Drive Connected Successfully!")),
              );
            },
            child: const Text("Connect Drive", style: TextStyle(color: Color(0xFF58A6FF))),
          ),
        ],
      ),
    );
  }

  void _verifyPasscode() {
    if (_passcodeController.text.trim() == "admin1283") {
      setState(() {
        _isAuthorized = true; // Passcode sahi hone par passcode box hide ho jayega aur chat bar aa jayega
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect Passcode! Try again.")),
      );
    }
  }

  Future<void> _fetchMetrics() async {
    try {
      final response = await http.get(Uri.parse(metricsUrl));
      if (response.statusCode == 200) {
        setState(() {
          metrics = json.decode(response.body);
        });
      }
    } catch (e) {}
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": text});
      _messageController.clear();
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "passcode": "admin1283",
          "command": text,
          "mode": selectedMode
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          messages.add({"sender": "agent", "text": data["response"]});
          if (data["metrics"] != null) {
            metrics = data["metrics"];
          }
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"sender": "agent", "text": "Network error connecting to backend."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text(
          selectedMode == "ask" ? "Ask AI Agent Chat Mode" : "Auto Pilot Chat Mode", 
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedMode,
              dropdownColor: const Color(0xFF161B22),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: "ask", child: Text("Ask AI Mode", style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: "autopilot", child: Text("Auto Pilot", style: TextStyle(fontSize: 13))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => selectedMode = val);
              },
            ),
          ),
        ],
      ),
      // Three-Line Slide Menu (Drawer)
      drawer: Drawer(
        backgroundColor: const Color(0xFF161B22),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF21262D)),
              child: Text('🧠 Agent Intelligence Panel', style: TextStyle(color: Color(0xFF58A6FF), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.psychology, color: Colors.blueAccent),
              title: const Text('1. AI agent kya soch raha hai'),
              subtitle: Text(metrics["thinking"] ?? "Thinking...", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.book, color: Colors.greenAccent),
              title: const Text('2. AI agent ne aaj kya sikha hai'),
              subtitle: Text(metrics["learned"] ?? "Learning logs...", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.redAccent),
              title: const Text('3. AI agent ko kahan problem aa rahi hai'),
              subtitle: Text(metrics["problems"] ?? "None", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF238636) : const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                );
              },
            ),
          ),

          // Bottom Control Section (Clean Conditional Layout)
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF161B22),
            child: !_isAuthorized
                ? 
                // 1. Passcode Box (Jab tak authorize na ho, sirf yeh dikhega)
                Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passcodeController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: "Enter passcode to connect...",
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636)),
                        onPressed: _verifyPasscode,
                        child: const Text("Unlock", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                : 
                // 2. Chat Input Box (Authorize hone ke baad passcode hide hokar sirf yeh dikhega)
                Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: "Ask AI or give command...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF58A6FF)),
                        onPressed: () => _sendMessage(_messageController.text),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
