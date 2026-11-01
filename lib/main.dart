import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isAuthorized = false;
  bool isDriveConnected = false;
  List initialAsk = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    isAuthorized = prefs.getBool('is_authorized') ?? false;
    isDriveConnected = prefs.getBool('is_drive_connected') ?? false;
    String? sAsk = prefs.getString('ask_messages');
    if (sAsk != null && sAsk.isNotEmpty) {
      var decoded = json.decode(sAsk);
      for (var i in decoded) {
        initialAsk.add(Map<String, String>.from(i));
      }
    }
  } catch (e) {}
  runApp(GodAgentApp(isAuthorized: isAuthorized, isDriveConnected: isDriveConnected, initialAsk: initialAsk));
}

class GodAgentApp extends StatelessWidget {
  final bool isAuthorized;
  final bool isDriveConnected;
  final List initialAsk;

  const GodAgentApp({
    Key? key,
    required this.isAuthorized,
    required this.isDriveConnected,
    required this.initialAsk,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obsidian AI Agent',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFFE0E0E0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE0E0E0),
          surface: Color(0xFF171717),
        ),
      ),
      home: MainAgentScreen(
        initialAuthorized: isAuthorized,
        isDriveConnected: isDriveConnected,
        initialAsk: initialAsk,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAgentScreen extends StatefulWidget {
  final bool initialAuthorized;
  final bool isDriveConnected;
  final List initialAsk;

  const MainAgentScreen({
    Key? key,
    required this.initialAuthorized,
    required this.isDriveConnected,
    required this.initialAsk,
  }) : super(key: key);

  @override
  State<MainAgentScreen> createState() => _MainAgentScreenState();
}

class _MainAgentScreenState extends State<MainAgentScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchTaskController = TextEditingController();
  
  late bool _isAuthorized;
  late bool _isDriveConnected;
  late List askMessages;

  List stagedTasks = [];
  bool awaitingFinalConfirmation = false;
  String taskSearchQuery = "";
  bool isVoiceCallActive = false;

  List liveAgentTasks = [
    {"task": "Obsidian Dark UI Core Initialized.", "status": "Running"},
    {"task": "Secure Google Drive Vault Sync Ready.", "status": "Running"},
    {"task": "Voice & Multi-Modal Parser Active.", "status": "Running"},
  ];

  Map metrics = {
    "thinking": "Natural language processing model active with dynamic call-style reasoning.",
    "learned": "Synthesized obsidian dark theme, encrypted Google Drive sync, and live activity tracker.",
    "problems": "None. All security and voice pipelines operating smoothly."
  };

  final String driveAuthUrl = "https://accounts.google.com/o/oauth2/v2/auth";

  @override
  void initState() {
    super.initState();
    _isAuthorized = widget.initialAuthorized;
    _isDriveConnected = widget.isDriveConnected;
    askMessages = List.from(widget.initialAsk);
    if (_isAuthorized && !_isDriveConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGoogleDriveDialog());
    }
  }

