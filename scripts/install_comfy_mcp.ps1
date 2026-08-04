$ErrorActionPreference = "Stop"
$src = "C:\Users\Kikuzen\comfyui-mcp-server"
if (-not (Test-Path (Join-Path $src "server.py"))) {
    Write-Host "[clone] joenorton/comfyui-mcp-server"
    git clone --depth 1 https://github.com/joenorton/comfyui-mcp-server.git $src
}
if (-not (Test-Path (Join-Path $src "comfy_mcp_venv\Scripts\python.exe"))) {
    Write-Host "[venv] comfy_mcp_venv"
    uv venv (Join-Path $src "comfy_mcp_venv")
}
Write-Host "[pip] deps..."
uv pip install --python (Join-Path $src "comfy_mcp_venv\Scripts\python.exe") -r (Join-Path $src "requirements.txt")
Write-Host "[ok] мост в $src"
