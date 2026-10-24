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
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF0D1117), primaryColor: const Color(0xFF58A6FF)),
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
  late bool _isAuthorized, _isDriveConnected;
  String selectedMode = "ask";
  late List<Map<String, String>> askMessages, autoPilotMessages;
  List<Map<String, dynamic>> liveAgentTasks = [
    {"task": "System Initialized successfully.", "status": "Running"},
    {"task": "Connected to secure session storage.", "status": "Running"},
    {"task": "Awaiting user task inputs...", "status": "Running"},
  ];
  Map<String, dynamic> metrics = {"thinking": "System active.", "learned": "Bilingual active.", "problems": "None."};
  final String backendUrl = "https://god-agent-core.onrender.com/command";
  final String metricsUrl = "https://god-agent-core.onrender.com/metrics";
  final String driveAuthUrl = "https://god-agent-core.onrender.com/auth/google";

  @override
  void initState() {
    super.initState();
    _isAuthorized = widget.initialAuthorized;
    _isDriveConnected = widget.initialDriveConnected;
    askMessages = List.from(widget.initialAsk);
    autoPilotMessages = List.from(widget.initialAuto);
    _fetchMetrics();
    if (_isAuthorized && !_isDriveConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGoogleDrivePrompt());
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
      if (liveAgentTasks.length > 30) liveAgentTasks.removeLast();
    });
  }

  void _toggleTaskPause(int index) {
    setState(() {
      String st = liveAgentTasks[index]["status"];
      liveAgentTasks[index]["status"] = st == "Running" ? "Paused" : "Running";
    });
  }

  void _showGoogleDrivePrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("Connect Google Drive", style: TextStyle(color: Colors.orangeAccent)),
        content: const Text("Link Google Drive via secure OAuth for cloud sync."),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_drive_connected', true);
                setState(() => _isDriveConnected = true);
                Navigator.of(ctx, rootNavigator: true).pop();
                _addTaskLog("Google Drive OAuth initiated.");
                final uri = Uri.parse(driveAuthUrl);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                Navigator.of(ctx, rootNavigator: true).pop();
              }
            },
            child: const Text("Authorize & Connect", style: TextStyle(color: Color(0xFF58A6FF))),
          )
        ],
      ),
    );
  }

  Future<void> _verifyPasscode() async {
    if (_passcodeController.text.trim() == "74882242959122690239") {
      try { (await SharedPreferences.getInstance()).setBool('is_authorized', true); } catch (e) {}
      setState(() => _isAuthorized = true);
      _addTaskLog("Console unlocked.");
      if (!_isDriveConnected) _showGoogleDrivePrompt();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Passcode!")));
    }
  }

  Future<void> _fetchMetrics() async {
    try {
      final res = await http.get(Uri.parse(metricsUrl));
      if (res.statusCode == 200) setState(() => metrics = json.decode(res.body));
    } catch (e) {}
  }

  void _showLiveActivityModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setStateModal) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: Row(children: const [Icon(Icons.monitor_heart, color: Colors.greenAccent), SizedBox(width: 10), Text("Live Agent Activity & Control", style: TextStyle(fontSize: 15, color: Colors.white))]),
          content: SizedBox(
            width: double.maxFinite, height: 320,
            child: ListView.builder(
              itemCount: liveAgentTasks.length,
              itemBuilder: (context, index) {
                final item = liveAgentTasks[index];
                bool isRunning = item["status"] == "Running";
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item["task"], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text("Status: ${item["status"]}", style: TextStyle(color: isRunning ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ])),
                    IconButton(
                      icon: Icon(isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill, color: isRunning ? Colors.orangeAccent : Colors.greenAccent),
                      onPressed: () {
                        setStateModal(() => _toggleTaskPause(index));
                        setState(() {});
                      },
                    )
                  ]),
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFF58A6FF))))],
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
    _addTaskLog("Query: '$trimmed'");

    if (["hi", "hello", "hlo", "hey", "sup", "kaise ho"].any((w) => lower.contains(w))) {
      setState(() => currentList.add({"sender": "agent", "text": "Hello bhai! Main aapka God-Level AI Agent hoon. Bataiye kya task karna hai?"}));
      await _saveChatHistories();
      return;
    }
    if (lower.contains("who are you") || lower.contains("tum kon ho")) {
      setState(() => currentList.add({"sender": "agent", "text": "Main aapka personal God-Level AI Agent hoon jo aapke tasks manage karta hai."}));
      await _saveChatHistories();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"passcode": "74882242959122690239", "command": trimmed, "mode": selectedMode}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String resp = data["response"] ?? "Done.";
        if (resp.contains("Successfully processed")) resp = "✅ Task completed: '$trimmed'";
        setState(() { currentList.add({"sender": "agent", "text": resp}); if (data["metrics"] != null) metrics = data["metrics"]; });
        _addTaskLog("Completed: '$trimmed'");
      } else {
        setState(() => currentList.add({"sender": "agent", "text": "⚠️ Server error: ${response.statusCode}"}));
      }
    } catch (e) {
      setState(() => currentList.add({"sender": "agent", "text": "❌ Network error."}));
    }
    await _saveChatHistories();
  }

  @override
  Widget build(BuildContext context) {
    final activeMsgs = selectedMode == "ask" ? askMessages : autoPilotMessages;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text(selectedMode == "ask" ? "Ask AI Agent Chat Mode" : "Auto Pilot Chat Mode", style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(icon: const Icon(Icons.monitor_heart, color: Colors.greenAccent), onPressed: _showLiveActivityModal),
          DropdownButton<String>(
            value: selectedMode, dropdownColor: const Color(0xFF161B22), underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: "ask", child: Text("Ask AI Mode", style: TextStyle(fontSize: 13, color: Colors.white))),
              DropdownMenuItem(value: "autopilot", child: Text("Auto Pilot", style: TextStyle(fontSize: 13, color: Colors.white))),
            ],
            onChanged: (val) { if (val != null) setState(() => selectedMode = val); },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF161B22),
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(decoration: BoxDecoration(color: Color(0xFF21262D)), child: Text('🧠 Agent Panel', style: TextStyle(color: Color(0xFF58A6FF), fontSize: 16))),
          ListTile(leading: const Icon(Icons.monitor_heart, color: Colors.greenAccent), title: const Text('Live Activity & Pause'), onTap: () { Navigator.pop(context); _showLiveActivityModal(); }),
        ]),
      ),
      body: !_isAuthorized
          ? Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_outline, size: 64, color: Color(0xFF58A6FF)),
              const SizedBox(height: 16),
              const Text("Enter Passcode", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              TextField(controller: _passcodeController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 16),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636)), onPressed: _verifyPasscode, child: const Text("Unlock"))
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
                      decoration: BoxDecoration(color: isUser ? const Color(0xFF238636) : const Color(0xFF21262D), borderRadius: BorderRadius.circular(12)),
                      child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  );
                },
              )),
              SafeArea(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: const Color(0xFF0D1117),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.add, color: Color(0xFF58A6FF)), onPressed: () {}),
                    Expanded(child: TextField(controller: _messageController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: "Ask AI...", border: InputBorder.none))),
                    IconButton(icon: const Icon(Icons.send, color: Color(0xFF58A6FF)), onPressed: () => _sendMessage(_messageController.text)),
                  ]),
                ),
              )),
            ]),
    );
  }
}
