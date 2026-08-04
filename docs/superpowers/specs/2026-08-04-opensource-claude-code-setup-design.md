# Дизайн: «open-source Claude Code» на базе opencode

Дата: 2026-08-04
Статус: утверждён пользователем

## 1. Цель

Расширить возможности opencode Desktop до паритета с Claude Code, используя только open-source решения (MIT, Apache-2.0). Полный доступ к файловой системе, терминалу, поиску по коду, контекстной памяти, генерации и редактированию изображений.

## 2. Текущее состояние (аудит)

| Компонент | Статус |
|---|---|
| opencode Desktop + Superpowers plugin | работает |
| MCP: mcp-unity, playwright, context7, filesystem, github(docker) | работают |
| Нативные инструменты: bash (PowerShell), ripgrep (grep/glob), read/edit/write, git | встроены |
| Python 3.14.6, uv 0.12.1, Node v24.17.0, npm 11.13.0 | установлены |
| NVIDIA RTX 3060 6GB (CUDA 13.3) | есть |
| Docker Desktop + github-mcp-server | запущен |
| ImageMagick / Pillow / OpenCV | отсутствуют |

**Паритет уже достигнут по:** файловая система, терминал, поиск по коду, веб, документация.
**Не хватает:** контекстная память, генерация изображений, редактирование изображений, setup-скрипт.

## 3. Архитектура

```
┌────────────────────────────────────────────────────────┐
│                    opencode Desktop                    │
│   (model + Superpowers + native bash/ripgrep/edit)     │
└──────────────┬───────────────────────┬─────────────────┘
               │ MCP                    │ MCP
   ┌───────────▼──────────┐  ┌──────────▼──────────┐
   │ Existing (5):        │  │ New (2):            │
   │ mcp-unity ·          │  │ server-memory       │
   │ playwright ·         │  │ comfyui-mcp-server  │
   │ context7 ·           │  └──────────┬──────────┘
   │ filesystem ·         │             │ HTTP :8188
   │ github(docker)       │  ┌──────────▼──────────┐
   └───────────┬──────────┘  │  ComfyUI (RTX 3060) │
               │             │  + SD 1.5 fp16      │
   ┌───────────▼──────────┐  └─────────────────────┘
   │ Skills (global):     │
   │ image-edit (Pillow)  │  Setup: setup_agent.ps1
   │ comfy-curl (reserve) │        setup_agent.sh
   │ vision-screenshot    │
   └──────────────────────┘
```

## 4. Компоненты

| # | Компонент | Назначение | Установка |
|---|---|---|---|
| 1 | `@modelcontextprotocol/server-memory` (MIT) | knowledge graph, память между сессиями | npx + `opencode.jsonc` |
| 2 | ComfyUI portable (GPL-3.0) | локальная генерация SD 1.5 | zip → `C:\Users\Kikuzen\ComfyUI` |
| 3 | SD 1.5 fp16 (≈2.4 ГБ) | чекпоинт модели | HuggingFace → `models\checkpoints\` |
| 4 | `joenorton/comfyui-mcp-server` (Apache-2.0) | мост opencode→ComfyUI (подход B) | uv venv + `opencode.jsonc` |
| 5 | Pillow (MIT) | кроп/резка/фильтры | uv venv `image-tools` |
| 6 | Skill `image-edit` | моя обёртка над Pillow | `~/.config/opencode/skills/` |
| 7 | Skill `comfy-curl` | прямой HTTP к ComfyUI, резерв (подход C) | `~/.config/opencode/skills/` |
| 8 | Skill `vision-screenshot` | скрин Game view из Unity | `~/.config/opencode/skills/` |
| 9 | `setup_agent.ps1` / `setup_agent.sh` | весь монтаж одной командой | `C:\Users\Kikuzen\AgentSetup\` |

## 5. Монтаж ComfyUI (автоматизирован в скрипте)

1. Скачать `ComfyUI_windows_portable_nvidia.7z` из релизов `comfyanonymous/ComfyUI`.
2. Распаковать в `C:\Users\Kikuzen\ComfyUI` (встроенный python + torch CUDA).
3. Положить `sd-v1-5-fp16-pruned.safetensors` в `models\checkpoints\`.
4. Запуск: `python_embeded\python.exe main.py --listen 127.0.0.1 --port 8188`.
5. Health check: `GET /system_stats` → 200.

## 6. Размещение

- Скиллы → `C:\Users\Kikuzen\.config\opencode\skills\` (глобальные, все проекты).
- MCP-конфигурация → `C:\Users\Kikuzen\.config\opencode\opencode.jsonc`.
- Pillow venv → `C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools`.
- Setup-скрипты и спецификации → `C:\Users\Kikuzen\AgentSetup\`.

## 7. Безопасность

- Скрипты показываются пользователю до выполнения.
- Секреты только через `{env:...}` интерполяцию в конфиге; в репозиториях секретов нет.
- ComfyUI слушает только `127.0.0.1`.
- Все загрузки по HTTPS с официальных релизов / HuggingFace.

## 8. Проверка и ошибки

- Каждый шаг скрипта проверяется (node, uv, HTTP-здоровье ComfyUI).
- Тест-сьют: запуск ComfyUI → memory MCP загружается → Pillow делает кроп → генерация 1 тестовой картинки.
- Скрипт идемпотентен: повторный запуск не ломает конфиг.

## 9. Вне объёма (YAGNI)

- Коммерческие API и платные сервисы.
- arto/kun comfyui-mcp (178 инструментов) — избыточен.
- Локальные LLM (ollama/llama.cpp) — не требуется сейчас, модель уже через opencode.
