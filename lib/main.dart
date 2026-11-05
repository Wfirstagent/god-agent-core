import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isAuthorized = false;
  bool isDriveConnected = false;
  List initialLogs = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    isAuthorized = prefs.getBool('is_authorized') ?? false;
    isDriveConnected = prefs.getBool('is_drive_connected') ?? false;
    String? logsData = prefs.getString('deven_logs');
    if (logsData != null && logsData.isNotEmpty) {
      var decoded = json.decode(logsData);
      if (decoded is List) {
        initialLogs = decoded;
      }
    }
  } catch (e) {}
  runApp(GodDevenApp(isAuthorized: isAuthorized, isDriveConnected: isDriveConnected, initialLogs: initialLogs));
}

class GodDevenApp extends StatelessWidget {
  final bool isAuthorized;
  final bool isDriveConnected;
  final List initialLogs;

  const GodDevenApp({
    Key? key,
    required this.isAuthorized,
    required this.isDriveConnected,
    required this.initialLogs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'God Deven AI Agent',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFFE0E0E0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE0E0E0),
          surface: Color(0xFF171717),
        ),
      ),
      home: DevenDashboardScreen(
        initialAuthorized: isAuthorized,
        isDriveConnected: isDriveConnected,
        initialLogs: initialLogs,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DevenDashboardScreen extends StatefulWidget {
  final bool initialAuthorized;
  final bool isDriveConnected;
  final List initialLogs;

  const DevenDashboardScreen({
    Key? key,
    required this.initialAuthorized,
    required this.isDriveConnected,
    required this.initialLogs,
  }) : super(key: key);

  @override
  State<DevenDashboardScreen> createState() => _DevenDashboardScreenState();
}

class _DevenDashboardScreenState extends State<DevenDashboardScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  late bool _isAuthorized;
  late bool _isDriveConnected;
  late List chatLogs;

  String selectedStatRange = "1 Day";
  bool isCloudBusy = false;
  String cloudStatusText = "Deven's Cloud Computer: Idle (Autonomous Skill Mining from YouTube/Reels & Web)";
  
  final List cloudTasks = [
    {"task": "GitHub Auto-Sync & Repo Indexing", "status": "Running"},
    {"task": "YouTube & Instagram Deep Plugin Handlers", "status": "Active"},
    {"task": "VK Social Bridge Initialized", "status": "Connected"},
    {"task": "Autonomous Idle Skill Miner", "status": "Learning Reels/Shorts"}
  ];

  @override
  void initState() {
    super.initState();
    _isAuthorized = widget.initialAuthorized;
    _isDriveConnected = widget.isDriveConnected;
    chatLogs = List.from(widget.initialLogs);
    if (chatLogs.isEmpty) {
      chatLogs.add({
        "sender": "deven",
        "text": "Namaste! Main hoon God Deven (Nickname: Deven). Aapka Cloud Computer aur Universal Plugins (GitHub, YouTube, Instagram, VK) fully active hain."
      });
    }
  }

  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deven_logs', json.encode(chatLogs));
    } catch (e) {}
  }

  void _verifyPasscode() {
    if (_passcodeController.text.trim() == "74882242959122690239") {
      SharedPreferences.getInstance().then((p) => p.setBool('is_authorized', true));
      setState(() => _isAuthorized = true);
      _passcodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("God Deven Console Unlocked Successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Passcode!")));
    }
  }

  void _sendDevenMessage(String text) async {
    if (text.trim().isEmpty) return;
    String query = text.trim();
    setState(() {
      chatLogs.add({"sender": "user", "text": query});
      _chatController.clear();
    });
    await _saveLogs();

    String reply = "";
    String lower = query.toLowerCase();

    if (lower.contains("cloud") || lower.contains("computer") || lower.contains("screen")) {
      reply = "🖥️ **Cloud Computer Status:** Deven is currently executing background scripts. Live viewer & manual access panel is open in the drawer!";
    } else if (lower.contains("plugin") || lower.contains("connect") || lower.contains("github") || lower.contains("youtube")) {
      reply = "🔌 **Universal Plugins Active:** GitHub, YouTube, Instagram, and VK connectors are synchronized at deep protocol level.";
    } else {
      reply = "⚡ **Deven Core Processed:** '$query'. Background agent is evaluating execution parameters across connected platforms.";
    }

    setState(() {
      chatLogs.add({"sender": "deven", "text": reply});
    });
    await _saveLogs();
  }

  void _showCloudComputerModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24, width: 1)),
          title: const Row(children: [
            Icon(Icons.computer, color: Colors.white),
            SizedBox(width: 10),
            Text("Deven Cloud Computer", style: TextStyle(fontSize: 15, color: Colors.white))
          ]),
          content: SizedBox(
            width: double.maxFinite,
            height: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF000000), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                  child: Text(cloudStatusText, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(height: 12),
                const Text("Active Background Tasks:", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: cloudTasks.length,
                    itemBuilder: (context, index) {
                      final t = cloudTasks[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)),
                        child: Row(children: [
                          Expanded(child: Text(t["task"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 12))),
                          Text(t["status"] ?? "", style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setModalState(() {
                  isCloudBusy = true;
                  cloudStatusText = "Deven: 'Wait! Currently processing critical block. Manual access requested.'";
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manual access requested. Deven is holding state safely.")));
              },
              child: const Text("Request Manual Access", style: TextStyle(color: Colors.orangeAccent)),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.white70))),
          ],
        ),
      ),
    );
  }

  void _showStatsModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStatState) => AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24, width: 1)),
          title: const Text("Deven Execution Stats", style: TextStyle(fontSize: 16, color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                children: ["1 Day", "1 Week", "1 Month", "3 Months", "6 Months", "1 Year"].map((range) {
                  bool isSelected = selectedStatRange == range;
                  return ChoiceChip(
                    label: Text(range, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE0E0E0),
                    backgroundColor: const Color(0xFF212121),
                    onSelected: (val) {
                      setStatState(() => selectedStatRange = range);
                      setState(() => selectedStatRange = range);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF000000), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Stats Range: $selectedStatRange", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  const Text("• Tasks Executed: 1,420\n• Autonomous Skills Learned: 88\n• GitHub/YouTube/VK Syncs: Optimal\n• System Stability: 99.9%", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.white70)))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        title: const Text("God Deven (Deven)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.computer, color: Colors.white70), tooltip: "Cloud Computer Live", onPressed: _showCloudComputerModal),
          IconButton(icon: const Icon(Icons.analytics, color: Colors.white70), tooltip: "Stats Dashboard", onPressed: _showStatsModal),
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
              Text('God Deven (Deven)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Universal Plugin & Cloud Agent', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.computer, color: Colors.white70),
            title: const Text('Cloud Computer Live Viewer'),
            onTap: () { Navigator.pop(context); _showCloudComputerModal(); },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.white70),
            title: const Text('Stats (1 Year to 1 Day)'),
            onTap: () { Navigator.pop(context); _showStatsModal(); },
          ),
          ListTile(
            leading: const Icon(Icons.bolt, color: Colors.white70),
            title: const Text('Universal Plugins (GitHub, YT, IG, VK)'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All deep plugin connectors active.")));
            },
          ),
        ]),
      ),
      body: !_isAuthorized
          ? Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text("Enter God Deven Secure Passcode", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              TextField(controller: _passcodeController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Passcode...")),
              const SizedBox(height: 16),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0E0E0), foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48)), onPressed: _verifyPasscode, child: const Text("Unlock Console", style: TextStyle(fontWeight: FontWeight.bold)))
            ])))
          : Column(children: [
              Expanded(child: ListView.builder(
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
                      decoration: BoxDecoration(color: isUser ? const Color(0xFF2E2E2E) : const Color(0xFF171717), borderRadius: BorderRadius.circular(12)),
                      child: Text(m["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  );
                },
              )),
              SafeArea(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color(0xFF000000),
                child: Row(children: [
                  Expanded(child: TextField(controller: _chatController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: "Message God Deven...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none))),
                  IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendDevenMessage(_chatController.text)),
                ]),
              )),
            ]),
    );
  }
}
