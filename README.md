# ailab

Local AI model deployments using Docker. Supports the most popular open-source generative AI models and is compatible with **Windows + WSL2** on both **NVIDIA** and **AMD** GPUs.

## Deployments

| Deployment | Models | Port |
|---|---|---|
| [ollama/](ollama/) | Llama 3.3, Mistral, Gemma 3, DeepSeek-R1, Qwen 2.5, Phi-4, CodeLlama, … | 3000 (WebUI), 11434 (API) |
| [stable-diffusion/](stable-diffusion/) | SD 3.5, SDXL, FLUX.1, SD 2.1 | 7860 |

## Quick start

### 1. Check your GPU

```bash
chmod +x scripts/check-gpu.sh
./scripts/check-gpu.sh
```

### 2. (First time) Install GPU drivers in WSL2

| GPU | Script |
|---|---|
| NVIDIA | `chmod +x scripts/setup-wsl-nvidia.sh && ./scripts/setup-wsl-nvidia.sh` |
| AMD | `chmod +x scripts/setup-wsl-amd.sh && ./scripts/setup-wsl-amd.sh` |

### 3. Start a deployment

#### LLMs with Ollama + Open WebUI

```bash
# NVIDIA
docker compose -f ollama/docker-compose.nvidia.yml up -d

# AMD
docker compose -f ollama/docker-compose.amd.yml up -d

# CPU only
docker compose -f ollama/docker-compose.cpu.yml up -d
```

Open **http://localhost:3000** → pull a model (e.g. `llama3.3`) → start chatting.

#### Image generation with Stable Diffusion

```bash
# NVIDIA
docker compose -f stable-diffusion/docker-compose.nvidia.yml up -d

# AMD
docker compose -f stable-diffusion/docker-compose.amd.yml up -d

# CPU only (slow)
docker compose -f stable-diffusion/docker-compose.cpu.yml up -d
```

Open **http://localhost:7860** to access the Stable Diffusion WebUI.

## Requirements

- Windows 11 or Windows 10 (version 21H2+) with **WSL2**
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (with WSL2 backend) or Docker Engine inside WSL2
- Compose V2 (`docker compose`)
- **NVIDIA**: Driver ≥ 525 on Windows + NVIDIA Container Toolkit in WSL2
- **AMD**: ROCm 6.x in WSL2 + supported GPU (RX 6000/7000 series or Instinct MI)

See the **[docs/](docs/)** folder for detailed guides, or each deployment's `README.md` for quick-reference instructions.

## Documentation

| Guide | Description |
|---|---|
| [docs/environment-setup.md](docs/environment-setup.md) | Full WSL2 + Docker + GPU driver setup walkthrough |
| [docs/ollama-usage.md](docs/ollama-usage.md) | LLM usage with API examples for each model |
| [docs/stable-diffusion-usage.md](docs/stable-diffusion-usage.md) | Image generation with prompts, API examples, and parameter reference |

## Repository structure

```
ailab/
├── docs/
│   ├── README.md                      # Documentation index
│   ├── environment-setup.md           # WSL2, Docker, NVIDIA, AMD setup guide
│   ├── ollama-usage.md                # LLM usage and examples
│   └── stable-diffusion-usage.md     # Image generation usage and examples
├── ollama/                            # LLM server + chat UI
│   ├── docker-compose.nvidia.yml
│   ├── docker-compose.amd.yml
│   ├── docker-compose.cpu.yml
│   └── README.md
├── stable-diffusion/                  # Image generation
│   ├── docker-compose.nvidia.yml
│   ├── docker-compose.amd.yml
│   ├── docker-compose.cpu.yml
│   └── README.md
└── scripts/
    ├── check-gpu.sh                   # Detect GPU and recommend compose file
    ├── setup-wsl-nvidia.sh            # Install NVIDIA Container Toolkit in WSL2
    └── setup-wsl-amd.sh              # Install AMD ROCm in WSL2
```
