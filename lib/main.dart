import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isAuthorized = false;
  bool isDriveConnected = false;
  List<Map<String, String>> initialAsk = [];
  List<Map<String, String>> initialAuto = [];

  try {
    final prefs = await SharedPreferences.getInstance();
    isAuthorized = prefs.getBool('is_authorized') ?? false;
    isDriveConnected = prefs.getBool('is_drive_connected') ?? false;

    String? savedAsk = prefs.getString('ask_messages');
    if (savedAsk != null && savedAsk.isNotEmpty) {
      List decoded = json.decode(savedAsk);
      initialAsk = decoded.map((item) => Map<String, String>.from(item)).toList();
    }

    String? savedAuto = prefs.getString('autopilot_messages');
    if (savedAuto != null && savedAuto.isNotEmpty) {
      List decoded = json.decode(savedAuto);
      initialAuto = decoded.map((item) => Map<String, String>.from(item)).toList();
    }
  } catch (e) {
    debugPrint("Init load error: $e");
  }

  runApp(GodAgentApp(
    isAuthorized: isAuthorized,
    isDriveConnected: isDriveConnected,
    initialAsk: initialAsk,
    initialAuto: initialAuto,
  ));
}

class GodAgentApp extends StatelessWidget {
  final bool isAuthorized;
  final bool isDriveConnected;
  final List<Map<String, String>> initialAsk;
  final List<Map<String, String>> initialAuto;

