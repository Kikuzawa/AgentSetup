# Open-Source Claude Code Setup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Развернуть на Windows-машине Kikuzen локальный open-source аналог Claude Code на базе opencode Desktop: контекстная память, генерация изображений (ComfyUI + SD 1.5 через MCP), редактирование изображений (Pillow-скилл), Vision-вход из Unity и автоматический setup-скрипт.

**Architecture:** opencode (уже установлен) расширяется через: (1) MCP-сервер `server-memory` для knowledge graph; (2) локальный ComfyUI (порт 8188) + мост `joenorton/comfyui-mcp-server` (порт 9000, streamable-http); (3) глобальные superpowers-скиллы `image-edit`, `comfy-curl`, `vision-screenshot` в `~/.config/opencode/skills/`; (4) установщик `setup_agent.ps1` + `setup_agent.sh`.

**Tech Stack:** opencode Desktop, MCP (Model Context Protocol), Python 3.14/uv, ComfyUI (SD 1.5 fp16), Pillow, Node/npx, PowerShell, bash, Docker.

## Global Constraints

- Платформа: Windows 11, shell PowerShell 5.1. Скрипты запускаются только через `bash` tool с `workdir`.
- Только open-source: MIT, Apache-2.0, GPL-3.0. Никаких платных API.
- Секреты — только через `{env:...}` интерполяцию в `opencode.jsonc`; в репозиториях и скриптах секретов нет.
- ComfyUI и MCP-мост слушают ТОЛЬКО `127.0.0.1`.
- Все скрипты показываются пользователю до выполнения.
- Пути: ComfyUI → `C:\Users\Kikuzen\ComfyUI`; скиллы → `C:\Users\Kikuzen\.config\opencode\skills\`; venv → `C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools`; скрипты → `C:\Users\Kikuzen\AgentSetup\`.
- Конфиг opencode: `C:\Users\Kikuzen\.config\opencode\opencode.jsonc` (редактируется только через Read+Edit; после правок требуется рестарт opencode).
- Windows-нюансы: в MCP-командах `npx.cmd` по полному пути `C:/Program Files/nodejs/npx.cmd`; PowerShell блокирует `npm.ps1` → `npm.cmd`.
- Версии: Node v24.17.0, uv 0.12.1, Python 3.14.6, ComfyUI v0.30.0 (nvidia portable), SD 1.5 fp16 (4.27 ГБ).

---

### Task 1: База проекта AgentSetup (структура + git)

**Files:**
- Create: `C:\Users\Kikuzen\AgentSetup\README.md`
- Create: `C:\Users\Kikuzen\AgentSetup\setup_agent.ps1`
- Create: `C:\Users\Kikuzen\AgentSetup\setup_agent.sh`
- Create: `C:\Users\Kikuzen\AgentSetup\.gitignore`

**Interfaces:**
- Consumes: ничего (корневой таск)
- Produces: папки `scripts/`, `skills/`, `docs/`; git-репозиторий с коммитом «chore: init AgentSetup scaffold». Последующие таски пишут скрипты поверх этого каркаса.

- [ ] **Step 1: Создать каркас директорий**

Run:
```powershell
New-Item -ItemType Directory -Force -Path "C:\Users\Kikuzen\AgentSetup\scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "C:\Users\Kikuzen\AgentSetup\docs" | Out-Null
New-Item -ItemType Directory -Force -Path "C:\Users\Kikuzen\AgentSetup\skills" | Out-Null
Test-Path "C:\Users\Kikuzen\AgentSetup\scripts"
```
Expected: `True` (для каждой из трёх).

- [ ] **Step 2: Создать .gitignore**

Create `C:\Users\Kikuzen\AgentSetup\.gitignore`:
```
*.log
*.tmp
venv/
__pycache__/
.DS_Store
```

- [ ] **Step 3: Создать README.md**

Create `C:\Users\Kikuzen\AgentSetup\README.md`:
```markdown
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
```

- [ ] **Step 4: Создать заглушки скриптов**

Create `C:\Users\Kikuzen\AgentSetup\setup_agent.ps1` (заглушка, заполняется в Task 7):
```powershell
# setup_agent.ps1 — сборка окружения open-source Claude Code
# Заполняется в Task 7.
Write-Host "AgentSetup: stub. See Task 7 for full implementation."
```

Create `C:\Users\Kikuzen\AgentSetup\setup_agent.sh` (заглушка):
```bash
#!/usr/bin/env bash
# setup_agent.sh — WSL-вариант сборки (заполняется в Task 7)
echo "AgentSetup: stub. See Task 7 for full implementation."
```

- [ ] **Step 5: Инициализировать git и закоммитить**

Run:
```bash
git add -A
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "chore: init AgentSetup scaffold"
```
Expected: commit создан, `git status` чистый.

---

### Task 2: Монтаж ComfyUI portable + SD 1.5 fp16

**Files:**
- Create: `C:\Users\Kikuzen\AgentSetup\scripts\install_comfyui.ps1`
- (скачивается и распаковывается) `C:\Users\Kikuzen\ComfyUI\`

**Interfaces:**
- Consumes: Task 1 (папка `scripts/`)
- Produces: скрипт `install_comfyui.ps1` и работающий ComfyUI; функция `Start-ComfyUI` (запускает `python_embeded\python.exe main.py --listen 127.0.0.1 --port 8188`). Далее используется Task 5 (MCP-мост) и Task 7 (setup-скрипт).

- [ ] **Step 1: Создать install_comfyui.ps1**

Create `C:\Users\Kikuzen\AgentSetup\scripts\install_comfyui.ps1`:
```powershell
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
```

- [ ] **Step 2: Показать скрипт пользователю и получить подтверждение**

Show the full content of `install_comfyui.ps1` to the user in chat. Ask: "Запускать установку ComfyUI (≈6.4 ГБ загрузок)? Да/Нет". Do NOT execute before explicit approval.

- [ ] **Step 3: Запустить установку**

Run:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Kikuzen\AgentSetup\scripts\install_comfyui.ps1"
```
Expected: скрипт завершится со строкой `[ok] ComfyUI в C:\Users\Kikuzen\ComfyUI`. Timeout: 1800000 мс (30 мин).

