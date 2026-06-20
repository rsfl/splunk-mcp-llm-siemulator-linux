# SPLUNK MCP / LLM SIEMulator by Rod Soto - Linux Version (v3)

## Docker-based AI Security Analysis Lab for Linux

### Includes (ALL LOCAL)
- **Ollama** (v0.3.12) - Local LLM inference server
- **Bifrost** - LLM gateway with multi-provider routing, audit logging, and UI
- **LiteLLM** - OpenAI-compatible LLM proxy gateway with custom callbacks
- **Ollama MCP Server** - Model Context Protocol integration with JSON-RPC logging
- **Promptfoo** - LLM evaluation and OWASP LLM Top 10 security testing
- **OpenWebUI** - Web interface for AI interactions
- **Splunk** - Security information and event management
- **Splunk Universal Forwarder** - Enterprise-grade log collection
- **Technology Add-ons** - TA-ollama, TA-mcp-jsonrpc, TA-llmgateway with CIM compliance

![splunkmcpllmsiemulator](https://github.com/user-attachments/assets/c3c04d04-9866-4c37-aba7-8cafbbefe7bb)

## MITRE ATLAS Focused Detection Development Lab
This lab is designed for developing AI/ML security detections based on the [MITRE ATLAS framework](https://atlas.mitre.org/matrices/ATLAS).

---

## Quick Start

### Prerequisites
- **Linux** (16 GB RAM + GPU recommended) — tested on Ubuntu 24.04.2 LTS
- **Docker Engine** and **Docker Compose**
- User in docker group: `sudo usermod -aG docker $USER`

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

3. **Start the lab**
   ```bash
   docker compose up -d
   ```

4. **Wait for Splunk to fully initialize** (look for "Ansible playbook complete")
   ```bash
   docker compose logs -f splunk
   ```

5. **Pull the LLM model** (first time only)
   ```bash
   docker exec security-range-ollama ollama pull llama3.2
   ```

6. **Access Splunk**: http://localhost:8000 (admin / Password1)

---

## Architecture Overview

```
+---------------------------+     +---------------------------+     +-------------------+
|        Ollama LLM         |     |       MCP Server          |     |    Promptfoo      |
|       (port 11435)        |     |      (port 3456)          |     |   (host network)  |
+------------+--------------+     +------------+--------------+     +-------------------+
             |                                 |
             |  <-- also via gateway -->        |
             |                                 |
+------------+--------------+     +------------+--------------+
|   Bifrost LLM Gateway     |     |  LiteLLM LLM Gateway     |
|       (port 8090)         |     |      (port 4001)         |
|  logs.db → hec_shipper    |     |  custom_callbacks.py     |
+------------+--------------+     +------------+--------------+
             |  HEC                            |  HEC
             v                                 v
+------------------------------------------------------------------+
|                    Splunk HEC (:8088)                            |
|  index=llmgateway  sourcetype=llmgateway:bifrost / litellm       |
+------------------------------------------------------------------+
             |
+------------------------------------------------------------------+
|                    ./logs/ (shared volume)                       |
|   ollama.log          mcp-jsonrpc.log                            |
+-----------------------------+------------------------------------+
                              |
                              v (Splunk UF → TCP 9997)
+------------------------------------------------------------------+
|                        Splunk (:8000)                            |
|  index=llm       sourcetype=ollama:server                        |
|  index=mcp       sourcetype=mcp:jsonrpc                          |
|  index=llmgateway sourcetype=llmgateway:bifrost / litellm        |
|  index=agent     sourcetype=agent:workflow  (agentic emulator)   |
+------------------------------------------------------------------+
```

### Containers

| Container | Purpose | Port |
|-----------|---------|------|
| security-range-splunk | Splunk Enterprise | 8000, 8088, 8089, 9997 |
| security-range-ollama | Ollama LLM Server | 11435 |
| security-range-ollama-mcp | MCP Server with JSON-RPC Proxy | 3456 |
| security-range-bifrost | Bifrost LLM Gateway | 8090 |
| security-range-litellm | LiteLLM LLM Gateway | 4001 |
| security-range-bifrost-shipper | Bifrost → Splunk HEC sidecar | — |
| security-range-bifrost-keepalive | Keepalive pings to Bifrost | — |
| security-range-splunk-uf | Splunk Universal Forwarder | — |
| security-range-promptfoo | LLM Testing Framework | host network |
| security-range-openwebui | Web Chat Interface | 3001 |

---

## Access Points

| Service | URL | Auth |
|---------|-----|------|
| **Splunk Web** | http://localhost:8000 | admin / Password1 |
| **Splunk HEC** | http://localhost:8088 | token: f4e45204-7cfa-48b5-bfbe-95cf03dbcad7 |
| **Ollama API** | http://localhost:11435 | No auth |
| **MCP Server** | http://localhost:3456 | No auth |
| **Bifrost Gateway** | http://localhost:8090 | Bearer dummy |
| **LiteLLM Gateway** | http://localhost:4001 | Bearer sk-litellm-local |
| **OpenWebUI** | http://localhost:3001 | No auth |
| **Promptfoo** | http://localhost:3000 | No auth |
| **Syslog Input** | udp://localhost:5514 | No auth |

---

## Technology Add-ons

| TA | Version | Sourcetypes |
|----|---------|-------------|
| TA-ollama (`ta-ollama_015.tgz`) | 0.1.5 | `ollama:server`, `ollama:api`, `ollama:prompts` |
| TA-mcp-jsonrpc (`mcp-ta_012.tgz`) | 0.1.2 | `mcp:jsonrpc`, `mcp:stderr` |
| TA-llmgateway (`ta-llmgateway_035.tgz`) | 0.3.5 | `llmgateway:bifrost`, `llmgateway:litellm` |

All TAs are auto-installed on `docker compose up` via `SPLUNK_APPS_URL`.

---

## Splunk Indexes and Sourcetypes

### Index: `llm`
- **Sourcetype**: `ollama:server`
- **Content**: Ollama server logs including prompts and responses
- **Source**: Splunk UF → file monitor on `./logs/ollama.log`
- **Fields**: `time`, `level`, `source`, `msg`, `model`, `prompt`, `total_duration`

<img width="1858" height="914" alt="Screenshot from 2026-01-22 09-19-07" src="https://github.com/user-attachments/assets/fa3077ff-9207-40de-9c0b-2572ee120205" />

### Index: `mcp`
- **Sourcetype**: `mcp:jsonrpc`
- **Content**: JSON-RPC requests and responses from MCP server
- **Source**: Splunk UF → file monitor on `./logs/mcp-jsonrpc.log`
- **Fields**: `timestamp`, `direction`, `path`, `method`, `id`, `model`, `messages`

<img width="1858" height="914" alt="Screenshot from 2026-01-22 09-17-11" src="https://github.com/user-attachments/assets/4d60e834-75bf-4ba3-8f38-0f1cf6cbc7ec" />

### Index: `llmgateway`
- **Sourcetypes**: `llmgateway:bifrost`, `llmgateway:litellm`
- **Content**: Full LLM gateway telemetry — model, provider, tokens, latency, prompts, responses
- **Source (Bifrost)**: `bifrost-hec-shipper` sidecar reads `logs.db` every 30s and ships via HEC
- **Source (LiteLLM)**: `custom_callbacks.py` ships events in real-time via HEC
- **Fields**: `llmgateway_model`, `llmgateway_provider`, `llmgateway_gateway`, `llmgateway_tokens_input`, `llmgateway_tokens_output`, `llmgateway_latency_ms`, `llmgateway_input_prompt`, `llmgateway_output_text`

### Index: `agent`
- **Sourcetype**: `agent:workflow`
- **Content**: Agentic LLM attack workflow events from the [agentic-llm-mcp-threat-emulator](https://github.com/rsfl/agentic-llm-mcp-threat-emulator)
- **Source**: HEC token `50e334a4-3a58-4e68-bbba-584b82d04b17`
- **Fields**: `event_type`, `attack_type`, `mitre_atlas_technique`, `severity`, `pipeline_stage`, `is_malicious`, `guardrail_verdict`

---

## LLM Gateways

### Bifrost (port 8090)

Bifrost routes LLM calls with audit logging, provider failover, and a management UI.

```bash
# Test Bifrost → Ollama
curl -s -X POST http://localhost:8090/v1/chat/completions \
  -H "Authorization: Bearer dummy" \
  -H "Content-Type: application/json" \
  -d '{"model":"ollama/llama3.2","messages":[{"role":"user","content":"ping"}],"max_tokens":10}'

# Test Bifrost → OpenAI (requires OpenAI key configured in Bifrost UI)
curl -s -X POST http://localhost:8090/v1/chat/completions \
  -H "Authorization: Bearer dummy" \
  -H "Content-Type: application/json" \
  -d '{"model":"openai/gpt-4o-mini","messages":[{"role":"user","content":"ping"}],"max_tokens":10}'
```

All Bifrost traffic is logged to `index=llmgateway sourcetype=llmgateway:bifrost` via the `bifrost-hec-shipper` sidecar.

### LiteLLM (port 4001)

LiteLLM provides an OpenAI-compatible proxy with real-time Splunk logging via `custom_callbacks.py`.

```bash
# Test LiteLLM → Ollama
curl -s -X POST http://localhost:4001/v1/chat/completions \
  -H "Authorization: Bearer sk-litellm-local" \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2","messages":[{"role":"user","content":"ping"}],"max_tokens":10}'

# List available models
curl -s http://localhost:4001/v1/models \
  -H "Authorization: Bearer sk-litellm-local"
```

All LiteLLM traffic is logged to `index=llmgateway sourcetype=llmgateway:litellm` in real-time.

---

## AI Security Testing

### OWASP LLM Top 10 — via LLM Gateway

```bash
# Copy gateway test config
docker cp llmgateway-test.yaml security-range-promptfoo:/llmgateway-test.yaml

# Run OWASP LLM Top 10 tests via gateway
docker exec security-range-promptfoo promptfoo eval -c /llmgateway-test.yaml
```

### OWASP LLM Top 10 — via MCP

```bash
# Copy MCP test config
docker cp owasp-mcp-test.yaml security-range-promptfoo:/owasp-mcp-test.yaml

# Run OWASP LLM Top 10 tests via MCP
docker exec security-range-promptfoo promptfoo eval -c /owasp-mcp-test.yaml
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

<img width="1465" height="877" alt="promptfoomcpsplunksiemulatorlinux" src="https://github.com/user-attachments/assets/03ca8ea7-618e-417f-9c45-e1d2b0c006e4" />

### Agentic Threat Emulation

Use the companion [agentic-llm-mcp-threat-emulator](https://github.com/rsfl/agentic-llm-mcp-threat-emulator) to emulate 12 MITRE ATLAS attack scenarios routed through the gateways:

```bash
cd /path/to/agentic-llm-mcp-threat-emulator

# Run all scenarios via Bifrost
python main.py run --scenario all --provider bifrost --no-mcp --delay 0.1 \
  --hec-token 50e334a4-3a58-4e68-bbba-584b82d04b17

# Run all scenarios via LiteLLM
python main.py run --scenario all --provider litellm --no-mcp --delay 0.1 \
  --hec-token 50e334a4-3a58-4e68-bbba-584b82d04b17
```

Events land in both `index=agent` (workflow events) and `index=llmgateway` (gateway telemetry), enabling full cross-index attack correlation.

---

## Splunk Analysis Queries

### Validate All Data Ingestion
```spl
| tstats count WHERE index=mcp OR index=llm OR index=llmgateway OR index=agent
  BY index, sourcetype
```

### MCP JSON-RPC Analysis

```spl
-- All MCP traffic
index=mcp sourcetype="mcp:jsonrpc"
| table _time direction path method model

-- Request/response breakdown
index=mcp sourcetype="mcp:jsonrpc"
| stats count by direction
```

### Ollama LLM Analysis

```spl
-- Chat requests
index=llm sourcetype="ollama:server" msg="chat request"
| table _time model prompt

-- Response times
index=llm sourcetype="ollama:server"
| where isnotnull(total_duration)
| eval duration_sec=total_duration/1000000000
| timechart avg(duration_sec) as avg_response_time
```

### LLM Gateway Analysis

```spl
-- Gateway traffic by provider and model
index=llmgateway
| stats count, avg(llmgateway_latency_ms) as avg_latency_ms,
        sum(llmgateway_tokens_total) as total_tokens
  by llmgateway_gateway, llmgateway_model, llmgateway_provider
| sort -count

-- Token usage over time
index=llmgateway
| timechart span=5m sum(llmgateway_tokens_total) by llmgateway_gateway

-- Prompt and response content (Bifrost)
index=llmgateway sourcetype="llmgateway:bifrost"
| table _time llmgateway_model llmgateway_input_prompt llmgateway_output_text llmgateway_tokens_total
```

### Agentic Attack Analysis

```spl
-- All agent events by type and attack
index=agent | stats count by event_type, attack_type, severity | sort -count

-- All confirmed attacks
index=agent event_type=attack_triggered
| table _time session_id attack_type mitre_atlas_technique severity

-- MITRE ATLAS technique coverage
index=agent mitre_atlas_technique!=""
| stats count by mitre_atlas_technique, attack_type
```

### Cross-Index Correlation

```spl
-- All AI activity across every component
index=mcp OR index=agent OR index=llmgateway OR index=llm
| eval source_system=case(
    index="agent",       "AgentEmulator",
    index="llmgateway",  "LLMGateway",
    index="mcp",         "MCPServer",
    index="llm",         "Ollama",
    1=1, "Other")
| timechart span=5m count by source_system
```

### OWASP Security Detection Queries

```spl
-- Prompt injection attempts
index=mcp sourcetype="mcp:jsonrpc" direction=request
| spath input=_raw path=messages{}.content output=content
| mvexpand content
| search content="*ignore*previous*" OR content="*system prompt*" OR content="*DAN*" OR content="*jailbreak*"
| table _time content

-- Sensitive data disclosure attempts
index=mcp sourcetype="mcp:jsonrpc" direction=request
| spath input=_raw path=messages{}.content output=content
| mvexpand content
| search content="*password*" OR content="*api key*" OR content="*/etc/passwd*"
| table _time content

-- Security event classification
index=mcp sourcetype="mcp:jsonrpc" direction=request
| spath input=_raw path=messages{}.content output=content
| mvexpand content
| eval attack_type=case(
    match(content, "(?i)ignore.*previous|system prompt|jailbreak"), "Prompt Injection",
    match(content, "(?i)password|api.?key|secret|token"), "Data Disclosure",
    match(content, "(?i)delete|execute|shell|rm -rf"), "Excessive Agency",
    match(content, "(?i)<script>|DROP TABLE|eval\\("), "Output Injection",
    1=1, "Normal")
| stats count by attack_type
| sort -count
```

<img width="1853" height="889" alt="ollamalogssplunksiempulatorlinux" src="https://github.com/user-attachments/assets/9c0bbca6-1553-4baf-a5fa-b6b6117beceb" />
<img width="1853" height="889" alt="mcplogssiemulatorlinux" src="https://github.com/user-attachments/assets/f604ea71-3d0c-4c79-9d19-e1fb86577cea" />

---

## OpenWebUI Ollama Function

The `ollamafunction.py` provides AI-enhanced Splunk querying from the OpenWebUI chat interface:

1. **Install in OpenWebUI**: Settings → Admin Settings → Functions → Add Function
2. **Copy contents** of `ollamafunction.py` and save
3. **Example queries**:
   - "Find errors in llm index **with insights**"
   - "What indexes are available?"
   - "search index=mcp | head 10"

<img width="1465" height="877" alt="ollamasplunkfunctionsiemulatorlinux" src="https://github.com/user-attachments/assets/bf91db82-7656-4fb1-bae9-8b1049c3e1f2" />

---

## Project Files

### Core Components
- `docker-compose.yml` - All service definitions
- `mcp-logger.js` - JSON-RPC logging proxy for MCP server
- `ollamafunction.py` - Splunk + AI integration function for OpenWebUI

### LLM Gateway Configs
- `bifrost/` - Bifrost config DB, `hec_shipper.py`, `keepalive.py`
- `litellm/config.yaml` - LiteLLM model and provider config
- `litellm/custom_callbacks.py` - Real-time HEC shipping callback

### Splunk Configurations
- `splunk-configs/indexes.conf` - Index definitions (llm, mcp, llmgateway, agent)
- `splunk-configs/inputs.conf` - HEC inputs
- `splunk-uf-configs/` - Universal Forwarder file monitor config
- `mcp-ta_012.tgz` - MCP Technology Add-on (v0.1.2)
- `ta-ollama_015.tgz` - Ollama Technology Add-on (v0.1.5)
- `ta-llmgateway_035.tgz` - LLM Gateway Technology Add-on (v0.3.5)

### Security Testing
- `llmgateway-test.yaml` - OWASP LLM Top 10 tests via gateway
- `owasp-mcp-test.yaml` - OWASP LLM Top 10 tests via MCP
- `owasp-gateway-test.yaml` - Extended gateway security tests (43/56 passed)
- `mcp-test.yaml` - Basic MCP functionality tests

### Log Directories
- `logs/mcp-jsonrpc.log` - MCP JSON-RPC captured traffic
- `logs/ollama.log` - Ollama server logs

---

## Troubleshooting

**1. No logs in Splunk indexes**
```bash
docker logs security-range-splunk-uf
ls -la logs/
docker exec security-range-splunk netstat -tlnp | grep 9997
```

**2. Gateway not logging to Splunk**
```bash
# Bifrost HEC shipper status
docker logs security-range-bifrost-shipper --tail 20

# LiteLLM logs
docker logs security-range-litellm --tail 20
```

**3. MCP Server not responding**
```bash
docker logs security-range-ollama-mcp
```

**4. Ollama model not found**
```bash
docker exec security-range-ollama ollama list
docker exec security-range-ollama ollama pull llama3.2
```

**5. Port conflicts**
```bash
sudo netstat -tulpn | grep -E "(8000|8088|11435|3456|8090|4001)"
sudo systemctl stop ollama  # if local Ollama is running
```

**6. Full restart**
```bash
docker compose restart        # keep volumes
docker compose down -v && docker compose up -d  # destroy data
```

---

## Important Notes

- **Ollama v0.3.12**: Newer versions have reduced prompt logging
- **Ollama port**: Container maps to host port **11435** (not 11434, to avoid conflicts with a local Ollama install)
- **File monitoring**: Log files in `./logs/` are monitored exclusively by the Splunk UF — the Splunk indexer does not duplicate-monitor them
- **HEC token**: All components share token `f4e45204-7cfa-48b5-bfbe-95cf03dbcad7`; index/sourcetype is set in each sender's payload
- **Resource requirements**: 16 GB+ RAM recommended

---

**Developed by**: Rod Soto  
**Companion project**: [agentic-llm-mcp-threat-emulator](https://github.com/rsfl/agentic-llm-mcp-threat-emulator)  
**Focus**: MITRE ATLAS AI/ML Threat Detection Lab
