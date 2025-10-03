# Manage-BattleNetAgentKillerService.ps1 - 服务管理脚本（相对路径版）
param(
    [string]$Action = "status"  # status, start, stop, restart, remove
)

# 获取脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NssmPath = Join-Path $ScriptDir "nssm.exe"
$ServiceName = "BattleNetAgentKiller"

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($Action -ne "status" -and -not (Test-Administrator)) {
    Write-Host "请求管理员权限..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action `"$Action`""
    Start-Process powershell -Verb runas -ArgumentList $arguments
    exit
}

if (-not (Test-Path $NssmPath)) {
    Write-Host "✗ 找不到 NSSM: $NssmPath" -ForegroundColor Red
    Write-Host "请先运行 Download-NSSM.ps1 下载 nssm.exe" -ForegroundColor Yellow
    exit 1
}

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

Write-Host "=== BattleNetAgentKiller 服务管理 ===" -ForegroundColor Cyan
Write-Host "脚本目录: $ScriptDir" -ForegroundColor Gray

switch ($Action.ToLower()) {
    "status" {
        Write-Host "`n服务状态:" -ForegroundColor Cyan
        if ($service) {
            Write-Host "服务名称: $($service.Name)" -ForegroundColor White
            Write-Host "显示名称: $($service.DisplayName)" -ForegroundColor White
            Write-Host "状态: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Yellow' })
            Write-Host "启动类型: $($service.StartType)" -ForegroundColor White
        } else {
            Write-Host "服务未安装" -ForegroundColor Red
        }
    }
    
    "start" {
        if ($service) {
            Write-Host "启动服务..." -ForegroundColor Yellow
            & $NssmPath start $ServiceName
            Start-Sleep -Seconds 2
            $service.Refresh()
            Write-Host "服务状态: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Red' })
        } else {
            Write-Host "服务未安装" -ForegroundColor Red
        }
    }
    
    "stop" {
        if ($service) {
            Write-Host "停止服务..." -ForegroundColor Yellow
            & $NssmPath stop $ServiceName
            Start-Sleep -Seconds 2
            $service.Refresh()
            Write-Host "服务状态: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Stopped') { 'Green' } else { 'Red' })
        } else {
            Write-Host "服务未安装" -ForegroundColor Red
        }
    }
    
    "restart" {
        if ($service) {
            Write-Host "重启服务..." -ForegroundColor Yellow
            & $NssmPath restart $ServiceName
            Start-Sleep -Seconds 3
            $service.Refresh()
            Write-Host "服务状态: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Red' })
        } else {
            Write-Host "服务未安装" -ForegroundColor Red
        }
    }
    
    "remove" {
        if ($service) {
            Write-Host "删除服务..." -ForegroundColor Yellow
            & $NssmPath remove $ServiceName confirm
            Write-Host "✓ 服务已删除" -ForegroundColor Green
        } else {
            Write-Host "服务未安装" -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "`n可用操作:" -ForegroundColor Cyan
        Write-Host "  status  - 查看服务状态" -ForegroundColor White
        Write-Host "  start   - 启动服务" -ForegroundColor White
        Write-Host "  stop    - 停止服务" -ForegroundColor White
        Write-Host "  restart - 重启服务" -ForegroundColor White
        Write-Host "  remove  - 删除服务" -ForegroundColor White
        Write-Host "`n使用示例: .\$($MyInvocation.MyCommand.Name) -Action status" -ForegroundColor Gray
    }
}

if ($Action -eq "status") {
    Write-Host "`n按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}