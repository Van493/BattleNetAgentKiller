param(
    [string]$ConfigPath = "BattleNetAgentKiller-config.ini"
)

# 获取脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# 读取配置文件
function Read-Config {
    param([string]$Path)
    
    $config = @{}
    if (Test-Path $Path) {
        $content = Get-Content $Path
        $currentSection = "Settings"
        
        foreach ($line in $content) {
            $line = $line.Trim()
            
            if ($line -match "^\s*\[(.+)\]\s*$") {
                $currentSection = $matches[1]
                continue
            }
            elseif ($line -match "^\s*;") {
                continue
            }
            elseif ($line -match "^\s*(\w+)\s*=\s*(.+)\s*$") {
                $key = $matches[1]
                $value = $matches[2].Trim()
                $config["$currentSection.$key"] = $value
            }
        }
    }
    return $config
}

# 日志轮转函数
function Invoke-LogRotation {
    param(
        [string]$LogPath,
        [int]$MaxLogSizeMB,
        [int]$MaxLogFiles
    )
    
    try {
        if (!(Test-Path $LogPath)) {
            return
        }
        
        $logFile = Get-Item $LogPath
        $logSizeMB = $logFile.Length / 1MB
        
        if ($logSizeMB -ge $MaxLogSizeMB) {
            Write-Host "执行日志轮转，当前日志大小: $([math]::Round($logSizeMB, 2))MB" -ForegroundColor Yellow
            
            $logDir = Split-Path $LogPath -Parent
            $logName = [System.IO.Path]::GetFileNameWithoutExtension($LogPath)
            $logExt = [System.IO.Path]::GetExtension($LogPath)
            
            $oldestLog = Join-Path $logDir "$logName.$MaxLogFiles$logExt"
            if (Test-Path $oldestLog) {
                Remove-Item $oldestLog -Force
            }
            
            for ($i = $MaxLogFiles - 1; $i -ge 1; $i--) {
                $currentLog = Join-Path $logDir "$logName.$i$logExt"
                $newLog = Join-Path $logDir "$logName.$(($i + 1))$logExt"
                
                if (Test-Path $currentLog) {
                    Move-Item $currentLog $newLog -Force
                }
            }
            
            $newLog = Join-Path $logDir "$logName.1$logExt"
            Move-Item $LogPath $newLog -Force
            
            Write-Host "日志轮转完成" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "日志轮转失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 写入日志
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogPath,
        [hashtable]$LogConfig
    )
    
    if ($LogConfig.EnableLogRotation -eq "true") {
        Invoke-LogRotation -LogPath $LogPath -MaxLogSizeMB $LogConfig.MaxLogSizeMB -MaxLogFiles $LogConfig.MaxLogFiles
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction Stop
        
        $color = @{
            "INFO" = "White"
            "WARNING" = "Yellow"
            "ERROR" = "Red"
            "SUCCESS" = "Green"
        }
        Write-Host $logEntry -ForegroundColor $color[$Level]
    }
    catch {
        Write-Host "无法写入日志文件: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 根据进程名称和路径模式查找进程
function Get-ProcessesByPattern {
    param(
        [string]$ProcessName,
        [string]$PathPattern
    )
    
    $matchingProcesses = @()
    
    try {
        $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        
        foreach ($process in $processes) {
            try {
                $processPath = $process.Path
                $processStartTime = $process.StartTime
                
                if ($processPath -and (Test-PathPattern -Path $processPath -Pattern $PathPattern)) {
                    $matchingProcesses += @{
                        Id = $process.Id
                        Name = $process.ProcessName
                        Path = $processPath
                        StartTime = if ($processStartTime) { $processStartTime } else { "未知" }
                    }
                }
            }
            catch {
                continue
            }
        }
    }
    catch {
        Write-Log -Message "获取进程列表失败: $($_.Exception.Message)" -Level "ERROR" -LogPath $global:LogPath -LogConfig $global:LogConfig
    }
    
    return ,$matchingProcesses
}

# 测试路径是否匹配模式
function Test-PathPattern {
    param(
        [string]$Path,
        [string]$Pattern
    )
    
    try {
        $regexPattern = [System.Text.RegularExpressions.Regex]::Escape($Pattern)
        $regexPattern = $regexPattern -replace '\\\*', '.*'
        $regexPattern = "^" + $regexPattern + "$"
        return $Path -match $regexPattern
    }
    catch {
        return $false
    }
}

# 安全终止进程
function Stop-ProcessSafely {
    param(
        [object]$ProcessInfo,
        [string]$LogPath,
        [hashtable]$LogConfig
    )
    
    try {
        Write-Log -Message "正在终止进程: $($ProcessInfo.Name) (PID: $($ProcessInfo.Id))" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
        
        $process = Get-Process -Id $ProcessInfo.Id -ErrorAction SilentlyContinue
        if ($process) {
            if ($process.Responding) {
                $process.CloseMainWindow() | Out-Null
                Start-Sleep -Seconds 2
            }
            
            if (!$process.HasExited) {
                $process.Kill()
                Start-Sleep -Seconds 1
            }
            
            if ($process.HasExited) {
                Write-Log -Message "成功终止进程: $($ProcessInfo.Name) (PID: $($ProcessInfo.Id))" -Level "SUCCESS" -LogPath $LogPath -LogConfig $LogConfig
                return $true
            } else {
                Write-Log -Message "无法终止进程: $($ProcessInfo.Name) (PID: $($ProcessInfo.Id))" -Level "ERROR" -LogPath $LogPath -LogConfig $LogConfig
                return $false
            }
        } else {
            Write-Log -Message "进程已不存在: $($ProcessInfo.Name) (PID: $($ProcessInfo.Id))" -Level "WARNING" -LogPath $LogPath -LogConfig $LogConfig
            return $true
        }
    }
    catch {
        Write-Log -Message "终止进程失败 $($ProcessInfo.Name) (PID: $($ProcessInfo.Id)): $($_.Exception.Message)" -Level "ERROR" -LogPath $LogPath -LogConfig $LogConfig
        return $false
    }
}

# 清理Agent进程
function Invoke-AgentCleanup {
    param(
        [string]$AgentProcessName,
        [string]$AgentPattern,
        [string]$LogPath,
        [hashtable]$LogConfig,
        [bool]$VerboseLogging
    )
    
    Write-Log -Message "开始清理Agent进程..." -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    
    $agentProcesses = Get-ProcessesByPattern -ProcessName $AgentProcessName -PathPattern $AgentPattern
    $cleanedCount = 0
    $failedCount = 0
    
    Write-Log -Message "找到 $($agentProcesses.Count) 个Agent进程需要清理" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    
    if ($agentProcesses.Count -gt 0) {
        Write-Log -Message "=== 找到的Agent进程详情 ===" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
        for ($i = 0; $i -lt $agentProcesses.Count; $i++) {
            $agentProcess = $agentProcesses[$i]
            Write-Log -Message "进程 #$($i+1): PID=$($agentProcess.Id), 名称=$($agentProcess.Name), 路径=$($agentProcess.Path), 启动时间=$($agentProcess.StartTime)" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
        }
        Write-Log -Message "=== 开始逐个清理 ===" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
        
        foreach ($agentProcess in $agentProcesses) {
            Write-Log -Message "正在处理进程: $($agentProcess.Name) (PID: $($agentProcess.Id))" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
            
            $result = Stop-ProcessSafely -ProcessInfo $agentProcess -LogPath $LogPath -LogConfig $LogConfig
            if ($result) {
                $cleanedCount++
                Write-Log -Message "✓ 成功终止进程: $($agentProcess.Name) (PID: $($agentProcess.Id))" -Level "SUCCESS" -LogPath $LogPath -LogConfig $LogConfig
            } else {
                $failedCount++
                Write-Log -Message "✗ 终止进程失败: $($agentProcess.Name) (PID: $($agentProcess.Id))" -Level "ERROR" -LogPath $LogPath -LogConfig $LogConfig
            }
            
            Start-Sleep -Milliseconds 500
        }
        
        Write-Log -Message "Agent进程清理完成: 成功 $cleanedCount/$($agentProcesses.Count), 失败 $failedCount/$($agentProcesses.Count)" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
        
        if ($failedCount -eq 0 -and $cleanedCount -gt 0) {
            Write-Log -Message "所有Agent进程清理成功！" -Level "SUCCESS" -LogPath $LogPath -LogConfig $LogConfig
        } elseif ($failedCount -gt 0) {
            Write-Log -Message "部分Agent进程清理失败，可能需要手动处理" -Level "WARNING" -LogPath $LogPath -LogConfig $LogConfig
        }
    } else {
        Write-Log -Message "未找到需要清理的Agent进程" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    }
    
    return $cleanedCount
}

# 主监控逻辑（持续运行版本）
function Start-Monitoring {
    param(
        [string]$BattleNetProcessName,
        [string]$BattleNetPattern,
        [string]$AgentProcessName,
        [string]$AgentPattern,
        [int]$CheckInterval,
        [bool]$VerboseLogging,
        [string]$LogPath,
        [hashtable]$LogConfig
    )
    
    Write-Log -Message "=== BattleNetAgentKiller 持续监控启动 ===" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    Write-Log -Message "监控进程: $BattleNetProcessName" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    Write-Log -Message "监控路径: $BattleNetPattern" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    Write-Log -Message "清理进程: $AgentProcessName" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    Write-Log -Message "清理路径: $AgentPattern" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    Write-Log -Message "检测间隔: $CheckInterval 秒 ($([math]::Round($CheckInterval/60, 1)) 分钟)" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    Write-Log -Message "运行模式: 持续监控，低资源占用" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
    
    $cycleCount = 0
    
    try {
        while ($true) {
            $cycleCount++
            $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            
            Write-Log -Message "=== 检测周期 #$cycleCount ($currentTime) ===" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
            
            # 检查战网主程序是否在运行
            $battleNetProcesses = Get-ProcessesByPattern -ProcessName $BattleNetProcessName -PathPattern $BattleNetPattern
            $battleNetRunning = $battleNetProcesses.Count -gt 0
            
            if ($VerboseLogging) {
                Write-Log -Message "战网进程状态: $(if ($battleNetRunning) { '运行中' } else { '未运行' }), 进程数: $($battleNetProcesses.Count)" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
            }
            
            # 如果战网没有在运行，检查并清理Agent进程
            if (-not $battleNetRunning) {
                Write-Log -Message "战网未在运行，检查并清理Agent进程..." -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
                
                $cleanedCount = Invoke-AgentCleanup -AgentProcessName $AgentProcessName -AgentPattern $AgentPattern -LogPath $LogPath -LogConfig $LogConfig -VerboseLogging $VerboseLogging
                
                if ($cleanedCount -gt 0) {
                    Write-Log -Message "本次清理完成: $cleanedCount 个Agent进程已终止" -Level "SUCCESS" -LogPath $LogPath -LogConfig $LogConfig
                } else {
                    Write-Log -Message "本次检查: 无需清理" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
                }
            } else {
                Write-Log -Message "战网正在运行，跳过清理" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
            }
            
            # 计算下次检测时间
            $nextCheckTime = (Get-Date).AddSeconds($CheckInterval).ToString("HH:mm:ss")
            Write-Log -Message "本次检测完成，下次检测时间: $nextCheckTime" -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
            Write-Log -Message "等待 $CheckInterval 秒后进行下一次检测..." -Level "INFO" -LogPath $LogPath -LogConfig $LogConfig
            
            # 等待指定间隔
            Start-Sleep -Seconds $CheckInterval
        }
    }
    catch {
        Write-Log -Message "监控过程中出错: $($_.Exception.Message)" -Level "ERROR" -LogPath $LogPath -LogConfig $LogConfig
        Write-Log -Message "脚本将在10秒后退出..." -Level "ERROR" -LogPath $LogPath -LogConfig $LogConfig
        Start-Sleep -Seconds 10
        exit 1
    }
}

# 主程序
function Main {
    # 读取配置
    $config = Read-Config -Path $ConfigPath
    
    # 设置配置值
    $BattleNetProcessName = if ($config["Settings.BattleNetProcessName"]) { $config["Settings.BattleNetProcessName"] } else { "Battle.net" }
    $BattleNetPattern = if ($config["Settings.BattleNetExePattern"]) { $config["Settings.BattleNetExePattern"] } else { "*\Battle.net.exe" }
    $AgentProcessName = if ($config["Settings.AgentProcessName"]) { $config["Settings.AgentProcessName"] } else { "Agent" }
    $AgentPattern = if ($config["Settings.AgentExePattern"]) { $config["Settings.AgentExePattern"] } else { "*\Battle.net\Agent\*\Agent.exe" }
    $CheckInterval = if ($config["Settings.CheckInterval"]) { [int]$config["Settings.CheckInterval"] } else { 600 }
    $VerboseLogging = if ($config["Settings.VerboseLogging"]) { $config["Settings.VerboseLogging"] -eq "true" } else { $true }
    
    # 日志配置
    $LogPath = if ($config["Logging.LogPath"]) { $config["Logging.LogPath"] } else { "BattleNetAgentKiller.log" }
    $EnableLogRotation = if ($config["Logging.EnableLogRotation"]) { $config["Logging.EnableLogRotation"] } else { "true" }
    $MaxLogSizeMB = if ($config["Logging.MaxLogSizeMB"]) { [int]$config["Logging.MaxLogSizeMB"] } else { 5 }
    $MaxLogFiles = if ($config["Logging.MaxLogFiles"]) { [int]$config["Logging.MaxLogFiles"] } else { 3 }
    
    # 确保日志路径是绝对路径
    if (![System.IO.Path]::IsPathRooted($LogPath)) {
        $LogPath = Join-Path $ScriptDir $LogPath
    }
    
    # 创建日志目录
    $logDir = Split-Path $LogPath -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # 设置全局配置
    $global:LogPath = $LogPath
    $global:LogConfig = @{
        EnableLogRotation = $EnableLogRotation
        MaxLogSizeMB = $MaxLogSizeMB
        MaxLogFiles = $MaxLogFiles
    }
    
    # 启动持续监控
    Start-Monitoring -BattleNetProcessName $BattleNetProcessName -BattleNetPattern $BattleNetPattern -AgentProcessName $AgentProcessName -AgentPattern $AgentPattern -CheckInterval $CheckInterval -VerboseLogging $VerboseLogging -LogPath $LogPath -LogConfig $global:LogConfig
}

# 执行主程序
Main