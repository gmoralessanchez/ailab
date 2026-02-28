# Environment Setup

This guide walks through everything needed to run the AI model deployments in this repository on **Windows with WSL2**, for both **NVIDIA** and **AMD** GPUs.

---

## Table of contents

1. [System requirements](#1-system-requirements)
2. [Enable WSL2 on Windows](#2-enable-wsl2-on-windows)
3. [Install Docker](#3-install-docker)
4. [GPU setup — NVIDIA (CUDA)](#4-gpu-setup--nvidia-cuda)
5. [GPU setup — AMD (ROCm)](#5-gpu-setup--amd-rocm)
6. [Verify the environment](#6-verify-the-environment)
7. [Start a deployment](#7-start-a-deployment)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. System requirements

| Component | Minimum | Recommended |
|---|---|---|
| OS | Windows 10 21H2 | Windows 11 22H2+ |
| RAM | 8 GB | 16 GB+ |
| Disk | 30 GB free | 60 GB+ free |
| GPU (NVIDIA) | 4 GB VRAM, GTX 1060+ | 8 GB+ VRAM, RTX 3060+ |
| GPU (AMD) | RX 6600 (gfx1030) | RX 7900 XTX or Instinct MI series |
| NVIDIA driver (Windows) | 525+ | latest |
| AMD driver (Windows) | Adrenalin 23.x | latest |

> CPU-only mode is available for both deployments but is significantly slower — suitable for testing only.

### Windows host software

The following must be installed or configured on the **Windows machine** before you start the WSL2 and Docker setup:

| Software / Setting | Where to get it | Notes |
|---|---|---|
| **Hardware virtualization** | BIOS/UEFI settings | Required by WSL2. Look for "Intel VT-x", "AMD-V", or "SVM Mode" and enable it. |
| **Docker Desktop 4.x+** | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) | Easiest Docker option; includes Engine, Compose, and WSL2 integration. |
| **Git for Windows** | [git-scm.com/download/win](https://git-scm.com/download/win) | Needed to clone this repository on Windows. Alternatively, clone inside WSL2 with `sudo apt-get install git`. |

> **Docker Desktop vs Docker Engine:** Docker Desktop runs on Windows and exposes Docker inside WSL2 via integration. Docker Engine can alternatively be installed directly inside WSL2 (Option B in [Section 3](#3-install-docker)). **AMD GPU users should use Docker Engine** because Docker Desktop does not correctly expose `/dev/kfd` to containers, which prevents ROCm GPU access.

---

## 2. Enable WSL2 on Windows

> **Before you begin — verify that hardware virtualization is enabled in BIOS/UEFI.**
>
> WSL2 and Docker Desktop both require CPU virtualization support.
>
> **To check:** Open **Task Manager** (`Ctrl+Shift+Esc`) → **Performance** tab → **CPU**. The line "Virtualization: **Enabled**" must appear.
>
> **If it shows "Disabled":** Reboot into your BIOS/UEFI settings (press Del, F2, or F10 during the power-on screen — the key varies by manufacturer). Enable the virtualization option — it may be labelled "Intel VT-x", "Intel Virtualization Technology", "AMD-V", or "SVM Mode". Save and reboot.

Open **PowerShell as Administrator** and run:

```powershell
# Install WSL2 with Ubuntu (default distro)
wsl --install

# If WSL is already installed, ensure it is on version 2 and up to date
wsl --set-default-version 2
wsl --update
```

Restart your computer when prompted. After reboot, Ubuntu will finish installation and ask you to create a UNIX username and password.

### Verify WSL2 is running

```powershell
wsl -l -v
```

Expected output:
```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

### Recommended: increase WSL2 memory limit

By default WSL2 uses up to 50% of host RAM. For large models you may want to raise this. Create or edit `%USERPROFILE%\.wslconfig` on Windows:

```ini
[wsl2]
memory=12GB      # adjust to your RAM (leave ~4 GB for Windows)
processors=8     # number of CPU cores
swap=8GB
```

Apply with `wsl --shutdown` then reopen WSL.

---

## 3. Install Docker

### Option A — Docker Desktop (easiest)

> **Requirements:** Docker Desktop 4.x or later. Supported on Windows 11 (Home/Pro/Enterprise, 21H2+) and Windows 10 (Home/Pro/Enterprise, 21H2+, build 19044+). Hardware virtualization must be enabled (see [Section 2](#2-enable-wsl2-on-windows)).

1. Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
2. Install and open Docker Desktop.
3. Go to **Settings → General** and enable **"Use the WSL 2 based engine"**.
4. Go to **Settings → Resources → WSL Integration** and enable integration for your Ubuntu distro.
5. Click **Apply & Restart**.

Verify inside WSL2:

```bash
docker --version        # should print Docker version
docker compose version  # should print Compose version v2.x
```

### Option B — Docker Engine inside WSL2 (no Docker Desktop)

```bash
# Install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Add Docker's GPG key and repo
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list

# Install Docker Engine + Compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Allow running docker without sudo
sudo usermod -aG docker $USER
newgrp docker

# Start Docker daemon
sudo service docker start
```

> **Note:** With Docker Engine (no Docker Desktop), run `sudo service docker start` each time you open a new WSL2 session, or add it to your `~/.bashrc`:
> ```bash
> sudo service docker status > /dev/null 2>&1 || sudo service docker start > /dev/null 2>&1
> ```

---

## 4. GPU setup — NVIDIA (CUDA)

> Skip this section if you have an AMD GPU.

### 4a. Install NVIDIA driver on Windows

Download and install the latest Game Ready or Studio driver for your GPU from [nvidia.com/drivers](https://www.nvidia.com/drivers/). The driver must be **version 525 or higher**. You do **not** install any CUDA toolkit on Windows.

After installation, open PowerShell and verify:

```powershell
nvidia-smi
```

You should see your GPU listed. This command also works inside WSL2 once the driver is installed on Windows.

### 4b. Install NVIDIA Container Toolkit inside WSL2

Open your WSL2 terminal (Ubuntu) and run:

```bash
# Import the GPG key
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Add the repository
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker to use the NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker

# Restart Docker
sudo systemctl restart docker 2>/dev/null || sudo service docker restart
```

Alternatively, run the included setup script from the repository root:

```bash
chmod +x scripts/setup-wsl-nvidia.sh
./scripts/setup-wsl-nvidia.sh
```

### 4c. Verify NVIDIA GPU in Docker

```bash
docker run --rm --gpus all \
  nvcr.io/nvidia/cuda:12.3.0-base-ubuntu22.04 nvidia-smi
```

You should see your GPU details printed inside the container. If it works, you are ready for the NVIDIA compose files.

---

## 5. GPU setup — AMD (ROCm)

> Skip this section if you have an NVIDIA GPU.

### 5a. Check AMD driver on Windows

Install the latest **AMD Software: Adrenalin Edition** driver from [amd.com/support](https://www.amd.com/support). ROCm support in WSL2 is built into the Windows driver — no extra installation is needed on the Windows side.

### 5b. Update WSL2 kernel

ROCm on WSL2 requires kernel 5.15+:

```powershell
# Run in PowerShell (Windows)
wsl --update
wsl --shutdown
```

Reopen WSL2 and verify:

```bash
uname -r   # should show 5.15.x or higher
```

### 5c. Install ROCm inside WSL2

Open your WSL2 terminal (Ubuntu 22.04 recommended) and run:

```bash
# Install prerequisites
sudo apt-get update
sudo apt-get install -y wget gnupg2 software-properties-common lsb-release

# Add the ROCm repository key
wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/rocm-archive-keyring.gpg > /dev/null

# Add the ROCm 6.x repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm-archive-keyring.gpg] \
  https://repo.radeon.com/rocm/apt/6.0 $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/rocm.list

# Install ROCm
sudo apt-get update
sudo apt-get install -y rocm-hip-sdk rocminfo

# Add user to required groups
sudo usermod -aG render,video $USER
```

Log out and back in (or run `newgrp render`) for group membership to take effect.

Alternatively, use the setup script:

```bash
chmod +x scripts/setup-wsl-amd.sh
./scripts/setup-wsl-amd.sh
```

### 5d. Verify AMD GPU in Docker

Check that the GPU devices are present:

```bash
ls /dev/kfd /dev/dri    # both should exist
rocminfo | grep -E "Agent|Name"
```

Then test inside a container:

```bash
docker run --rm \
  --device /dev/kfd \
  --device /dev/dri \
  --group-add video \
  --group-add render \
  rocm/rocm-terminal rocminfo | grep -E "Agent|Name" | head -20
```

### 5e. Unsupported GPU workaround

Some AMD GPUs (e.g. RX 6600/6700 series with gfx1030/gfx1031) are not officially listed but can work with an environment variable override. If your GPU is not detected automatically, add this to the relevant compose file:

```yaml
environment:
  - HSA_OVERRIDE_GFX_VERSION=10.3.0
```

Check the [AMD ROCm compatibility matrix](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html) for officially supported GPUs.

---

## 6. Verify the environment

Run the included GPU detection script from the repository root:

```bash
chmod +x scripts/check-gpu.sh
./scripts/check-gpu.sh
```

The script will:
- Detect NVIDIA and AMD GPUs
- Check whether the NVIDIA Container Runtime is configured in Docker
- Print the exact `docker compose` command to use

Example output for an NVIDIA system:
```
=== GPU Detection for ailab ===

NVIDIA GPU(s) detected:
  • NVIDIA GeForce RTX 4090 | 24564 MiB | Driver 535.129.03

=== Recommended compose files ===

Ollama + Open WebUI (LLMs):
  docker compose -f ollama/docker-compose.nvidia.yml up -d

Stable Diffusion (image generation):
  docker compose -f stable-diffusion/docker-compose.nvidia.yml up -d
```

---

## 7. Start a deployment

From the repository root, run the compose command that matches your GPU.

### Ollama (LLMs)

```bash
# NVIDIA
docker compose -f ollama/docker-compose.nvidia.yml up -d

# AMD
docker compose -f ollama/docker-compose.amd.yml up -d

# CPU only
docker compose -f ollama/docker-compose.cpu.yml up -d
```

Open **http://localhost:3000** for the Open WebUI chat interface.

See [ollama-usage.md](ollama-usage.md) for pulling models and usage examples.

### Stable Diffusion (image generation)

```bash
# NVIDIA
docker compose -f stable-diffusion/docker-compose.nvidia.yml up -d

# AMD
docker compose -f stable-diffusion/docker-compose.amd.yml up -d

# CPU only
docker compose -f stable-diffusion/docker-compose.cpu.yml up -d
```

Open **http://localhost:7860** for the Stable Diffusion WebUI.

See [stable-diffusion-usage.md](stable-diffusion-usage.md) for model downloads and usage examples.

---

## 8. Troubleshooting

### `docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]]`

The NVIDIA Container Runtime is not configured. Re-run:

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo service docker restart
```

Then verify `docker info | grep -i runtime` shows `nvidia` in the list.

### `nvidia-smi` works on Windows but not in WSL2

Make sure you installed the **Windows** driver (not a Linux driver inside WSL). WSL2 uses the Windows GPU driver automatically — no Linux NVIDIA driver should be installed inside WSL.

### `/dev/kfd not found` (AMD)

The `amdgpu` kernel module may not be loaded:

```bash
sudo modprobe amdgpu
ls /dev/kfd   # should now exist
```

If the module is missing, ensure your WSL2 kernel is up to date (`wsl --update` from PowerShell).

### `permission denied` on `/dev/kfd` or `/dev/dri` (AMD)

Your user is not in the required groups. Run:

```bash
sudo usermod -aG render,video $USER
newgrp render   # apply without logging out
```

### Out of memory / container crashes on first model load

- Use a smaller model (e.g. `llama3.2` instead of `llama3.3 70B`).
- Add `--medvram` or `--lowvram` to `COMMANDLINE_ARGS` in the Stable Diffusion compose file.
- Increase the WSL2 memory limit in `%USERPROFILE%\.wslconfig` (see [Section 2](#2-enable-wsl2-on-windows)).

### Docker Compose `version` field warning

Compose V2 no longer requires the top-level `version:` field. The warning is harmless and can be ignored.

### Containers start but GPU is not used

Check that you are using the correct compose file for your GPU. The CPU compose files do not configure any GPU runtime. Run `docker stats` to see GPU memory utilization, or for Ollama run:

```bash
docker exec -it ollama ollama ps   # shows running models and their device
```
