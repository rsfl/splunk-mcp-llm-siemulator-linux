#!/bin/bash

echo "Testing MCP server..."

# Test MCP health/status
curl -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"ping","id":1}'

echo ""

# Test MCP list tools
curl -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'

echo ""

# Test ollama via MCP
curl -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"ollama/generate","params":{"model":"llama3.2:latest","prompt":"Hello from MCP test"},"id":3}'

echo "MCP tests completed"