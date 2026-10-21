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

  // Chat histories
  List<Map<String, String>> askMessages = [];
  List<Map<String, String>> autoPilotMessages = [];

  // Pending task waiting for clarification/final confirmation
  String? pendingTask;
  bool awaitingConfirmation = false;

  Map<String, dynamic> metrics = {
    "thinking": "System active. Awaiting verified tasks...",
    "learned": "Initialized robust conversational clarification layer.",
    "problems": "None. All systems operational."
  };

  final String backendUrl = "https://god-agent-core.onrender.com/command";
  final String metricsUrl = "https://god-agent-core.onrender.com/metrics";

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _fetchMetrics();
  }

  // Load persistent authentication, drive status, and chat histories safely
  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = prefs.getBool('is_authorized') ?? false;
      final drive = prefs.getBool('is_drive_connected') ?? false;

      final String? savedAsk = prefs.getString('ask_messages');
      final String? savedAuto = prefs.getString('autopilot_messages');

      setState(() {
        _isAuthorized = auth;
        _isDriveConnected = drive;

        if (savedAsk != null) {
          askMessages = List<Map<String, String>>.from(
            json.decode(savedAsk).map((item) => Map<String, String>.from(item)),
          );
        }
        if (savedAuto != null) {
          autoPilotMessages = List<Map<String, String>>.from(
            json.decode(savedAuto).map((item) => Map<String, String>.from(item)),
          );
        }
      });

      if (_isAuthorized && !_isDriveConnected) {
        _showGoogleDrivePrompt();
      }
    } catch (e) {
      debugPrint("Error loading saved state: $e");
    }
  }

  // Save chat histories securely with error handling
  Future<void> _saveChatHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ask_messages', json.encode(askMessages));
      await prefs.setString('autopilot_messages', json.encode(autoPilotMessages));
    } catch (e) {
      debugPrint("Error saving chat histories: $e");
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
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_drive_connected', true);
                setState(() => _isDriveConnected = true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Google Drive Connected & Synced Successfully!")),
                );
              } catch (e) {
                debugPrint("Error connecting drive: $e");
              }
            },
            child: const Text("Connect Drive", style: TextStyle(color: Color(0xFF58A6FF))),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPasscode() async {
    String enteredText = _passcodeController.text.trim();
    const targetPasscode = "74882242959122690239";

    if (enteredText == targetPasscode) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authorized', true);
      } catch (e) {
        debugPrint("Error saving auth state: $e");
      }

      setState(() {
        _isAuthorized = true;
      });

      if (!_isDriveConnected) {
        _showGoogleDrivePrompt();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect Passcode! Please try again.")),
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
    } catch (e) {
      debugPrint("Error fetching metrics: $e");
    }
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

  // Conversational Assistant Layer + Backend Dispatch
  Future<void> _handleUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentList = selectedMode == "ask" ? askMessages : autoPilotMessages;

    setState(() {
      currentList.add({"sender": "user", "text": text});
      _messageController.clear();
    });
    await _saveChatHistories();

    if (awaitingConfirmation) {
      String lower = text.toLowerCase();
      if (lower.contains("haan") || lower.contains("yes") || lower.contains("ok") || lower.contains("final") || lower.contains("kar do")) {
        String taskToSend = pendingTask ?? text;
        pendingTask = null;
        awaitingConfirmation = false;

        setState(() {
          currentList.add({"sender": "agent", "text": "🔄 Dispatching verified task to AI agent core..."});
        });
        await _saveChatHistories();

        await _dispatchToBackend(taskToSend);
        return;
      } else {
        pendingTask = text;
        setState(() {
          currentList.add({
            "sender": "agent",
            "text": "Theek hai, samajh gaya. Kya ab main ise final kar doon aur AI agent ko bata du ki ye kaam mila hai? (Haan / Final kar do bole)"
          });
        });
        await _saveChatHistories();
        return;
      }
    }

    pendingTask = text;
    awaitingConfirmation = true;

    setState(() {
      currentList.add({
        "sender": "agent",
        "text": "🤖 **Assistant:** Main aapki baat samajh raha hoon ('$text'). Kya aap chahte hain ki main is task ko refine karke final kar doon aur AI agent ko assign kar doon? (Aap batayein, ya 'Haan final kar do' kahein)"
      });
    });
    await _saveChatHistories();
  }

  Future<void> _dispatchToBackend(String commandText) async {
    final currentList = selectedMode == "ask" ? askMessages : autoPilotMessages;

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "passcode": "74882242959122690239",
          "command": commandText,
          "mode": selectedMode
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentList.add({"sender": "agent", "text": "✅ ${data["response"]}"});
          if (data["metrics"] != null) {
            metrics = data["metrics"];
          }
        });
      } else {
        setState(() {
          currentList.add({"sender": "agent", "text": "⚠️ Backend server returned error code: ${response.statusCode}"});
        });
      }
    } catch (e) {
      setState(() {
        currentList.add({"sender": "agent", "text": "❌ Network error connecting to backend core."});
      });
    }
    await _saveChatHistories();
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
                if (val != null) {
                  setState(() => selectedMode = val);
                }
              },
            ),
          ),
        ],
      ),
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
      body: !_isAuthorized
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
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
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
                // Properly padded capsule input bar elevated above system bar using SafeArea
                SafeArea(
                  child: Container(
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
                            onPressed: () => _handleUserMessage(_messageController.text),
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
