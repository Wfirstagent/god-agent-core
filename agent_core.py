import os
import sys
import json
import requests
from flask import Flask, request, jsonify
from config import AGENT_NAME, SECRET_PASSCODE

app = Flask(__name__)

RENDER_BASE_URL = "https://api.render.com/v1"

def get_render_owner_id(headers):
    """
    Fetches the authenticated owner/user ID from Render API
    """
    try:
        res = requests.get(f"{RENDER_BASE_URL}/owners", headers=headers)
        if res.status_code == 200:
            owners = res.json()
            if isinstance(owners, list) and len(owners) > 0:
                # Returns the first owner's ID (usr-xxx or tea-xxx)
                return owners[0].get("owner", {}).get("id")
    except Exception as e:
        print(f"Error fetching ownerId: {e}")
    return None

def deploy_to_render(api_key, github_repo):
    """
    Triggers automated cloud deployment on Render via API
    """
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
                "message": "Missing 'render_api_key' in payload."
            }), 400
            
        deploy_res = deploy_to_render(render_api_key, github_repo)
        
        if deploy_res["success"]:
            return jsonify({
                "status": "success",
                "output": "Cloud deployment successfully triggered via Render API!",
                "live_url": deploy_res["url"],
                "cognitive": f"Agent auto-hosting initialized on repository {github_repo}."
            })
        else:
            return jsonify({
                "status": "error",
                "message": "Render Deployment Failed",
                "details": deploy_res["error"]
            }), 500

    return jsonify({"status": "error", "message": "Unknown Command"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
