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
