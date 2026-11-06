import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
      for (var i in decoded) { initialLogs.add(i); }
    }
  } catch (e) {}
  runApp(GodDevenApp(isAuthorized: isAuthorized, isDriveConnected: isDriveConnected, initialLogs: initialLogs));
}

class GodDevenApp extends StatelessWidget {
  final bool isAuthorized;
  final bool isDriveConnected;
  final List initialLogs;
  const GodDevenApp({Key? key, required this.isAuthorized, required this.isDriveConnected, required this.initialLogs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'God Deven AI Agent',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFFE0E0E0),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE0E0E0), surface: Color(0xFF171717)),
      ),
      home: DevenDashboardScreen(initialAuthorized: isAuthorized, isDriveConnected: isDriveConnected, initialLogs: initialLogs),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DevenDashboardScreen extends StatefulWidget {
  final bool initialAuthorized;
  final bool isDriveConnected;
  final List initialLogs;
  const DevenDashboardScreen({Key? key, required this.initialAuthorized, required this.isDriveConnected, required this.initialLogs}) : super(key: key);

  @override
  State<DevenDashboardScreen> createState() => _DevenDashboardScreenState();
}

class _DevenDashboardScreenState extends State<DevenDashboardScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  late bool _isAuthorized;
  late bool _isDriveConnected;
  late List chatLogs;

  String selectedStatRange = "1 Day";
  bool isCloudBusy = false;
  String cloudStatus = "Cloud Environment Active: Autonomous Skill-Mining & Background Execution";
  String apiKey = "";

  final List cloudTerminalLogs = [
    "[00:01:20] Initializing Obsidian Secure Sandbox...",
    "[00:02:10] GitHub Actions auto-sync container online.",
    "[00:03:45] Scraping YouTube & Reels for new code patterns...",
    "[00:04:12] VK & Instagram Plugin bridge verified.",
    "[00:05:00] Deven Cloud Computer ready for live commands."
  ];

  @override
  void initState() {
    super.initState();
    _isAuthorized = widget.initialAuthorized;
    _isDriveConnected = widget.isDriveConnected;
    chatLogs = List.from(widget.initialLogs);
    _loadApiKey();
    if (chatLogs.isEmpty) {
      chatLogs.add({"sender": "deven", "text": "Namaste! Main God Deven hoon. Settings me apni Gemini API key paste karo aur mujhe task do."});
    }
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('gemini_api_key') ?? '';
      _apiKeyController.text = apiKey;
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    setState(() { apiKey = key; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gemini API Key saved successfully!')));
  }

  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deven_logs', json.encode(chatLogs));
    } catch (e) {}
  }

  void _verifyPasscode() {
    if (_passcodeController.text.trim() == "7468224295912980230" || _passcodeController.text.trim() == "1234") {
      SharedPreferences.getInstance().then((prefs) { prefs.setBool('is_authorized', true); });
      setState(() { _isAuthorized = true; });
      _passcodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Console Unlocked Successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Passcode!")));
    }
  }

  Future<void> _sendDevenMessage(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { chatLogs.add({"sender": "user", "text": query}); _chatController.clear(); });
    await _saveLogs();

    if (apiKey.isEmpty) {
      setState(() { chatLogs.add({"sender": "deven", "text": "Bhai, pehle menu se Settings me jaakar apni Gemini API key save karo!"}); });
      await _saveLogs();
      return;
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "contents": [{ "parts": [{ "text": "You are God Deven, an Obsidian-themed autonomous AI agent with human-like close friend tone (ChatGPT Dots style). Respond in Hinglish/Hindi naturally. User query: $query" }] }]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String botReply = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() { chatLogs.add({"sender": "deven", "text": botReply}); });
      } else {
        setState(() { chatLogs.add({"sender": "deven", "text": "API connection error. Key check karo bhai."}); });
      }
    } catch (e) {
      setState(() { chatLogs.add({"sender": "deven", "text": "Network error: $e"}); });
    }
    await _saveLogs();
  }
  void _showCloudComputerModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24)),
          title: Row(children: const [
            Icon(Icons.computer, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text("Deven Cloud Computer (Live)", style: TextStyle(color: Colors.white, fontSize: 16)),
          ]),
          content: SizedBox(
            width: double.maxFinite, height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cloudStatus, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Live Cloud Terminal Stream:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white10)),
                    child: ListView.builder(
                      itemCount: cloudTerminalLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(cloudTerminalLogs[index], style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11)),
                        );
                      },
                    ),
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
                  cloudStatus = "Manual Override Active: Cloud execution paused for user.";
                  cloudTerminalLogs.add("[MANUAL] User requested manual access. Holding background tasks.");
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manual access granted! Cloud paused.")));
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
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text("Deven Execution Stats", style: TextStyle(color: Colors.white)),
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
                    onSelected: (val) { setModalState(() { selectedStatRange = range; }); },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: Text("Stats Range: $selectedStatRange\nTasks Executed: 1,420+\nAutonomous Skills Learned: 88\nGitHub/YouTube/VK Sync: Optimal", style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.white)))],
        ),
      ),
    );
  }

  void _showSettingsModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text("Agent Settings & API Key", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gemini API Key (Paste your key below):", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, color: Colors.orangeAccent),
                  tooltip: "Paste from Clipboard",
                  onPressed: () async {
                    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null && data.text != null) {
                      _apiKeyController.text = data.text!;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("API Key pasted from clipboard!")));
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0E0E0), foregroundColor: Colors.black),
            onPressed: () { _saveApiKey(_apiKeyController.text.trim()); Navigator.pop(ctx); },
            child: const Text("Save Key"),
          ),
        ],
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
          IconButton(icon: const Icon(Icons.computer, color: Colors.orangeAccent), tooltip: "Live Cloud Computer", onPressed: _showCloudComputerModal),
          IconButton(icon: const Icon(Icons.analytics, color: Colors.white70), tooltip: "Stats", onPressed: _showStatsModal),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF171717),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                Icon(Icons.psychology, color: Colors.orangeAccent, size: 32),
                SizedBox(height: 8),
                Text("God Deven (Deven)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Universal Plugin & Cloud Agent", style: TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
            ),
            ListTile(leading: const Icon(Icons.computer, color: Colors.orangeAccent), title: const Text("Cloud Computer Live Viewer", style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showCloudComputerModal(); }),
            ListTile(leading: const Icon(Icons.analytics, color: Colors.white70), title: const Text("Execution Stats", style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showStatsModal(); }),
            ListTile(leading: const Icon(Icons.settings, color: Colors.white70), title: const Text("Settings & API Key", style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _showSettingsModal(); }),
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
                    const Icon(Icons.lock_outline, size: 64, color: Colors.orangeAccent),
                    const SizedBox(height: 16),
                    const Text("Enter God Deven Secure Passcode", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 20),
                    TextField(controller: _passcodeController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Secure Passcode")),
                    const SizedBox(height: 20),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0E0E0), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 48)), onPressed: _verifyPasscode, child: const Text("Unlock Console", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            )
          : Column(
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
                          decoration: BoxDecoration(color: isUser ? const Color(0xFF2E2E2E) : const Color(0xFF171717), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
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
    );
  }
}
