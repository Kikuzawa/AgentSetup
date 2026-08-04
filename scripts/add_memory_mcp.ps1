$ErrorActionPreference = "Stop"
$config = "C:\Users\Kikuzen\.config\opencode\opencode.jsonc"
$json = Get-Content $config -Raw | ConvertFrom-Json
if ($json.mcp.PSObject.Properties.Name -contains "memory") {
    Write-Host "[skip] memory уже в конфиге"
    exit 0
}
$memoryBlock = @{
    type = "local"
    command = @("C:/Program Files/nodejs/npx.cmd", "-y", "@modelcontextprotocol/server-memory")
    enabled = $true
}
$json.mcp | Add-Member -NotePropertyName "memory" -NotePropertyValue $memoryBlock
$json | ConvertTo-Json -Depth 10 | Set-Content $config -Encoding UTF8
Write-Host "[ok] memory добавлен в $config"
