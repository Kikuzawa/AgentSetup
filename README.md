# AgentSetup — open-source Claude Code (Windows)

Набор для сборки окружения open-source альтернативы Claude Code на opencode Desktop:
локальная генерация изображений (ComfyUI), редактирование (Pillow), память
(server-memory) и vision-вход из Unity (mcp-unity + скиллы).

## Стек

- **opencode + Superpowers** — основа агента и навыков.
- **ComfyUI (SD 1.5)** — локальная генерация изображений на `127.0.0.1:8188`.
- **comfyui-mcp-server** — мост opencode ↔ ComfyUI на `127.0.0.1:9000/mcp`.
- **server-memory** — knowledge graph, заметки сохраняются между сессиями.
- **Pillow venv** — `C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools`.
- **3 глобальных скилла** — `image-edit`, `comfy-curl`, `vision-screenshot`.

## Запуск

1. Установить окружение: `powershell -ExecutionPolicy Bypass -File .\setup_agent.ps1` (Windows)
   или `bash setup_agent.sh` (WSL/Linux).
2. Перезапустить opencode — MCP `memory` и `comfyui-mcp-server` подхватятся автоматически.

## Проверка

    powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1

Health-check всех компонентов (ComfyUI, мост, память, Pillow, скиллы).

## Лицензии

Open-source стек: MIT / Apache-2.0 / GPL-3.0.
