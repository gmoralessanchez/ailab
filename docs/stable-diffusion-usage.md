# ThinkExponential AILab — Stable Diffusion Usage Guide

This guide covers how to generate images with [AUTOMATIC1111 Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) running locally in Docker.

> **Prerequisite:** Complete [environment-setup.md](environment-setup.md) and start the Stable Diffusion stack before following this guide.

---

## Table of contents

1. [Start the stack](#1-start-the-stack)
2. [Download a model](#2-download-a-model)
3. [WebUI walkthrough](#3-webui-walkthrough)
4. [Text-to-image (txt2img)](#4-text-to-image-txt2img)
5. [Image-to-image (img2img)](#5-image-to-image-img2img)
6. [REST API examples](#6-rest-api-examples)
7. [Python client examples](#7-python-client-examples)
8. [Per-model guide and examples](#8-per-model-guide-and-examples)
   - [Stable Diffusion 2.1](#stable-diffusion-21)
   - [Stable Diffusion XL (SDXL)](#stable-diffusion-xl-sdxl)
   - [Stable Diffusion 3.5](#stable-diffusion-35)
   - [FLUX.1](#flux1)
9. [Prompt engineering guide](#9-prompt-engineering-guide)
10. [Parameter reference](#10-parameter-reference)
11. [Managing models](#11-managing-models)

---

## 1. Start the stack

From the repository root:

```bash
# NVIDIA GPU
docker compose -f stable-diffusion/docker-compose.nvidia.yml up -d

# AMD GPU
docker compose -f stable-diffusion/docker-compose.amd.yml up -d

# CPU only (slow — minutes per image)
docker compose -f stable-diffusion/docker-compose.cpu.yml up -d
```

The first startup takes a few minutes while it downloads the base image layers. Open **http://localhost:7860** to access the WebUI.

---

## 2. Download a model

Models are stored in the `sd_models` Docker volume and persist across restarts.

### Option A — download from Hugging Face via the WebUI

1. Open **http://localhost:7860**
2. Go to the **Civitai Helper** or **Model Downloader** extension (if installed), or use the terminal method below.

### Option B — download directly inside the container

```bash
# Open a shell inside the container
docker exec -it stable-diffusion-webui bash

# Navigate to the models folder
cd /app/stable-diffusion-webui/models/Stable-diffusion/

# Download SD 2.1 (requires Hugging Face login for some models)
wget -q "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors"

# Exit the container shell
exit
```

### Option C — copy a local file into the container

```bash
docker cp ~/Downloads/my-model.safetensors \
  stable-diffusion-webui:/app/stable-diffusion-webui/models/Stable-diffusion/
```

After copying, click **🔄 Refresh** next to the model dropdown in the WebUI.

### Model download links

| Model | File | Size |
|---|---|---|
| SD 2.1 | [v2-1_768-ema-pruned.safetensors](https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors) | 5.2 GB |
| SDXL base | [sd_xl_base_1.0.safetensors](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors) | 6.9 GB |
| SDXL refiner | [sd_xl_refiner_1.0.safetensors](https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors) | 6.1 GB |
| FLUX.1 [schnell] | See [Hugging Face](https://huggingface.co/black-forest-labs/FLUX.1-schnell) | ~24 GB |
| FLUX.1 [dev] | See [Hugging Face](https://huggingface.co/black-forest-labs/FLUX.1-dev) | ~24 GB (gated) |
| SD 3.5 Large | See [Hugging Face](https://huggingface.co/stabilityai/stable-diffusion-3.5-large) | ~16 GB (gated) |

> **Gated models** require a Hugging Face account and model access request. Log in with `huggingface-cli login` inside the container and use the access token.

---

## 3. WebUI walkthrough

Open **http://localhost:7860**.

### Main tabs

| Tab | Purpose |
|---|---|
| **txt2img** | Generate images from a text prompt |
| **img2img** | Transform or vary an existing image |
| **Extras** | Upscale, face restoration |
| **PNG Info** | Read generation parameters from a saved image |
| **Settings** | Configure defaults, extensions, and server options |

### Key UI controls

- **Checkpoint** (top-left) — select which model file to use; click 🔄 to refresh after adding new files
- **Prompt** — positive prompt (what to include)
- **Negative prompt** — what to exclude
- **Sampling method** — the diffusion algorithm (DPM++ 2M Karras is a reliable default)
- **Sampling steps** — more steps = higher quality but slower (20–30 is a good range)
- **Width / Height** — output image resolution
- **CFG Scale** — how closely to follow the prompt (7–12 is typical)
- **Seed** — `-1` for random; fix a seed to reproduce an image exactly

---

## 4. Text-to-image (txt2img)

### Basic generation

1. Select a model from the **Checkpoint** dropdown.
2. Enter a positive prompt in the top text box.
3. (Optional) Enter a negative prompt.
4. Click **Generate**.

### Example prompts

**Landscape photography:**
```
Prompt:
  a misty mountain valley at sunrise, golden hour light, pine forest,
  photorealistic, 8k, shot on Canon EOS R5, depth of field

Negative prompt:
  cartoon, painting, blurry, low quality, watermark, text
```

**Portrait:**
```
Prompt:
  portrait of a woman in her 30s, soft studio lighting, bokeh background,
  professional headshot, high resolution, sharp focus

Negative prompt:
  deformed, ugly, bad anatomy, extra limbs, watermark, signature
```

**Concept art:**
```
Prompt:
  futuristic city at night, neon reflections on wet street, flying cars,
  cyberpunk aesthetic, detailed, artstation, by Greg Rutkowski

Negative prompt:
  blurry, low resolution, oversaturated, distorted
```

---

## 5. Image-to-image (img2img)

Img2img lets you start from an existing image and guide the generation with a prompt.

### Steps

1. Click the **img2img** tab.
2. Upload a source image by dragging it into the canvas or clicking the upload icon.
3. Enter a prompt describing what you want the output to look like.
4. Adjust **Denoising strength**:
   - `0.3–0.5` — subtle variation, stays close to original
   - `0.6–0.8` — significant change
   - `0.9–1.0` — almost entirely new image
5. Click **Generate**.

### Common img2img use cases

- **Style transfer** — change the art style while keeping composition
- **Inpainting** — fill in or replace part of an image (use the Inpaint sub-tab)
- **Upscaling with detail** — use img2img with low denoising at 2× resolution
- **Sketch to image** — turn a rough sketch into a rendered image

---

## 6. REST API examples

The WebUI exposes a REST API at **http://localhost:7860/sdapi/v1/**. The full Swagger UI is available at **http://localhost:7860/docs**.

### txt2img

```bash
curl -s -X POST http://localhost:7860/sdapi/v1/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a cozy cabin in a snowy forest, warm light from windows, evening, photorealistic",
    "negative_prompt": "blurry, low quality, cartoon, painting",
    "steps": 25,
    "cfg_scale": 7.5,
    "width": 512,
    "height": 512,
    "sampler_name": "DPM++ 2M Karras",
    "seed": -1
  }' | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
img = base64.b64decode(data['images'][0])
open('output.png', 'wb').write(img)
print('Saved output.png')
"
```

### img2img

```bash
# Encode the source image to base64
BASE64_IMAGE=$(base64 -w 0 input.png)

curl -s -X POST http://localhost:7860/sdapi/v1/img2img \
  -H "Content-Type: application/json" \
  -d "{
    \"init_images\": [\"${BASE64_IMAGE}\"],
    \"prompt\": \"oil painting style, impressionist, vibrant colors\",
    \"denoising_strength\": 0.65,
    \"steps\": 20,
    \"cfg_scale\": 7,
    \"width\": 512,
    \"height\": 512
  }" | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
img = base64.b64decode(data['images'][0])
open('output_img2img.png', 'wb').write(img)
print('Saved output_img2img.png')
"
```

### Get available models

```bash
curl http://localhost:7860/sdapi/v1/sd-models | python3 -m json.tool
```

### Switch active model

```bash
curl -X POST http://localhost:7860/sdapi/v1/options \
  -H "Content-Type: application/json" \
  -d '{"sd_model_checkpoint": "v2-1_768-ema-pruned.safetensors"}'
```

### Get current settings

```bash
curl http://localhost:7860/sdapi/v1/options | python3 -m json.tool
```

---

## 7. Python client examples

```bash
pip install requests pillow
```

### Generate and save an image

```python
import requests
import base64
from PIL import Image
from io import BytesIO

def txt2img(prompt: str, negative_prompt: str = "", steps: int = 25, **kwargs) -> Image.Image:
    payload = {
        "prompt": prompt,
        "negative_prompt": negative_prompt,
        "steps": steps,
        "cfg_scale": kwargs.get("cfg_scale", 7.5),
        "width": kwargs.get("width", 512),
        "height": kwargs.get("height", 512),
        "sampler_name": kwargs.get("sampler_name", "DPM++ 2M Karras"),
        "seed": kwargs.get("seed", -1),
    }
    response = requests.post("http://localhost:7860/sdapi/v1/txt2img", json=payload)
    response.raise_for_status()
    image_data = base64.b64decode(response.json()["images"][0])
    return Image.open(BytesIO(image_data))


# Generate an image
image = txt2img(
    prompt="a serene Japanese garden with a koi pond, cherry blossoms, golden hour",
    negative_prompt="people, text, watermark, low quality",
    steps=30,
    cfg_scale=8,
    width=768,
    height=512,
)
image.save("japanese_garden.png")
print("Saved japanese_garden.png")
```

### Batch generation

```python
import requests, base64
from PIL import Image
from io import BytesIO

prompts = [
    "a red apple on a wooden table, photorealistic",
    "a blue sports car on a mountain road, cinematic",
    "an abstract painting with swirling galaxies, vibrant colors",
]

for i, prompt in enumerate(prompts):
    response = requests.post(
        "http://localhost:7860/sdapi/v1/txt2img",
        json={"prompt": prompt, "steps": 20, "width": 512, "height": 512},
    )
    image_data = base64.b64decode(response.json()["images"][0])
    image = Image.open(BytesIO(image_data))
    image.save(f"batch_{i}.png")
    print(f"Saved batch_{i}.png")
```

---

## 8. Per-model guide and examples

### Stable Diffusion 2.1

SD 2.1 uses a 768×768 native resolution. Best for general photography, landscapes, and portraits with simple prompts.

**Recommended settings:**
- Sampler: `DPM++ 2M Karras`
- Steps: 20–30
- CFG Scale: 7–9
- Resolution: 768×768

**Example:**
```
Prompt:
  majestic eagle soaring above snow-capped mountains, dramatic clouds,
  golden sunlight, wildlife photography, Canon EF 500mm, sharp focus

Negative prompt:
  blurry, overexposed, low detail, cartoonish
```

---

### Stable Diffusion XL (SDXL)

SDXL produces 1024×1024 outputs and can be chained with the refiner model for enhanced detail.

**Recommended settings:**
- Sampler: `DPM++ 2M Karras`
- Steps: 30–40
- CFG Scale: 6–8
- Resolution: 1024×1024

**Switch to SDXL:**
```bash
curl -X POST http://localhost:7860/sdapi/v1/options \
  -H "Content-Type: application/json" \
  -d '{"sd_model_checkpoint": "sd_xl_base_1.0.safetensors"}'
```

**Example:**
```
Prompt:
  hyperrealistic portrait of an elderly sailor with weathered skin,
  piercing blue eyes, white beard, dramatic ocean background,
  studio lighting, 8k, photorealistic, Rembrandt lighting

Negative prompt:
  cartoon, painting, unrealistic, bad anatomy, extra fingers, watermark
```

**Using base + refiner (two-pass):**
```python
import requests, base64
from PIL import Image
from io import BytesIO

# Pass 1: base model generates a latent
base_response = requests.post("http://localhost:7860/sdapi/v1/txt2img", json={
    "prompt": "a futuristic cityscape at dusk, neon lights reflecting on glass towers",
    "steps": 40,
    "cfg_scale": 7,
    "width": 1024,
    "height": 1024,
    "denoising_strength": 0.8,
}).json()

# Save base output
base_image_bytes = base64.b64decode(base_response["images"][0])
Image.open(BytesIO(base_image_bytes)).save("sdxl_base.png")

# Pass 2: refiner polishes the output
requests.post("http://localhost:7860/sdapi/v1/options", json={
    "sd_model_checkpoint": "sd_xl_refiner_1.0.safetensors"
})
refiner_response = requests.post("http://localhost:7860/sdapi/v1/img2img", json={
    "init_images": [base_response["images"][0]],
    "prompt": "a futuristic cityscape at dusk, neon lights reflecting on glass towers",
    "denoising_strength": 0.3,
    "steps": 20,
    "cfg_scale": 7,
    "width": 1024,
    "height": 1024,
}).json()

Image.open(BytesIO(base64.b64decode(refiner_response["images"][0]))).save("sdxl_refined.png")
print("Saved sdxl_base.png and sdxl_refined.png")
```

---

### Stable Diffusion 3.5

SD 3.5 is Stability AI's most recent release. It features significantly improved text rendering, prompt adherence, and composition. It requires at least 10 GB VRAM for the full model.

**Recommended settings:**
- Sampler: `Euler`
- Steps: 28
- CFG Scale: 4.5
- Resolution: 1024×1024

> SD 3.5 uses a different architecture (MMDiT). Ensure the WebUI version supports it, or use a dedicated SD 3.5-compatible loader.

**Example:**
```
Prompt:
  A glass bottle containing a tiny universe with swirling galaxies inside,
  placed on an ancient wooden table, dramatic lighting, hyperrealistic macro photography

Negative prompt:
  (none needed — SD 3.5 follows positive prompts very well)
```

---

### FLUX.1

FLUX.1 by Black Forest Labs achieves state-of-the-art image quality. It requires 16–24 GB VRAM for full performance. The `schnell` variant is faster; `dev` is higher quality.

**Recommended settings:**
- Sampler: `Euler`
- Steps: 4 (schnell) / 20–28 (dev)
- CFG Scale: 1 (schnell) / 3.5 (dev)
- Resolution: 1024×1024

> FLUX.1 requires the `sd-forge` or `ComfyUI` frontend for best compatibility. AUTOMATIC1111 may require an extension.

**Example:**
```
Prompt (FLUX.1 schnell — 4 steps):
  a photorealistic image of a golden retriever puppy playing in autumn leaves,
  shallow depth of field, warm afternoon light

Negative prompt:
  (FLUX.1 does not use negative prompts — leave empty)
```

```bash
# FLUX.1 schnell — fast generation (4 steps)
curl -s -X POST http://localhost:7860/sdapi/v1/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a photorealistic image of a golden retriever puppy playing in autumn leaves, shallow depth of field",
    "steps": 4,
    "cfg_scale": 1,
    "width": 1024,
    "height": 1024,
    "sampler_name": "Euler"
  }' | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
open('flux_output.png', 'wb').write(base64.b64decode(data['images'][0]))
print('Saved flux_output.png')
"
```

---

## 9. Prompt engineering guide

### Positive prompt structure

A well-structured prompt typically follows this pattern:

```
[subject], [setting/context], [style descriptors], [lighting], [camera/technical details], [quality boosters]
```

**Example:**
```
a lone wolf standing on a cliff, overlooking a misty valley,
oil painting style, dramatic, chiaroscuro lighting,
highly detailed, masterpiece, artstation
```

### Effective quality boosters

```
photorealistic, hyperrealistic, 8k, ultra-detailed, sharp focus, 
masterpiece, best quality, professional, award-winning photography
```

### Effective negative prompt terms

```
blurry, low quality, low resolution, bad anatomy, deformed hands, 
extra fingers, watermark, signature, text, username, artist name,
ugly, pixelated, overexposed, underexposed, grainy, noisy
```

### Prompt weighting

Increase or decrease the influence of specific terms using parentheses:

```
# Increase weight (default multiplier: 1.1 per level)
(bright sunlight:1.4) a forest path

# Decrease weight
a forest path [rain:0.5]
```

### Negative prompt for anatomy

When generating people, a detailed negative prompt helps:

```
bad anatomy, bad hands, extra fingers, missing fingers, fused fingers,
too many fingers, deformed, mutated, disfigured, poorly drawn face,
poorly drawn hands, extra limbs, missing limbs, floating limbs,
disconnected limbs, malformed limbs, ugly, duplicate, morbid
```

---

## 10. Parameter reference

| Parameter | Typical range | Notes |
|---|---|---|
| **Steps** | 20–40 | More steps = better quality, slower. Diminishing returns above 40 |
| **CFG Scale** | 5–12 | How strictly to follow the prompt. Higher = more literal but may lose realism |
| **Denoising strength** | 0.3–0.9 | img2img only. Lower = more similar to input image |
| **Width / Height** | 512–1024 | Stay near the model's native resolution. SDXL/FLUX: 1024. SD 2.1: 768 |
| **Seed** | -1 or any int | -1 = random. Fix seed to reproduce images exactly |
| **Batch size** | 1–4 | Number of images per generation (uses more VRAM) |
| **Batch count** | 1–8 | Number of sequential generation runs |

### Samplers comparison

| Sampler | Speed | Quality | Notes |
|---|---|---|---|
| **Euler** | Fast | Good | Reliable default, works well with FLUX |
| **Euler a** | Fast | Good | More variation per seed |
| **DPM++ 2M Karras** | Medium | Very good | Best general-purpose sampler for SD 1.x/2.x |
| **DPM++ SDE Karras** | Slow | Excellent | Highest detail, less predictable |
| **DDIM** | Medium | Good | Deterministic, useful for img2img |
| **LMS Karras** | Fast | Good | Fast convergence |

---

## 11. Managing models

### List installed models

```bash
curl http://localhost:7860/sdapi/v1/sd-models | python3 -c "
import sys, json
for m in json.load(sys.stdin):
    print(m['model_name'])
"
```

### Check current model

```bash
curl http://localhost:7860/sdapi/v1/options | python3 -c "
import sys, json
opts = json.load(sys.stdin)
print('Current model:', opts.get('sd_model_checkpoint'))
"
```

### Switch model via API

```bash
curl -X POST http://localhost:7860/sdapi/v1/options \
  -H "Content-Type: application/json" \
  -d '{"sd_model_checkpoint": "sd_xl_base_1.0.safetensors"}'
```

### Remove a model (free disk space)

```bash
# Enter the container and delete the file
docker exec -it stable-diffusion-webui \
  rm /app/stable-diffusion-webui/models/Stable-diffusion/old-model.safetensors
```

### Inspect volume disk usage

```bash
docker system df -v | grep sd_models
```
