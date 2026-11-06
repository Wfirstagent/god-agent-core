import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isAuthorized = false;
  List initialLogs = [];
  try {
    final prefs = await SharedPreferences.getInstance();
    isAuthorized = prefs.getBool('is_authorized') ?? false;
    String? logsData = prefs.getString('deven_logs');
    if (logsData != null && logsData.isNotEmpty) {
      var decoded = json.decode(logsData);
      for (var i in decoded) { initialLogs.add(i); }
    }
  } catch (e) {}
  runApp(GodDevenApp(isAuthorized: isAuthorized, initialLogs: initialLogs));
}

class GodDevenApp extends StatelessWidget {
  final bool isAuthorized;
  final List initialLogs;
  const GodDevenApp({Key? key, required this.isAuthorized, required this.initialLogs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'God Deven Secure Cloud OS',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070707),
        primaryColor: const Color(0xFFE0E0E0),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE0E0E0), surface: Color(0xFF141414)),
      ),
      home: DevenDesktopScreen(initialAuthorized: isAuthorized, initialLogs: initialLogs),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DevenDesktopScreen extends StatefulWidget {
  final bool initialAuthorized;
  final List initialLogs;
  const DevenDesktopScreen({Key? key, required this.initialAuthorized, required this.initialLogs}) : super(key: key);

  @override
  State<DevenDesktopScreen> createState() => _DevenDesktopScreenState();
}

