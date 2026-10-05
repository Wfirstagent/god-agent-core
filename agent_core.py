import os
import psutil
import time
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)
START_TIME = time.time()
PASSCODE = "admin1283"

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>God Agent Console</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { background-color: #0B0E14; color: #E2E8F0; font-family: sans-serif; padding: 15px; margin: 0; }
        .card { background: #1E293B; padding: 15px; border-radius: 10px; margin-bottom: 10px; }
        input, button { width: 100%; padding: 10px; margin-top: 8px; border-radius: 6px; border: none; box-sizing: border-box; }
        input { background: #0F172A; color: white; }
        button { background: #38BDF8; color: black; font-weight: bold; cursor: pointer; }
    </style>
</head>
<body>
    <h2>🤖 God_Level_AI_Agent</h2>
    <div id="logs" class="card">Welcome Master! System monitoring active.<br>Try commands: 'stats', 'ping', 'help'.</div>
    <div class="card">
        <input type="password" id="pass" value="admin1283" placeholder="Passcode">
        <input type="text" id="cmd" placeholder="Type command (e.g., stats)...">
        <button onclick="send()">Send</button>
    </div>
    <script>
        async function send() {
            let cmd = document.getElementById('cmd').value;
            let pass = document.getElementById('pass').value;
            if(!cmd) return;
            let res = await fetch('/command', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({passcode: pass, command: cmd})
            });
            let data = await res.json();
            document.getElementById('logs').innerHTML += `<br><b>> ${cmd}</b><br>${data.response}`;
            document.getElementById('cmd').value = '';
        }
    </script>
</body>
</html>
"""

def execute_command(cmd):
    cmd = cmd.strip().lower()
    if cmd == "stats":
        cpu = psutil.cpu_percent(interval=0.5)
        ram = psutil.virtual_memory().percent
        uptime = int(time.time() - START_TIME)
        hours, remainder = divmod(uptime, 3600)
        minutes, seconds = divmod(remainder, 60)
        return (f"📊 LIVE SYSTEM METRICS\n"
                f"----------------------------------------\n"
                f"• CPU Load: {cpu}%\n"
                f"• RAM Usage: {ram}%\n"
                f"• System Uptime: {hours}h {minutes}m {seconds}s\n"
                f"• Environment: Render Cloud Free Tier")
    elif cmd == "ping":
        return "🏓 Pong! Agent core is live and operational."
    elif cmd == "help":
        return "Available Commands:\n- stats: View system performance metrics\n- ping: Test latency\n- help: List all commands"
    else:
        return f"Unknown command: '{cmd}'. Try 'stats', 'ping', or 'help'."

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

# Fix for 404: Both Flutter app and Web interface route mapped to /command
@app.route('/command', methods=['POST'])
def handle_command():
    data = request.get_json(force=True, silent=True) or {}
    passcode = data.get('passcode', '')
    command = data.get('command', '')

    if passcode != PASSCODE:
        return jsonify({"response": "Unauthorized: Invalid Passcode"}), 401

    response_text = execute_command(command)
    return jsonify({"response": response_text}), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