- [ ] **Step 4: Проверить здоровье ComfyUI**

Run (в новом bash-вызове, фоновый запуск через Start-Process):
```powershell
Start-Process -FilePath "C:\Users\Kikuzen\ComfyUI\python_embeded\python.exe" -ArgumentList "-s main.py --listen 127.0.0.1 --port 8188" -WorkingDirectory "C:\Users\Kikuzen\ComfyUI\ComfyUI" -WindowStyle Hidden
Start-Sleep -Seconds 40
try { $r = Invoke-RestMethod -Uri "http://127.0.0.1:8188/system_stats" -TimeoutSec 20; Write-Output "OK devices: $($r.devices.Count)" } catch { Write-Output "ERR: $($_.Exception.Message)" }
```
Expected: `OK devices: 1` (CUDA). Завершить процесс после проверки.

- [ ] **Step 5: Commit**

```bash
git add scripts/install_comfyui.ps1
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "feat: install ComfyUI portable + SD 1.5 checkpoint"
```

---

### Task 3: Venv image-tools + установка Pillow

**Files:**
- Create: `C:\Users\Kikuzen\AgentSetup\scripts\setup_image_tools.ps1`
- (создаётся) `C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools\`

**Interfaces:**
- Consumes: Task 1 (папка `scripts/`), uv (глобально установлен)
- Produces: venv с Pillow; путь `$VENV\Scripts\python.exe`. Используется Task 6 (скилл image-edit) и Task 7.

- [ ] **Step 1: Создать setup_image_tools.ps1**

Create `C:\Users\Kikuzen\AgentSetup\scripts\setup_image_tools.ps1`:
```powershell
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
```

- [ ] **Step 2: Показать и получить подтверждение**

Show script to user, ask "Установить Pillow venv? Да/Нет".

- [ ] **Step 3: Запустить установку**

Run:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Kikuzen\AgentSetup\scripts\setup_image_tools.ps1"
```
Expected: вывод версии Pillow (например `11.0.0`).

- [ ] **Step 4: Commit**

```bash
git add scripts/setup_image_tools.ps1
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "feat: Pillow venv for image editing"
```

---

### Task 4: server-memory MCP (knowledge graph)

**Files:**
- Modify: `C:\Users\Kikuzen\.config\opencode\opencode.jsonc` (добавить сервер `memory`)
- Create: `C:\Users\Kikuzen\AgentSetup\scripts\add_memory_mcp.ps1`

**Interfaces:**
- Consumes: Task 1 (папка `scripts/`)
- Produces: сервер `memory` в конфиге opencode; инструменты `memory_store`/`memory_query` (появятся после рестарта opencode). Используется в Task 7 (setup-скрипт).

