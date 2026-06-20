# SPLUNK MCP / LLM SIEMulator - Linux Quick Start

## Architecture: Splunk + Ollama + LLM Gateways + MCP

### Quick Start

1. **Set environment variable**
   ```bash
   export SPLUNK_HEC_TOKEN=f4e45204-7cfa-48b5-bfbe-95cf03dbcad7
   ```

2. **Start the lab**
   ```bash
   docker compose up -d
   ```

3. **Wait for Splunk** (look for "Ansible playbook complete")
   ```bash
   docker compose logs -f splunk
   ```

4. **Pull the LLM model** (first time only)
   ```bash
   docker exec security-range-ollama ollama pull llama3.2
   ```

5. **Access Splunk**: http://localhost:8000 (admin/Password1)

---

### Check Your Logs in Splunk

```spl
-- Validate all data ingestion
| tstats count WHERE index=mcp OR index=llm OR index=llmgateway OR index=agent BY index, sourcetype

-- MCP JSON-RPC traffic
index=mcp sourcetype="mcp:jsonrpc"
| table _time direction path method model

-- Ollama LLM server logs
index=llm sourcetype="ollama:server"
| table _time level msg model

-- Bifrost gateway calls
index=llmgateway sourcetype="llmgateway:bifrost"
| table _time llmgateway_model llmgateway_provider llmgateway_tokens_total llmgateway_latency_ms

-- LiteLLM gateway calls
index=llmgateway sourcetype="llmgateway:litellm"
| table _time llmgateway_model llmgateway_provider llmgateway_tokens_total llmgateway_latency_ms

-- Agentic threat emulator events
index=agent sourcetype="agent:workflow"
| table _time event_type attack_type mitre_atlas_technique severity
```

---

### Indexes and Sourcetypes

| Index | Sourcetype | Content | Source |
|-------|------------|---------|--------|
| `llm` | `ollama:server` | Ollama LLM server logs | Splunk UF → file monitor |
| `mcp` | `mcp:jsonrpc` | MCP server JSON-RPC requests/responses | Splunk UF → file monitor |
| `llmgateway` | `llmgateway:bifrost` | Bifrost gateway request/response telemetry | HEC sidecar (bifrost-hec-shipper) |
| `llmgateway` | `llmgateway:litellm` | LiteLLM gateway request/response telemetry | HEC via custom callback |
| `agent` | `agent:workflow` | Agentic attack emulator workflow events | HEC (agentic-llm-mcp-threat-emulator) |

---

### Access Points

| Service | URL | Auth |
|---------|-----|------|
| Splunk Web | http://localhost:8000 | admin/Password1 |
| Splunk HEC | http://localhost:8088 | token: f4e45204-7cfa-48b5-bfbe-95cf03dbcad7 |
| Ollama API | http://localhost:11435 | None |
| MCP Server | http://localhost:3456 | None |
| Bifrost Gateway | http://localhost:8090 | Bearer dummy |
| LiteLLM Gateway | http://localhost:4001 | Bearer sk-litellm-local |
| OpenWebUI | http://localhost:3001 | None |
| Promptfoo | http://localhost:3000 | None |

---

### Technology Add-ons (auto-installed)

| TA | Version | Sourcetypes |
|----|---------|-------------|
| TA-ollama | 0.1.5 | `ollama:server`, `ollama:api`, `ollama:prompts` |
| TA-mcp-jsonrpc | 0.1.2 | `mcp:jsonrpc`, `mcp:stderr` |
| TA-llmgateway | 0.3.5 | `llmgateway:bifrost`, `llmgateway:litellm` |

---

### Test the LLM Gateways

```bash
# Bifrost → Ollama
curl -s -X POST http://localhost:8090/v1/chat/completions \
  -H "Authorization: Bearer dummy" \
  -H "Content-Type: application/json" \
  -d '{"model":"ollama/llama3.2","messages":[{"role":"user","content":"ping"}],"max_tokens":10}'

# LiteLLM → Ollama
curl -s -X POST http://localhost:4001/v1/chat/completions \
  -H "Authorization: Bearer sk-litellm-local" \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2","messages":[{"role":"user","content":"ping"}],"max_tokens":10}'
```

---

### Run OWASP LLM Top 10 Tests

```bash
# Test via LLM gateway (Bifrost)
docker cp llmgateway-test.yaml security-range-promptfoo:/llmgateway-test.yaml
docker exec security-range-promptfoo promptfoo eval -c /llmgateway-test.yaml

# Test via MCP
docker cp owasp-mcp-test.yaml security-range-promptfoo:/owasp-mcp-test.yaml
docker exec security-range-promptfoo promptfoo eval -c /owasp-mcp-test.yaml
```

---

### Run the Agentic Threat Emulator

Requires the companion project: https://github.com/rsfl/agentic-llm-mcp-threat-emulator

```bash
cd /path/to/agentic-llm-mcp-threat-emulator

# All 12 MITRE ATLAS scenarios via Bifrost
python main.py run --scenario all --provider bifrost --no-mcp --delay 0.1 \
  --hec-token 50e334a4-3a58-4e68-bbba-584b82d04b17

# All 12 scenarios via LiteLLM
python main.py run --scenario all --provider litellm --no-mcp --delay 0.1 \
  --hec-token 50e334a4-3a58-4e68-bbba-584b82d04b17
```

Events land in `index=agent` (workflow) and `index=llmgateway` (gateway telemetry).

---

### Troubleshooting

```bash
# Check all container status
docker compose ps

# Check Splunk startup
docker logs security-range-splunk --tail 20

# Check UF log forwarding
docker logs security-range-splunk-uf --tail 20

# Check Bifrost HEC shipper
docker logs security-range-bifrost-shipper --tail 20

# Check log files on host
ls -la logs/

# Full restart (keeps volumes)
docker compose restart

# Full teardown and rebuild (destroys data)
docker compose down -v && docker compose up -d
```

---

See README.md for complete documentation and SPL queries.
