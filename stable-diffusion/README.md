# ThinkExponential AILab — Stable Diffusion WebUI

Runs [AUTOMATIC1111 Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) in a Docker container for local AI image generation. Compatible with Windows + WSL2 on both AMD and NVIDIA GPUs.

## Supported models

This WebUI is powered by [AUTOMATIC1111 Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui). For the full list of supported model formats and architectures, refer to the [AUTOMATIC1111 repository](https://github.com/AUTOMATIC1111/stable-diffusion-webui).

Place `.safetensors` or `.ckpt` model files in the `sd_models` Docker volume, or download them through the WebUI.

### Pre-installed models (CPU / OpenVINO image)

The CPU Docker image ships with two SD 1.5-based checkpoints so you can start generating immediately:

| Model | Style | Size |
|---|---|---|
| `deliberate_v2` | Photorealistic | ~2 GB — high quality portraits and scenes |
| `dreamshaper_8` | Versatile | ~2 GB — good at both artistic and photorealistic |

## Prerequisites

### All platforms
- [Docker](https://docs.docker.com/get-docker/) with Compose v2 (`docker compose`)
- At least 8 GB RAM (16 GB+ recommended)
- At least 20 GB free disk space

### NVIDIA (WSL2 on Windows)
1. Update WSL kernel: `wsl --update`
2. Install NVIDIA driver ≥525 on **Windows** from [nvidia.com/drivers](https://www.nvidia.com/drivers/)
3. Inside WSL2, run the included setup script to install the NVIDIA Container Toolkit and configure Docker:
   ```bash
   chmod +x scripts/setup-wsl-nvidia.sh
   ./scripts/setup-wsl-nvidia.sh
   ```
   (See [ollama/README.md](../ollama/README.md) for the manual installation steps.)
4. Minimum 4 GB VRAM (6 GB+ recommended)

### AMD (WSL2 on Windows)
1. Update WSL kernel to 5.15+: `wsl --update`
2. Install ROCm 6.x inside WSL2 using the included setup script:
   ```bash
   chmod +x scripts/setup-wsl-amd.sh
   ./scripts/setup-wsl-amd.sh
   ```
   Or follow the [ROCm installation guide](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/) manually.
3. Add your user to `render` and `video` groups (the script does this automatically):
   ```bash
   sudo usermod -aG render,video $USER
   ```
4. Supported GPUs: RX 6000/7000 series (gfx1030+), Instinct MI series — check the [AMD ROCm compatibility matrix](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html)

### CPU only — Intel Silicon (OpenVINO)

No additional prerequisites beyond Docker. The compose file sets the OpenVINO-compatible flags automatically:
- `--skip-torch-cuda-test` — bypasses the GPU detection that would otherwise prevent startup on CPU-only hosts
- `--precision full --no-half` — disables half-precision arithmetic, required for CPU inference
- `PYTORCH_TRACING_MODE=TORCHFX` — enables OpenVINO acceleration via `torch.compile`
- `--enable-insecure-extension-access` — allows WebUI extensions broader access to internal APIs; this is enabled for compatibility with common extensions and assumes you are running on a trusted local network and not exposing the WebUI directly to the internet

> **Note:** Image generation on CPU is very slow (minutes per image). This mode is intended for testing the interface or on Intel CPU-only machines. See the [Intel Silicon installation guide](https://github.com/openvinotoolkit/stable-diffusion-webui/wiki/Installation-on-Intel-Silicon) for more details.

## Quick start

### NVIDIA GPU
```bash
docker compose -f docker-compose.nvidia.yml up -d
```

### AMD GPU
```bash
docker compose -f docker-compose.amd.yml up -d
```

### Intel CPU only (OpenVINO, slow)
```bash
docker compose -f docker-compose.cpu.yml up -d
```

Open **http://localhost:7860** in your browser.

## Adding models

Download model files from [Hugging Face](https://huggingface.co/models?pipeline_tag=text-to-image) or [CivitAI](https://civitai.com/) and copy them into the Docker volume:

```bash
# Find the volume mount path
docker volume inspect thinkexponential-ailab-stable-diffusion_sd_models

# Or copy a model file directly into the container
docker cp my-model.safetensors stable-diffusion-webui:/app/stable-diffusion-webui/models/Stable-diffusion/
```

After copying, click **Refresh** in the WebUI model selector.

### Adding models to the CPU container

The `sd_models` Docker volume mounts to `models/Stable-diffusion/` inside the container.
You can add models without rebuilding:

```bash
# Download from Hugging Face (example: Realistic Vision v5.1)
docker exec stable-diffusion-webui curl -L -o models/Stable-diffusion/realisticVision_v51.safetensors \
  "https://huggingface.co/SG161222/Realistic_Vision_V5.1_noVAE/resolve/main/Realistic_Vision_V5.1_fp16-no-ema.safetensors"

# Or copy a local file into the running container
docker cp my-model.safetensors stable-diffusion-webui:/app/stable-diffusion-webui/models/Stable-diffusion/
```

After adding a model, click **🔄 Refresh** next to the checkpoint dropdown in the WebUI (no restart needed).

## Tips for better results on CPU (OpenVINO)

1. **Select "Accelerate with OpenVINO"** from the Script dropdown at the bottom of the txt2img / img2img tab
2. **Set OpenVINO Device to `CPU`** in the script options
3. **Use a better model** — select `deliberate_v2` or `dreamshaper_8` via the checkpoint dropdown (top-left)
4. **Recommended settings:**
   - Steps: **20–30** (more steps = better quality but slower)
   - Sampler: **DPM++ 2M Karras** or **Euler a**
   - CFG Scale: **7**
   - Resolution: **512×512** (SD 1.5 models) or **768×768** max
5. **First inference is slow** (~2-5 min) because OpenVINO compiles the model. Subsequent runs with the same resolution/settings are much faster due to caching
6. **Use descriptive prompts:**
   ```
   photo of a golden retriever in a sunlit meadow, shallow depth of field,
   professional photography, 8k, highly detailed
   ```
7. **Use negative prompts** to avoid common artifacts:
   ```
   blurry, low quality, deformed, ugly, bad anatomy, watermark, text
   ```

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