- [ ] **Step 1: Создать add_memory_mcp.ps1**

Create `C:\Users\Kikuzen\AgentSetup\scripts\add_memory_mcp.ps1`:
```powershell
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
```

- [ ] **Step 2: Проверить итоговый JSON валиден**

Run: `node -e "JSON.parse(require('fs').readFileSync('C:/Users/Kikuzen/.config/opencode/opencode.jsonc','utf8').replace(/\/\/.*$/gm,'').replace(/,\s*}/g,'}'))"` — Expected: без ошибок (JSONC → JSON через strip комментариев). NOTE: если в конфиге остались `"enabled": true` trailing issues — исправить вручную.

- [ ] **Step 3: Показать пользователю diff конфига**

Show the `memory` block to the user. Ask: "Добавить server-memory в конфиг? Да/Нет".

- [ ] **Step 4: Commit**

```bash
git add scripts/add_memory_mcp.ps1
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "feat: memory MCP server (knowledge graph)"
```

NOTE: применение требует рестарта opencode — пометить как pending в выводе.

---

### Task 5: comfyui-mcp-server (мост, подход B)

**Files:**
- Create: `C:\Users\Kikuzen\AgentSetup\scripts\install_comfy_mcp.ps1`
- (клонируется) `C:\Users\Kikuzen\comfyui-mcp-server\`

**Interfaces:**
- Consumes: Task 2 (работающий ComfyUI :8188), Task 1 (папка `scripts/`)
- Produces: MCP-мост на `http://127.0.0.1:9000/mcp` (streamable-http) + блок `comfyui-mcp-server` (type remote) в `opencode.jsonc`. Используется Task 7.

- [ ] **Step 1: Создать install_comfy_mcp.ps1**

Create `C:\Users\Kikuzen\AgentSetup\scripts\install_comfy_mcp.ps1`:
```powershell
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
# mcp>=2.0 удалил mcp.server.fastmcp (крашит server.py на импорте) - фиксируем <2.0
uv pip install --python (Join-Path $src "comfy_mcp_venv\Scripts\python.exe") "mcp<2.0"
uv pip install --python (Join-Path $src "comfy_mcp_venv\Scripts\python.exe") -r (Join-Path $src "requirements.txt")
Write-Host "[ok] мост в $src"
```

- [ ] **Step 2: Показать и получить подтверждение**

Show script to user, ask "Установить comfyui-mcp-server? Да/Нет".

- [ ] **Step 3: Запустить установку**

Run:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Kikuzen\AgentSetup\scripts\install_comfy_mcp.ps1"
```
Expected: клон создан, deps установлены.

- [ ] **Step 4: Добавить remote-сервер в конфиг opencode**

Edit `C:\Users\Kikuzen\.config\opencode\opencode.jsonc` — добавить в `"mcp"`:
```jsonc
"comfyui-mcp-server": {
  "type": "remote",
  "url": "http://127.0.0.1:9000/mcp",
  "enabled": true
}
```

- [ ] **Step 5: Проверить запуск моста**

Run (фоновый процесс, как в Task 2 Step 4):
```powershell
Start-Process -FilePath "C:\Users\Kikuzen\comfyui-mcp-server\comfy_mcp_venv\Scripts\python.exe" -ArgumentList "server.py" -WorkingDirectory "C:\Users\Kikuzen\comfyui-mcp-server" -WindowStyle Hidden
Start-Sleep -Seconds 10
try { $r = Invoke-WebRequest -Uri "http://127.0.0.1:9000/mcp" -UseBasicParsing -TimeoutSec 10; Write-Output "HTTP $($r.StatusCode)" } catch { Write-Output "ERR: $($_.Exception.Message)" }
```
Expected: HTTP 200 (или MCP-ответ). Остановить процесс после проверки.

- [ ] **Step 6: Commit**

```bash
git add scripts/install_comfy_mcp.ps1
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "feat: comfyui-mcp-server bridge"
```

---

### Task 6: Глобальные скиллы (image-edit, comfy-curl, vision-screenshot)

**Files:**
- Create: `C:\Users\Kikuzen\.config\opencode\skills\image-edit\SKILL.md`
- Create: `C:\Users\Kikuzen\.config\opencode\skills\comfy-curl\SKILL.md`
- Create: `C:\Users\Kikuzen\.config\opencode\skills\vision-screenshot\SKILL.md`

**Interfaces:**
- Consumes: Task 3 (venv image-tools + Pillow), Task 2 (ComfyUI :8188), mcp-unity (уже есть)
- Produces: три суперпауэр-скилла, видимых во всех проектах. Используются в Task 7 (проверка end-to-end).

- [ ] **Step 1: Создать папки скиллов**

Run:
```powershell
New-Item -ItemType Directory -Force -Path "C:\Users\Kikuzen\.config\opencode\skills\image-edit" | Out-Null
New-Item -ItemType Directory -Force -Path "C:\Users\Kikuzen\.config\opencode\skills\comfy-curl" | Out-Null
New-Item -ItemType Directory -Force -Path "C:\Users\Kikuzen\.config\opencode\skills\vision-screenshot" | Out-Null
```

- [ ] **Step 2: Создать скилл image-edit**

Create `C:\Users\Kikuzen\.config\opencode\skills\image-edit\SKILL.md`:
```markdown
---
name: image-edit
description: Редактирование изображений с помощью Pillow (venv image-tools). Кроп, изменение размера, конвертация форматов, наложение фильтров, наложение текста/прямоугольников по текстовому запросу. Использовать, когда нужно обработать локальный файл изображения.
---

