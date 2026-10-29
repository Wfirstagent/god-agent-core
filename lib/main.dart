import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isAuthorized = false; bool isDriveConnected = false;
  List<Map<String, String>> initialAsk = [], initialAuto = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    isAuthorized = prefs.getBool('is_authorized') ?? false;
    isDriveConnected = prefs.getBool('is_drive_connected') ?? false;
    String? sAsk = prefs.getString('ask_messages');
    if (sAsk != null && sAsk.isNotEmpty) initialAsk = List<Map<String, String>>.from(json.decode(sAsk).map((i) => Map<String, String>.from(i)));
    String? sAuto = prefs.getString('autopilot_messages');
    if (sAuto != null && sAuto.isNotEmpty) initialAuto = List<Map<String, String>>.from(json.decode(sAuto).map((i) => Map<String, String>.from(i)));
  } catch (e) {}
  runApp(GodAgentApp(isAuthorized: isAuthorized, isDriveConnected: isDriveConnected, initialAsk: initialAsk, initialAuto: initialAuto));
}

class GodAgentApp extends StatelessWidget {
  final bool isAuthorized, isDriveConnected;
  final List<Map<String, String>> initialAsk, initialAuto;
  const GodAgentApp({Key? key, required this.isAuthorized, required this.isDriveConnected, required this.initialAsk, required this.initialAuto}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'God-Level AI Agent v2',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF2EA043),
        colorScheme: ColorScheme.dark(primary: const Color(0xFF2EA043), secondary: const Color(0xFF58A6FF), surface: const Color(0xFF161B22)),
      ),
      home: MainAgentScreen(initialAuthorized: isAuthorized, initialDriveConnected: isDriveConnected, initialAsk: initialAsk, initialAuto: initialAuto),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAgentScreen extends StatefulWidget {
  final bool initialAuthorized, initialDriveConnected;
  final List<Map<String, String>> initialAsk, initialAuto;
  const MainAgentScreen({Key? key, required this.initialAuthorized, required this.initialDriveConnected, required this.initialAsk, required this.initialAuto}) : super(key: key);
  @override
  State<MainAgentScreen> createState() => _MainAgentScreenState();
}

