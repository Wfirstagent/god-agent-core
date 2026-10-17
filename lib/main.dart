import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _messageController = TextEditingController();
  
  bool _isAuthorized = false;
  bool _isDriveConnected = false;
  String selectedMode = "ask"; // "ask" or "autopilot"

  // Separate chat histories for both modes
  final List<Map<String, String>> askMessages = [];
  final List<Map<String, String>> autoPilotMessages = [];

  Map<String, dynamic> metrics = {
    "thinking": "System active. Awaiting commands...",
    "learned": "Initialized secure agent core.",
    "problems": "None. All systems optimal."
  };

  final String backendUrl = "https://god-agent-core.onrender.com/command";
  final String metricsUrl = "https://god-agent-core.onrender.com/metrics";

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _fetchMetrics();
  }

  // Load persistent login and drive status
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAuthorized = prefs.getBool('is_authorized') ?? false;
      _isDriveConnected = prefs.getBool('is_drive_connected') ?? false;
    });

    if (_isAuthorized && !_isDriveConnected) {
      _showGoogleDrivePrompt();
    }
  }

  Future<void> _showGoogleDrivePrompt() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("Connect Google Drive", style: TextStyle(color: Colors.orangeAccent)),
        content: const Text("Connect your Google Drive to sync agent logs and session history securely."),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_drive_connected', true);
              setState(() => _isDriveConnected = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Google Drive Connected & Synced Successfully!")),
              );
            },
            child: const Text("Connect Drive", style: TextStyle(color: Color(0xFF58A6FF))),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPasscode() async {
    if (_passcodeController.text.trim() == "74882242959122690239") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authorized', true);
      setState(() {
        _isAuthorized = true;
      });
      if (!_isDriveConnected) {
        _showGoogleDrivePrompt();
      }
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

  void _showMetricDetailDialog(String title, String content, IconData icon, Color color) {
    _fetchMetrics();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.white))),
          ],
        ),
        content: Text(content.isNotEmpty ? content : "No data available yet.", style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Color(0xFF58A6FF))),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      if (selectedMode == "ask") {
        askMessages.add({"sender": "user", "text": text});
      } else {
        autoPilotMessages.add({"sender": "user", "text": text});
      }
      _messageController.clear();
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "passcode": "74882242959122690239",
          "command": text,
          "mode": selectedMode
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (selectedMode == "ask") {
            askMessages.add({"sender": "agent", "text": data["response"]});
          } else {
            autoPilotMessages.add({"sender": "agent", "text": data["response"]});
          }
          if (data["metrics"] != null) {
            metrics = data["metrics"];
          }
        });
      }
    } catch (e) {
      setState(() {
        final errText = "Network error connecting to backend core.";
        if (selectedMode == "ask") {
          askMessages.add({"sender": "agent", "text": errText});
        } else {
          autoPilotMessages.add({"sender": "agent", "text": errText});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMessages = selectedMode == "ask" ? askMessages : autoPilotMessages;

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
                DropdownMenuItem(value: "ask", child: Text("Ask AI Mode", style: TextStyle(fontSize: 13, color: Colors.white))),
                DropdownMenuItem(value: "autopilot", child: Text("Auto Pilot", style: TextStyle(fontSize: 13, color: Colors.white))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => selectedMode = val);
              },
            ),
          ),
        ],
      ),
      // 3-Line Slide Menu (Drawer) with interactive metric taps
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
              subtitle: Text(metrics["thinking"] ?? "Thinking...", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () => _showMetricDetailDialog("AI Agent Thinking Process", metrics["thinking"], Icons.psychology, Colors.blueAccent),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.book, color: Colors.greenAccent),
              title: const Text('2. AI agent ne aaj kya sikha hai'),
              subtitle: Text(metrics["learned"] ?? "Learning logs...", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () => _showMetricDetailDialog("AI Agent Learning Logs", metrics["learned"], Icons.book, Colors.greenAccent),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.redAccent),
              title: const Text('3. AI agent ko kahan problem aa rahi hai'),
              subtitle: Text(metrics["problems"] ?? "None", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () => _showMetricDetailDialog("AI Agent Error Tracker", metrics["problems"], Icons.warning, Colors.redAccent),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: !_isAuthorized
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 64, color: Color(0xFF58A6FF)),
                          const SizedBox(height: 16),
                          const Text("Enter Secure Passcode to Access Console", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passcodeController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: "Enter passcode...",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF238636),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: _verifyPasscode,
                            child: const Text("Unlock Console", style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: activeMessages.length,
                    itemBuilder: (context, index) {
                      final msg = activeMessages[index];
                      final isUser = msg["sender"] == "user";
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF238636) : const Color(0xFF21262D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      );
                    },
                  ),
          ),

          // Modern Capsule Input Bar (Matching Reference Image Style)
          if (_isAuthorized)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF0D1117),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFF58A6FF)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Attachment / Quick Action menu")),
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: "Ask AI or give command...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.white70),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF58A6FF)),
                      onPressed: () => _sendMessage(_messageController.text),
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
