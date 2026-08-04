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
