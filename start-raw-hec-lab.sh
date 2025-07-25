#!/bin/bash
# start-raw-hec-lab.sh
# Start Splunk Raw HEC MCP LLM SIEMulator on Linux by Rod Soto

SKIP_VALIDATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

echo -e "\033[36mStarting Raw HEC Lab Environment\033[0m"
echo -e "\033[36m====================================\033[0m"

# Check environment file
if [[ ! -f ".env" ]]; then
    echo -e "\033[31m.env file not found\033[0m"
    echo -e "\033[33mCreating default .env file...\033[0m"
    
    cat > .env << EOF
SPLUNK_PASSWORD=Password1
SPLUNK_HEC_TOKEN=f4e45204-7cfa-48b5-bfbe-95cf03dbcad7
EOF
    echo -e "\033[32mDefault .env file created\033[0m"
fi

# Stop existing services
echo -e "\033[34mStopping existing services...\033[0m"
docker compose down --remove-orphans 2>/dev/null

# Start services
echo -e "\033[34mStarting services...\033[0m"
docker compose up -d

if [[ $? -ne 0 ]]; then
    echo -e "\033[31mFailed to start services\033[0m"
    exit 1
fi

echo -e "\033[34mWaiting for services to start...\033[0m"
sleep 30

# Validate setup
if [[ "$SKIP_VALIDATION" == false ]]; then
    echo -e "\033[34mValidating setup...\033[0m"
    if [[ -f "./validate-raw-hec.sh" ]]; then
        chmod +x ./validate-raw-hec.sh
        ./validate-raw-hec.sh
    else
        echo -e "\033[33mValidation script not found, manual validation required\033[0m"
    fi
fi

echo ""
echo -e "\033[32mRaw HEC Lab Environment Started!\033[0m"
echo ""
echo -e "\033[36mAccess Points:\033[0m"
echo -e "\033[37m   Splunk Web:  http://localhost:8000 (admin/Password1)\033[0m"
echo -e "\033[37m   Ollama API:  http://localhost:11434\033[0m"
echo -e "\033[37m   MCP Service: http://localhost:3456\033[0m"
echo -e "\033[37m   Promptfoo:   http://localhost:3000\033[0m"
echo -e "\033[37m   OpenWebUI:   http://localhost:3001\033[0m"
echo ""
echo -e "\033[36mRaw HEC Endpoints:\033[0m"
echo -e "\033[37m   Health:      http://localhost:8088/services/collector/health\033[0m"
echo -e "\033[37m   Raw Event:   http://localhost:8088/services/collector/raw/1.0\033[0m"
echo ""
echo -e "\033[36mMonitoring:\033[0m"
echo -e "\033[37m   docker-compose logs -f ollama\033[0m"
echo -e "\033[37m   bash ./scripts/raw-hec-shipper.sh\033[0m"