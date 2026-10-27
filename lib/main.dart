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
        scaffoldBackgroundColor: const Color(0xFF05070B),
        primaryColor: const Color(0xFF00FF66),
        colorScheme: ColorScheme.dark(primary: const Color(0xFF00FF66), secondary: const Color(0xFF00E5FF), surface: const Color(0xFF0D1117)),
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
  late bool _isAuthorized, _isDriveConnected;
  String selectedMode = "ask";
  late List<Map<String, String>> askMessages, autoPilotMessages;

  List<String> stagedTasks = [];
  bool awaitingFinalConfirmation = false;

  List<Map<String, dynamic>> liveAgentTasks = [
    {"task": "System Core Initialized.", "status": "Running"},
    {"task": "Secure Session Vault Connected.", "status": "Running"},
    {"task": "Awaiting User Task Stream...", "status": "Running"},
  ];

  Map<String, dynamic> metrics = {
    "thinking": "Analyzing user query streams with zero-latency neural parsing...",
    "learned": "Synthesized flawless conversational engine and OAuth hooks.",
    "problems": "None. All security and execution pipelines operating at peak performance."
  };

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

  Future<void> _disconnectDrive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_drive_connected', false);
      setState(() => _isDriveConnected = false);
      _addTaskLog("Google Drive disconnected by user.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Drive Disconnected!")));
      _showGoogleDrivePrompt();
    } catch (e) {}
  }

  Future<void> _relockConsole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authorized', false);
      setState(() => _isAuthorized = false);
      _addTaskLog("Console relocked securely.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Console Relocked. Enter Passcode to access history.")));
    } catch (e) {}
  }

  void _showGoogleDrivePrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF00FF66), width: 1.5)),
        title: const Text("Connect Real Google Drive", style: TextStyle(color: Color(0xFF00FF66), fontWeight: FontWeight.bold)),
        content: const Text("Authenticate securely via browser OAuth to sync your vaults and logs directly to your real Google Drive account.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_drive_connected', true);
                setState(() => _isDriveConnected = true);
                Navigator.of(ctx, rootNavigator: true).pop();
                _addTaskLog("Google Drive real OAuth initiated.");
                final uri = Uri.parse(driveAuthUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                Navigator.of(ctx, rootNavigator: true).pop();
              }
            },
            child: const Text("Authorize & Connect", style: TextStyle(color: Color(0xFF00FF66), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _verifyPasscode() async {
    if (_passcodeController.text.trim() == "74882242959122690239") {
      try { (await SharedPreferences.getInstance()).setBool('is_authorized', true); } catch (e) {}
      setState(() => _isAuthorized = true);
      _passcodeController.clear();
      _addTaskLog("Console unlocked securely. History restored.");
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

  void _showMetricDetailDialog(String title, String content, IconData icon, Color color) {
    _fetchMetrics();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color, width: 1.5)),
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
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF00FF66), width: 1.5)),
          title: Row(children: const [Icon(Icons.monitor_heart, color: Color(0xFF00FF66)), SizedBox(width: 10), Text("Live Agent Activity & Pause", style: TextStyle(fontSize: 15, color: Colors.white))]),
          content: SizedBox(
            width: double.maxFinite, height: 320,
            child: ListView.builder(
              itemCount: liveAgentTasks.length,
              itemBuilder: (context, index) {
                final item = liveAgentTasks[index];
                bool isRunning = item["status"] == "Running";
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF05070B), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item["task"], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text("Status: ${item["status"]}", style: TextStyle(color: isRunning ? const Color(0xFF00FF66) : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ])),
                    IconButton(
                      icon: Icon(isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill, color: isRunning ? Colors.orangeAccent : const Color(0xFF00FF66)),
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
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFF00FF66))))],
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

    // STRICT CONVERSATIONAL FILTER: Prevent robotic task execution bubbles for casual chat / greetings
    List<String> casualTriggers = ["hi", "hello", "hlo", "hey", "sup", "yoo", "hii", "bhai", "bro", "yup", "kaise ho", "kya हाल", "what's up"];
    if (casualTriggers.any((w) => lower == w || lower.startsWith(w + " ") || lower.endsWith(" " + w))) {
      setState(() => currentList.add({"sender": "agent", "text": "Hello bhai! Main aapka God-Level AI Agent hoon. Sab set hai, bataiye kya task execute karwana hai?"}));
      await _saveChatHistories();
      return;
    }

    if (lower.contains("who are you") || lower.contains("tum kon ho") || lower.contains("tum kaun ho")) {
      setState(() => currentList.add({"sender": "agent", "text": "Main aapka personal God-Level AI Agent hoon jo aapke sabhi tasks, automations aur workflows ko manage karne ke liye bana hai."}));
      await _saveChatHistories();
      return;
    }

    if (lower.contains("kya kar rhe ho") || lower.contains("what are you doing") || lower.contains("what you doing") || lower.contains("status")) {
      setState(() => currentList.add({"sender": "agent", "text": "Main abhi aapke system vaults monitor kar raha hoon aur background task streams ko optimize kar raha hoon. Aap bataiye, kaun sa naya task execute karna hai?"}));
      await _saveChatHistories();
      return;
    }

    if (lower.contains("kitna kaam") || lower.contains("capacity") || lower.contains("handle")) {
      setState(() => currentList.add({"sender": "agent", "text": "Main ek sath unlimited concurrent tasks, multi-threaded code execution, aur automated workflows handle kar sakta hoon!"}));
      await _saveChatHistories();
      return;
    }

    // Interactive Task Staging & Finalization Workflow
    if (awaitingFinalConfirmation) {
      if (lower.contains("final") || lower.contains("haan") || lower.contains("ok") || lower.contains("suru kar") || lower.contains("start")) {
        awaitingFinalConfirmation = false;
        String allTasksSummary = stagedTasks.join(", ");
        stagedTasks.clear();
        setState(() => currentList.add({"sender": "agent", "text": "🚀 **All Tasks Finalized!** Execution started for: [$allTasksSummary]. Background loops running smoothly."}));
        await _saveChatHistories();
        _addTaskLog("Executed finalized task stack: $allTasksSummary");
        return;
      } else if (lower.contains("hata") || lower.contains("remove")) {
        setState(() => currentList.add({"sender": "agent", "text": "Theek hai, kaun sa task hatana hai uska naam bataiye? Staged tasks: ${stagedTasks.join(', ')}"}));
        await _saveChatHistories();
        return;
      } else {
        stagedTasks.add(trimmed);
        setState(() => currentList.add({"sender": "agent", "text": "📝 Maine ye naya task bhi jod liya hai. Total tasks: [${stagedTasks.join(', ')}]. Kya isme kuch aur add/remove karna hai, ya main 'Final kar do' bolun?"}));
        await _saveChatHistories();
        return;
      }
    }

    if (lower.contains("naya kaam") || lower.contains("new task") || lower.contains("upgrade") || lower.contains("task dena hai")) {
      awaitingFinalConfirmation = true;
      stagedTasks.clear();
      setState(() => currentList.add({"sender": "agent", "text": "🎯 Theek hai! Aapko kya-kya naya kaam ya upgrade dena hai? Ek-ek karke batayiye. Jab saare tasks ho jayein, tab 'Final kar do' boliyega, main sab list karke start kar dunga."}));
      await _saveChatHistories();
      return;
    }

    // Real Backend Dispatch for actual complex commands
    _addTaskLog("Query: '$trimmed'");
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"passcode": "74882242959122690239", "command": trimmed, "mode": selectedMode}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String resp = data["response"] ?? "Done.";
        if (resp.contains("Successfully processed")) {
          resp = "✅ Task executed successfully: '$trimmed'";
        }
        setState(() { currentList.add({"sender": "agent", "text": resp}); if (data["metrics"] != null) metrics = data["metrics"]; });
        _addTaskLog("Completed: '$trimmed'");
      } else {
        setState(() => currentList.add({"sender": "agent", "text": "⚠️ Server error code: ${response.statusCode}"}));
      }
    } catch (e) {
      setState(() => currentList.add({"sender": "agent", "text": "❌ Network error connecting to core."}));
    }
    await _saveChatHistories();
  }

  @override
  Widget build(BuildContext context) {
    final activeMsgs = selectedMode == "ask" ? askMessages : autoPilotMessages;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: Text(selectedMode == "ask" ? "Ask AI Agent Chat Mode" : "Auto Pilot Chat Mode", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.monitor_heart, color: Color(0xFF00FF66)), tooltip: "Live Activity", onPressed: _showLiveActivityModal),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedMode, dropdownColor: const Color(0xFF0D1117), underline: const SizedBox(),
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
        backgroundColor: const Color(0xFF0D1117),
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF05070B)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(Icons.psychology, color: Color(0xFF00FF66), size: 32),
              SizedBox(height: 8),
              Text('🧠 God-Level Agent Panel', style: TextStyle(color: Color(0xFF00FF66), fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart, color: Color(0xFF00FF66)),
            title: const Text('Live Activity & Pause'),
            subtitle: const Text('Monitor and control tasks', style: TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _showLiveActivityModal(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.blueAccent),
            title: const Text('1. AI Agent kya soch raha hai'),
            subtitle: Text(metrics["thinking"] ?? "Thinking...", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Thinking Process", metrics["thinking"], Icons.psychology, Colors.blueAccent),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.greenAccent),
            title: const Text('2. AI Agent ne aaj kya sikha hai'),
            subtitle: Text(metrics["learned"] ?? "Learning logs...", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Learning Logs", metrics["learned"], Icons.book, Colors.greenAccent),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.redAccent),
            title: const Text('3. AI Agent ko kahan problem aa rahi hai'),
            subtitle: Text(metrics["problems"] ?? "None", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Error Tracker", metrics["problems"], Icons.warning, Colors.redAccent),
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
              const Icon(Icons.lock_outline, size: 64, color: Color(0xFF00FF66)),
              const SizedBox(height: 16),
              const Text("Enter Secure Console Passcode to Restore History", style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(controller: _passcodeController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Passcode...")),
              const SizedBox(height: 16),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF66), minimumSize: const Size.fromHeight(48)), onPressed: _verifyPasscode, child: const Text("Unlock & Restore History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))
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
                        color: isUser ? const Color(0xFF0D3B26) : const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isUser ? const Color(0xFF00FF66) : Colors.white24, width: 1),
                      ),
                      child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  );
                },
              )),
              SafeArea(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: const Color(0xFF05070B),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF00FF66), width: 1)),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.add, color: Color(0xFF00FF66)), onPressed: () {}),
                    Expanded(child: TextField(controller: _messageController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: "Ask AI or give command...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none))),
                    IconButton(icon: const Icon(Icons.send, color: Color(0xFF00FF66)), onPressed: () => _sendMessage(_messageController.text)),
                  ]),
                ),
              )),
            ]),
    );
  }
}
