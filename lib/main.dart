import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GodConsolePage(),
  ));
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class GodConsolePage extends StatefulWidget {
  const GodConsolePage({super.key});

  @override
  State<GodConsolePage> createState() => _GodConsolePageState();
}

class _GodConsolePageState extends State<GodConsolePage> {
  final TextEditingController _cmdController = TextEditingController();
  final TextEditingController _passController = TextEditingController(text: "admin1283");
  final String _backendUrl = "https://god-agent-core.onrender.com";

  List<ChatMessage> messages = [
    ChatMessage(
      text: "Welcome Master! System monitoring and cloud command pipeline active.\nTry commands: 'stats', 'ping', 'help'.",
      isUser: false,
    )
  ];
  bool _loading = false;

  Future<void> _sendCommand(String command) async {
    if (command.trim().isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: command, isUser: true));
      _loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$_backendUrl/command"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "passcode": _passController.text,
          "command": command,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String respText = data['response'] ?? "Success";
        
        setState(() {
          messages.add(ChatMessage(text: respText, isUser: false));
        });
      } else {
        setState(() {
          messages.add(ChatMessage(text: "Error: ${response.statusCode}\n${response.body}", isUser: false));
        });
      }
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(text: "Connection Failed: $e", isUser: false));
      });
    } finally {
      setState(() {
        _loading = false;
      });
      _cmdController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Row(
          children: [
            Text("🤖 ", style: TextStyle(fontSize: 18)),
            Text("God_Level_AI_Agent", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text("ONLINE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFF131B2E),
              child: const Text(
                "⚡ God Agent Console v2.0 (Metrics Enabled)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                      decoration: BoxDecoration(
                        color: msg.isUser ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_loading) const LinearProgressIndicator(color: Color(0xFF38BDF8)),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              color: const Color(0xFF0F172A),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _passController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Enter Passcode",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _cmdController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "Type command (e.g., stats)...",
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            onSubmitted: _sendCommand,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => _sendCommand(_cmdController.text),
                          child: const Text("Send", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
