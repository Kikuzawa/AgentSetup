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
