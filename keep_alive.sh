#!/bin/bash
URL="https://god-agent-core.onrender.com/"
echo "⚡ Starting God-Agent Keep-Alive Service..."

while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "[$TIMESTAMP] Ping Success (200 OK)"
    else
        echo "[$TIMESTAMP] Ping Failed (Status: $HTTP_STATUS)"
    fi
    sleep 600
done
