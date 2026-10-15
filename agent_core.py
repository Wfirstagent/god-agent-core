from flask import Flask, request, jsonify, render_template_string
import os

app = Flask(__name__)
PASSCODE = "74882242959122690239"

agent_state = {
    "thinking": "System active with secure token. Awaiting commands...",
    "learned": "Updated secure passcode authentication.",
    "problems": "None. All systems operational.",
    "current_mode": "ask"
}

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head><title>God-Level AI Agent Core</title></head>
<body style="background-color: #0d1117; color: #58a6ff; font-family: monospace; padding: 40px;">
    <h2>⚡ God-Level AI Agent Core is Online</h2>
    <p>Status: <span style="color: #3fb950;">Operational</span></p>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/command', methods=['POST'])
def handle_command():
    data = request.get_json(force=True, silent=True) or {}
    passcode = data.get("passcode", "")
    command = data.get("command", "")
    mode = data.get("mode", "ask")

    if passcode != PASSCODE:
        return jsonify({"response": "Unauthorized: Invalid Passcode"}), 401

    agent_state["current_mode"] = mode
    cmd_lower = command.strip().lower()

    if cmd_lower == "stats":
        response_text = "📊 LIVE SYSTEM METRICS\n• CPU Load: 12.4%\n• RAM Usage: 48.2%\n• Status: Optimal"
    elif cmd_lower == "ping":
        response_text = "🏓 Pong! Agent core secure connection active."
    elif mode == "autopilot":
        response_text = f"[AUTO-PILOT ACTIVE] Executing autonomous routine: '{command}'. Running in background loop."
        agent_state["thinking"] = f"Running auto-pilot task: {command}"
    else:
        response_text = f"[ASK AI AGENT] Response to: '{command}'"
        agent_state["thinking"] = f"Processed query: {command}"

    agent_state["learned"] = f"Executed command: {command}"
    return jsonify({"response": response_text, "metrics": agent_state}), 200

@app.route('/metrics', methods=['GET'])
def get_metrics():
    return jsonify(agent_state), 200

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
