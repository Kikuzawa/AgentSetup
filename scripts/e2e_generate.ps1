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
$promptId = $resp.prompt_id
Write-Host "[2] prompt_id: $promptId"
Start-Sleep -Seconds 25
# 3) Скачивание результата
$img = Invoke-WebRequest -Uri "http://127.0.0.1:8188/view?filename=opencode_e2e_00001_.png&subfolder=&type=output" -UseBasicParsing -TimeoutSec 20 -OutFile "$out\test_output.png"
# 4) Pillow: проверка + кроп
& "C:\Users\Kikuzen\.local\share\opencode\venvs\image-tools\Scripts\python.exe" -c "from PIL import Image; im=Image.open(r'$out\test_output.png'); print('size:', im.size); im.crop((0,0,256,256)).save(r'$out\test_crop.png'); print('crop ok')"
Write-Host "[ok] результат: $out\test_output.png"
