import os
import json
import time
import datetime
import importlib
from flask import Flask, request, jsonify
from config import AGENT_NAME, SECRET_PASSCODE, MEMORY_FILE, CREDENTIALS_FILE

app = Flask(__name__)

SKILLS_DIR = "skills"
if not os.path.exists(SKILLS_DIR):
    os.makedirs(SKILLS_DIR)

def load_vault_file(filepath):
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            return json.load(f)
    return {"logs": [], "credentials": [], "projects": []}

def save_vault_file(filepath, data):
    with open(filepath, "w") as f:
        json.dump(data, f, indent=4)

class CognitiveAgentCore:
    def __init__(self):
        self.agent_name = AGENT_NAME

    def process_user_command(self, command):
        timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        if "learn" in command.lower():
            return f"[{timestamp}] [Cognitive Core]: Mujhe ye skill sahi nahi aati. Kya main documentation fetch karke ise seekh loon?"
        return f"[{timestamp}] [Cognitive Core]: Command '{command}' analyzed and sub-agent task routing initialized."

class SkillEngine:
    @staticmethod
    def learn(skill_name, code_content):
        file_path = os.path.join(SKILLS_DIR, f"{skill_name}.py")
        with open(file_path, "w") as f:
            f.write(code_content)
        return f"[Self-Upgrade]: Nayi skill '{skill_name}' learn aur register ho gayi hai!"

    @staticmethod
    def execute(skill_name, *args, **kwargs):
        try:
            module = importlib.import_module(f"{SKILLS_DIR}.{skill_name}")
            importlib.reload(module)
            return module.run(*args, **kwargs)
        except Exception as e:
            return f"[Execution Error]: {str(e)}"

@app.route("/api/command", methods=["POST"])
def handle_command():
    data = request.json or {}
    if data.get("passcode") != SECRET_PASSCODE:
        return jsonify({"status": "error", "message": "Unauthorized Access"}), 403

    user_command = data.get("command", "")
    core_engine = CognitiveAgentCore()
    cognitive_log = core_engine.process_user_command(user_command)

    memory = load_vault_file(MEMORY_FILE)
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    memory["logs"].append({"timestamp": timestamp, "command": user_command, "status": "executed"})
    save_vault_file(MEMORY_FILE, memory)

    return jsonify({
        "status": "success",
        "cognitive": cognitive_log,
        "output": f"Command '{user_command}' processed successfully.",
        "vault_status": "Synced to local vault buffer"
    })

if __name__ == "__main__":
    print(f"[{AGENT_NAME} Core Engine Running...]")
    app.run(host="0.0.0.0", port=5000, debug=True)
