# Использование

## Ежедневный запуск
1. Запустить ComfyUI: `C:\Users\Kikuzen\ComfyUI\run_nvidia_gpu.bat`
2. Запустить мост: `C:\Users\Kikuzen\comfyui-mcp-server\comfy_mcp_venv\Scripts\python.exe C:\Users\Kikuzen\comfyui-mcp-server\server.py`
3. Открыть opencode — MCP `comfyui-mcp-server` и `memory` активны.

## Генерация изображения
Просто попроси: «сгенерируй картинку: ...» — opencode вызовет `generate_image` через comfyui-mcp-server.

## Редактирование
«обрежь image.png по центру 400x300» — скилл image-edit (Pillow).

## Резерв (если мост упал)
Скилл comfy-curl: прямой HTTP в ComfyUI.

## Память
Заметки через MCP memory — сохраняются между сессиями.
