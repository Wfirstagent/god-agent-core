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
      title: 'God Deven Real Cloud OS & AI Call',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
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

class _DevenDesktopScreenState extends State<DevenDesktopScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _cloudUrlController = TextEditingController();

  late bool _isAuthorized;
  late List chatLogs;
  String apiKey = "";
  String cloudWorkspaceUrl = "https://shell.cloud-workstation.internal";
  bool isCloudOpen = false;
  bool isCallActive = false;
  String callStatus = "Ready for AI Voice Call";
  String activeWindow = "desktop";

  late AnimationController _voiceAnimation;

  final List<String> terminalOutput = [
    "God Deven Kernel v14.0 [Encrypted WebRTC & Cloud Core]",
    "Type shell commands, connect cloud VM stream, or start AI voice call.",
    "------------------------------------------------------------------"
  ];

  @override
  void initState() {
    super.initState();
    _isAuthorized = widget.initialAuthorized;
    chatLogs = List.from(widget.initialLogs);
    _loadSettings();
    
    _voiceAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (chatLogs.isEmpty) {
      chatLogs.add({"sender": "deven", "text": "Namaste! Main God Deven hoon. Settings me API key daal, Cloud Workstation khol ya AI Voice Call shuru kar!"});
    }
  }

  @override
  void dispose() {
    _voiceAnimation.dispose();
    _passcodeController.dispose();
    _chatController.dispose();
    _apiKeyController.dispose();
    _cloudUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('gemini_api_key') ?? '';
      _apiKeyController.text = apiKey;
      cloudWorkspaceUrl = prefs.getString('cloud_url') ?? 'https://github.com';
      _cloudUrlController.text = cloudWorkspaceUrl;
    });
  }

  Future<void> _saveSettings(String key, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key.trim());
    await prefs.setString('cloud_url', url.trim());
    setState(() {
      apiKey = key.trim();
      cloudWorkspaceUrl = url.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully!')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cloud Workstation Unlocked!")));
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
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'
      ];

      http.Response? response;
      for (String endpoint in endpoints) {
        try {
          response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "contents": [{ "parts": [{ "text": "You are God Deven, an advanced autonomous AI agent and cloud workstation core. Respond in Hinglish/Hindi naturally. User query: $query" }] }]
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
  void _toggleAICallOverlay() {
    setState(() {
      isCallActive = !isCallActive;
      callStatus = isCallActive ? "Connected to God Deven AI Voice" : "Call Ended";
    });
  }

  void _showSettingsModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text("Workstation & API Settings", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gemini API Key:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text("Cloud VM Stream URL:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _cloudUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            onPressed: () {
              _saveSettings(_apiKeyController.text, _cloudUrlController.text);
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
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
        title: const Text("God Deven [Cloud OS & AI Voice]", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: Colors.greenAccent),
            tooltip: "AI Voice Call",
            onPressed: _toggleAICallOverlay,
          ),
          IconButton(
            icon: const Icon(Icons.desktop_windows, color: Colors.orangeAccent),
            tooltip: "Cloud Desktop",
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
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 48)), onPressed: _verifyPasscode, child: const Text("Unlock Workstation", style: TextStyle(fontWeight: FontWeight.bold))),
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
                if (isCallActive)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.95),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          AnimatedBuilder(
                            animation: _voiceAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_voiceAnimation.value * 0.15),
                                child: Container(
                                  height: 160,
                                  width: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1E1E1E),
                                    border: Border.all(color: Colors.greenAccent, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                                  ),
                                  child: const Icon(Icons.mic, color: Colors.greenAccent, size: 70),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                          const Text("God Deven AI Voice Bridge", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(callStatus, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          const Text("Hindi • English Real-time", style: TextStyle(color: Colors.white38, fontSize: 12)),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: _toggleAICallOverlay,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                  child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                if (isCloudOpen)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.98),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: const Color(0xFF1F1F1F),
                            child: Row(
                              children: [
                                const Icon(Icons.computer, color: Colors.orangeAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text("Cloud Workstation [$activeWindow]", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                                if (activeWindow != "desktop")
                                  TextButton(
                                    onPressed: () { setState(() { activeWindow = "desktop"; }); },
                                    child: const Text("← Back", style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                  onPressed: () { setState(() { isCloudOpen = false; }); },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: activeWindow == "desktop"
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Select Workstation Environment:", style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 20,
                                          runSpacing: 20,
                                          children: [
                                            _buildAppIcon(Icons.terminal, "Terminal", () { setState(() { activeWindow = "terminal"; }); }),
                                            _buildAppIcon(Icons.cloud, "Cloud Stream VM", () { setState(() { activeWindow = "stream"; }); }),
                                            _buildAppIcon(Icons.folder, "Files", () { setState(() { activeWindow = "files"; }); }),
                                            _buildAppIcon(Icons.psychology, "AI Core", () { setState(() { activeWindow = "ai"; }); }),
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
                                                hintText: "Type shell command...",
                                                filled: true,
                                                fillColor: Color(0xFF141414),
                                                border: OutlineInputBorder(borderSide: BorderSide.none),
                                              ),
                                              onSubmitted: (val) {
                                                setState(() {
                                                  terminalOutput.add("root@deven-cloud:~# $val");
                                                  if (val == 'status') terminalOutput.add("[INFO] Cloud VM container running.");
                                                  else terminalOutput.add("Executed: $val");
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      : activeWindow == "stream"
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.cloud_done, size: 64, color: Colors.orangeAccent),
                                                  const SizedBox(height: 12),
                                                  Text("Connected to Remote VM:\n$cloudWorkspaceUrl", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                                ],
                                              ),
                                            )
                                          : activeWindow == "files"
                                              ? ListView(
                                                  children: const [
                                                    ListTile(leading: Icon(Icons.folder, color: Colors.amber), title: Text("/root/workspace"), subtitle: Text("Cloud Storage")),
                                                  ],
                                                )
                                              : const Center(child: Text("AI Core Active", style: TextStyle(color: Colors.white, fontSize: 16))),
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
