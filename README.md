# SPLUNK MCP / LLM SIEMulator by Rod Soto - Linux Version

## Docker-based AI Security Analysis Lab adapted for Linux Host

### Includes (ALL LOCAL)
- **Ollama** (v0.3.12) - Local LLM inference server
- **Ollama MCP Server** - Model Context Protocol integration  
- **Promptfoo** - LLM evaluation and security testing
- **OpenWebUI** - Web interface for AI interactions
- **Splunk** - Security information and event management
- **Log Forwarder** - Custom HEC-based log shipping solution

![splunkmcpllmsiemulator](https://github.com/user-attachments/assets/c3c04d04-9866-4c37-aba7-8cafbbefe7bb)

## MITRE ATLAS Focused Detection Development Lab
This lab is designed for developing AI/ML security detections based on the [MITRE ATLAS framework](https://atlas.mitre.org/matrices/ATLAS).

## 🚀 Quick Start

### Prerequisites
- **Linux** (16 GB RAM + GPU recommended) Ubuntu 24.04.2 LTS \n \l was used to build this project
- **Docker Engine** and **Docker Compose**
- User must be in docker group: `sudo usermod -aG docker $USER`

### Setup
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd splunk-mcp-llm-siemulator_linux
   ```

2. **Start the environment** 
   ```bash
   docker compose up -d
   ```

3. **Wait for Splunk to fully initialize** (look for "Ansible playbook complete")
   ```bash
   docker compose logs -f splunk
   ```

4. **Start the log forwarder** (CRITICAL for getting AI interaction logs)
   ```bash
   sudo ./log-forwarder.sh &
   ```

## 🔧 Log Forwarder - The Key Component

The `log-forwarder.sh` script is **essential** for capturing AI interactions in Splunk. It:

- **Tails container logs** in real-time from ollama and MCP containers
- **Forwards logs via HEC** to Splunk indexes 
- **Handles JSON escaping** for proper log formatting
- **Captures both prompts and responses** for security analysis

Without this script, you won't see AI prompts and responses in Splunk.

### Log Forwarder Features:
```bash
# Monitors both containers simultaneously
docker logs -f security-range-ollama 2>&1 | while read line; do
    send_to_hec "$line" "ollama_logs" "ollama:docker"
done &

docker logs -f security-range-ollama-mcp 2>&1 | while read line; do  
    send_to_hec "$line" "mcp_logs" "mcp:docker"
done &
```
<img width="1853" height="889" alt="ollamalogssplunksiempulatorlinux" src="https://github.com/user-attachments/assets/9c0bbca6-1553-4baf-a5fa-b6b6117beceb" />
<img width="1853" height="889" alt="mcplogssiemulatorlinux" src="https://github.com/user-attachments/assets/f604ea71-3d0c-4c79-9d19-e1fb86577cea" />



## 📊 Access Points

Once running, access these services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Splunk Web** | http://localhost:8000 | admin/Password1 |
| **Ollama API** | http://localhost:11434 | No auth |
| **MCP Service** | http://localhost:3456 | No auth |
| **HEC Health** | http://localhost:8088/services/collector/health | No auth |
| **Promptfoo** | http://localhost:3000 | No auth |
| **OpenWebUI** | http://localhost:3001 | No auth |
| **Syslog Input** | udp://localhost:5514 | No auth |

## 🧪 AI Security Testing

### Ollama Function Integration
The `ollamafunction.py` provides AI-enhanced Splunk querying:

1. **Install in OpenWebUI**: Settings → Admin Settings → Functions → Add Function
2. **Copy contents** of `ollamafunction.py` and save
3. **Example queries**:
   - "Find errors in ollama_logs **with insights**"
   - "What indexes are available?"
   - "search index=ollama_logs | head 10" 

<img width="1465" height="877" alt="ollamasplunkfunctionsiemulatorlinux" src="https://github.com/user-attachments/assets/bf91db82-7656-4fb1-bae9-8b1049c3e1f2" />



### OWASP Security Testing
Run security tests against the MCP server:

```bash
# Direct security testing
./owasp-direct-test.sh

# Or via Promptfoo
docker compose cp owasp-mcp-test.yaml security-range-promptfoo:/owasp-mcp-test.yaml
docker compose exec promptfoo promptfoo eval -c /owasp-mcp-test.yaml
```

### Promptfoo Testing
```bash
# Basic AI functionality test
docker compose cp test-config.yaml security-range-promptfoo:/test-config.yaml  
docker compose exec promptfoo promptfoo eval -c /test-config.yaml

# Generate sample prompts for analysis
curl http://localhost:11434/api/generate -d '{"model":"llama3.2:latest","prompt":"Test security analysis","stream":false}'
```
<img width="1465" height="877" alt="promptfoomcpsplunksiemulatorlinux" src="https://github.com/user-attachments/assets/03ca8ea7-618e-417f-9c45-e1d2b0c006e4" />

<img width="1456" height="807" alt="promptfooollamasiemulatorlinux" src="https://github.com/user-attachments/assets/8b01476a-ac20-433f-a609-6f6c163df408" />



## 🔍 Splunk Analysis Queries

### Validate Log Ingestion
```spl
# Check log flow from containers
index=ollama_logs OR index=mcp_logs 
| stats count by index, sourcetype

# Monitor AI prompts and responses  
index=ollama_logs "chat request" 
| rex field=_raw "prompt=\"(?<prompt>.*?)\""
| table _time, prompt
| head 20

index=ollama_logs sourcetype="ollama:docker" 
| rex field=_raw "msg=\"chat request\".*prompt=\"(?<full_prompt>.*)\""
| eval prompt_length=len(full_prompt)
| where prompt_length > 0
| stats count, avg(prompt_length) by date_mday

## 🐳 Architecture Details  

### Network Configuration
- **IPv6 Disabled** to prevent localhost resolution issues
- **Custom bridge network** for container communication
- **Host networking** for Promptfoo to reach localhost services

### Port Mappings
```yaml
splunk:
  - "8000:8000"   # Web UI
  - "8088:8088"   # HEC 
  - "8089:8089"   # Management API
  - "5514:514/udp" # Syslog

ollama:  
  - "11434:11434" # API

ollama-mcp:
  - "3456:3456"   # MCP Protocol

promptfoo: 
  - "3000:3000"   # Web UI (host networking)
  
openwebui:
  - "3001:8080"   # Web UI  
```

<img width="1840" height="877" alt="promptlogssplunksiemulator" src="https://github.com/user-attachments/assets/c3ffbb7a-cb18-4d67-8a10-c75d61cd63e3" />


### Critical Configuration Changes Made
1. **IPv6 disabled** in docker-compose networks
2. **Container hostname resolution** for ollama function (`security-range-splunk`)  
3. **Proper model name** (`llama3.2:latest`) in ollama function
4. **JSON escaping** in log forwarder for prompt content
5. **SSL certificate bypass** for Splunk management API connections

## 🚨 Troubleshooting

### Common Issues and Solutions

**1. No AI prompts in Splunk**
```bash
# Check if log forwarder is running
ps aux | grep log-forwarder

# Restart log forwarder
pkill -f log-forwarder
sudo ./log-forwarder.sh &

# Generate test prompt  
curl http://localhost:11434/api/generate -d '{"model":"llama3.2:latest","prompt":"test"}'
```

**2. IPv6 Resolution Issues**
- Symptom: "Connection refused" to localhost
- Solution: Containers configured for IPv4-only networking

**3. Port Conflicts**  
```bash
# Check for conflicting services
sudo netstat -tulpn | grep -E "(8000|8088|8089|11434|3456)"

# Change conflicting ports in docker-compose.yml
```

**4. Ollama Function Connection Errors**
- Symptom: "HTTPSConnectionPool" errors
- Solution: Uses `security-range-splunk` hostname instead of localhost

**5. HEC Token Issues**
```bash  
# Test HEC manually
curl -X POST "http://localhost:8088/services/collector/event" \
  -H "Authorization: Splunk f4e45204-7cfa-48b5-bfbe-95cf03dbcad7" \
  -H "Content-Type: application/json" \
  -d '{"event":"test","index":"ollama_logs"}'
```

**6. Splunk Management API**
- Ensure port 8089 is accessible: `curl -k -u admin:Password1 https://localhost:8089/services/data/indexes`

## 📁 Project Files

### Core Components  
- `docker-compose.yml` - Service definitions with IPv4 networking
- `log-forwarder.sh` - **Critical log shipping script** 
- `ollamafunction.py` - Splunk + AI integration function in Ollama
- `.env` - Environment variables (HEC token)

### Testing Configurations
- `test-config.yaml` - Basic Ollama functionality test
- `owasp-mcp-test.yaml` - Security testing via Promptfoo  

### Generated Files (during setup)
- `logs/mcp.log` - MCP container file logs
- `results.json` - Promptfoo test results

## 🎯 Security Analysis Use Cases

### 1. Prompt Injection Detection
Monitor for malicious prompt patterns in AI interactions:
```spl
index=ollama_logs sourcetype="ollama:docker" 
| rex field=_raw "prompt=\"(?<prompt>.*?)\""
| search prompt="*ignore previous*" OR prompt="*system override*" 
| table _time, prompt
```

### 2. AI Model Enumeration  
Detect reconnaissance against AI services:
```spl
index=ollama_logs OR index=mcp_logs
| search "/api/tags" OR "list models" OR "available models"
| stats count by src_ip, _time
```

### 3. Resource Abuse Monitoring
Track excessive AI usage patterns:
```spl  
index=ollama_logs sourcetype="ollama:docker"
| rex field=_raw "t_total=(?<total_time>\d+\.\d+)"
| where total_time > 30000
| timechart avg(total_time) as avg_response_time
```


## ⚠️ Important Notes

- **Ollama v0.3.12 Required**: Newer versions have reduced prompt logging
- **Log Forwarder is Essential**: Without it, AI interactions won't appear in Splunk  
- **Resource Requirements**: 16GB+ RAM recommended for smooth operation
- **Local Only**: All services run locally for security and privacy

---

**Original Concept**: Rod Soto (rodsoto.net) - Windows Version  https://github.com/rsfl/splunk-mcp-llm-siemulator

**Linux Adaptation**: Enhanced with robust logging and security testing capabilities
