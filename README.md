# AgentSetup — open-source Claude Code (Windows)

Расширение opencode Desktop: память, генерация/редактирование изображений, Vision.

## Запуск

    powershell -ExecutionPolicy Bypass -File .\setup_agent.ps1

Или (WSL/bash): `bash setup_agent.sh`.

## Компоненты

- ComfyUI portable (SD 1.5 fp16) — `C:\Users\Kikuzen\ComfyUI`, порт 8188
- comfyui-mcp-server — порт 9000 (streamable-http)
- server-memory (npx) — knowledge graph
- Pillow venv — `C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools`
- Скиллы: image-edit, comfy-curl, vision-screenshot
