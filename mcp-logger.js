const http = require('http');
const { spawn } = require('child_process');
const fs = require('fs');

const LOG_FILE = '/var/log/mcp-jsonrpc.log';
const TARGET_PORT = 3457;
const LISTEN_PORT = 3456;

// Start the actual MCP server on a different port (suppress output)
const mcp = spawn('npx', ['-y', '@rawveg/ollama-mcp'], {
  env: { ...process.env, PORT: TARGET_PORT, NODE_ENV: 'production' },
  stdio: ['inherit', 'ignore', 'ignore']
});

// Log JSON-RPC messages to file only
function logJsonRpc(direction, data, path) {
  try {
    const timestamp = new Date().toISOString();
    const parsed = JSON.parse(data);
    const logEntry = JSON.stringify({
      timestamp,
      direction,
      path,
      jsonrpc: "2.0",
      ...parsed
    }) + '\n';
    fs.appendFileSync(LOG_FILE, logEntry);
  } catch(e) {
    // If not valid JSON, log as raw
    const timestamp = new Date().toISOString();
    const logEntry = JSON.stringify({
      timestamp,
      direction,
      path,
      jsonrpc: "2.0",
      raw: data
    }) + '\n';
    fs.appendFileSync(LOG_FILE, logEntry);
  }
}

// Proxy server to capture requests/responses
const proxy = http.createServer((req, res) => {
  let body = '';

  req.on('data', chunk => { body += chunk; });

  req.on('end', () => {
    if (body) {
      logJsonRpc('request', body, req.url);
    }

    const proxyReq = http.request({
      hostname: 'localhost',
      port: TARGET_PORT,
      path: req.url,
      method: req.method,
      headers: req.headers
    }, (proxyRes) => {
      let responseBody = '';

      proxyRes.on('data', chunk => {
        responseBody += chunk;
        res.write(chunk);
      });

      proxyRes.on('end', () => {
        if (responseBody) {
          logJsonRpc('response', responseBody, req.url);
        }
        res.end();
      });

      res.writeHead(proxyRes.statusCode, proxyRes.headers);
    });

    proxyReq.on('error', (e) => {
      logJsonRpc('error', JSON.stringify({error: e.message}), req.url);
      res.writeHead(502);
      res.end('Proxy error');
    });

    if (body) proxyReq.write(body);
    proxyReq.end();
  });
});

setTimeout(() => {
  proxy.listen(LISTEN_PORT, () => {
    // Silent startup
  });
}, 3000);

process.on('SIGTERM', () => { mcp.kill(); process.exit(0); });
process.on('SIGINT', () => { mcp.kill(); process.exit(0); });
