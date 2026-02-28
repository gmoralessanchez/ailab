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

### Windows host

- Windows 11 (21H2+) or Windows 10 (21H2+, build 19044+)
- Hardware virtualization enabled in BIOS/UEFI (Intel VT-x / AMD-V / SVM Mode)
- [Docker Desktop 4.x+](https://www.docker.com/products/docker-desktop/) with WSL2 backend enabled **or** Docker Engine installed inside WSL2
- [Git for Windows](https://git-scm.com/download/win) to clone this repository, **or** clone it inside WSL2 with `git clone`
- **NVIDIA**: Driver ≥ 525 from [nvidia.com/drivers](https://www.nvidia.com/drivers/)
- **AMD**: Adrenalin 23.x+ from [amd.com/support](https://www.amd.com/support)

### Inside WSL2 (Ubuntu)

- Compose V2 (`docker compose`) — included with Docker Desktop or the Docker Engine Compose plugin
- **NVIDIA**: NVIDIA Container Toolkit (run `scripts/setup-wsl-nvidia.sh`)
- **AMD**: ROCm 6.x + WSL2 kernel 5.15+ (run `scripts/setup-wsl-amd.sh`)

> **AMD users:** Docker Engine inside WSL2 is recommended over Docker Desktop — Docker Desktop does not correctly expose `/dev/kfd` to containers, which prevents ROCm GPU access.

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
