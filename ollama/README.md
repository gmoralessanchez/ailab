# ThinkExponential AILab — Ollama + Open WebUI

Runs [Ollama](https://ollama.com/) as a local LLM server with [Open WebUI](https://github.com/open-webui/open-webui) as a browser-based chat interface. Compatible with Windows + WSL2 on both AMD and NVIDIA GPUs.

## Supported models

Pull any model from [ollama.com/library](https://ollama.com/library) after the stack is running:

| Model | Pull command | Notes |
|---|---|---|
| Llama 3.3 70B | `ollama pull llama3.3` | Meta, top-tier open weights |
| Llama 3.2 3B/1B | `ollama pull llama3.2` | Lightweight Meta model |
| Mistral 7B | `ollama pull mistral` | Fast, efficient |
| Mistral Small 3.1 | `ollama pull mistral-small:3.1` | Latest Mistral |
| Gemma 3 | `ollama pull gemma3` | Google, strong reasoning |
| DeepSeek-R1 | `ollama pull deepseek-r1` | Chain-of-thought reasoning |
| Qwen 2.5 | `ollama pull qwen2.5` | Alibaba, multilingual |
| Phi-4 | `ollama pull phi4` | Microsoft, small but capable |
| CodeLlama | `ollama pull codellama` | Code generation |
| DeepSeek-Coder V2 | `ollama pull deepseek-coder-v2` | Code generation |

## Prerequisites

### All platforms
- [Docker](https://docs.docker.com/get-docker/) with Compose v2 (`docker compose`)

### NVIDIA (WSL2 on Windows)
1. Update WSL kernel: `wsl --update`
2. Install the latest NVIDIA driver on **Windows** (≥525) from [nvidia.com/drivers](https://www.nvidia.com/drivers/)
3. Inside WSL2, run the included setup script to install the NVIDIA Container Toolkit and configure Docker:
   ```bash
   chmod +x scripts/setup-wsl-nvidia.sh
   ./scripts/setup-wsl-nvidia.sh
   ```
   Or install manually:
   ```bash
   curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
   curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
     sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
     sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
   sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
   sudo nvidia-ctk runtime configure --runtime=docker
   sudo systemctl restart docker
   ```
4. Verify: `nvidia-smi` should show your GPU

### AMD (WSL2 on Windows)
1. Update WSL kernel to 5.15+: `wsl --update`
2. Install ROCm 6.x inside WSL2 using the included setup script:
   ```bash
   chmod +x scripts/setup-wsl-amd.sh
   ./scripts/setup-wsl-amd.sh
   ```
   Or follow the [ROCm installation guide](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/) manually.
3. Add your user to the `render` and `video` groups (the script does this automatically):
   ```bash
   sudo usermod -aG render,video $USER
   ```
4. Verify: `rocminfo` should list your GPU
5. Check that `/dev/kfd` and `/dev/dri` are present

> **Note:** ROCm on WSL2 is actively developing. Check the [AMD ROCm compatibility matrix](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html) to confirm your GPU is supported.
> **Note:** Docker Engine inside WSL2 is recommended over Docker Desktop for AMD GPU access — Docker Desktop may not correctly expose `/dev/kfd` to containers.

## Quick start

### NVIDIA GPU
```bash
docker compose -f docker-compose.nvidia.yml up -d
```

### AMD GPU
```bash
docker compose -f docker-compose.amd.yml up -d
```

### CPU only
```bash
docker compose -f docker-compose.cpu.yml up -d
```

Open **http://localhost:3000** in your browser to access Open WebUI.

## Pulling models

After the stack is running, pull a model in one of two ways:

### Option A — Open WebUI (browser)

1. Open **http://localhost:3000** and sign in.
2. Click the **⚙ Settings** icon (top-right).
3. Go to **Models → Manage**.
4. In the **"Pull a model from Ollama.com"** field, type the model name (e.g. `llama3.3`).
5. Click the **download (↓) icon** to start pulling the model.

Browse all available models at **[ollama.com/library](https://ollama.com/library)**.

### Option B — Docker CLI

```bash
docker exec -it ollama ollama pull llama3.3
```

## API access

Ollama exposes an OpenAI-compatible API at **http://localhost:11434**:

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.3",
  "prompt": "Why is the sky blue?"
}'
```

## Stopping the stack

```bash
docker compose -f docker-compose.nvidia.yml down   # stop and remove containers
docker compose -f docker-compose.nvidia.yml down -v  # also remove volumes (model data)
```
