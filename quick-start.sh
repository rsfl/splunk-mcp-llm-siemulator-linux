#!/bin/bash
# Quick start for Raw HEC Lab - Linux Shell Version

echo ""
echo "🚀 Quick Start - Raw HEC Lab Environment"
echo "========================================"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Engine."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker."
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cat > .env << EOF
SPLUNK_PASSWORD=Password1
SPLUNK_HEC_TOKEN=f4e45204-7cfa-48b5-bfbe-95cf03dbcad7
EOF
    echo "✅ .env file created"
fi

# Stop existing services
echo "🔄 Stopping existing services..."
docker compose down --remove-orphans > /dev/null 2>&1

# Start services
echo "🚀 Starting services..."
docker compose up -d

if [ $? -ne 0 ]; then
    echo "❌ Failed to start services"
    exit 1
fi

echo "⏳ Waiting for services to start..."
sleep 30

echo ""
echo "🎉 Environment Started!"
echo ""
echo "📊 Access Points:"
echo "    Splunk Web:  http://localhost:8000 (admin/Password1)"
echo "    Ollama API:  http://localhost:11434"
echo "    MCP Service: http://localhost:3456"
echo ""
echo "🔍 Raw HEC Endpoints:"
echo "    Health:      http://localhost:8088/services/collector/health"
echo ""
echo "📝 To validate setup run: ./validate-raw-hec.sh"
echo ""