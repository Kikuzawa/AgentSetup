# setup_agent.ps1 — сборка окружения open-source Claude Code
$ErrorActionPreference = "Stop"
$root = "C:\Users\Kikuzen\AgentSetup"
Write-Host "== AgentSetup: полная сборка =="
foreach ($step in @(
    "$root\scripts\install_comfyui.ps1",
    "$root\scripts\setup_image_tools.ps1",
    "$root\scripts\add_memory_mcp.ps1",
    "$root\scripts\install_comfy_mcp.ps1"
)) {
    if (Test-Path $step) { Write-Host "[run] $step"; & powershell -ExecutionPolicy Bypass -File $step }
}
Write-Host "== Проверка =="
& powershell -ExecutionPolicy Bypass -File "$root\scripts\verify.ps1"
Write-Host "== Готово. Перезапустите opencode. =="