# Image Edit (Pillow)

## Вход
- Путь к файлу изображения (PNG/JPEG/WebP)
- Текстовое описание операции

## Venv
`C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools\Scripts\python.exe`

## Шаблон команды

    & <venv>\python.exe <скрипт>.py <вход> <выход> <операции...>

## Примеры операций (пишутся в Python через Pillow)
- Кроп: `Image.open(src).crop((x0,y0,x1,y1)).save(dst)`
- Resize: `.resize((w,h), Image.LANCZOS)`
- Конвертация: `.convert("RGB").save(dst, "JPEG")`
- Грейскейл/сепия/размытие: фильтры `ImageFilter.BLUR`, `ImageEnhance`
- Текст/фигуры: `ImageDraw.Draw(img).text(...)` / `.rectangle(...)`

## Правила
1. Всегда сохраняй результат в новый файл — не перезаписывай исходник.
2. Выводи путь результата и размеры (пиксели) после операции.
3. Для batch-обработки — цикл по входной папке.
```

- [ ] **Step 3: Создать скилл comfy-curl (резерв, подход C)**

Create `C:\Users\Kikuzen\.config\opencode\skills\comfy-curl\SKILL.md`:
```markdown
---
name: comfy-curl
description: Прямая отправка workflow-запросов в ComfyUI (127.0.0.1:8188) через HTTP/WebSocket. Резерв для генерации изображений, когда comfyui-mcp-server недоступен или нужен кастомный workflow.
---

# ComfyUI via HTTP (резервный канал)

## Endpoint
- Base: `http://127.0.0.1:8188`
- Submit: `POST /prompt` с `{ "prompt": <workflow JSON>, "client_id": "opencode" }`
- Ожидание: WebSocket `ws://127.0.0.1:8188/ws?clientId=opencode` — события `executing`
- Скачивание результата: `GET /view?filename=...&subfolder=...&type=output`

## Минимальный workflow SD 1.5 (JSON)
```json
{
  "1": {"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":"v1-5-pruned-emaonly.safetensors"}},
  "2": {"class_type":"CLIPTextEncode","inputs":{"text":"PARAM_PROMPT","clip":["1",1]}},
  "3": {"class_type":"CLIPTextEncode","inputs":{"text":"","clip":["1",1]}},
  "4": {"class_type":"EmptyLatentImage","inputs":{"width":512,"height":512,"batch_size":1}},
  "5": {"class_type":"KSampler","inputs":{"seed":0,"steps":20,"cfg":7,"sampler_name":"euler","scheduler":"normal","denoise":1,"model":["1",0],"positive":["2",0],"negative":["3",0],"latent_image":["4",0]}},
  "6": {"class_type":"VAEDecode","inputs":{"samples":["5",0],"vae":["1",2]}},
  "7": {"class_type":"SaveImage","inputs":{"filename_prefix":"opencode","images":["6",0]}}
}
```
Заменить `PARAM_PROMPT` на запрос, `POST` на `/prompt`, прочитать `prompt_id`, ждать события `"prompt_id"` в WS, затем `GET /view`.