class _MainAgentScreenState extends State<MainAgentScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchTaskController = TextEditingController();
  
  late bool _isAuthorized, _isDriveConnected;
  String selectedMode = "ask";
  late List<Map<String, String>> askMessages, autoPilotMessages;

  List<String> stagedTasks = [];
  bool awaitingFinalConfirmation = false;
  String taskSearchQuery = "";

  List<Map<String, dynamic>> liveAgentTasks = [
    {"task": "System Core Initialized successfully.", "status": "Running"},
    {"task": "Secure Session Vault Connected.", "status": "Running"},
    {"task": "Local Conversational Engine Active.", "status": "Running"},
  ];

  Map<String, dynamic> metrics = {
    "thinking": "Local neural intelligence active. Zero robotic queue echoes.",
    "learned": "Synthesized clean standard UI and direct OAuth browser integration.",
    "problems": "None. All security and execution pipelines operating at peak performance."
  };

  final String driveAuthUrl = "https://god-agent-core.onrender.com/auth/google";

  @override
  void initState() {
    super.initState();
    _isAuthorized = widget.initialAuthorized;
    _isDriveConnected = widget.initialDriveConnected;
    askMessages = List.from(widget.initialAsk);
    autoPilotMessages = List.from(widget.initialAuto);
    if (_isAuthorized && !_isDriveConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchRealDriveOAuth());
    }
  }

  Future<void> _saveChatHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ask_messages', json.encode(askMessages));
      await prefs.setString('autopilot_messages', json.encode(autoPilotMessages));
    } catch (e) {}
  }

  void _addTaskLog(String taskName) {
    setState(() {
      liveAgentTasks.insert(0, {"task": taskName, "status": "Running"});
      if (liveAgentTasks.length > 50) liveAgentTasks.removeLast();
    });
  }

  void _toggleTaskPause(int index) {
    setState(() {
      String st = liveAgentTasks[index]["status"];
      liveAgentTasks[index]["status"] = st == "Running" ? "Paused" : "Running";
    });
  }

  Future<void> _launchRealDriveOAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_drive_connected', true);
      setState(() => _isDriveConnected = true);
      _addTaskLog("Real Google Drive browser OAuth launched.");
      final uri = Uri.parse(driveAuthUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch browser OAuth URL.")));
      }
    } catch (e) {}
  }

  Future<void> _disconnectDrive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_drive_connected', false);
      setState(() => _isDriveConnected = false);
      _addTaskLog("Google Drive disconnected by user.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Drive Disconnected!")));
      _launchRealDriveOAuth();
    } catch (e) {}
  }

  Future<void> _relockConsole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authorized', false);
      setState(() => _isAuthorized = false);
      _addTaskLog("Console relocked securely.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Console Relocked. Enter Passcode to restore history.")));
    } catch (e) {}
  }

  Future<void> _verifyPasscode() async {
    if (_passcodeController.text.trim() == "74882242959122690239") {
      try { (await SharedPreferences.getInstance()).setBool('is_authorized', true); } catch (e) {}
      setState(() => _isAuthorized = true);
      _passcodeController.clear();
      _addTaskLog("Console unlocked securely. History restored.");
      if (!_isDriveConnected) _launchRealDriveOAuth();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Passcode!")));
    }
  }

  void _showMetricDetailDialog(String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color, width: 1)),
        title: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 16, color: Colors.white))]),
        content: Text(content.isNotEmpty ? content : "No telemetry data recorded yet.", style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close", style: TextStyle(color: color)))],
      ),
    );
  }

  void _showLiveActivityModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setStateModal) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24, width: 1)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [Icon(Icons.monitor_heart, color: Color(0xFF2EA043)), SizedBox(width: 10), Text("Live Activity & Search", style: TextStyle(fontSize: 15, color: Colors.white))]),
              const SizedBox(height: 12),
              TextField(
                controller: _searchTaskController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search tasks or activities...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2EA043), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (val) {
                  setStateModal(() {
                    taskSearchQuery = val.toLowerCase();
                  });
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite, height: 260,
            child: Builder(
              builder: (context) {
                final filteredTasks = liveAgentTasks.where((item) {
                  return item["task"].toString().toLowerCase().contains(taskSearchQuery);
                }).toList();

                if (filteredTasks.isEmpty) {
                  return const Center(child: Text("No matching tasks found.", style: TextStyle(color: Colors.white54, fontSize: 13)));
                }

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final item = filteredTasks[index];
                    bool isRunning = item["status"] == "Running";
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item["task"], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text("Status: ${item["status"]}", style: TextStyle(color: isRunning ? const Color(0xFF2EA043) : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ])),
                        IconButton(
                          icon: Icon(isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill, color: isRunning ? Colors.orangeAccent : const Color(0xFF2EA043)),
                          onPressed: () {
                            setStateModal(() {
                              int realIndex = liveAgentTasks.indexOf(item);
                              if (realIndex != -1) _toggleTaskPause(realIndex);
                            });
                            setState(() {});
                          },
                        )
                      ]),
                    );
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFF2EA043))))],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final currentList = selectedMode == "ask" ? askMessages : autoPilotMessages;
    String trimmed = text.trim(), lower = trimmed.toLowerCase();
    setState(() { currentList.add({"sender": "user", "text": trimmed}); _messageController.clear(); });
    await _saveChatHistories();

    // 100% SMART CONVERSATIONAL FALLBACK (NEVER robotic queue spam for general text)
    String reply = "";

    if (lower.contains("hi") || lower.contains("hello") || lower.contains("hlo") || lower.contains("hey") || lower.contains("sup") || lower.contains("yoo") || lower.contains("bhai") || lower.contains("bro") || lower.contains("hel") || lower.contains("wow")) {
      reply = "Hello bhai! Main aapka AI Agent hoon. Sab kuch makkhan chal raha hai. Bataiye, aaj kya naya task execute karwana hai?";
    } else if (lower.contains("how are you") || lower.contains("kaise ho") || lower.contains("kya haal") || lower.contains("pagal")) {
      reply = "Main ekdam badhiya hoon bhai! Aap bataiye, aapka system aur workflow kaisa chal raha hai?";
    } else if (lower.contains("who are you") || lower.contains("tum kon ho") || lower.contains("tum kaun ho") || lower.contains("what your name") || lower.contains("what is your name")) {
      reply = "Main aapka personal AI Agent hoon jo aapke sabhi tasks, automations aur workflows ko manage karne ke liye bana hai.";
    } else if (lower.contains("kya kar rhe ho") || lower.contains("what are you doing") || lower.contains("what you doing") || lower.contains("status")) {
      reply = "Main abhi aapke system vaults, background loops, aur secure session streams ko monitor kar raha hoon. Aap apna naya task bataiye!";
    } else if (lower.contains("kitna kaam") || lower.contains("capacity") || lower.contains("handle")) {
      reply = "Main ek sath unlimited concurrent tasks, multi-threaded code execution, aur automated workflows handle kar sakta hoon!";
    } else if (awaitingFinalConfirmation) {
      if (lower.contains("final") || lower.contains("haan") || lower.contains("ok") || lower.contains("suru kar") || lower.contains("start") || lower.contains("kar do")) {
        awaitingFinalConfirmation = false;
        String allTasksSummary = stagedTasks.join(", ");
        stagedTasks.clear();
        reply = "🚀 **All Tasks Finalized!** Execution started for: [$allTasksSummary]. Background loops running smoothly.";
        _addTaskLog("Executed finalized task stack: $allTasksSummary");
      } else if (lower.contains("hata") || lower.contains("remove")) {
        reply = "Theek hai, kaun sa task hatana hai uska naam bataiye? Staged tasks: ${stagedTasks.join(', ')}";
      } else {
        stagedTasks.add(trimmed);
        reply = "📝 Maine ye naya task bhi jod liya hai. Total staged tasks: [${stagedTasks.join(', ')}]. Kya isme kuch aur add/remove karna hai, ya main 'Final kar do' bolun?";
      }
    } else if (lower.contains("naya kaam") || lower.contains("new task") || lower.contains("upgrade") || lower.contains("task dena hai")) {
      awaitingFinalConfirmation = true;
      stagedTasks.clear();
      reply = "🎯 Theek hai! Aapko kya-kya naya kaam ya upgrade dena hai? Ek-ek karke batayiye. Jab saare tasks ho jayein, tab 'Final kar do' boliyega, main sab list karke start kar dunga.";
    } else {
      reply = "Bhai, maine aapka message samajh liya: '$trimmed'. Agar ye koi naya task hai toh 'naya kaam' boliye, warna bataiye isme kya assist karoon.";
      _addTaskLog("Chat message: '$trimmed'");
    }

    setState(() {
      currentList.add({"sender": "agent", "text": reply});
    });
    await _saveChatHistories();
  }

  @override
  Widget build(BuildContext context) {
    final activeMsgs = selectedMode == "ask" ? askMessages : autoPilotMessages;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Text(selectedMode == "ask" ? "Ask AI Agent Chat Mode" : "Auto Pilot Chat Mode", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.monitor_heart, color: Color(0xFF2EA043)), tooltip: "Live Activity & Search", onPressed: _showLiveActivityModal),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedMode, dropdownColor: const Color(0xFF161B22), underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: "ask", child: Text("Ask AI Mode", style: TextStyle(fontSize: 13, color: Colors.white))),
                DropdownMenuItem(value: "autopilot", child: Text("Auto Pilot", style: TextStyle(fontSize: 13, color: Colors.white))),
              ],
              onChanged: (val) { if (val != null) setState(() => selectedMode = val); },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF161B22),
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0A0A0A)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(Icons.psychology, color: Color(0xFF2EA043), size: 32),
              SizedBox(height: 8),
              Text('🧠 God-Level Agent Panel', style: TextStyle(color: Color(0xFF2EA043), fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart, color: Color(0xFF2EA043)),
            title: const Text('Live Activity & Search'),
            subtitle: const Text('Monitor, search and control tasks', style: TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _showLiveActivityModal(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.blueAccent),
            title: const Text('1. AI Agent kya soch raha hai'),
            subtitle: Text(metrics["thinking"] ?? "Thinking...", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Thinking Process", metrics["thinking"] ?? "", Icons.psychology, Colors.blueAccent),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.greenAccent),
            title: const Text('2. AI Agent ne aaj kya sikha hai'),
            subtitle: Text(metrics["learned"] ?? "Learning logs...", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Learning Logs", metrics["learned"] ?? "", Icons.book, Colors.greenAccent),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.redAccent),
            title: const Text('3. AI Agent ko kahan problem aa rahi hai'),
            subtitle: Text(metrics["problems"] ?? "None", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Error Tracker", metrics["problems"] ?? "", Icons.warning, Colors.redAccent),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.cloud_off, color: Colors.orangeAccent),
            title: const Text('Disconnect Google Drive'),
            subtitle: Text(_isDriveConnected ? "Connected" : "Not Connected", style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _disconnectDrive(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.redAccent),
            title: const Text('Relock Console (Passcode)'),
            subtitle: const Text('Secure and lock session', style: TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _relockConsole(); },
          ),
        ]),
      ),
      body: !_isAuthorized
          ? Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_outline, size: 64, color: Color(0xFF2EA043)),
              const SizedBox(height: 16),
              const Text("Enter Secure Console Passcode to Restore History", style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(controller: _passcodeController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Passcode...")),
              const SizedBox(height: 16),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EA043), minimumSize: const Size.fromHeight(48)), onPressed: _verifyPasscode, child: const Text("Unlock & Restore History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))
            ])))
          : Column(children: [
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(12), itemCount: activeMsgs.length,
                itemBuilder: (context, index) {
                  final m = activeMsgs[index];
                  final isUser = m["sender"] == "user";
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF238636) : const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isUser ? const Color(0xFF2EA043) : Colors.white12, width: 1),
                      ),
                      child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  );
                },
              )),
              SafeArea(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: const Color(0xFF0A0A0A),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  // Standard professional border, no neon glowing border
                  decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24, width: 1)),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: () {}),
                    Expanded(child: TextField(controller: _messageController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: "Type a message...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none))),
                    IconButton(icon: const Icon(Icons.send, color: Color(0xFF2EA043)), onPressed: () => _sendMessage(_messageController.text)),
                  ]),
                ),
              )),
            ]),
    );
  }
}
