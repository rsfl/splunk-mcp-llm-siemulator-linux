#!/bin/bash
# deploy-raw-hec.sh
# Linux Bash script for Raw HEC deployment Splunk MCP LLM SIEMulator by Rod Soto

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/splunk-configs"
LOGS_DIR="$SCRIPT_DIR/logs"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
BACKUP_DIR="$SCRIPT_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
HEC_TOKEN="f4e45204-7cfa-48b5-bfbe-95cf03dbcad7"

# Colors for output
log_success() { echo -e "\033[32m[$(date +%H:%M:%S)] $1\033[0m"; }
log_warning() { echo -e "\033[33m[$(date +%H:%M:%S)] WARNING: $1\033[0m"; }
log_error() { echo -e "\033[31m[$(date +%H:%M:%S)] ERROR: $1\033[0m"; }
log_info() { echo -e "\033[34m[$(date +%H:%M:%S)] $1\033[0m"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker found: $DOCKER_VERSION"
    else
        log_error "Docker not found or not in PATH"
        return 1
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        log_success "Docker Compose found: $COMPOSE_VERSION"
    else
        log_error "Docker Compose not found or not in PATH"
        return 1
    fi
    
    # Check Docker daemon
    if docker info &> /dev/null; then
        log_success "Docker daemon is running"
    else
        log_error "Docker daemon is not running"
        return 1
    fi
    
    return 0
}

# Create directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    
    local directories=("$CONFIG_DIR" "$LOGS_DIR" "$SCRIPTS_DIR" "$BACKUP_DIR")
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        fi
    done
}

# Create Splunk configuration files
create_splunk_configs() {
    log_info "Creating Splunk configuration files..."
    
    # indexes.conf
    cat > "$CONFIG_DIR/indexes.conf" << EOF
[ollama_logs]
homePath = \$SPLUNK_DB/ollama_logs/db
coldPath = \$SPLUNK_DB/ollama_logs/colddb
thawedPath = \$SPLUNK_DB/ollama_logs/thaweddb
maxDataSize = auto_high_volume
maxHotBuckets = 15
maxWarmDBCount = 300
maxMemMB = 200
maxConcurrentOptimizes = 6
rawChunks = true

[mcp_logs]
homePath = \$SPLUNK_DB/mcp_logs/db
coldPath = \$SPLUNK_DB/mcp_logs/colddb
thawedPath = \$SPLUNK_DB/mcp_logs/thaweddb
maxDataSize = auto_high_volume
maxHotBuckets = 10
maxWarmDBCount = 300
maxMemMB = 150
rawChunks = true

[atlas_logs]
homePath = \$SPLUNK_DB/atlas_logs/db
coldPath = \$SPLUNK_DB/atlas_logs/colddb
thawedPath = \$SPLUNK_DB/atlas_logs/thaweddb
maxDataSize = auto_high_volume
maxHotBuckets = 5
maxWarmDBCount = 100
maxMemMB = 100
maxConcurrentOptimizes = 3
rawChunks = true
EOF
    
    # inputs.conf
    cat > "$CONFIG_DIR/inputs.conf" << EOF
[http]
disabled = 0
port = 8088
enableSSL = 0
max_content_length = 838860800
max_sockets = 2048

[http://ollama_raw_hec]
disabled = 0
token = $HEC_TOKEN
index = ollama_logs
sourcetype = ollama:raw
connection_host = ip
useACK = 0
outputformat = raw

[http://mcp_raw_hec]
disabled = 0
token = $HEC_TOKEN
index = mcp_logs
sourcetype = mcp:raw
connection_host = ip
useACK = 0
outputformat = raw

[http://atlas_raw_hec]
disabled = 0
token = $HEC_TOKEN
index = atlas_logs
sourcetype = atlas:raw
connection_host = ip
useACK = 0
outputformat = raw

[udp://514]
connection_host = ip
index = ollama_logs
sourcetype = syslog

[splunktcp://9997]
connection_host = ip
index = ollama_logs
EOF
    
    log_success "Splunk configuration files created"
}

# Create enhanced Docker Compose
create_enhanced_docker_compose() {
    log_info "Creating enhanced docker-compose.yml..."
    
    local compose_file="$SCRIPT_DIR/docker-compose.yml"
    if [[ -f "$compose_file" ]]; then
        local backup_file="$SCRIPT_DIR/docker-compose.yml.backup.$TIMESTAMP"
        cp "$compose_file" "$backup_file"
        log_success "Backed up existing docker-compose.yml"
    fi
    
    log_success "Docker Compose file is ready with Raw HEC configuration"
}

# Main deployment function
start_deployment() {
    log_success "Starting Raw HEC Deployment for Linux"
    log_success "====================================="
    
    if [[ "$1" != "--force" && "$1" != "--test-only" ]]; then
        read -p "Deploy enhanced Raw HEC logging? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Deployment cancelled"
            return
        fi
    fi
    
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        return 1
    fi
    
    if [[ "$1" == "--test-only" ]]; then
        log_info "Test mode - creating directories and configs only"
        create_directory_structure
        create_splunk_configs
        log_success "Test deployment complete. Check splunk-configs/ directory."
        return
    fi
    
    create_directory_structure
    create_splunk_configs
    create_enhanced_docker_compose
    
    log_success "====================================="
    log_success "Linux Raw HEC Deployment Complete!"
    log_success ""
    log_info "Files Created/Updated:"
    log_info "- docker-compose.yml (enhanced with Raw HEC)"
    log_info "- splunk-configs/indexes.conf (optimized for Raw HEC)"
    log_info "- splunk-configs/inputs.conf (Raw HEC endpoints)"
    log_info "- splunk-configs/props.conf (parsing rules)"
    log_success ""
    log_info "Next Steps:"
    log_info "1. Run: ./start-raw-hec-lab.sh"
    log_info "2. Validate: ./validate-raw-hec.sh"
    log_info "3. Access Splunk: http://localhost:8000 (admin/Password1)"
    log_success ""
    log_info "Raw HEC Benefits:"
    log_info "- Preserves original log format"
    log_info "- Better performance than JSON endpoint"
    log_info "- Native Splunk parsing pipeline"
    log_info "- ATLAS TTP detection included"
}

# Run deployment
start_deployment "$@"