  const GodAgentApp({
    Key? key,
    required this.isAuthorized,
    required this.isDriveConnected,
    required this.initialAsk,
    required this.initialAuto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'God-Level AI Agent v2',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF58A6FF),
      ),
      home: MainAgentScreen(
        initialAuthorized: isAuthorized,
        initialDriveConnected: isDriveConnected,
        initialAsk: initialAsk,
        initialAuto: initialAuto,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAgentScreen extends StatefulWidget {
  final bool initialAuthorized;
  final bool initialDriveConnected;
  final List<Map<String, String>> initialAsk;
  final List<Map<String, String>> initialAuto;

  const MainAgentScreen({
    Key? key,
    required this.initialAuthorized,
    required this.initialDriveConnected,
    required this.initialAsk,
    required this.initialAuto,
  }) : super(key: key);

  @override
  State<MainAgentScreen> createState() => _MainAgentScreenState();
}
class _MainAgentScreenState extends State<MainAgentScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  late bool _isAuthorized;
  late bool _isDriveConnected;
  String selectedMode = "ask"; 

  late List<Map<String, String>> askMessages;
  late List<Map<String, String>> autoPilotMessages;

  List<Map<String, dynamic>> liveAgentTasks = [
    {"task": "System Initialized successfully.", "status": "Running"},
    {"task": "Connected to secure local session storage.", "status": "Running"},
    {"task": "Awaiting user task inputs & commands...", "status": "Running"},
  ];

  Map<String, dynamic> metrics = {
    "thinking": "System active. Parsing Hinglish and English commands...",
    "learned": "Advanced bilingual and live activity pause controller active.",
    "problems": "None. All systems operational."
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGoogleDrivePrompt();
      });
    }
  }

  Future<void> _saveChatHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ask_messages', json.encode(askMessages));
      await prefs.setString('autopilot_messages', json.encode(autoPilotMessages));
    } catch (e) {
      debugPrint("Save chat error: $e");
    }
  }

  void _addTaskLog(String taskName) {
    setState(() {
      liveAgentTasks.insert(0, {"task": taskName, "status": "Running"});
      if (liveAgentTasks.length > 30) liveAgentTasks.removeLast();
    });
  }

  void _toggleTaskPause(int index) {
    setState(() {
      String currentStatus = liveAgentTasks[index]["status"];
      liveAgentTasks[index]["status"] = currentStatus == "Running" ? "Paused" : "Running";
    });
  }

  void _showGoogleDrivePrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("Connect Real Google Drive", style: TextStyle(color: Colors.orangeAccent)),
        content: const Text("Link your Google Drive via secure OAuth to enable real-time cloud sync."),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_drive_connected', true);
                setState(() {
                  _isDriveConnected = true;
                });
                Navigator.of(dialogContext, rootNavigator: true).pop();
                _addTaskLog("Google Drive OAuth initiated.");

                final Uri uri = Uri.parse(driveAuthUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              }
            },
            child: const Text("Authorize & Connect", style: TextStyle(color: Color(0xFF58A6FF))),
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
      } catch (e) {}

      setState(() {
        _isAuthorized = true;
      });
      _addTaskLog("Console unlocked with secure passcode.");

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
    } catch (e) {}
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
class _MainAgentScreenState extends State<MainAgentScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  late bool _isAuthorized;
  late bool _isDriveConnected;
  String selectedMode = "ask"; 

  late List<Map<String, String>> askMessages;
  late List<Map<String, String>> autoPilotMessages;

  List<Map<String, dynamic>> liveAgentTasks = [
    {"task": "System Initialized successfully.", "status": "Running"},
    {"task": "Connected to secure local session storage.", "status": "Running"},
    {"task": "Awaiting user task inputs & commands...", "status": "Running"},
  ];

  Map<String, dynamic> metrics = {
    "thinking": "System active. Parsing Hinglish and English commands...",
    "learned": "Advanced bilingual and live activity pause controller active.",
    "problems": "None. All systems operational."
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGoogleDrivePrompt();
      });
    }
  }

  Future<void> _saveChatHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ask_messages', json.encode(askMessages));
      await prefs.setString('autopilot_messages', json.encode(autoPilotMessages));
    } catch (e) {
      debugPrint("Save chat error: $e");
    }
  }

  void _addTaskLog(String taskName) {
    setState(() {
      liveAgentTasks.insert(0, {"task": taskName, "status": "Running"});
      if (liveAgentTasks.length > 30) liveAgentTasks.removeLast();
    });
  }

  void _toggleTaskPause(int index) {
    setState(() {
      String currentStatus = liveAgentTasks[index]["status"];
      liveAgentTasks[index]["status"] = currentStatus == "Running" ? "Paused" : "Running";
    });
  }

  void _showGoogleDrivePrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("Connect Real Google Drive", style: TextStyle(color: Colors.orangeAccent)),
        content: const Text("Link your Google Drive via secure OAuth to enable real-time cloud sync."),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_drive_connected', true);
                setState(() {
                  _isDriveConnected = true;
                });
                Navigator.of(dialogContext, rootNavigator: true).pop();
                _addTaskLog("Google Drive OAuth initiated.");

                final Uri uri = Uri.parse(driveAuthUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              }
            },
            child: const Text("Authorize & Connect", style: TextStyle(color: Color(0xFF58A6FF))),
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
      } catch (e) {}

      setState(() {
        _isAuthorized = true;
      });
      _addTaskLog("Console unlocked with secure passcode.");

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
    } catch (e) {}
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
  void _showLiveActivityModal() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: Row(
            children: const [
              Icon(Icons.monitor_heart, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text("Live Agent Activity & Control", style: TextStyle(fontSize: 15, color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: ListView.builder(
              itemCount: liveAgentTasks.length,
              itemBuilder: (context, index) {
                final item = liveAgentTasks[index];
                bool isRunning = item["status"] == "Running";
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item["task"], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text("Status: ${item["status"]}", style: TextStyle(color: isRunning ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill, color: isRunning ? Colors.orangeAccent : Colors.greenAccent),
                        onPressed: () {
                          setStateModal(() {
                            _toggleTaskPause(index);
                          });
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Color(0xFF58A6FF))),
            ),
          ],
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
    _addTaskLog("Query: '$trimmed' ($selectedMode mode)");

    if (lower.contains("hi") || lower.contains("hello") || lower.contains("hlo") || lower.contains("hey") || lower.contains("sup") || lower.contains("kaise ho")) {
      String reply = "Hello bhai! Main aapka God-Level AI Agent hoon. Sab set hai, bataiye kya task execute karwana hai?";
      setState(() {
        currentList.add({"sender": "agent", "text": reply});
      });
      await _saveChatHistories();
      _addTaskLog("Responded with bilingual greeting.");
      return;
    }

    if (lower.contains("who are you") || lower.contains("tum kon ho") || lower.contains("tum kaun ho")) {
      String reply = "Main aapka personal God-Level AI Agent hoon. Main aapke sabhi tasks, code execution, aur automated workflows ko manage aur execute karne ke liye bana hoon.";
      setState(() {
        currentList.add({"sender": "agent", "text": reply});
      });
      await _saveChatHistories();
      _addTaskLog("Responded to identity query.");
      return;
    }

    if (lower.contains("hinglish") || lower.contains("hindi") || lower.contains("language")) {
      String reply = "Haan bilkul! Main English aur Hinglish dono achhi tarah samajh sakta hoon. Aap apna koi bhi sawal ya task pooch sakte hain.";
      setState(() {
        currentList.add({"sender": "agent", "text": reply});
      });
      await _saveChatHistories();
      _addTaskLog("Confirmed bilingual capability.");
      return;
    }

    _addTaskLog("Dispatching task to backend core: '$trimmed'");
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "passcode": "74882242959122690239",
          "command": trimmed,
          "mode": selectedMode
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String backendResp = data["response"] ?? "Task executed successfully.";
        
        if (backendResp.contains("Successfully processed your request:")) {
          backendResp = "✅ Task successfully processed and completed: '$trimmed'";
        }

        setState(() {
          currentList.add({"sender": "agent", "text": backendResp});
          if (data["metrics"] != null) {
            metrics = data["metrics"];
          }
        });
        _addTaskLog("Task completed: '$trimmed'");
      } else {
        setState(() {
          currentList.add({"sender": "agent", "text": "⚠️ Server returned error code: ${response.statusCode}"});
        });
        _addTaskLog("Backend error code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        currentList.add({"sender": "agent", "text": "❌ Network error connecting to backend core."});
      });
      _addTaskLog("Network exception encountered.");
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
          IconButton(
            icon: const Icon(Icons.monitor_heart, color: Colors.greenAccent),
            tooltip: "Live Agent Activity",
            onPressed: _showLiveActivityModal,
          ),
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
              leading: const Icon(Icons.monitor_heart, color: Colors.greenAccent),
              title: const Text('Live Agent Activity & Pause'),
              subtitle: const Text('Tap to view and pause active tasks', style: TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showLiveActivityModal();
              },
            ),
            const Divider(color: Colors.white24),
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
                                hintText: "Ask AI or give command (Hinglish/English)...",
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: constIcon(Icons.mic, color: Colors.white70),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF58A6FF)),
                            onPressed: () => _sendMessage(_messageController.text),
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