## Правила
1. Только localhost — никогда не шлём наружу.
2. Проверяй `GET /system_stats` перед стартом.
3. Выводи путь сохранённого файла.
```

- [ ] **Step 4: Создать скилл vision-screenshot**

Create `C:\Users\Kikuzen\.config\opencode\skills\vision-screenshot\SKILL.md`:
```markdown
---
name: vision-screenshot
description: Получение визуального состояния Unity-сцены. Снимок Game view через mcp-unity (или нативный скриншот экрана), сохранение в PNG и чтение как изображение для vision-анализа.
---

# Vision Screenshot (Unity)

## Способ 1 — mcp-unity
Использовать mcp-unity инструмент получения скриншота сцены (если доступен) и сохранить в `assets/screenshots/<name>.png`.

## Способ 2 — нативный скриншот (резерв)
PowerShell: `Add-Type -AssemblyName System.Windows.Forms,System.Drawing` → захват виртуального экрана → сохранить PNG.

## Способ 3 — Playwright
Если нужен скрин веб-превью — playwright `browser_take_screenshot` с указанием `filename`.

## Правила
1. PNG — основной формат (без потерь).
2. Сохраняй с осмысленным именем: `scene_before_change.png`.
3. Всегда читай результат обратно как изображение (vision), чтобы подтвердить, что видно.
```

- [ ] **Step 5: Показать пользователю скиллы и получить подтверждение**

Show the three SKILL.md files. Ask: "Создать глобальные скиллы? Да/Нет".

- [ ] **Step 6: Commit (в AgentSetup repo — копии для версионирования)**

```bash
Copy-Item "C:\Users\Kikuzen\.config\opencode\skills" "C:\Users\Kikuzen\AgentSetup\skills\global" -Recurse -Force
git add skills/
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "feat: global skills image-edit, comfy-curl, vision-screenshot"
```

---

### Task 7: Полноценный setup_agent.ps1 + setup_agent.sh

**Files:**
- Modify: `C:\Users\Kikuzen\AgentSetup\setup_agent.ps1`
- Modify: `C:\Users\Kikuzen\AgentSetup\setup_agent.sh`
- Create: `C:\Users\Kikuzen\AgentSetup\scripts\verify.ps1`

**Interfaces:**
- Consumes: Task 2 (ComfyUI), Task 3 (Pillow), Task 4 (memory config), Task 5 (comfy mcp), Task 6 (скиллы)
- Produces: единая точка входа `setup_agent.ps1`/`.sh` (источник правды для пользователя) и `verify.ps1` (health-check всех компонентов). Финал проекта.

- [ ] **Step 1: Заменить заглушку setup_agent.ps1**

Replace `C:\Users\Kikuzen\AgentSetup\setup_agent.ps1` content:
```powershell
# setup_agent.ps1 — сборка окружения open-source Claude Code
$ErrorActionPreference = "Stop"
$root = "C:\Users\Kikuzen\AgentSetup"
Write-Host "== AgentSetup: полная сборка =="
foreach ($step in @(
    "$root\scripts\install_comfyui.ps1",
    "$root\scripts\setup_image_tools.ps1",
    "$root\scripts\add_memory_mcp.ps1",
    "$root\scripts\install_comfy_mcp.ps1"
)) {
    if (Test-Path $step) { Write-Host "[run] $step"; & powershell -ExecutionPolicy Bypass -File $step }
}
Write-Host "== Проверка =="
& powershell -ExecutionPolicy Bypass -File "$root\scripts\verify.ps1"
Write-Host "== Готово. Перезапустите opencode. =="
```

- [ ] **Step 2: Заменить заглушку setup_agent.sh**

Replace `C:\Users\Kikuzen\AgentSetup\setup_agent.sh`:
```bash
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
```

- [ ] **Step 3: Создать verify.ps1**

Create `C:\Users\Kikuzen\AgentSetup\scripts\verify.ps1`:
```powershell
$ok = $true
$checks = @()
function Test-Step($Name, [scriptblock]$Check) {
    try { $r = & $Check; if ($r) { Write-Host "[ok] $Name" } else { Write-Host "[FAIL] $Name"; $script:ok = $false } }
    catch { Write-Host "[FAIL] $Name — $($_.Exception.Message)"; $script:ok = $false }
}
Test-Step "ComfyUI :8188" { (Invoke-WebRequest "http://127.0.0.1:8188/system_stats" -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 }
Test-Step "comfy-mcp :9000" { (Invoke-WebRequest "http://127.0.0.1:9000/mcp" -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 }
Test-Step "Pillow venv" { Test-Path "C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools\Scripts\python.exe" }
Test-Step "Memory MCP в конфиге" { (Get-Content "C:\Users\Kikuzen\.config\opencode\opencode.jsonc" -Raw) -match '"memory"' }
Test-Step "Скиллы" { (Test-Path "C:\Users\Kikuzen\.config\opencode\skills\image-edit\SKILL.md") -and (Test-Path "C:\Users\Kikuzen\.config\opencode\skills\comfy-curl\SKILL.md") -and (Test-Path "C:\Users\Kikuzen\.config\opencode\skills\vision-screenshot\SKILL.md") }
if (-not $ok) { Write-Host "[result] ЕСТЬ ОШИБКИ"; exit 1 } else { Write-Host "[result] ВСЁ ОК" }
```

- [ ] **Step 4: Показать setup-скрипты и получить подтверждение**

Show `setup_agent.ps1` full content to user. Ask: "Запустить полную сборку? Да/Нет". (Каждый подскрипт уже одобрен ранее; здесь — общий прогон.)

- [ ] **Step 5: Прогнать verify**

Run:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Kikuzen\AgentSetup\scripts\verify.ps1"
```
Expected: `[result] ВСЁ ОК` (ComfyUI и мост должны быть запущены).

- [ ] **Step 6: Commit**

```bash
git add -A
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "feat: complete setup_agent entry points + verify"
```

---

### Task 8: E2E-проверка (генерация тестовой картинки)

**Files:**
- Create: `C:\Users\Kikuzen\AgentSetup\scripts\e2e_generate.ps1`

**Interfaces:**
- Consumes: Task 2 (ComfyUI), Task 5 (comfy mcp), Task 3 (Pillow)
- Produces: `test_output.png` в `C:\Users\Kikuzen\AgentSetup\e2e\`; подтверждение, что вся цепочка opencode→MCP→ComfyUI→Pillow работает.

- [ ] **Step 1: Создать e2e_generate.ps1**

Create `C:\Users\Kikuzen\AgentSetup\scripts\e2e_generate.ps1`:
```powershell
$ErrorActionPreference = "Stop"
$out = "C:\Users\Kikuzen\AgentSetup\e2e"
New-Item -ItemType Directory -Force -Path $out | Out-Null
# 1) Проверка ComfyUI
$stats = Invoke-RestMethod "http://127.0.0.1:8188/system_stats" -TimeoutSec 10
Write-Host "[1] ComfyUI OK, devices: $($stats.devices.Count)"
# 2) Отправка workflow через comfy-curl подход (прямой HTTP)
$wf = @{
  "1" = @{ class_type = "CheckpointLoaderSimple"; inputs = @{ ckpt_name = "v1-5-pruned-emaonly.safetensors" } }
  "2" = @{ class_type = "CLIPTextEncode"; inputs = @{ text = "a cute robot in a field"; clip = @("1", 1) } }
  "3" = @{ class_type = "CLIPTextEncode"; inputs = @{ text = ""; clip = @("1", 1) } }
  "4" = @{ class_type = "EmptyLatentImage"; inputs = @{ width = 512; height = 512; batch_size = 1 } }
  "5" = @{ class_type = "KSampler"; inputs = @{ seed = 42; steps = 20; cfg = 7; sampler_name = "euler"; scheduler = "normal"; denoise = 1; model = @("1",0); positive = @("2",0); negative = @("3",0); latent_image = @("4",0) } }
  "6" = @{ class_type = "VAEDecode"; inputs = @{ samples = @("5",0); vae = @("1",2) } }
  "7" = @{ class_type = "SaveImage"; inputs = @{ filename_prefix = "opencode_e2e"; images = @("6",0) } }
}
$body = @{ prompt = $wf; client_id = "opencode-e2e" } | ConvertTo-Json -Depth 10
$resp = Invoke-RestMethod -Uri "http://127.0.0.1:8188/prompt" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 15
$pid = $resp.prompt_id
Write-Host "[2] prompt_id: $pid"
Start-Sleep -Seconds 25
# 3) Скачивание результата
$img = Invoke-WebRequest -Uri "http://127.0.0.1:8188/view?filename=opencode_e2e_00001_.png&subfolder=&type=output" -UseBasicParsing -TimeoutSec 20 -OutFile "$out\test_output.png"
# 4) Pillow: проверка + кроп
& "C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools\Scripts\python.exe" -c "from PIL import Image; im=Image.open(r'$out\test_output.png'); print('size:', im.size); im.crop((0,0,256,256)).save(r'$out\test_crop.png'); print('crop ok')"
Write-Host "[ok] результат: $out\test_output.png"
```

- [ ] **Step 2: Показать и получить подтверждение**

Show script to user. Ask: "Запустить E2E-тест генерации? Да/Нет".

- [ ] **Step 3: Запустить E2E**

Run:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Kikuzen\AgentSetup\scripts\e2e_generate.ps1"
```
Expected: `[ok] результат: ...\test_output.png` и строка `size: (512, 512)` + `crop ok`. Timeout: 300000 мс.

- [ ] **Step 4: Открыть результат для vision-проверки**

Read `C:\Users\Kikuzen\AgentSetup\e2e\test_output.png` (read tool, image attachment) — подтвердить, что картинка сгенерирована корректно.

- [ ] **Step 5: Commit**

```bash
git add scripts/e2e_generate.ps1 e2e/
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "test: e2e image generation smoke test"
```

---

### Task 9: Финальная интеграция и документация

**Files:**
- Modify: `C:\Users\Kikuzen\AgentSetup\README.md`
- Create: `C:\Users\Kikuzen\AgentSetup\docs\USAGE.md`

**Interfaces:**
- Consumes: все предыдущие таски
- Produces: полная документация по запуску и использованию системы.

- [ ] **Step 1: Обновить README**

Modify `C:\Users\Kikuzen\AgentSetup\README.md` — добавить секции: «Статус компонентов» (что установлено), «Как перезапустить opencode для применения MCP», «Как запускать ComfyUI вручную», «Как использовать скиллы».

- [ ] **Step 2: Создать docs/USAGE.md**

Create `C:\Users\Kikuzen\AgentSetup\docs\USAGE.md`:
```markdown
# Использование

## Ежедневный запуск
1. Запустить ComfyUI: `C:\Users\Kikuzen\ComfyUI\run_nvidia_gpu.bat`
2. Запустить мост: `python C:\Users\Kikuzen\comfyui-mcp-server\server.py`
3. Открыть opencode — MCP `comfyui-mcp-server` и `memory` активны.

## Генерация изображения
Просто попроси: «сгенерируй картинку: ...» — opencode вызовет `generate_image` через comfyui-mcp-server.

## Редактирование
«обрежь image.png по центру 400x300» — скилл image-edit (Pillow).

## Резерв (если мост упал)
Скилл comfy-curl: прямой HTTP в ComfyUI.

## Память
Заметки через MCP memory — сохраняются между сессиями.
```

- [ ] **Step 3: Показать документацию пользователю**

Ask: "Документация готова — финальный коммит? Да/Нет".

- [ ] **Step 4: Финальный commit**

```bash
git add -A
git -c user.name="AgentSetup" -c user.email="agent@local" commit -m "docs: final usage documentation"
```

---

## Self-Review

**Spec coverage:**
- ✅ Память (гибрид) → Task 4 (server-memory) + Superpowers-спеки уже в проекте
- ✅ ImageGen (подход B) → Task 5 (comfyui-mcp-server)
- ✅ ImageGen (резерв C) → Task 6 (comfy-curl skill) + Task 8 (прямой HTTP в E2E)
- ✅ Image editing → Task 3 (Pillow) + Task 6 (image-edit skill)
- ✅ Vision вход → Task 6 (vision-screenshot skill через mcp-unity)
- ✅ Setup-скрипты оба → Task 7 (setup_agent.ps1 + .sh)
- ✅ Безопасность (только localhost, секреты через env) → Global Constraints + скиллы
- ✅ Health-check → Task 7 verify.ps1 + Task 8 E2E

**Placeholder scan:** Нет TBD/TODO; все скрипты содержат полный код. Один осознанный нюанс: Task 4 Step 2 удаляет `//`-комментарии для JSON-валидации — `opencode.jsonc` содержит только комментарии верхнего уровня, это покрыто regex.

**Type consistency:** Имена серверов в конфиге (`memory`, `comfyui-mcp-server`), пути (`C:\Users\Kikuzen\ComfyUI`, venv `image-tools`), имена скиллов (`image-edit`, `comfy-curl`, `vision-screenshot`) согласованы во всех тасках.