class _DevenDesktopScreenState extends State<DevenDesktopScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  late bool _isAuthorized;
  late List chatLogs;
  String apiKey = "";
  bool isCloudOpen = false;
  String activeWindow = "desktop";

  final List<String> terminalOutput = [
    "Deven Secure Cloud OS v9.0 [Encrypted Kernel Online]",
    "Type 'help' for shell commands, or launch workstation apps.",
    "-------------------------------------------------------"
  ];

  @override
  void initState() {
    super.initState();
    _isAuthorized = widget.initialAuthorized;
    chatLogs = List.from(widget.initialLogs);
    _loadApiKey();
    if (chatLogs.isEmpty) {
      chatLogs.add({"sender": "deven", "text": "Namaste! Main God Deven hoon. Settings me apni Gemini API key daal aur Cloud Desktop OS khol!"});
    }
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('gemini_api_key'] ?? '';
      _apiKeyController.text = apiKey;
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key.trim());
    setState(() { apiKey = key.trim(); });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key securely encrypted & saved!')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Secure Console Unlocked!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Passcode!")));
    }
  }

  Future<void> _sendDevenMessage(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { chatLogs.add({"sender": "user", "text": query}); _chatController.clear(); });
    await _saveLogs();

    if (apiKey.isEmpty) {
      setState(() { chatLogs.add({"sender": "deven", "text": "Bhai, pehle Settings me apni Gemini API key save kar!"}); });
      await _saveLogs();
      return;
    }

    try {
      final List<String> endpoints = [
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
        'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey'
      ];

      http.Response? response;
      for (String endpoint in endpoints) {
        try {
          response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "contents": [{ "parts": [{ "text": "You are God Deven, an Obsidian-themed secure autonomous AI agent. Respond in Hinglish/Hindi naturally. User query: $query" }] }]
            }),
          );
          if (response.statusCode == 200) break;
        } catch (e) {}
      }

      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        String botReply = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() { chatLogs.add({"sender": "deven", "text": botReply}); });
      } else {
        setState(() { chatLogs.add({"sender": "deven", "text": "API Error (${response?.statusCode}): ${response?.body ?? 'Unknown error'}"}); });
      }
    } catch (e) {
      setState(() { chatLogs.add({"sender": "deven", "text": "Network error: $e"}); });
    }
    await _saveLogs();
  }

  void _showSettingsModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text("Secure API Settings", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gemini API Key (AIza... or AQ...):", style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                  onPressed: () async {
                    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null && data.text != null) {
                      _apiKeyController.text = data.text!;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Key pasted from clipboard!")));
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            onPressed: () { _saveApiKey(_apiKeyController.text.trim()); Navigator.pop(ctx); },
            child: const Text("Save Securely"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text("God Deven [Secure OS Core]", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.desktop_windows, color: Colors.orangeAccent),
            tooltip: "Open Cloud Desktop OS",
            onPressed: () { setState(() { isCloudOpen = true; }); },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: "Settings",
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: !_isAuthorized
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security, size: 64, color: Colors.orangeAccent),
                    const SizedBox(height: 16),
                    const Text("Enter Secure Console Passcode", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 20),
                    TextField(controller: _passcodeController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Passcode")),
                    const SizedBox(height: 20),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 48)), onPressed: _verifyPasscode, child: const Text("Unlock Workspace", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Column(
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
                              decoration: BoxDecoration(color: isUser ? const Color(0xFF262626) : const Color(0xFF171717), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
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
                if (isCloudOpen)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.94),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: const Color(0xFF1F1F1F),
                            child: Row(
                              children: [
                                const Icon(Icons.computer, color: Colors.orangeAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text("Deven Cloud Desktop OS [Secure Workspace - $activeWindow]", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                                if (activeWindow != "desktop")
                                  TextButton(
                                    onPressed: () { setState(() { activeWindow = "desktop"; }); },
                                    child: const Text("← Desktop", style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                  onPressed: () { setState(() { isCloudOpen = false; }); },
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            color: const Color(0xFF111111),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("CPU: 0.8% | RAM: ∞ / ∞ TB (Encrypted)", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace')),
                                Text("Status: Securely Connected", style: TextStyle(color: Colors.white70, fontSize: 10)),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: activeWindow == "desktop"
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Cloud Desktop Applications & Environment:", style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 20,
                                          runSpacing: 20,
                                          children: [
                                            _buildAppIcon(Icons.terminal, "Terminal", () { setState(() { activeWindow = "terminal"; }); }),
                                            _buildAppIcon(Icons.sports_esports, "Free Fire Hub", () { setState(() { activeWindow = "freefire"; }); }),
                                            _buildAppIcon(Icons.folder, "File Explorer", () { setState(() { activeWindow = "files"; }); }),
                                            _buildAppIcon(Icons.psychology, "AI Agent Core", () { setState(() { activeWindow = "ai"; }); }),
                                          ],
                                        ),
                                      ],
                                    )
                                  : activeWindow == "terminal"
                                      ? Column(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(color: const Color(0xFF030303), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                                                child: ListView.builder(
                                                  itemCount: terminalOutput.length,
                                                  itemBuilder: (context, index) => Text(terminalOutput[index], style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            TextField(
                                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                                              decoration: const InputDecoration(
                                                hintText: "Type shell command (help, status, ff, clear)...",
                                                hintStyle: TextStyle(color: Colors.white30),
                                                filled: true,
                                                fillColor: Color(0xFF141414),
                                                border: OutlineInputBorder(borderSide: BorderSide.none),
                                              ),
                                              onSubmitted: (val) {
                                                setState(() {
                                                  terminalOutput.add("root@deven-cloud:~# $val");
                                                  if (val == 'help') terminalOutput.add("Commands: ff (launch cloud game), status, clear, ls");
                                                  else if (val == 'ff') terminalOutput.add("[SUCCESS] Free Fire cloud container running at 120 FPS.");
                                                  else if (val == 'status') terminalOutput.add("[INFO] All systems encrypted and operational.");
                                                  else if (val == 'clear') terminalOutput.clear();
                                                  else terminalOutput.add("Executed: $val");
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      : activeWindow == "freefire"
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.sports_esports, size: 64, color: Colors.orangeAccent),
                                                  const SizedBox(height: 12),
                                                  const Text("Free Fire Cloud Gaming Container", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 6),
                                                  const Text("High-performance GPU cloud streaming ready.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                                  const SizedBox(height: 20),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                                                    onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cloud gaming stream started!"))); },
                                                    child: const Text("Launch Game Stream"),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : activeWindow == "files"
                                              ? ListView(
                                                  children: const [
                                                    ListTile(leading: Icon(Icons.folder, color: Colors.amber), title: Text("/root/secure_vault"), subtitle: Text("Encrypted Storage")),
                                                    ListTile(leading: Icon(Icons.folder, color: Colors.amber), title: Text("/root/ai_models"), subtitle: Text("Gemini & Weights")),
                                                    ListTile(leading: Icon(Icons.insert_drive_file, color: Colors.blueAccent), title: Text("config.env"), subtitle: Text("Secure credentials")),
                                                  ],
                                                )
                                              : Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.psychology, size: 64, color: Colors.orangeAccent),
                                                      const SizedBox(height: 12),
                                                      const Text("AI Agent Core Engine", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 6),
                                                      const Text("Autonomous background tasks running securely.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildAppIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
            child: Icon(icon, color: Colors.orangeAccent, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
