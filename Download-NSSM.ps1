# Download-NSSM.ps1 - 下载并配置 NSSM（相对路径版）
param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NssmPath = Join-Path $ScriptDir "nssm.exe"

Write-Host "正在下载 NSSM..." -ForegroundColor Cyan
Write-Host "目标路径: $NssmPath" -ForegroundColor Gray

try {
    $nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
    $zipPath = Join-Path $env:TEMP "nssm.zip"
    
    # 下载 ZIP 文件
    Write-Host "从 $nssmUrl 下载..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $nssmUrl -OutFile $zipPath
    
    # 解压
    $extractPath = Join-Path $env:TEMP "nssm-extract"
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    Expand-Archive -Path $zipPath -DestinationPath $extractPath
    
    # 找到 nssm.exe (根据系统架构)
    $bitness = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win32" }
    # 修复 Join-Path 使用 - 分步构建路径
    $nssmVersionDir = Join-Path $extractPath "nssm-2.24"
    $bitnessDir = Join-Path $nssmVersionDir $bitness
    $sourceExe = Join-Path $bitnessDir "nssm.exe"
    
    if (Test-Path $sourceExe) {
        Copy-Item $sourceExe $NssmPath
        Write-Host "✓ NSSM 下载完成: $NssmPath" -ForegroundColor Green
    } else {
        throw "在下载包中找不到 nssm.exe"
    }
    
    # 清理临时文件
    Remove-Item $zipPath -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "✗ 下载 NSSM 失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请手动从 https://nssm.cc/download 下载 nssm.exe 并放在脚本目录" -ForegroundColor Yellow
}

Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")