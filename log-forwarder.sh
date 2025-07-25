#!/bin/bash

HEC_TOKEN="f4e45204-7cfa-48b5-bfbe-95cf03dbcad7"
HEC_URL="http://localhost:8088/services/collector/event"

# Function to send log to HEC
send_to_hec() {
    local message="$1"
    local index="$2"
    local sourcetype="$3"
    
    # Escape quotes and backslashes for JSON
    message=$(echo "$message" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    
    curl -s -X POST "$HEC_URL" \
        -H "Authorization: Splunk $HEC_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"event\":\"$message\",\"index\":\"$index\",\"sourcetype\":\"$sourcetype\"}" > /dev/null
}

# Tail ollama container logs
docker logs -f security-range-ollama 2>&1 | while read line; do
    send_to_hec "$line" "ollama_logs" "ollama:docker"
done &

# Tail MCP container logs  
docker logs -f security-range-ollama-mcp 2>&1 | while read line; do
    send_to_hec "$line" "mcp_logs" "mcp:docker"
done &

# Also tail MCP file logs if available
if [ -f "./logs/mcp.log" ]; then
    tail -f ./logs/mcp.log 2>&1 | while read line; do
        send_to_hec "$line" "mcp_logs" "mcp:file"
    done &
fi

wait