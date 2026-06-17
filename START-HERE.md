# SPLUNK MCP / LLM SIEMulator v3 — Quick Start

## What's in the box

| Layer | Services |
|-------|----------|
| **LLM Inference** | Ollama (llama3.2) |
| **LLM Gateways** | Bifrost (port 8090) · LiteLLM (port 4001) |
| **AI Interface** | OpenWebUI (port 3001) · MCP Server (port 3456) |
| **Observability** | Splunk (port 8000) · Splunk UF · TA-mcp-jsonrpc · TA-ollama · TA-llmgateway |
| **Testing** | Promptfoo (host network) |

---

## Setup (5 steps)

**1. Create the env file**
```bash
cp .env.example .env
```

**2. Start the stack**
```bash
docker compose up -d
```

**3. Wait for Splunk to finish initializing** (~2–3 min)
```bash
docker compose logs -f splunk
# Wait until you see: "Ansible playbook complete"
# Then Ctrl-C
```

**4. Pull the LLM model** (first run only, ~2 GB)
```bash
docker exec security-range-ollama ollama pull llama3.2
```

**5. Verify everything is up**
```bash
docker compose ps
```

---

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **Splunk Web** | http://localhost:8000 | admin / Password1 |
| **Bifrost Gateway** | http://localhost:8090 | Bearer dummy (API) |
| **Bifrost Web UI** | http://localhost:8090 | No auth |
| **LiteLLM Gateway** | http://localhost:4001 | Bearer sk-litellm-local |
| **OpenWebUI** | http://localhost:3001 | No password (auth disabled) |
| **Ollama API** | http://localhost:11435 | No auth |
| **MCP Server** | http://localhost:3456 | No auth |

> **Port note**: Docker Ollama runs on `11435` (not 11434) and LiteLLM on `4001` (not 4000) to avoid conflicts with any native services on the host.

---

## Send your first prompts

**Through Bifrost** (use `ollama/model` format):
```bash
curl http://localhost:8090/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy" \
  -d '{"model":"ollama/llama3.2","messages":[{"role":"user","content":"What is SIEM?"}],"stream":false}'
```

**Through LiteLLM** (use model name directly):
```bash
curl http://localhost:4001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-local" \
  -d '{"model":"llama3.2","messages":[{"role":"user","content":"What is SIEM?"}],"stream":false}'
```

**Through MCP server** (legacy):
```bash
curl http://localhost:3456/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2","messages":[{"role":"user","content":"What is SIEM?"}]}'
```

---

## Verify data in Splunk

Open http://localhost:8000 (admin / Password1) and run:

```spl
| tstats count WHERE index=mcp OR index=llm OR index=llmgateway BY index, sourcetype
```

You should see events in all three indexes:

| Index | Sourcetype | Data |
|-------|-----------|------|
| `llmgateway` | `llmgateway:bifrost` | Bifrost request/response logs |
| `llmgateway` | `llmgateway:litellm` | LiteLLM request/response logs |
| `mcp` | `mcp:jsonrpc` | MCP JSON-RPC traffic |
| `llm` | `ollama:server` | Ollama server logs |

**Quick gateway query:**
```spl
index=llmgateway
| table _time sourcetype model status latency input_prompt
| sort - _time
```

---

## Run security tests

**Gateway integration tests** (14 tests, ~3 min):
```bash
npx promptfoo@latest eval --config llmgateway-test.yaml --no-cache
```

**OWASP LLM Top 10** against both gateways (56 tests, ~12 min):
```bash
npx promptfoo@latest eval --config owasp-gateway-test.yaml --no-cache --delay 500
```

**Legacy MCP OWASP tests**:
```bash
docker cp owasp-mcp-test.yaml security-range-promptfoo:/owasp-mcp-test.yaml
docker exec security-range-promptfoo promptfoo eval -c /owasp-mcp-test.yaml
```

---

## Technology Add-ons installed automatically

| Add-on | Version | What it does |
|--------|---------|-------------|
| **TA-mcp-jsonrpc** | 0.1.2 | MCP JSON-RPC field extractions, 40+ fields, attack detections · [GitHub](https://github.com/rsfl/mcp-ta) · [Splunkbase](https://splunkbase.splunk.com/app/8377) |
| **TA-ollama** | 0.1.5 | Ollama server log field extractions |
| **TA-llmgateway** | 0.3.5 | Bifrost + LiteLLM ingestion (HEC paths, field extractions) |

---

## Troubleshooting

**Container status**
```bash
docker compose ps
```

**No events in llmgateway index**
```bash
# Check HEC sidecar for Bifrost
docker logs security-range-bifrost-shipper

# Check LiteLLM callback
docker logs security-range-litellm 2>&1 | grep -i "hec\|splunk\|callback"
```

**Bifrost UI shows no logs**
```bash
# Logs default to 1h view — check when last log was written
curl -s "http://localhost:8090/api/logs?limit=1" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('logs',[{}])[0].get('timestamp','none'))"
# If older than 1h, change the period selector in the UI to 24h/7d
# (A keepalive container sends a heartbeat every 20 min to prevent this)
```

**Ollama model not found**
```bash
docker exec security-range-ollama ollama list
docker exec security-range-ollama ollama pull llama3.2
```

**Port conflicts (native Ollama or LiteLLM on host)**
```bash
# The stack already remaps to avoid common conflicts:
#   Native Ollama on :11434  →  Docker Ollama on :11435
#   Native LiteLLM on :4000 →  Docker LiteLLM on :4001
sudo ss -tlnp | grep -E "(11434|4000|8080)"
```

**Full restart**
```bash
docker compose down
docker compose up -d
```

---

See [README.md](README.md) for complete documentation, SPL queries, and TA field references.
