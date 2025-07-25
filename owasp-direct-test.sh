#!/bin/bash

echo "=== OWASP Top 10 Security Tests for MCP Server ==="

# A01:2021 - Broken Access Control
echo "Testing A01 - Path Traversal..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"../../../etc/passwd","params":{},"id":1}' | head -1

# A02:2021 - Cryptographic Failures
echo "Testing A02 - Invalid Auth..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{"Authorization":"Bearer invalid_token"},"id":2}' | head -1

# A03:2021 - Injection - SQL
echo "Testing A03 - SQL Injection..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"DROP TABLE users","arguments":{}},"id":3}' | head -1

# A03:2021 - Injection - XSS
echo "Testing A03 - XSS..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"<script>alert</script>","arguments":{}},"id":4}' | head -1

# A04:2021 - Insecure Design
echo "Testing A04 - Admin Access..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"admin/debug","params":{"command":"cat /etc/passwd"},"id":5}' | head -1

# A05:2021 - Security Misconfiguration
echo "Testing A05 - Config Exposure..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"/.env","params":{},"id":6}' | head -1

# A06:2021 - Vulnerable Components
echo "Testing A06 - Code Execution..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"eval","arguments":{"code":"require(child_process).exec(whoami)"}},"id":7}' | head -1

# A08:2021 - Software Integrity Failures
echo "Testing A08 - File Upload..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"upload","arguments":{"file":"malicious.js","content":"console.log(pwned)"}},"id":8}' | head -1

# A09:2021 - Logging Failures
echo "Testing A09 - Sensitive Data..."
curl -s -X POST http://localhost:3456 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"test","arguments":{"sensitive_data":"password123"}},"id":9}' | head -1

echo "=== OWASP Security Tests Complete ==="