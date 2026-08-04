#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
echo "== AgentSetup: полная сборка (WSL/linux) =="
# Windows-шаги (ComfyUI, конфиг) выполняются на Windows.
# Здесь — только подготовка окружения WSL:
command -v uv >/dev/null || echo "[warn] uv отсутствует"
command -v python3 >/dev/null || echo "[warn] python3 отсутствует"
echo "== Проверка =="
"$ROOT/scripts/verify.sh" 2>/dev/null || echo "[warn] verify.sh не найден — скопируйте с Windows"
