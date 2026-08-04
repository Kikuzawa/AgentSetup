param(
    [string]$ComfyRoot = "C:\Users\Kikuzen\ComfyUI",
    [string]$Version = "v0.30.0"
)
$ErrorActionPreference = "Stop"
$releaseUrl = "https://github.com/Comfy-Org/ComfyUI/releases/download/$Version/ComfyUI_windows_portable_nvidia.7z"
$dl = Join-Path $env:TEMP "ComfyUI_portable.7z"
$sevenZip = Join-Path $env:TEMP "7zr.exe"

# Флаги-артефакты установки: main.py и чекпоинт должны существовать.
$mainPy = Join-Path $ComfyRoot "ComfyUI\main.py"
$ckpt = Join-Path $ComfyRoot "ComfyUI\models\checkpoints\v1-5-pruned-emaonly.safetensors"

if ((Test-Path $mainPy) -and (Test-Path $ckpt) -and ((Get-Item $ckpt).Length -gt 100MB)) {
    Write-Host "[skip] ComfyUI уже установлен в $ComfyRoot"
    exit 0
}

# 7-Zip standalone (используется для .7z распаковки)
if (-not (Test-Path $sevenZip)) {
    Write-Host "[fetch] 7zr.exe..."
    & curl.exe -L --retry 3 -o $sevenZip "https://www.7-zip.org/a/7zr.exe"
}
if (-not (Test-Path $mainPy)) {
    if (-not (Test-Path $dl) -or ((Get-Item $dl).Length -lt 100MB)) {
        Write-Host "[fetch] ComfyUI $Version (2.1 ГБ, с докачкой)..."
        & curl.exe -L -C - --retry 3 --retry-delay 5 -o $dl $releaseUrl
    }
    Write-Host "[extract]..."
    New-Item -ItemType Directory -Force -Path $ComfyRoot | Out-Null
    Push-Location $ComfyRoot
    & $sevenZip x $dl -y | Out-Null
    # Portable-архив распаковывается в обёртку ComfyUI_windows_portable\ —
    # поднимаем содержимое на уровень $ComfyRoot (плоская структура из плана).
    $wrapper = Join-Path $ComfyRoot "ComfyUI_windows_portable"
    if ((Test-Path $wrapper) -and -not (Test-Path $mainPy)) {
        Write-Host "[flatten] $wrapper -> $ComfyRoot"
        Get-ChildItem $wrapper | Move-Item -Destination $ComfyRoot -Force
        Remove-Item $wrapper -Recurse -Force
    }
    Pop-Location
}

# Чекпоинт качается независимо от skip-guard (докачка после частичной неудачи).
if (-not (Test-Path $ckpt) -or ((Get-Item $ckpt).Length -lt 100MB)) {
    Write-Host "[fetch] SD 1.5 fp16 (4.3 ГБ, с докачкой)..."
    New-Item -ItemType Directory -Force -Path (Split-Path $ckpt) | Out-Null
    & curl.exe -L -C - --retry 3 --retry-delay 5 -o $ckpt "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
}
Write-Host "[ok] ComfyUI в $ComfyRoot"
