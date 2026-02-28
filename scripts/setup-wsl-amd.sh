#!/usr/bin/env bash
# setup-wsl-amd.sh
#
# Sets up AMD ROCm in WSL2 for Docker GPU access.
# Run this script inside WSL2 (Ubuntu 22.04 recommended).
#
# Requirements:
#   - WSL2 with kernel 5.15+ (`wsl --update` from Windows PowerShell)
#   - AMD GPU supported by ROCm: https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html
#   - Docker Engine installed (Docker Desktop may not correctly expose /dev/kfd)
#
# Usage:
#   chmod +x setup-wsl-amd.sh
#   ./setup-wsl-amd.sh

set -euo pipefail

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
echo "#   AMD ROCm Setup  ::  WSL2                                                      #"
echo "#                                                                                 #"
echo "###################################################################################"
echo ""

# --- Verify WSL2 ---
if ! grep -qi "microsoft" /proc/version 2>/dev/null; then
  echo "WARNING: This does not appear to be a WSL environment."
  echo "         This script is intended for WSL2 on Windows."
  read -r -p "Continue anyway? [y/N] " response
  [[ "${response}" =~ ^[Yy]$ ]] || exit 1
fi

# --- Detect Ubuntu version ---
. /etc/os-release
echo "Detected OS: ${PRETTY_NAME}"
if [[ "${ID}" != "ubuntu" ]]; then
  echo "WARNING: This script is designed for Ubuntu. Adjust package manager commands as needed."
fi

# --- Check Docker is installed ---
if ! command -v docker &>/dev/null; then
  echo "ERROR: Docker is not installed."
  echo "       Install Docker Engine inside WSL2 before running this script."
  echo "       See: https://docs.docker.com/engine/install/ubuntu/"
  echo "       NOTE: Docker Desktop may not correctly expose /dev/kfd to containers."
  exit 1
fi

# --- Check WSL2 kernel version (ROCm requires 5.15+) ---
KERNEL_VERSION=$(uname -r)
KERNEL_MAJOR=$(echo "${KERNEL_VERSION}" | cut -d. -f1)
KERNEL_MINOR=$(echo "${KERNEL_VERSION}" | cut -d. -f2)
if [[ "${KERNEL_MAJOR}" -lt 5 ]] || ( [[ "${KERNEL_MAJOR}" -eq 5 ]] && [[ "${KERNEL_MINOR}" -lt 15 ]] ); then
  echo "ERROR: ROCm on WSL2 requires kernel 5.15 or higher."
  echo "       Detected: ${KERNEL_VERSION}"
  echo "       Run 'wsl --update' from Windows PowerShell, then restart WSL and re-run this script."
  exit 1
fi
echo "WSL2 kernel ${KERNEL_VERSION} — OK (5.15+ required for ROCm)"
echo ""

# --- Install ROCm ---
echo ""
echo "Installing ROCm 6.x..."

# Install prerequisites
sudo apt-get update -y
sudo apt-get install -y wget gnupg2 software-properties-common lsb-release

# Download and install ROCm repo key
wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/rocm-archive-keyring.gpg > /dev/null

# Add ROCm repository (ROCm 6.x for Ubuntu 22.04)
UBUNTU_CODENAME=$(lsb_release -cs)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm-archive-keyring.gpg] \
https://repo.radeon.com/rocm/apt/6.0 ${UBUNTU_CODENAME} main" \
  | sudo tee /etc/apt/sources.list.d/rocm.list

sudo apt-get update -y
sudo apt-get install -y rocm-hip-sdk rocminfo

# --- Add user to required groups ---
echo ""
echo "Adding ${USER} to 'render' and 'video' groups..."
sudo usermod -aG render,video "${USER}"

# --- Verify GPU devices ---
echo ""
echo "=== Verification ==="

if [[ -e /dev/kfd ]]; then
  echo "✓ /dev/kfd found"
else
  echo "✗ /dev/kfd not found — ROCm kernel device may not be loaded."
  echo "  Try: sudo modprobe amdgpu"
fi

if [[ -d /dev/dri ]]; then
  echo "✓ /dev/dri found: $(ls /dev/dri)"
else
  echo "✗ /dev/dri not found"
fi

echo ""
echo "Running rocminfo to list detected GPUs..."
if rocminfo | grep -E "Agent |Name:" | head -20; then
  echo ""
  echo "ROCm is installed. Verifying Docker GPU access..."
  docker run --rm \
    --device /dev/kfd \
    --device /dev/dri \
    --group-add video \
    --group-add render \
    rocm/rocm-terminal rocminfo | grep -E "Agent |Name:" | head -20
  echo ""
  echo "SUCCESS: AMD GPU is accessible inside Docker containers."
  echo "You can now run the GPU-accelerated deployments:"
  echo "  cd ollama && docker compose -f docker-compose.amd.yml up -d"
  echo "  cd stable-diffusion && docker compose -f docker-compose.amd.yml up -d"
else
  echo ""
  echo "WARNING: rocminfo did not detect a GPU."
  echo "Check that your GPU is supported: https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html"
  echo "You may need to log out and back in for group changes to take effect."
fi

echo ""
echo "NOTE: Log out and back in (or start a new WSL session) for group membership changes to take effect."
