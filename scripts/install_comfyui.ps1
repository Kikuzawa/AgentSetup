param(
    [string]$ComfyRoot = "C:\Users\Kikuzen\ComfyUI",
    [string]$Version = "v0.30.0"
)
$ErrorActionPreference = "Stop"
$releaseUrl = "https://github.com/Comfy-Org/ComfyUI/releases/download/$Version/ComfyUI_windows_portable_nvidia.7z"
$dl = Join-Path $env:TEMP "ComfyUI_portable.7z"
$sevenZip = Join-Path $env:TEMP "7zr.exe"

if (Test-Path (Join-Path $ComfyRoot "ComfyUI")) {
    Write-Host "[skip] ComfyUI уже установлен в $ComfyRoot"
    exit 0
}

# 7-Zip standalone (используется для .7z распаковки)
if (-not (Test-Path $sevenZip)) {
    Write-Host "[fetch] 7zr.exe..."
    & curl.exe -L --retry 3 -o $sevenZip "https://www.7-zip.org/a/7zr.exe"
}
if (-not (Test-Path $dl) -or ((Get-Item $dl).Length -lt 100MB)) {
    Write-Host "[fetch] ComfyUI $Version (2.1 ГБ, с докачкой)..."
    & curl.exe -L -C - --retry 3 --retry-delay 5 -o $dl $releaseUrl
}
Write-Host "[extract]..."
New-Item -ItemType Directory -Force -Path $ComfyRoot | Out-Null
Push-Location $ComfyRoot
& $sevenZip x $dl -y | Out-Null
Pop-Location

$checkpointDir = Join-Path $ComfyRoot "ComfyUI\models\checkpoints"
$ckpt = Join-Path $checkpointDir "v1-5-pruned-emaonly.safetensors"
if (-not (Test-Path $ckpt) -or ((Get-Item $ckpt).Length -lt 100MB)) {
    Write-Host "[fetch] SD 1.5 fp16 (4.3 ГБ, с докачкой)..."
    & curl.exe -L -C - --retry 3 --retry-delay 5 -o $ckpt "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
}
Write-Host "[ok] ComfyUI в $ComfyRoot"
