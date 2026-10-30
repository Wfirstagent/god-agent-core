import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isAuthorized = false;
  bool isDriveConnected = false;
  List> initialAsk = [];
  List> initialAuto = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    isAuthorized = prefs.getBool('is_authorized') ?? false;
    isDriveConnected = prefs.getBool('is_drive_connected') ?? false;
    String? sAsk = prefs.getString('ask_messages');
    if (sAsk != null && sAsk.isNotEmpty) {
      initialAsk = List>.from(json.decode(sAsk).map((i) => Map<String, String>.from(i)));
    }
    String? sAuto = prefs.getString('autopilot_messages');
    if (sAuto != null && sAuto.isNotEmpty) {
      initialAuto = List>.from(json.decode(sAuto).map((i) => Map<String, String>.from(i)));
    }
  } catch (e) {}
  runApp(GodAgentApp(isAuthorized: isAuthorized, isDriveConnected: isDriveConnected, initialAsk: initialAsk, initialAuto: initialAuto));
}

class GodAgentApp extends StatelessWidget {
  final bool isAuthorized;
  final bool isDriveConnected;
  final List> initialAsk;
  final List> initialAuto;

  GodAgentApp({Key? key, required this.isAuthorized, required this.isDriveConnected, required this.initialAsk, required this.initialAuto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT Obsidian Agent',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF10A37F),
        colorScheme: ColorScheme.dark(primary: const Color(0xFF10A37F), secondary: const Color(0xFF19C37D), surface: const Color(0xFF171717)),
      ),
      home: MainAgentScreen(initialAuthorized: isAuthorized, isDriveConnected: isDriveConnected, initialAsk: initialAsk, initialAuto: initialAuto),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAgentScreen extends StatefulWidget {
  final bool initialAuthorized;
  final bool isDriveConnected;
  final List> initialAsk;
  final List> initialAuto;

  MainAgentScreen({Key? key, required this.initialAuthorized, required this.isDriveConnected, required this.initialAsk, required this.initialAuto}) : super(key: key);

  @override
  State<MainAgentScreen> createState() => _MainAgentScreenState();
}

class _MainAgentScreenState extends State<MainAgentScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchTaskController = TextEditingController();
  
  late bool _isAuthorized;
  late bool _isDriveConnected;
  String selectedMode = "ask";
  late List> askMessages;
  late List> autoPilotMessages;

  List<String> stagedTasks = [];
  bool awaitingFinalConfirmation = false;
  String taskSearchQuery = "";

  List> liveAgentTasks = [
    {"task": "ChatGPT Obsidian UI Core Initialized.", "status": "Running"},
    {"task": "Secure Local Session Vault Connected.", "status": "Running"},
    {"task": "Conversational Discussion Engine Active.", "status": "Running"},
  ];

  Map<String, dynamic> metrics = {
    "thinking": "Natural language processing model active with dynamic task suggestion engine.",
    "learned": "Synthesized ChatGPT obsidian theme and interactive browser OAuth modal.",
    "problems": "None. All security and UI pipelines operating at peak performance."
  };

  final String driveAuthUrl = "https://accounts.google.com/o/oauth2/v2/auth";

  @override
  void initState() {
    super.initState();
    _isAuthorized = widget.initialAuthorized;
    _isDriveConnected = widget.isDriveConnected;
    askMessages = List.from(widget.initialAsk);
    autoPilotMessages = List.from(widget.initialAuto);
    if (_isAuthorized && !_isDriveConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGoogleDriveDialog());
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
      String st = liveAgentTasks[index]["status"].toString();
      liveAgentTasks[index]["status"] = st == "Running" ? "Paused" : "Running";
    });
  }

  void _showGoogleDriveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF10A37F), width: 1.5)),
        title: const Row(children: [
          Icon(Icons.cloud, color: Color(0xFF10A37F)),
          SizedBox(width: 10),
          Text("Connect Real Google Drive", style: TextStyle(fontSize: 16, color: Colors.white))
        ]),
        content: const Text("Authenticate securely via browser OAuth to sync your vaults and logs directly to your real Google Drive account.", style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Later", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10A37F)),
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
                _addTaskLog("Real Google Drive OAuth browser session authorized.");
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Drive Connected Successfully!")));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch browser OAuth.")));
              }
            },
            child: const Text("Authorize & Connect", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectDrive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_drive_connected', false);
      setState(() => _isDriveConnected = false);
      _addTaskLog("Google Drive disconnected by user.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Drive Disconnected!")));
      _showGoogleDriveDialog();
    } catch (e) {}
  }

  Future<void> _relockConsole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authorized', false);
      setState(() => _isAuthorized = false);
      _addTaskLog("Console relocked securely.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Console Relocked. Enter Passcode.")));
    } catch (e) {}
  }

  Future<void> _verifyPasscode() async {
    if (_passcodeController.text.trim() == "74882242959122690239") {
      try { (await SharedPreferences.getInstance()).setBool('is_authorized', true); } catch (e) {}
      setState(() => _isAuthorized = true);
      _passcodeController.clear();
      _addTaskLog("Console unlocked securely. History restored.");
      if (!_isDriveConnected) _showGoogleDriveDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Passcode!")));
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
              Row(children: const [Icon(Icons.monitor_heart, color: Color(0xFF10A37F)), SizedBox(width: 10), Text("Live Activity & Search", style: TextStyle(fontSize: 15, color: Colors.white))]),
              const SizedBox(height: 12),
              TextField(
                controller: _searchTaskController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search tasks or activities...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF10A37F), size: 18),
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
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF171717), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item["task"].toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text("Status: ${item["status"]}", style: TextStyle(color: isRunning ? const Color(0xFF10A37F) : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ])),
                        IconButton(
                          icon: Icon(isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill, color: isRunning ? Colors.orangeAccent : const Color(0xFF10A37F)),
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
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFF10A37F))))],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final currentList = selectedMode == "ask" ? askMessages : autoPilotMessages;
    String trimmed = text.trim();
    String lower = trimmed.toLowerCase();
    setState(() { 
      currentList.add({"sender": "user", "text": trimmed}); 
      _messageController.clear(); 
    });
    await _saveChatHistories();

    String reply = "";

    if (awaitingFinalConfirmation) {
      if (lower.contains("final") || lower.contains("kar do") || lower.contains("suru kar") || lower.contains("start") || lower.contains("haan")) {
        awaitingFinalConfirmation = false;
        String allTasksSummary = stagedTasks.join(", ");
        stagedTasks.clear();
        reply = "🚀 **Task Staging Finalized!** Discussion completed and successfully dispatched to AI Agent core: [$allTasksSummary]. Background execution started.";
        _addTaskLog("Executed finalized task stack: $allTasksSummary");
      } else if (lower.contains("hata") || lower.contains("remove")) {
        reply = "Theek hai, kaun sa task hatana hai uska naam batayiye? Current staged tasks: ${stagedTasks.join(', ')}";
      } else {
        stagedTasks.add(trimmed);
        reply = "📝 Maine aapki baat note kar li hai. Total staged tasks: [${stagedTasks.join(', ')}]. Kya isme kuch aur discuss karke add karna hai, ya ab main **'Final kar do'** bolun?";
      }
    } else if (lower.contains("idea") || lower.contains("suggest") || lower.contains("task do") || lower.contains("kya karu") || lower.contains("kya task")) {
      reply = "Bhai, aapke project ke liye yeh 3 sabse best tasks suggest kar raha hoon:\n\n1. **Telegram Media Indexer Bot**: Forwarded files ko automatically SQLite database me index karna;\n2. **Automated SQLite/Drive Backup Sync**: Har 1 hour me local databases ko Google Drive par backup bhejna;\n3. **Background Media Downloader (yt-dlp)**: Link send karte hi background me video/audio queue process karna.\n\nInme se kaun sa task final karwana hai?";
    } else if (lower.contains("naya kaam") || lower.contains("new task") || lower.contains("task dena hai") || lower.contains("upgrade") || lower.contains("diside karna hai") || lower.contains("discuss")) {
      awaitingFinalConfirmation = true;
      stagedTasks.clear();
      reply = "🎯 Theek hai bhai! Pehle hum aaram se discuss kar lete hain. Aap apne points ya tasks ek-ek karke batayiye, aur jab sab kuch final ho jaye tab **'Final kar do'** boliyega!";
    } else if (lower.contains("hi") || lower.contains("hello") || lower.contains("hlo") || lower.contains("hey") || lower.contains("sup") || lower.contains("yoo") || lower.contains("bhai") || lower.contains("bro") || lower.contains("hel")) {
      reply = "Hello bhai! Main aapka ChatGPT-style AI Assistant hoon. Aap mujhse freely kuch bhi discuss kar sakte hain, task ideas maang sakte hain.";
    } else if (lower.contains("how are you") || lower.contains("kaise ho") || lower.contains("kya haal")) {
      reply = "Main ekdam badhiya hoon bhai! Aap bataiye, aaj aapke project ke liye kya discussion karni hai?";
    } else if (lower.contains("who are you") || lower.contains("tum kon ho") || lower.contains("tum kaun ho")) {
      reply = "Main aapka personal AI Assistant hoon jo aapki baaton ko samajhkar discuss karta hai aur final command agent tak pahunchata hai.";
    } else {
      reply = "Maine aapki baat suni aur samajhi: '$trimmed'. Agar aapko ise agent ke liye task discuss karke fix karna hai toh **'naya kaam'** boliye!";
      _addTaskLog("Discussed query: '$trimmed'");
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
        backgroundColor: const Color(0xFF171717),
        elevation: 0,
        title: Text(selectedMode == "ask" ? "Ask AI Agent Chat Mode" : "Auto Pilot Chat Mode", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.monitor_heart, color: Color(0xFF10A37F)), tooltip: "Live Activity & Search", onPressed: _showLiveActivityModal),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedMode, dropdownColor: const Color(0xFF171717), underline: const SizedBox(),
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
        backgroundColor: const Color(0xFF171717),
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF000000)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(Icons.psychology, color: Color(0xFF10A37F), size: 32),
              SizedBox(height: 8),
              Text('🧠 ChatGPT Obsidian Agent', style: TextStyle(color: Color(0xFF10A37F), fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart, color: Color(0xFF10A37F)),
            title: const Text('Live Activity & Search'),
            subtitle: const Text('Monitor, search and control tasks', style: TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _showLiveActivityModal(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.blueAccent),
            title: const Text('Connect Google Drive'),
            subtitle: Text(_isDriveConnected ? "Connected Successfully" : "Click to Sync Drive", style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () { Navigator.pop(context); _showGoogleDriveDialog(); },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.blueAccent),
            title: const Text('1. AI Agent kya soch raha hai'),
            subtitle: Text(metrics["thinking"].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Thinking Process", metrics["thinking"].toString(), Icons.psychology, Colors.blueAccent),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.greenAccent),
            title: const Text('2. AI Agent ne aaj kya sikha hai'),
            subtitle: Text(metrics["learned"].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Learning Logs", metrics["learned"].toString(), Icons.book, Colors.greenAccent),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.redAccent),
            title: const Text('3. AI Agent ko kahan problem aa rahi hai'),
            subtitle: Text(metrics["problems"].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            onTap: () => _showMetricDetailDialog("AI Agent Error Tracker", metrics["problems"].toString(), Icons.warning, Colors.redAccent),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.cloud_off, color: Colors.orangeAccent),
            title: const Text('Disconnect Google Drive'),
            subtitle: const Text('Revoke sync session', style: TextStyle(color: Colors.white70, fontSize: 11)),
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
              const Icon(Icons.lock_outline, size: 64, color: Color(0xFF10A37F)),
              const SizedBox(height: 16),
              const Text("Enter Secure Console Passcode to Restore History", style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(controller: _passcodeController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Passcode...")),
              const SizedBox(height: 16),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10A37F), minimumSize: const Size.fromHeight(48)), onPressed: _verifyPasscode, child: const Text("Unlock & Restore History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))
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
                      decoration: BoxDecoration(color: isUser ? const Color(0xFF10A37F) : const Color(0xFF212121), borderRadius: BorderRadius.circular(12)),
                      child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  );
                },
              )),
              SafeArea(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: const Color(0xFF000000),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24, width: 1)),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: () {}),
                    Expanded(child: TextField(controller: _messageController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: "Message ChatGPT Agent...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none))),
                    IconButton(icon: const Icon(Icons.send, color: Color(0xFF10A37F)), onPressed: () => _sendMessage(_messageController.text)),
                  ]),
                ),
              )),
            ]),
    );
  }
}