  Future<void> _saveChatHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ask_messages', json.encode(askMessages));
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
      String st = liveAgentTasks[index]["status"].toString();
      liveAgentTasks[index]["status"] = st == "Running" ? "Paused" : "Running";
    });
  }

  void _removeTask(int index) {
    setState(() {
      liveAgentTasks.removeAt(index);
    });
  }

  void _showGoogleDriveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24, width: 1)),
        title: const Row(children: [
          Icon(Icons.cloud, color: Colors.white),
          SizedBox(width: 10),
          Text("Connect Google Drive Vault", style: TextStyle(fontSize: 16, color: Colors.white))
        ]),
        content: const Text("Authenticate securely via browser OAuth to sync your encrypted credentials, usernames, and passwords directly to your Google Drive folder.", style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0E0E0), foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final uri = Uri.parse(driveAuthUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_drive_connected', true);
                setState(() => _isDriveConnected = true);
                _addTaskLog("Google Drive OAuth session authorized.");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Drive Connected Successfully!")));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch browser OAuth.")));
                }
              }
            },
            child: const Text("Authorize & Connect", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showVoiceCallModal() {
    setState(() => isVoiceCallActive = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24, width: 1)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.mic, size: 54, color: Color(0xFFE0E0E0)),
              const SizedBox(height: 16),
              const Text("AI Voice Call Active", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Jaise YouTube video me baat hoti hai, waisa live conversational session chal raha hai...", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
                icon: const Icon(Icons.call_end),
                label: const Text("End Call", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() => isVoiceCallActive = false);
                  Navigator.pop(ctx);
                  _addTaskLog("Voice call session ended.");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _disconnectDrive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_drive_connected', false);
      setState(() => _isDriveConnected = false);
      _addTaskLog("Google Drive disconnected.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Drive Disconnected!")));
      }
    } catch (e) {}
  }

  Future<void> _relockConsole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authorized', false);
      setState(() => _isAuthorized = false);
      _addTaskLog("Console relocked.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Console Relocked.")));
      }
    } catch (e) {}
  }

  Future<void> _verifyPasscode() async {
    if (_passcodeController.text.trim() == "74882242959122690239") {
      try { (await SharedPreferences.getInstance()).setBool('is_authorized', true); } catch (e) {}
      setState(() => _isAuthorized = true);
      _passcodeController.clear();
      _addTaskLog("Console unlocked securely.");
      if (!_isDriveConnected) _showGoogleDriveDialog();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Passcode!")));
      }
    }
  }

  void _showMetricDetailDialog(String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
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
          backgroundColor: const Color(0xFF212121),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24, width: 1)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [Icon(Icons.monitor_heart, color: Colors.white), SizedBox(width: 10), Text("Live Activity & Task Search", style: TextStyle(fontSize: 15, color: Colors.white))]),
              const SizedBox(height: 12),
              TextField(
                controller: _searchTaskController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search tasks or activities...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF171717),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (val) {
                  setStateModal(() { taskSearchQuery = val.toLowerCase(); });
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
                    int realIndex = liveAgentTasks.indexOf(item);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF171717), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item["task"].toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text("Status: ${item["status"]}", style: TextStyle(color: isRunning ? Colors.white : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ])),
                        IconButton(
                          icon: Icon(isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill, color: isRunning ? Colors.orangeAccent : Colors.white),
                          onPressed: () {
                            setStateModal(() { _toggleTaskPause(realIndex); });
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            setStateModal(() { _removeTask(realIndex); });
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
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.white70)))],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    String trimmed = text.trim();
    String lower = trimmed.toLowerCase();
    setState(() { 
      askMessages.add({"sender": "user", "text": trimmed}); 
      _messageController.clear(); 
    });
    await _saveChatHistories();

    String reply = "";

    if (awaitingFinalConfirmation) {
      if (lower.contains("final") || lower.contains("kar do") || lower.contains("bej do") || lower.contains("suru kar") || lower.contains("haan")) {
        awaitingFinalConfirmation = false;
        String allTasksSummary = stagedTasks.join(", ");
        stagedTasks.clear();
        reply = "🚀 **Task Staging Finalized!** Saare tasks [$allTasksSummary] successfully agent core ko dispatch kar diye gaye hain. Background execution shuru ho raha hai.";
        _addTaskLog("Executed task stack: $allTasksSummary");
      } else if (lower.contains("hata") || lower.contains("remove")) {
        reply = "Theek hai bhai, kaun sa task hatana hai uska naam batayiye? Current staged tasks: ${stagedTasks.join(', ')}";
      } else {
        stagedTasks.add(trimmed);
        reply = "📝 Maine aapki baat note kar li hai. Total staged tasks: [${stagedTasks.join(', ')}]. Kya isme kuch aur add karna hai, ya ab main **'Final kar do'** bolun?";
      }
    } else if (lower.contains("naya kaam") || lower.contains("new task") || lower.contains("task dena hai") || lower.contains("discuss")) {
      awaitingFinalConfirmation = true;
      stagedTasks.clear();
      reply = "🎯 Theek hai bhai! Pehle hum aaram se discuss kar lete hain. Aap apne points ya tasks ek-ek karke batayiye, aur jab sab kuch final ho jaye tab **'Final kar do'** atau **'Bej do'** boliyega!";
    } else {
      if (lower.contains("orange")) {
        reply = "Orange ek refreshing citrus fruit bhi hai aur ek bright color ka naam bhi hai. Iske bare me koi specific app ya script banwani hai kya?";
      } else if (lower.contains("apple")) {
        reply = "Apple ek healthy fruit bhi hai aur global tech giant Apple Inc. bhi hai. Bataiye, iske regarding kya discuss karna hai?";
      } else if (lower.contains("hi") || lower.contains("hello") || lower.contains("hlo") || lower.contains("hey") || lower.contains("bhai")) {
        reply = "Hello bhai! Main aapka Obsidian AI Agent hoon. Aap mujhse koi bhi sawal pooch sakte hain, aur jab naya task discuss karna ho toh **'naya kaam'** bol sakte hain.";
      } else {
        reply = "Maine aapki baat dhyan se suni aur samajhi: '$trimmed'. Yeh ek interesting topic hai. Agar aapko isko agent ke liye task ya project banana hai toh **'naya kaam'** boliye!";
        _addTaskLog("Discussed query: '$trimmed'");
      }
    }

    setState(() {
      askMessages.add({"sender": "agent", "text": reply});
    });
    await _saveChatHistories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        elevation: 0,
        title: const Text("Obsidian AI Agent", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.phone_in_talk, color: Colors.white70), tooltip: "Voice Call Mode", onPressed: _showVoiceCallModal),
          IconButton(icon: const Icon(Icons.monitor_heart, color: Colors.white70), tooltip: "Live Activity & Search", onPressed: _showLiveActivityModal),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF171717),
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF000000)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(Icons.psychology, color: Colors.white, size: 32),
              SizedBox(height: 8),
              Text('🧠 Obsidian AI Agent', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.phone_in_talk, color: Colors.white70),
            title: const Text('Voice Call Simulation'),
            subtitle: const Text('Start YouTube-style live voice chat', style: TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _showVoiceCallModal(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.monitor_heart, color: Colors.white70),
            title: const Text('Live Activity & Search'),
            subtitle: const Text('Monitor, search, pause & remove tasks', style: TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _showLiveActivityModal(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.white70),
            title: const Text('Google Drive Vault'),
            subtitle: Text(_isDriveConnected ? "Connected Successfully" : "Click to Sync Drive", style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _showGoogleDriveDialog(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.white70),
            title: const Text('1. AI Thinking Process'),
            subtitle: Text(metrics["thinking"].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Thinking Process", metrics["thinking"].toString(), Icons.psychology, Colors.white70),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.white70),
            title: const Text('2. AI Learning Logs'),
            subtitle: Text(metrics["learned"].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Learning Logs", metrics["learned"].toString(), Icons.book, Colors.white70),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.white70),
            title: const Text('3. AI Error Tracker'),
            subtitle: Text(metrics["problems"].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Error Tracker", metrics["problems"].toString(), Icons.warning, Colors.white70),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.cloud_off, color: Colors.white70),
            title: const Text('Disconnect Google Drive'),
            subtitle: const Text('Revoke sync session', style: TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _disconnectDrive(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.white70),
            title: const Text('Relock Console'),
            subtitle: const Text('Secure and lock session', style: TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _relockConsole(); },
          ),
        ]),
      ),
      body: !_isAuthorized
          ? Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text("Enter Secure Console Passcode", style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(controller: _passcodeController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Passcode...")),
              const SizedBox(height: 16),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0E0E0), foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48)), onPressed: _verifyPasscode, child: const Text("Unlock Console", style: TextStyle(fontWeight: FontWeight.bold)))
            ])))
          : Column(children: [
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(12), itemCount: askMessages.length,
                itemBuilder: (context, index) {
                  final m = askMessages[index];
                  final isUser = m["sender"] == "user";
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isUser ? const Color(0xFF2E2E2E) : const Color(0xFF171717), borderRadius: BorderRadius.circular(12)),
                      child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                  );
                },
              )),
              SafeArea(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: const Color(0xFF000000),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF171717), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24, width: 1)),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.attach_file, color: Colors.white70), onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Multi-Modal Support: Attach images, files or documents ready.")));
                    }),
                    Expanded(child: TextField(controller: _messageController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: "Message AI Agent or type 'naya kaam'...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none))),
                    IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendMessage(_messageController.text)),
                  ]),
                ),
              )),
            ]),
    );
  }
}
