
# BattleNet Agent Killer

For English, see [README.en.md](README.en.md)

一个自动监控战网进程并在退出时清理后台 Agent 进程的 Windows 服务工具。

## 目录

- [功能特点](#功能特点)
- [问题背景](#问题背景)
- [快速开始](#快速开始)
- [文件说明](#文件说明)
- [配置说明](#配置说明)
- [服务管理](#服务管理)
- [手动安装](#手动安装)
- [日志查看](#日志查看)
- [故障排除](#故障排除)
- [系统要求](#系统要求)
- [免责声明](#免责声明)

## 功能特点

- 🎯 **智能监控**：自动检测战网主程序运行状态
- 🧹 **自动清理**：战网退出时自动清理后台 Agent 进程
- 🔧 **服务化运行**：作为 Windows 服务运行，无需用户干预
- ⚡ **低资源占用**：每10分钟检测一次，系统资源占用极低
- 📝 **详细日志**：完整的操作日志和错误记录
- ⚙️ **高度可配置**：通过配置文件自定义监控参数
- 📦 **便携部署**：所有文件相对路径，可放在任意位置

## 问题背景

战网客户端退出后，相关的 `Agent.exe` 进程有时会继续在后台运行，导致：

- **WmiPrvSE.exe 进程 CPU 占用过高**
- **系统资源浪费**
- **需要手动结束进程**

本工具专门解决这个问题，自动监控并在战网退出时清理这些残留进程。

## 快速开始

### 第一步：下载 NSSM
```powershell
# 在项目目录中执行
.\Download-NSSM.ps1
```
这个脚本会自动下载并配置 NSSM（服务管理器）。

### 第二步：安装服务
```powershell
# 以管理员权限安装服务
.\Install-BattleNetAgentKillerService.ps1
```

### 第三步：验证安装
```powershell
# 检查服务状态
.\Manage-BattleNetAgentKillerService.ps1 -Action status
```

如果看到服务状态为 "Running"，说明安装成功！

## 文件说明

```
BattleNetAgentKiller/
├── 📄 BattleNetAgentKiller.ps1                    # 主监控脚本
├── ⚙️  BattleNetAgentKiller-config.ini             # 配置文件
├── 📋 BattleNetAgentKiller.log                    # 运行日志
├── 🔧 nssm.exe                                    # 服务管理器
├── 📥 Download-NSSM.ps1                           # NSSM 下载脚本
├── 🛠️  Install-BattleNetAgentKillerService.ps1     # 服务安装脚本
└── 🎛️  Manage-BattleNetAgentKillerService.ps1      # 服务管理脚本
```

## 配置说明

编辑 `BattleNetAgentKiller-config.ini` 文件来自定义行为：

```ini
[Settings]
; 战网主程序进程名称（不含.exe）
BattleNetProcessName=Battle.net

; 战网主程序路径模式（使用通配符）
BattleNetExePattern=*\Battle.net.exe

; Agent进程名称（不含.exe）
AgentProcessName=Agent

; Agent进程路径模式（使用通配符）
AgentExePattern=*\Battle.net\Agent\*\Agent.exe

; 检测间隔（秒） - 默认10分钟
CheckInterval=600

; 是否启用详细日志（true/false）
VerboseLogging=true

[Logging]
; 日志文件路径（相对路径）
LogPath=BattleNetAgentKiller.log

; 启用日志轮转（true/false）
EnableLogRotation=true

; 单个日志文件最大大小（MB）
MaxLogSizeMB=5

; 保留的日志文件数量
MaxLogFiles=3
```

### 配置说明

- **检测间隔**：建议保持 600 秒（10分钟），平衡实时性和资源占用
- **详细日志**：调试时可设为 true，正常使用可设为 false 减少日志量
- **路径模式**：使用通配符 `*` 匹配不同版本的路径

## 服务管理

### 查看服务状态
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action status
```

### 启动服务
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action start
```

### 停止服务
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action stop
```

### 重启服务
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action restart
```

### 卸载服务
```powershell
.\Manage-BattleNetAgentKillerService.ps1 -Action remove
```

## 手动安装

如果自动安装失败，可以手动安装服务：

1. **以管理员身份打开命令提示符**
2. **导航到项目目录**
3. **执行以下命令**：

```cmd
nssm install BattleNetAgentKiller "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
nssm set BattleNetAgentKiller AppDirectory "当前项目完整路径"
nssm set BattleNetAgentKiller AppParameters "-ExecutionPolicy Bypass -WindowStyle Hidden -File BattleNetAgentKiller.ps1"
nssm set BattleNetAgentKiller DisplayName "BattleNet Agent Killer"
nssm set BattleNetAgentKiller Description "监控战网进程并在退出时自动清理Agent进程"
nssm set BattleNetAgentKiller Start SERVICE_AUTO_START
nssm start BattleNetAgentKiller
```

## 日志查看

工具提供多层次的日志记录：

### 应用日志
- **文件**: `BattleNetAgentKiller.log`
- **内容**: 主程序的运行日志，包括检测和清理记录

### 服务日志
- **目录**: `logs\`
- **文件**: 
  - `service.log` - 服务标准输出
  - `service-error.log` - 服务错误输出

### 日志示例
```
[2024-01-15 14:30:01] [INFO] === 检测周期 #5 (2024-01-15 14:30:01) ===
[2024-01-15 14:30:01] [INFO] 战网进程状态: 运行中, 进程数: 1
[2024-01-15 14:30:01] [INFO] 战网正在运行，跳过清理
```

## 故障排除

### ❌ 服务无法启动

**可能原因**：
1. 没有以管理员权限运行安装脚本
2. 配置文件路径错误
3. NSSM 下载不完整

**解决方案**：
1. 右键点击安装脚本，选择"以管理员身份运行"
2. 检查 `logs\service-error.log` 文件
3. 重新运行 `.\Download-NSSM.ps1`

### ❌ 进程清理失败

**可能原因**：
1. 进程路径不匹配配置
2. 权限不足
3. 进程已被其他程序占用

**解决方案**：
1. 检查配置文件中的路径模式
2. 确认服务以 SYSTEM 账户运行
3. 查看详细日志了解具体错误

### ❌ NSSM 下载失败

**解决方案**：
1. 手动访问 [NSSM 官网](https://nssm.cc/download)
2. 下载 nssm 2.24
3. 解压后将对应架构的 nssm.exe 放在项目目录

### 🔄 完全卸载

```powershell
# 停止并删除服务
.\Manage-BattleNetAgentKillerService.ps1 -Action remove

# 手动清理（如果需要）
Stop-Process -Name "powershell" -ErrorAction SilentlyContinue
```

## 系统要求

- **操作系统**: Windows 7 / 8 / 10 / 11 / Server 2008+
- **PowerShell**: 版本 5.0 或更高
- **权限**: 管理员权限（仅安装时需要）
- **空间**: 约 10MB 可用空间

## 工作原理

1. **服务启动**：系统启动时自动运行监控服务
2. **定期检测**：每10分钟检查一次战网进程状态
3. **智能判断**：
   - 如果战网在运行 → 等待下次检测
   - 如果战网已退出 → 清理所有匹配的 Agent 进程
4. **循环执行**：持续监控，确保不会错过任何清理机会

## 常见问题

### Q: 这个工具安全吗？
A: 本工具只结束战网相关的 Agent 进程，不会影响其他系统进程。代码开源，可审查。

### Q: 会影响战网正常使用吗？
A: 不会。工具只在战网退出后清理进程，不会干扰战网的正常运行。

### Q: 如何确认工具在工作？
A: 查看 `BattleNetAgentKiller.log` 文件，可以看到每次检测和清理的记录。

### Q: 可以调整检测频率吗？
A: 可以。在配置文件中修改 `CheckInterval` 参数（单位：秒）。

## 更新日志

### v1.0.0
- ✅ 初始版本发布
- ✅ 基础监控和清理功能
- ✅ 服务化部署
- ✅ 完整配置系统

## 技术支持

如果遇到问题：
1. 首先查看日志文件获取详细信息
2. 检查配置文件参数是否正确
3. 尝试重启服务：`.\Manage-BattleNetAgentKillerService.ps1 -Action restart`

## 免责声明

本工具仅用于学习和技术交流目的。使用者应自行承担使用本工具可能产生的任何风险和责任。工具作者不对因使用本工具而导致的任何损失或损害负责。

---

**享受干净的游戏环境！** 🎮
