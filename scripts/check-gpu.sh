#!/usr/bin/env bash
# check-gpu.sh
#
# Detects available GPUs and recommends the appropriate Docker Compose file to use.
# Run inside WSL2 or Linux.
#
# Usage:
#   chmod +x check-gpu.sh
#   ./check-gpu.sh

set -euo pipefail

NVIDIA_FOUND=false
AMD_FOUND=false

echo "###################################################################################"
echo "#                                                                                 #"
echo "#  _____ _     _       _    _____                                  _   _       _  #"
echo "# |_   _| |   (_)     | |  |  ___|                                | | (_)     | | #"
echo "#   | | | |__  _ _ __ | | _| |____  ___ __   ___  _ __   ___ _ __ | |_ _  __ _| | #"
echo "#   | | | '_ \\| | '_ \\| |/ /  __\\ \\/ / '_ \\ / _ \\| '_ \\ / _ \\ '_ \\| __| |/ _\` | | #"
echo "#   | | | | | | | | | |   <| |___>  <| |_) | (_) | | | |  __/ | | | |_| | (_| | | #"
echo "#   \\_/ |_| |_|_|_| |_|_|\\_\\____/_/\\_\\ .__/ \\___/|_| |_|\\___|_| |_|\\__|_|\\__,_|_| #"
echo "#                                    | |                                          #"
echo "#                                    |_|                                          #"
echo "#                                                                                 #"
echo "#   ___  _____ _           _                                                      #"
echo "#  / _ \\|_   _| |         | |                                                     #"
echo "# / /_\\ \\ | | | |     __ _| |__                                                   #"
echo "# |  _  | | | | |    / _\` | '_ \\                                                  #"
echo "# | | | |_| |_| |___| (_| | |_) |                                                 #"
echo "# \\_| |_/\\___/\\_____/\\__,_|_.__/                                                  #"
echo "#                                                                                 #"
echo "#   Local AI Model Deployments  ::  GPU Detection                                 #"
echo "#                                                                                 #"
echo "###################################################################################"
echo ""

# --- WSL2 kernel version ---
if grep -qi "microsoft" /proc/version 2>/dev/null; then
  KERNEL_VERSION=$(uname -r)
  echo "WSL2 kernel: ${KERNEL_VERSION}"
  KERNEL_MAJOR=$(echo "${KERNEL_VERSION}" | cut -d. -f1)
  KERNEL_MINOR=$(echo "${KERNEL_VERSION}" | cut -d. -f2)
  if [[ "${KERNEL_MAJOR}" -lt 5 ]] || ( [[ "${KERNEL_MAJOR}" -eq 5 ]] && [[ "${KERNEL_MINOR}" -lt 15 ]] ); then
    echo "WARNING: Kernel 5.15+ is required for AMD ROCm. Run 'wsl --update' from Windows PowerShell."
  fi
  echo ""
fi

# --- Check for NVIDIA GPU ---
if command -v nvidia-smi &>/dev/null; then
  echo "NVIDIA GPU(s) detected:"
  nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader \
    | while IFS=',' read -r name mem driver; do
        echo "  • ${name} | ${mem} | Driver ${driver}"
      done
  NVIDIA_FOUND=true
else
  echo "NVIDIA GPU: not detected (nvidia-smi not found)"
fi

echo ""

# --- Check for AMD GPU ---
if command -v rocminfo &>/dev/null; then
  AMD_GPU=$(rocminfo 2>/dev/null | grep -E "^\s+Name:" | grep -v "Kfd" | head -5 || true)
  if [[ -n "${AMD_GPU}" ]]; then
    echo "AMD GPU(s) detected (via rocminfo):"
    echo "${AMD_GPU}" | while read -r line; do echo "  •${line}"; done
    AMD_FOUND=true
  else
    echo "AMD GPU: rocminfo found but no GPUs listed"
  fi
elif [[ -e /dev/kfd ]]; then
  echo "AMD GPU: /dev/kfd present (ROCm device found, install rocminfo for details)"
  AMD_FOUND=true
else
  echo "AMD GPU: not detected (/dev/kfd not found, rocminfo not installed)"
fi

echo ""

# --- Check Docker & NVIDIA Container Toolkit ---
echo "=== Docker Runtime ==="
if command -v docker &>/dev/null; then
  DOCKER_VERSION=$(docker --version)
  echo "Docker: ${DOCKER_VERSION}"
  if docker info 2>/dev/null | grep -q "nvidia"; then
    echo "NVIDIA Container Runtime: configured ✓"
  else
    echo "NVIDIA Container Runtime: not configured (run scripts/setup-wsl-nvidia.sh)"
  fi
  if $AMD_FOUND; then
    echo "NOTE (AMD): Docker Engine inside WSL2 is recommended over Docker Desktop"
    echo "            to ensure /dev/kfd is correctly exposed to containers."
  fi
else
  echo "Docker: not found — install Docker to use this project"
fi

echo ""

# --- Recommendation ---
echo "=== Recommended compose files ==="
echo ""
echo "Ollama + Open WebUI (LLMs):"
if $NVIDIA_FOUND; then
  echo "  docker compose -f ollama/docker-compose.nvidia.yml up -d"
elif $AMD_FOUND; then
  echo "  docker compose -f ollama/docker-compose.amd.yml up -d"
else
  echo "  docker compose -f ollama/docker-compose.cpu.yml up -d  (no GPU found)"
fi

echo ""
echo "Stable Diffusion (image generation):"
if $NVIDIA_FOUND; then
  echo "  docker compose -f stable-diffusion/docker-compose.nvidia.yml up -d"
elif $AMD_FOUND; then
  echo "  docker compose -f stable-diffusion/docker-compose.amd.yml up -d"
else
  echo "  docker compose -f stable-diffusion/docker-compose.cpu.yml up -d  (no GPU found)"
fi

echo ""
if ! $NVIDIA_FOUND && ! $AMD_FOUND; then
  echo "No GPU detected. For GPU setup instructions:"
  echo "  NVIDIA: scripts/setup-wsl-nvidia.sh"
  echo "  AMD:    scripts/setup-wsl-amd.sh"
fi
