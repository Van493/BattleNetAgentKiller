# BattleNet Agent Killer

A Windows service tool that automatically monitors Battle.net processes and cleans up background Agent processes upon exit.

## Table of Contents

- [Features](#features)
- [Problem Background](#problem-background)
- [Quick Start](#quick-start)
- [File Description](#file-description)
- [Configuration](#configuration)
- [Service Management](#service-management)
- [Manual Installation](#manual-installation)
- [Logging](#logging)
- [Troubleshooting](#troubleshooting)
- [System Requirements](#system-requirements)
- [Disclaimer](#disclaimer)

## Features

- 🎯 **Smart Monitoring**: Automatically detects the status of the Battle.net main process
- 🧹 **Automatic Cleanup**: Cleans up background Agent processes when Battle.net exits
- 🔧 **Service Operation**: Runs as a Windows service, no user intervention required
- ⚡ **Low Resource Usage**: Checks every 10 minutes, minimal system resource consumption
- 📝 **Detailed Logging**: Comprehensive operation logs and error records
- ⚙️ **Highly Configurable**: Customize monitoring parameters via configuration file
- 📦 **Portable Deployment**: All files use relative paths and can be placed anywhere

## Problem Background

After the Battle.net client exits, related `Agent.exe` processes sometimes continue running in the background, causing:

- **High CPU usage by WmiPrvSE.exe process**
- **System resource waste**
- **Manual process termination required**

This tool specifically addresses this issue by automatically monitoring and cleaning up these residual processes when Battle.net exits.

## Quick Start

### Step 1: Download NSSM
```powershell
# Execute in the project directory
.\Download-NSSM.ps1
```
This script automatically downloads and configures NSSM (service manager).

### Step 2: Install Service
```powershell
# Install service with administrator privileges
.\Install-BattleNetAgentKillerService.ps1
```

### Step 3: Verify Installation
```powershell
# Check service status
.\Manage-BattleNetAgentKillerService.ps1 -Action status
```

If you see the service status as "Running", the installation was successful!

## File Description

```
BattleNetAgentKiller/
├── 📄 BattleNetAgentKiller.ps1                    # Main monitoring script
├── ⚙️  BattleNetAgentKiller-config.ini             # Configuration file
├── 📋 BattleNetAgentKiller.log                    # Runtime log
├── 🔧 nssm.exe                                    # Service manager
├── 📥 Download-NSSM.ps1                           # NSSM download script
├── 🛠️  Install-BattleNetAgentKillerService.ps1     # Service installation script
└── 🎛️  Manage-BattleNetAgentKillerService.ps1      # Service management script
```

## Configuration

Edit the `BattleNetAgentKiller-config.ini` file to customize behavior:

```ini
[Settings]
; Battle.net main process name (without .exe)
BattleNetProcessName=Battle.net

; Battle.net main process path pattern (using wildcards)
BattleNetExePattern=*\Battle.net.exe

; Agent process name (without .exe)
AgentProcessName=Agent

; Agent process path pattern (using wildcards)
AgentExePattern=*\Battle.net\Agent\*\Agent.exe

; Check interval (seconds) - Default 10 minutes
CheckInterval=600

; Enable verbose logging (true/false)
VerboseLogging=true

[Logging]
; Log file path (relative path)
LogPath=BattleNetAgentKiller.log

; Enable log rotation (true/false)
EnableLogRotation=true

; Maximum single log file size (MB)
MaxLogSizeMB=5

; Number of log files to retain
MaxLogFiles=3
```

### Configuration Notes

- **Check Interval**: Recommended to keep at 600 seconds (10 minutes) to balance real-time performance and resource usage
- **Verbose Logging**: Set to true for debugging, false for normal use to reduce log volume
- **Path Patterns**: Use wildcard `*` to match different version paths

## Service Management

### Check Service Status
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action status
```

### Start Service
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action start
```

### Stop Service
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action stop
```

### Restart Service
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action restart
```

### Uninstall Service
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action remove
```

## Manual Installation

If automatic installation fails, you can install the service manually:

1. **Open Command Prompt as Administrator**
2. **Navigate to the project directory**
3. **Execute the following commands**:

```cmd
nssm install BattleNetAgentKiller "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
nssm set BattleNetAgentKiller AppDirectory "Full path to current project"
nssm set BattleNetAgentKiller AppParameters "-ExecutionPolicy Bypass -WindowStyle Hidden -File BattleNetAgentKiller.ps1"
nssm set BattleNetAgentKiller DisplayName "BattleNet Agent Killer"
nssm set BattleNetAgentKiller Description "Monitors Battle.net processes and automatically cleans up Agent processes upon exit"
nssm set BattleNetAgentKiller Start SERVICE_AUTO_START
nssm start BattleNetAgentKiller
```

## Logging

The tool provides multi-level logging:

### Application Logs
- **File**: `BattleNetAgentKiller.log`
- **Content**: Main program runtime logs, including detection and cleanup records

### Service Logs
- **Directory**: `logs\`
- **Files**:
  - `service.log` - Service standard output
  - `service-error.log` - Service error output

### Log Example
```
[2024-01-15 14:30:01] [INFO] === Detection Cycle #5 (2024-01-15 14:30:01) ===
[2024-01-15 14:30:01] [INFO] Battle.net process status: Running, Process count: 1
[2024-01-15 14:30:01] [INFO] Battle.net is running, skipping cleanup
```

## Troubleshooting

### ❌ Service Fails to Start

**Possible Causes**:
1. Installation script not run with administrator privileges
2. Incorrect configuration file path
3. NSSM download incomplete

**Solutions**:
1. Right-click the installation script and select "Run as administrator"
2. Check the `logs\service-error.log` file
3. Re-run `.\Download-NSSM.ps1`

### ❌ Process Cleanup Fails

**Possible Causes**:
1. Process path doesn't match configuration
2. Insufficient permissions
3. Process is being used by another program

**Solutions**:
1. Check path patterns in the configuration file
2. Confirm the service is running under the SYSTEM account
3. Check detailed logs for specific errors

### ❌ NSSM Download Fails

**Solutions**:
1. Manually visit [NSSM Official Website](https://nssm.cc/download)
2. Download nssm 2.24
3. Place the appropriate architecture nssm.exe in the project directory

### 🔄 Complete Uninstall

```powershell
# Stop and remove service
.\Manage-BattleNetAgentKillerService.ps1 -Action remove

# Manual cleanup (if needed)
Stop-Process -Name "powershell" -ErrorAction SilentlyContinue
```

## System Requirements

- **Operating System**: Windows 7 / 8 / 10 / 11 / Server 2008+
- **PowerShell**: Version 5.0 or higher
- **Permissions**: Administrator privileges (required only for installation)
- **Space**: Approximately 10MB available space

## How It Works

1. **Service Startup**: Monitoring service automatically runs at system startup
2. **Periodic Checks**: Checks Battle.net process status every 10 minutes
3. **Smart Decision Making**:
   - If Battle.net is running → Wait for next check
   - If Battle.net has exited → Clean up all matching Agent processes
4. **Continuous Execution**: Persistent monitoring ensures no cleanup opportunities are missed

## Frequently Asked Questions

### Q: Is this tool safe?
A: This tool only terminates Battle.net-related Agent processes and does not affect other system processes. The code is open source and can be reviewed.

### Q: Will it affect normal Battle.net usage?
A: No. The tool only cleans up processes after Battle.net exits and does not interfere with normal Battle.net operation.

### Q: How can I confirm the tool is working?
A: Check the `BattleNetAgentKiller.log` file to see records of each detection and cleanup.

### Q: Can I adjust the detection frequency?
A: Yes. Modify the `CheckInterval` parameter in the configuration file (unit: seconds).

## Changelog

### v1.0.0
- ✅ Initial version release
- ✅ Basic monitoring and cleanup functionality
- ✅ Service deployment
- ✅ Complete configuration system

## Technical Support

If you encounter issues:
1. First check the log files for detailed information
2. Verify configuration file parameters are correct
3. Try restarting the service: `.\Manage-BattleNetAgentKillerService.ps1 -Action restart`

## Disclaimer

This tool is for learning and technical exchange purposes only. Users shall bear any risks and responsibilities arising from the use of this tool. The tool author is not responsible for any losses or damages caused by using this tool.

---

**Enjoy a clean gaming environment!** 🎮