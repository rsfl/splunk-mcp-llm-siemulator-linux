# SPLUNK MCP / LLM SIEMulator v2 - Linux Quick Start

## v2 Architecture: Splunk Universal Forwarder + JSON-RPC Logging

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
   docker exec security-range-ollama ollama pull llama3.2:1b
   ```

5. **Access Splunk**: http://localhost:8000 (admin/Password1)

### Check Your Logs in Splunk

```spl
# Validate data ingestion
| tstats count WHERE index=mcp OR index=llm BY index, sourcetype

# View MCP JSON-RPC traffic
index=mcp sourcetype="mcp:jsonrpc"
| table _time direction path method model

# View Ollama LLM logs
index=llm sourcetype="ollama:server"
| table _time level msg model
```

### Indexes and Sourcetypes

| Index | Sourcetype | Content |
|-------|------------|---------|
| `mcp` | `mcp:jsonrpc` | MCP server JSON-RPC requests/responses |
| `llm` | `ollama:server` | Ollama LLM server logs |

### v2 Key Features

- **Splunk Universal Forwarder** - Enterprise-grade log collection (replaced HEC script)
- **JSON-RPC Logging Proxy** - Clean MCP protocol capture
- **OWASP LLM Top 10 Testing** - Security test suite via Promptfoo
- **Technology Add-ons** - Auto-installed with field extractions
- **Promptfoo GUI** - View test results at http://localhost:15500

### Run OWASP LLM Top 10 Tests

```bash
# Copy test config
docker cp owasp-mcp-test.yaml security-range-promptfoo:/owasp-mcp-test.yaml

# Run security tests
docker exec security-range-promptfoo promptfoo eval -c /owasp-mcp-test.yaml

# View results in GUI
docker exec -d security-range-promptfoo promptfoo view -p 15500 -y
```

Then open http://localhost:15500

### Access Points

| Service | URL | Auth |
|---------|-----|------|
| Splunk Web | http://localhost:8000 | admin/Password1 |
| Ollama API | http://localhost:11434 | None |
| MCP Server | http://localhost:3456 | None |
| Promptfoo GUI | http://localhost:15500 | None |
| OpenWebUI | http://localhost:3001 | None |

### Troubleshooting

```bash
# Check container status
docker compose ps

# View UF logs
docker logs security-range-splunk-uf

# Check log files
ls -la logs/

# Full restart
docker compose down -v && docker compose up -d
```

---

See README.md for complete documentation and SPL queries.
