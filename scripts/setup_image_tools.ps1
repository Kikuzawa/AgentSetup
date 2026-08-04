$ErrorActionPreference = "Stop"
$venv = "C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools"
if (-not (Test-Path (Join-Path $venv "Scripts\python.exe"))) {
    Write-Host "[venv] создаю $venv"
    uv venv $venv
}
Write-Host "[pip] Pillow..."
uv pip install --python (Join-Path $venv "Scripts\python.exe") pillow
Write-Host "[ok] Pillow:"
& (Join-Path $venv "Scripts\python.exe") -c "import PIL; print(PIL.__version__)"
