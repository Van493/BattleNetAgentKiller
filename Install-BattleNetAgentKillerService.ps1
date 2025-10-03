# Install-BattleNetAgentKillerService.ps1 - 安装服务（相对路径版）
param(
    [string]$ServiceName = "BattleNetAgentKiller"
)

# 获取脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NssmPath = Join-Path $ScriptDir "nssm.exe"
$ScriptPath = Join-Path $ScriptDir "BattleNetAgentKiller.ps1"
$ConfigPath = Join-Path $ScriptDir "BattleNetAgentKiller-config.ini"

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "请求管理员权限..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ServiceName `"$ServiceName`""
    Start-Process powershell -Verb runas -ArgumentList $arguments
    exit
}

Write-Host "=== BattleNetAgentKiller 服务安装 ===" -ForegroundColor Cyan
Write-Host "脚本目录: $ScriptDir" -ForegroundColor Gray

# 检查必要文件
if (-not (Test-Path $NssmPath)) {
    Write-Host "✗ 找不到 NSSM: $NssmPath" -ForegroundColor Red
    Write-Host "请先运行 Download-NSSM.ps1 或手动下载 nssm.exe 到脚本目录" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $ScriptPath)) {
    Write-Host "✗ 找不到主脚本: $ScriptPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ConfigPath)) {
    Write-Host "⚠ 找不到配置文件，将使用默认配置" -ForegroundColor Yellow
}

try {
    # 检查服务是否已存在
    $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($existingService) {
        Write-Host "发现已存在的服务，正在停止并删除..." -ForegroundColor Yellow
        & $NssmPath remove $ServiceName confirm
        Start-Sleep -Seconds 2
    }
    
    Write-Host "正在创建服务..." -ForegroundColor Green
    
    # 安装服务
    & $NssmPath install $ServiceName "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    
    # 配置服务参数
    & $NssmPath set $ServiceName AppDirectory $ScriptDir
    & $NssmPath set $ServiceName AppParameters "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
    & $NssmPath set $ServiceName DisplayName "BattleNet Agent Killer"
    & $NssmPath set $ServiceName Description "监控战网进程并在退出时自动清理Agent进程"
    
    # 配置启动类型
    & $NssmPath set $ServiceName Start SERVICE_AUTO_START
    
    # 配置故障恢复
    & $NssmPath set $ServiceName ObjectName "LocalSystem"
    & $NssmPath set $ServiceName Type SERVICE_WIN32_OWN_PROCESS
    & $NssmPath set $ServiceName AppPriority NORMAL_PRIORITY_CLASS
    & $NssmPath set $ServiceName AppNoConsole 1
    
    # 配置标准输出（可选，用于调试）
    $logDir = Join-Path $ScriptDir "logs"
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    & $NssmPath set $ServiceName AppStdout (Join-Path $logDir "service.log")
    & $NssmPath set $ServiceName AppStderr (Join-Path $logDir "service-error.log")
    & $NssmPath set $ServiceName AppRotateFiles 1
    & $NssmPath set $ServiceName AppRotateOnline 1
    & $NssmPath set $ServiceName AppRotateSeconds 86400
    & $NssmPath set $ServiceName AppRotateBytes 1048576
    
    Write-Host "✓ 服务创建完成" -ForegroundColor Green
    
    # 启动服务
    Write-Host "启动服务..." -ForegroundColor Yellow
    & $NssmPath start $ServiceName
    
    # 检查服务状态
    Start-Sleep -Seconds 3
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Write-Host "✓ 服务启动成功！" -ForegroundColor Green
    } else {
        Write-Host "⚠ 服务可能启动较慢，请稍后检查状态" -ForegroundColor Yellow
    }
    
    Write-Host "`n=== 服务信息 ===" -ForegroundColor Cyan
    Write-Host "服务名称: $ServiceName" -ForegroundColor White
    Write-Host "显示名称: BattleNet Agent Killer" -ForegroundColor White
    Write-Host "启动类型: 自动" -ForegroundColor White
    Write-Host "运行账户: LocalSystem" -ForegroundColor White
    Write-Host "脚本目录: $ScriptDir" -ForegroundColor White
    
    Write-Host "`n=== 管理命令 ===" -ForegroundColor Cyan
    Write-Host "启动服务: .\Manage-BattleNetAgentKillerService.ps1 -Action start" -ForegroundColor White
    Write-Host "停止服务: .\Manage-BattleNetAgentKillerService.ps1 -Action stop" -ForegroundColor White
    Write-Host "重启服务: .\Manage-BattleNetAgentKillerService.ps1 -Action restart" -ForegroundColor White
    Write-Host "删除服务: .\Manage-BattleNetAgentKillerService.ps1 -Action remove" -ForegroundColor White
    Write-Host "服务状态: .\Manage-BattleNetAgentKillerService.ps1 -Action status" -ForegroundColor White
    
}
catch {
    Write-Host "✗ 服务安装失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")