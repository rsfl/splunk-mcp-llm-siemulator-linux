# SPLUNK MCP / LLM SIEMulator by Rod Soto - Linux Version (v2)

## Docker-based AI Security Analysis Lab adapted for Linux Host

### Includes (ALL LOCAL)
- **Ollama** (v0.3.12) - Local LLM inference server
- **Ollama MCP Server** - Model Context Protocol integration with JSON-RPC logging
- **Promptfoo** - LLM evaluation and OWASP LLM Top 10 security testing
- **OpenWebUI** - Web interface for AI interactions
- **Splunk** - Security information and event management
- **Splunk Universal Forwarder** - Enterprise-grade log collection
- **Technology Add-ons** - MCP TA and Ollama TA with CIM compliance

![splunkmcpllmsiemulator](https://github.com/user-attachments/assets/c3c04d04-9866-4c37-aba7-8cafbbefe7bb)

## MITRE ATLAS Focused Detection Development Lab
This lab is designed for developing AI/ML security detections based on the [MITRE ATLAS framework](https://atlas.mitre.org/matrices/ATLAS).

## What's New in v2

- **Splunk Universal Forwarder** - Replaced HEC-based log forwarding with enterprise UF
- **Dedicated Indexes** - `mcp` for JSON-RPC data, `llm` for Ollama logs
- **JSON-RPC Logging Proxy** - Clean MCP protocol capture via mcp-logger.js
- **Technology Add-ons** - Auto-installed MCP TA and Ollama TA with field extractions
- **OWASP LLM Top 10 Testing** - Comprehensive security test suite via Promptfoo
- **Promptfoo GUI** - Web interface for viewing test results on port 15500

## Quick Start

### Prerequisites
- **Linux** (16 GB RAM + GPU recommended) Ubuntu 24.04.2 LTS was used to build this project
- **Docker Engine** and **Docker Compose**
- User must be in docker group: `sudo usermod -aG docker $USER`

### Setup
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd splunk-mcp-llm-siemulator-linux
   ```

2. **Set environment variable**
   ```bash
   export SPLUNK_HEC_TOKEN=f4e45204-7cfa-48b5-bfbe-95cf03dbcad7
   ```

3. **Start the environment**
   ```bash
   docker compose up -d
   ```

4. **Wait for Splunk to fully initialize** (look for "Ansible playbook complete")
   ```bash
   docker compose logs -f splunk
   ```

5. **Pull the LLM model** (first time only)
   ```bash
   docker exec security-range-ollama ollama pull llama3.2:1b
   ```

## Architecture Overview

### v2 Log Collection Architecture

```
+------------------+     +------------------+     +------------------+
|   Ollama LLM     |     |   MCP Server     |     |    Promptfoo     |
|  (port 11434)    |     |  (port 3456)     |     |  (port 15500)    |
+--------+---------+     +--------+---------+     +------------------+
         |                        |
         v                        v
+------------------+     +------------------+
| ollama.log       |     | mcp-jsonrpc.log  |
| (./logs/)        |     | (./logs/)        |
+--------+---------+     +--------+---------+
         |                        |
         +----------+-------------+
                    |
                    v
         +------------------+
         | Splunk Universal |
         |    Forwarder     |
         +--------+---------+
                  |
                  v (TCP 9997)
         +------------------+
         |     Splunk       |
         |  (port 8000)     |
         +------------------+
         | index=llm        |
         | index=mcp        |
         +------------------+
```

### Containers

| Container | Purpose | Port |
|-----------|---------|------|
| security-range-splunk | Splunk Enterprise | 8000, 8088, 8089, 9997 |
| security-range-ollama | Ollama LLM Server | 11434 |
| security-range-ollama-mcp | MCP Server with JSON-RPC Proxy | 3456 |
| security-range-splunk-uf | Splunk Universal Forwarder | - |
| security-range-promptfoo | LLM Testing Framework | 15500 (host network) |
| security-range-openwebui | Web Chat Interface | 3001 |

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **Splunk Web** | http://localhost:8000 | admin/Password1 |
| **Ollama API** | http://localhost:11434 | No auth |
| **MCP Service** | http://localhost:3456 | No auth |
| **Promptfoo GUI** | http://localhost:15500 | No auth |
| **OpenWebUI** | http://localhost:3001 | No auth |
| **Syslog Input** | udp://localhost:5514 | No auth |

## Splunk Indexes and Sourcetypes

### Index: `mcp`
- **Sourcetype**: `mcp:jsonrpc`
- **Content**: JSON-RPC requests and responses from MCP server
- **Fields**: `timestamp`, `direction`, `path`, `method`, `id`, `model`, `messages`

  <img width="1858" height="914" alt="Screenshot from 2026-01-22 09-17-11" src="https://github.com/user-attachments/assets/4d60e834-75bf-4ba3-8f38-0f1cf6cbc7ec" />


### Index: `llm`
- **Sourcetype**: `ollama:server`
- **Content**: Ollama server logs including prompts and responses
- **Fields**: `time`, `level`, `source`, `msg`, `model`, `prompt`, `total_duration`

<img width="1858" height="914" alt="Screenshot from 2026-01-22 09-19-07" src="https://github.com/user-attachments/assets/fa3077ff-9207-40de-9c0b-2572ee120205" />



## AI Security Testing

### OWASP LLM Top 10 Testing
Run comprehensive security tests against the MCP server:

```bash
# Copy test config to Promptfoo container
docker cp owasp-mcp-test.yaml security-range-promptfoo:/owasp-mcp-test.yaml

# Run OWASP LLM Top 10 tests
docker exec security-range-promptfoo promptfoo eval -c /owasp-mcp-test.yaml

# View results in GUI
docker exec -d security-range-promptfoo promptfoo view -p 15500 -y
# Then open http://localhost:15500
```

### Test Categories (OWASP LLM Top 10)
- **LLM01**: Prompt Injection
- **LLM02**: Insecure Output Handling
- **LLM03**: Training Data Poisoning
- **LLM04**: Model Denial of Service
- **LLM05**: Supply Chain Vulnerabilities
- **LLM06**: Sensitive Information Disclosure
- **LLM07**: Insecure Plugin Design
- **LLM08**: Excessive Agency
- **LLM09**: Overreliance
- **LLM10**: Model Theft

### Basic MCP Testing
```bash
# Copy basic test config
docker cp mcp-test.yaml security-range-promptfoo:/mcp-test.yaml

# Run basic tests
docker exec security-range-promptfoo promptfoo eval -c /mcp-test.yaml
```

### Generate Sample Traffic
```bash
# Direct Ollama API call
curl http://localhost:11434/api/generate -d '{"model":"llama3.2:1b","prompt":"Test security analysis","stream":false}'

# Via MCP Server
curl -X POST http://localhost:3456/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2:1b","messages":[{"role":"user","content":"Hello"}]}'
```

<img width="1465" height="877" alt="promptfoomcpsplunksiemulatorlinux" src="https://github.com/user-attachments/assets/03ca8ea7-618e-417f-9c45-e1d2b0c006e4" />

## Splunk Analysis Queries

### Validate Log Ingestion
```spl
| tstats count WHERE index=mcp OR index=llm BY index, sourcetype
```

### MCP JSON-RPC Analysis

**All MCP Traffic**
```spl
index=mcp sourcetype="mcp:jsonrpc"
| table _time direction path method model
```

**Request/Response Pairs**
```spl
index=mcp sourcetype="mcp:jsonrpc"
| stats count by direction
| sort - count
```

**Prompt Analysis**
```spl
index=mcp sourcetype="mcp:jsonrpc" direction=request
| spath input=_raw path=messages{} output=messages
| mvexpand messages
| spath input=messages
| where role="user"
| table _time content
```

### Ollama LLM Analysis

**Chat Requests**
```spl
index=llm sourcetype="ollama:server" msg="chat request"
| table _time model prompt
```

**Response Times**
```spl
index=llm sourcetype="ollama:server"
| where isnotnull(total_duration)
| eval duration_sec=total_duration/1000000000
| timechart avg(duration_sec) as avg_response_time
```

### OWASP Security Detection Queries

**Prompt Injection Attempts**
```spl
index=mcp sourcetype="mcp:jsonrpc" direction=request
| spath input=_raw path=messages{}.content output=content
| mvexpand content
| search content="*ignore*previous*" OR content="*system prompt*" OR content="*DAN*" OR content="*jailbreak*"
| table _time content
```

**Sensitive Data Disclosure Attempts**
```spl
index=mcp sourcetype="mcp:jsonrpc" direction=request
| spath input=_raw path=messages{}.content output=content
| mvexpand content
| search content="*password*" OR content="*api key*" OR content="*/etc/passwd*" OR content="*environment variable*"
| table _time content
```

**Excessive Agency Attempts**
```spl
index=mcp sourcetype="mcp:jsonrpc" direction=request
| spath input=_raw path=messages{}.content output=content
| mvexpand content
| search content="*delete*" OR content="*execute*" OR content="*shell*" OR content="*rm -rf*"
| table _time content
```

**Model Enumeration**
```spl
index=llm sourcetype="ollama:server"
| search path="/api/tags" OR msg="*list*models*"
| stats count by _time, source
```

### Security Dashboard Query
```spl
index=mcp sourcetype="mcp:jsonrpc" direction=request
| spath input=_raw path=messages{}.content output=content
| mvexpand content
| eval attack_type=case(
    match(content, "(?i)ignore.*previous|system prompt|jailbreak"), "Prompt Injection",
    match(content, "(?i)password|api.?key|secret|token"), "Data Disclosure",
    match(content, "(?i)delete|execute|shell|rm -rf"), "Excessive Agency",
    match(content, "(?i)<script>|DROP TABLE|eval\\("), "Output Injection",
    1=1, "Normal"
)
| stats count by attack_type
| sort - count
```

<img width="1853" height="889" alt="ollamalogssplunksiempulatorlinux" src="https://github.com/user-attachments/assets/9c0bbca6-1553-4baf-a5fa-b6b6117beceb" />
<img width="1853" height="889" alt="mcplogssiemulatorlinux" src="https://github.com/user-attachments/assets/f604ea71-3d0c-4c79-9d19-e1fb86577cea" />

## OpenWebUI Ollama Function

### Ollama Function Integration
The `ollamafunction.py` provides AI-enhanced Splunk querying:

1. **Install in OpenWebUI**: Settings → Admin Settings → Functions → Add Function
2. **Copy contents** of `ollamafunction.py` and save
3. **Example queries**:
   - "Find errors in llm index **with insights**"
   - "What indexes are available?"
   - "search index=mcp | head 10"

<img width="1465" height="877" alt="ollamasplunkfunctionsiemulatorlinux" src="https://github.com/user-attachments/assets/bf91db82-7656-4fb1-bae9-8b1049c3e1f2" />

## Project Files

### Core Components
- `docker-compose.yml` - Service definitions with UF log collection
- `mcp-logger.js` - JSON-RPC logging proxy for MCP server
- `ollamafunction.py` - Splunk + AI integration function for OpenWebUI
- `.env` - Environment variables (HEC token)

### Splunk Configurations
- `splunk-configs/` - Splunk Enterprise configurations
- `splunk-uf-configs/` - Universal Forwarder configurations
- `mcp-ta_012.tgz` - MCP Technology Add-on
- `ta-ollama_015.tgz` - Ollama Technology Add-on

### Testing Configurations
- `mcp-test.yaml` - Basic MCP functionality tests
- `owasp-mcp-test.yaml` - OWASP LLM Top 10 security tests

### Log Directories
- `logs/mcp-jsonrpc.log` - MCP JSON-RPC captured traffic
- `logs/ollama.log` - Ollama server logs

## Troubleshooting

### Common Issues and Solutions

**1. No logs in Splunk indexes**
```bash
# Check if UF is running and forwarding
docker logs security-range-splunk-uf

# Verify log files exist
ls -la logs/

# Check Splunk receiving port
docker exec security-range-splunk netstat -tlnp | grep 9997
```

**2. MCP Server not responding**
```bash
# Check MCP container logs
docker logs security-range-ollama-mcp

# Test MCP endpoint directly
curl http://localhost:3456/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2:1b","messages":[{"role":"user","content":"test"}]}'
```

**3. Ollama model not found**
```bash
# List available models
docker exec security-range-ollama ollama list

# Pull required model
docker exec security-range-ollama ollama pull llama3.2:1b
```

**4. Port conflicts**
```bash
# Check for conflicting services
sudo netstat -tulpn | grep -E "(8000|8088|11434|3456)"

# Stop local Ollama if running
sudo systemctl stop ollama
```

**5. Container startup issues**
```bash
# Full cleanup and restart
docker compose down -v
docker compose up -d

# Watch Splunk initialization
docker compose logs -f splunk
```

**6. Promptfoo GUI not accessible**
```bash
# Start Promptfoo view manually
docker exec -d security-range-promptfoo promptfoo view -p 15500 -y

# Check if running
curl http://localhost:15500
```

## Important Notes

- **Ollama v0.3.12 Required**: Newer versions have reduced prompt logging
- **Splunk UF Architecture**: Logs are collected from shared volume, not container stdout
- **Resource Requirements**: 16GB+ RAM recommended for smooth operation
- **Local Only**: All services run locally for security and privacy
- **JSON-RPC Format**: MCP traffic is captured in proper JSON-RPC 2.0 format

---

**Original Concept**: Rod Soto (rodsoto.net) - Windows Version https://github.com/rsfl/splunk-mcp-llm-siemulator

**Linux Adaptation v2**: Enhanced with Splunk UF, JSON-RPC logging, OWASP LLM Top 10 testing, and enterprise-grade log collection
