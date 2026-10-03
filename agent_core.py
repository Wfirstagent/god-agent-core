import os
import sys
import json
import requests
from flask import Flask, request, jsonify
from config import AGENT_NAME, SECRET_PASSCODE

app = Flask(__name__)

RENDER_BASE_URL = "https://api.render.com/v1"

def get_render_owner_id(headers):
    """Fetches the authenticated owner/user ID from Render API"""
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
    """Triggers automated cloud deployment on Render via API"""
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
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{AGENT_NAME} Core</title>
        <style>
            body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0f172a; color: #f8fafc; text-align: center; padding: 30px 15px; margin: 0; }}
            .card {{ background: #1e293b; max-width: 450px; margin: 0 auto; padding: 25px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }}
            h1 {{ color: #38bdf8; font-size: 24px; margin-bottom: 10px; }}
            .status {{ background: #0284c7; color: #fff; padding: 8px 16px; border-radius: 20px; display: inline-block; font-weight: bold; font-size: 14px; margin-bottom: 20px; }}
            p {{ color: #94a3b8; font-size: 14px; line-height: 1.5; }}
            .footer {{ margin-top: 25px; font-size: 12px; color: #64748b; }}
        </style>
    </head>
    <body>
        <div class="card">
            <h1>🤖 {AGENT_NAME}</h1>
            <div class="status">⚡ ONLINE & CONNECTED</div>
            <p>Mobile App WebView connection successfully established.</p>
            <p>Ready to receive JSON payload commands at <code>/api/command</code>.</p>
            <div class="footer">God-Level Engine Core v1.0 • Running on Render</div>
        </div>
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

    if command in ["Check Server Status", "Get Engine Status"]:
        return jsonify({
            "status": "success",
            "output": f"{AGENT_NAME} local core active.",
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

    return jsonify({"status": "error", "message": "Unknown Command"}), 400

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
