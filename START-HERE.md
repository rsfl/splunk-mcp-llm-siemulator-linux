# 🎉 Your Raw HEC Setup is Ready! - Linux Version by Rod Soto rodsoto.net



### 🚀 Quick Start Options

**EASIEST**: Run `./quick-start.sh`

**RECOMMENDED**: Open terminal and run:
```bash
./start-raw-hec-lab.sh
```

### 📁 Files Created for You

✅ **deploy-raw-hec.sh** - Main deployment script
✅ **start-raw-hec-lab.sh** - Start your lab environment  
✅ **validate-raw-hec.sh** - Test Raw HEC connectivity
✅ **quick-start.sh** - One-click startup (simplest)
✅ **docker-compose.yml** - Enhanced Docker Compose with Raw HEC
✅ **README.md** - Complete documentation
✅ **splunk-configs/indexes.conf** - Enhanced Splunk indexes
✅ **splunk-configs/inputs.conf** - Raw HEC endpoint configuration
✅ **splunk-configs/props.conf** - Log parsing rules for Raw HEC

### 🔄 Next Steps

1. **Start your lab**:
   ```bash
   ./quick-start.sh
   ```

2. **Wait 30 seconds** for services to start

3. **Validate it's working**:
   ```bash
   ./validate-raw-hec.sh
   ```

4. **Access Splunk**: http://localhost:8000 (admin/Password1)

5. **Test Raw HEC**: http://localhost:8088/services/collector/health

### 🔍 Check Your Logs in Splunk

Use these searches in Splunk:

```spl
# See all your logs
index=ollama_logs OR index=mcp_logs 

# Check Raw HEC is working
index=ollama_logs sourcetype=ollama:docker | head 10

```

### 📊 What Raw HEC Does for You

✅ **Preserves Original Log Format** - Logs look exactly like they do on disk
✅ **Better Performance** - Faster than JSON endpoint  
✅ **Native Splunk Parsing** - Uses your props.conf rules
✅ **ATLAS TTP Detection** - Automatic threat hunting
✅ **Simple Configuration** - Metadata via URL parameters

### 🛠️ Manual Test (Optional)

Test Raw HEC directly:
```bash
curl -X POST \
  -H "Authorization: Splunk f4e45204-7cfa-48b5-bfbe-95cf03dbcad7" \
  -H "Content-Type: text/plain" \
  -d "Test message from Linux curl" \
  "http://localhost:8088/services/collector/raw/1.0?index=ollama_logs&sourcetype=test"
```

### 🚨 If Something Goes Wrong

1. **Check Docker**: Make sure Docker Engine is running
2. **Check .env file**: Should contain your HEC token
3. **Check logs**: `docker-compose logs splunk`
4. **Restart**: `docker-compose down && docker-compose up -d`
5. **Permissions**: Ensure user is in docker group: `sudo usermod -aG docker $USER`

### 🎯 Key Differences from Windows Setup

- **Bash scripts** instead of PowerShell scripts
- **Linux Docker networking** (localhost instead of host.docker.internal)
- **Unix file permissions** and paths
- **curl commands** instead of Invoke-RestMethod

---

## 🚀 START HERE: Run `./quick-start.sh` to begin!

Then check Splunk at http://localhost:8000 (admin/Password1)
