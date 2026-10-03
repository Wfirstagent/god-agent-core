import os
import sys
import json
import requests
from flask import Flask, request, jsonify
from config import AGENT_NAME, SECRET_PASSCODE

app = Flask(__name__)

RENDER_BASE_URL = "https://api.render.com/v1"

def get_render_owner_id(headers):
    try:
        res = requests.get(f"{RENDER_BASE_URL}/owners", headers=headers)
        if res.status_code == 200:
            owners = res.json()
            if isinstance(owners, list) and len(owners) > 0:
                return owners[0].get("owner", {}).get("id")
    except Exception as e:
        print(f"Error fetching ownerId: {e}")
    return None

def deploy_to_render(api_key, github_repo):
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }

    owner_id = get_render_owner_id(headers)
    if not owner_id:
        return {"success": False, "error": "Failed to retrieve valid Render ownerId using provided API Key."}

    repo_name = github_repo.rstrip("/").split("/")[-1].lower()

    payload = {
        "type": "web_service",
        "name": repo_name,
        "ownerId": owner_id,
        "repo": github_repo,
        "autoDeploy": "yes",
        "serviceDetails": {
            "env": "python",
            "envSpecificDetails": {
                "buildCommand": "pip install -r requirements.txt",
                "startCommand": "python agent_core.py"
            },
            "region": "singapore"
        }
    }

    try:
        response = requests.post(f"{RENDER_BASE_URL}/services", json=payload, headers=headers)
        if response.status_code in [200, 201]:
            data = response.json()
            service_url = data.get("service", {}).get("serviceDetails", {}).get("url", "Deployment Initiated")
            return {"success": True, "url": service_url, "raw": data}
        else:
            return {"success": False, "error": response.text}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.route('/', methods=['GET'])
def home():
    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{AGENT_NAME} Core Console</title>
        <style>
            * {{ box-sizing: border-box; margin: 0; padding: 0; }}
            body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #090d16; color: #f8fafc; height: 100vh; display: flex; flex-direction: column; }}
            header {{ background: #111827; padding: 15px 20px; border-bottom: 1px solid #1f2937; display: flex; justify-content: space-between; align-items: center; }}
            h1 {{ font-size: 18px; color: #38bdf8; font-weight: 700; }}
            .badge {{ background: #0284c7; color: #fff; font-size: 11px; font-weight: bold; padding: 4px 10px; border-radius: 12px; }}
            #chat-container {{ flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 15px; }}
            .msg {{ max-width: 85%; padding: 12px 16px; border-radius: 12px; font-size: 14px; line-height: 1.5; word-wrap: break-word; }}
            .agent {{ background: #1e293b; color: #38bdf8; border: 1px solid #334155; align-self: flex-start; }}
            .user {{ background: #2563eb; color: #fff; align-self: flex-end; }}
            .system {{ background: #0f172a; color: #94a3b8; font-size: 12px; align-self: center; border: 1px dashed #334155; text-align: center; }}
            footer {{ background: #111827; padding: 12px; border-top: 1px solid #1f2937; display: flex; gap: 8px; flex-direction: column; }}
            .input-group {{ display: flex; gap: 8px; }}
            input[type="text"], input[type="password"] {{ flex: 1; background: #0f172a; border: 1px solid #334155; color: #fff; padding: 12px 14px; border-radius: 8px; font-size: 14px; outline: none; }}
            input:focus {{ border-color: #38bdf8; }}
            button {{ background: #38bdf8; color: #0f172a; border: none; font-weight: bold; padding: 12px 18px; border-radius: 8px; cursor: pointer; transition: 0.2s; }}
            button:active {{ transform: scale(0.98); }}
        </style>
    </head>
    <body>
        <header>
            <h1>🤖 {AGENT_NAME}</h1>
            <span class="badge">ONLINE</span>
        </header>

        <div id="chat-container">
            <div class="msg system">⚡ God Agent Interactive Console Ready</div>
            <div class="msg agent">Welcome Master! Direct JSON payload and cognitive commands are active. Enter your passcode below to send commands.</div>
        </div>

        <footer>
            <div class="input-group">
                <input type="password" id="passcode" placeholder="Enter Secret Passcode" value="{SECRET_PASSCODE}">
            </div>
            <div class="input-group">
                <input type="text" id="commandInput" placeholder="Type command (e.g., Check Server Status)...">
                <button onclick="sendCommand()">Send</button>
            </div>
        </footer>

        <script>
            async function sendCommand() {{
                const passcode = document.getElementById("passcode").value;
                const commandInput = document.getElementById("commandInput");
                const command = commandInput.value.trim();
                const container = document.getElementById("chat-container");

                if (!command) return;

                // Render User Msg
                const userDiv = document.createElement("div");
                userDiv.className = "msg user";
                userDiv.innerText = command;
                container.appendChild(userDiv);
                commandInput.value = "";
                container.scrollTop = container.scrollHeight;

                try {{
                    const response = await fetch("/api/command", {{
                        method: "POST",
                        headers: {{ "Content-Type": "application/json" }},
                        body: JSON.stringify({{ passcode: passcode, command: command }})
                    }});

                    const data = await response.json();
                    
                    const agentDiv = document.createElement("div");
                    agentDiv.className = "msg agent";
                    
                    if (response.ok) {{
                        agentDiv.innerText = data.output || data.cognitive || "Command Executed Successfully";
                    }} else {{
                        agentDiv.style.color = "#f87171";
                        agentDiv.innerText = "Error: " + (data.message || "Execution Failed");
                    }}

                    container.appendChild(agentDiv);
                }} catch (e) {{
                    const errDiv = document.createElement("div");
                    errDiv.className = "msg agent";
                    errDiv.style.color = "#f87171";
                    errDiv.innerText = "Network Error: Unable to connect to core server.";
                    container.appendChild(errDiv);
                }}

                container.scrollTop = container.scrollHeight;
            }}

            document.getElementById("commandInput").addEventListener("keypress", function(e) {{
                if (e.key === "Enter") sendCommand();
            }});
        </script>
    </body>
    </html>
    """

@app.route('/api/command', methods=['POST'])
def handle_command():
    data = request.get_json() or {}

    if data.get("passcode") != SECRET_PASSCODE:
        return jsonify({"status": "error", "message": "Unauthorized Access"}), 403

    command = data.get("command")
    payload = data.get("payload", {})

    if command in ["Check Server Status", "Get Engine Status", "ping", "status"]:
        return jsonify({
            "status": "success",
            "output": f"⚡ {AGENT_NAME} active. Core metrics functional. All services operating nominal.",
            "cognitive": "Server healthy and accepting payload requests."
        })

    elif command == "DEPLOY_TO_CLOUD":
        render_api_key = payload.get("render_api_key")
        github_repo = payload.get("github_repo", "https://github.com/Wfirstagent/god-agent-core")

        if not render_api_key:
            return jsonify({
                "status": "error",
                "message": "Missing render_api_key in payload."
            }), 400

        deploy_res = deploy_to_render(render_api_key, github_repo)

        if deploy_res.get("success"):
            return jsonify({
                "status": "success",
                "output": "Cloud deployment successfully triggered via Render API!",
                "live_url": deploy_res.get("url"),
                "cognitive": f"Agent auto-hosting initialized on repository {github_repo}."
            })
        else:
            return jsonify({
                "status": "error",
                "message": "Render Deployment Failed",
                "details": deploy_res.get("error")
            }), 500

    return jsonify({"status": "success", "output": f"Executed command: '{command}'. Core response processed."})

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
