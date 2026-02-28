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

echo "=== AMD ROCm Setup for WSL2 ==="
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

# --- Install ROCm ---
echo ""
echo "Installing ROCm 6.x..."

# Install prerequisites
sudo apt-get update -y
sudo apt-get install -y wget gnupg2 software-properties-common

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
