$ok = $true
$checks = @()
function Test-Step($Name, [scriptblock]$Check) {
    try { $r = & $Check; if ($r) { Write-Host "[ok] $Name" } else { Write-Host "[FAIL] $Name"; $script:ok = $false } }
    catch { Write-Host "[FAIL] $Name — $($_.Exception.Message)"; $script:ok = $false }
}
Test-Step "ComfyUI :8188" { (Invoke-WebRequest "http://127.0.0.1:8188/system_stats" -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 }
Test-Step "comfy-mcp :9000" { (& curl.exe -s -o NUL -w "%{http_code}" --max-time 5 -H "Accept: text/event-stream" "http://127.0.0.1:9000/mcp") -eq "200" }
Test-Step "Pillow venv" { Test-Path "C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools\Scripts\python.exe" }
Test-Step "Memory MCP в конфиге" { (Get-Content "C:\Users\Kikuzen\.config\opencode\opencode.jsonc" -Raw) -match '"memory"' }
Test-Step "Скиллы" { (Test-Path "C:\Users\Kikuzen\.config\opencode\skills\image-edit\SKILL.md") -and (Test-Path "C:\Users\Kikuzen\.config\opencode\skills\comfy-curl\SKILL.md") -and (Test-Path "C:\Users\Kikuzen\.config\opencode\skills\vision-screenshot\SKILL.md") }
if (-not $ok) { Write-Host "[result] ЕСТЬ ОШИБКИ"; exit 1 } else { Write-Host "[result] ВСЁ ОК" }
