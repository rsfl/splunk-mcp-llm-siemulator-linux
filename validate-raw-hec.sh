#!/bin/bash
# validate-raw-hec.sh
# Linux validation script for Raw HEC setup Splunk MCP LLM SIEMulator

HEC_URL="http://localhost:8088"
HEC_TOKEN="f4e45204-7cfa-48b5-bfbe-95cf03dbcad7"

while [[ $# -gt 0 ]]; do
    case $1 in
        --hec-url)
            HEC_URL="$2"
            shift 2
            ;;
        --hec-token)
            HEC_TOKEN="$2"
            shift 2
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

echo -e "\033[36mValidating Raw HEC Setup\033[0m"
echo -e "\033[36m============================\033[0m"

# Test HEC health
echo -e "\033[34mChecking HEC health...\033[0m"
HEALTH_RESPONSE=$(curl -s -H "Authorization: Splunk $HEC_TOKEN" "$HEC_URL/services/collector/health")

if echo "$HEALTH_RESPONSE" | grep -q "HEC is available"; then
    echo -e "\033[32mHEC health check passed\033[0m"
else
    echo -e "\033[31mHEC health check failed\033[0m"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi

# Test raw endpoint
echo -e "\033[34mTesting raw endpoint...\033[0m"
TEST_DATA="$(date +'%Y-%m-%d %H:%M:%S') [INFO] Raw HEC validation test - $(date +%s)"
URI="$HEC_URL/services/collector/raw/1.0?index=ollama_logs&sourcetype=test:validation&source=validation_script"

RESPONSE=$(curl -s -X POST \
    -H "Authorization: Splunk $HEC_TOKEN" \
    -H "Content-Type: text/plain" \
    -d "$TEST_DATA" \
    "$URI")

if [[ $? -eq 0 ]]; then
    echo -e "\033[32mRaw endpoint test passed\033[0m"
else
    echo -e "\033[31mRaw endpoint test failed\033[0m"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo -e "\033[32mRaw HEC validation completed!\033[0m"
echo -e "\033[33m   Check Splunk for test events:\033[0m"
echo -e "\033[33m   - index=ollama_logs source=validation_script\033[0m"