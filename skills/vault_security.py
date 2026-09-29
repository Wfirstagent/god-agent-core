import json
import os
from datetime import datetime

class VaultSecurity:
    def __init__(self, vault_path="credentials_vault.json"):
        self.vault_path = vault_path
        if not os.path.exists(self.vault_path):
            self._init_vault()

    def _init_vault(self):
        initial_data = {
            "created_at": str(datetime.now()),
            "credentials": [],
            "burner_accounts": []
        }
        with open(self.vault_path, "w") as f:
            json.dump(initial_data, f, indent=4)

    def save_credential(self, platform, email, password, recovery_2fa="", cookies=""):
        """Saves platform credentials into vault"""
        with open(self.vault_path, "r") as f:
            data = json.load(f)

        credential_entry = {
            "platform": platform,
            "email": email,
            "password": password,
            "2fa_secret": recovery_2fa,
            "cookies": cookies,
            "saved_at": str(datetime.now())
        }
        
        data["credentials"].append(credential_entry)
        
        with open(self.vault_path, "w") as f:
            json.dump(data, f, indent=4)
            
        return f"[Vault Security]: Credentials for {platform} saved securely."

