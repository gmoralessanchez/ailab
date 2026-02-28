# Stable Diffusion WebUI

Runs [AUTOMATIC1111 Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) in a Docker container for local AI image generation. Compatible with Windows + WSL2 on both AMD and NVIDIA GPUs.

## Supported models

Place `.safetensors` or `.ckpt` model files in the `sd_models` Docker volume, or download them through the WebUI. Popular open-source models:

| Model | Source | Notes |
|---|---|---|
| Stable Diffusion 3.5 | [Hugging Face](https://huggingface.co/stabilityai/stable-diffusion-3.5-large) | Latest Stability AI release |
| Stable Diffusion XL (SDXL) | [Hugging Face](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) | High-res, versatile |
| FLUX.1 [dev] | [Hugging Face](https://huggingface.co/black-forest-labs/FLUX.1-dev) | State-of-the-art image quality |
| FLUX.1 [schnell] | [Hugging Face](https://huggingface.co/black-forest-labs/FLUX.1-schnell) | Faster FLUX variant |
| Stable Diffusion 2.1 | [Hugging Face](https://huggingface.co/stabilityai/stable-diffusion-2-1) | Reliable classic |

## Prerequisites

### All platforms
- [Docker](https://docs.docker.com/get-docker/) with Compose v2 (`docker compose`)
- At least 8 GB RAM (16 GB+ recommended)
- At least 20 GB free disk space

### NVIDIA (WSL2 on Windows)
1. Update WSL kernel: `wsl --update`
2. Install NVIDIA driver ≥525 on **Windows** from [nvidia.com/drivers](https://www.nvidia.com/drivers/)
3. Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) inside WSL2 (see [ollama/README.md](../ollama/README.md) for detailed steps)
4. Minimum 4 GB VRAM (6 GB+ recommended)

### AMD (WSL2 on Windows)
1. Update WSL kernel: `wsl --update`
2. Install ROCm 6.x inside WSL2 following the [ROCm installation guide](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/)
3. Add your user to `render` and `video` groups:
   ```bash
   sudo usermod -aG render,video $USER
   ```
4. Supported GPUs: RX 6000/7000 series (gfx1030+), Instinct MI series — check the [AMD ROCm compatibility matrix](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html)

## Quick start

### NVIDIA GPU
```bash
docker compose -f docker-compose.nvidia.yml up -d
```

### AMD GPU
```bash
docker compose -f docker-compose.amd.yml up -d
```

### CPU only (slow)
```bash
docker compose -f docker-compose.cpu.yml up -d
```

Open **http://localhost:7860** in your browser.

## Adding models

Download model files from [Hugging Face](https://huggingface.co/models?pipeline_tag=text-to-image) or [CivitAI](https://civitai.com/) and copy them into the Docker volume:

```bash
# Find the volume mount path
docker volume inspect ailab-stable-diffusion_sd_models

# Or copy a model file directly into the container
docker cp my-model.safetensors stable-diffusion-webui:/app/stable-diffusion-webui/models/Stable-diffusion/
```

After copying, click **Refresh** in the WebUI model selector.

## API access

The WebUI exposes a REST API at **http://localhost:7860/sdapi/v1/**:

```bash
curl -X POST http://localhost:7860/sdapi/v1/txt2img \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a beautiful sunset over mountains", "steps": 20}'
```

## Stopping the stack

```bash
docker compose -f docker-compose.nvidia.yml down     # stop and remove containers
docker compose -f docker-compose.nvidia.yml down -v  # also remove volumes (model data)
```
