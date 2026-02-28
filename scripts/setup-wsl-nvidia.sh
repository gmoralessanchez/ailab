#!/usr/bin/env bash
# setup-wsl-nvidia.sh
#
# Sets up NVIDIA Container Toolkit in WSL2 for Docker GPU access.
# Run this script inside WSL2 (Ubuntu/Debian-based distributions).
#
# Requirements:
#   - WSL2 (not WSL1): verify with `wsl -l -v` from Windows PowerShell
#   - NVIDIA driver 525+ installed on Windows (NOT inside WSL)
#   - Docker Engine or Docker Desktop already installed
#
# Usage:
#   chmod +x setup-wsl-nvidia.sh
#   ./setup-wsl-nvidia.sh

set -euo pipefail

echo "=== NVIDIA Container Toolkit Setup for WSL2 ==="
echo ""

# --- Verify WSL2 ---
if ! grep -qi "microsoft" /proc/version 2>/dev/null; then
  echo "WARNING: This does not appear to be a WSL environment."
  echo "         This script is intended for WSL2 on Windows."
  read -r -p "Continue anyway? [y/N] " response
  [[ "${response}" =~ ^[Yy]$ ]] || exit 1
fi

# --- Check Docker is installed ---
if ! command -v docker &>/dev/null; then
  echo "ERROR: Docker is not installed."
  echo "       Install Docker Desktop (with WSL2 integration) or Docker Engine inside WSL2 first."
  echo "       See: https://docs.docker.com/engine/install/ubuntu/"
  exit 1
fi

# --- Check nvidia-smi is accessible (driver must be installed on Windows) ---
if ! command -v nvidia-smi &>/dev/null; then
  echo "ERROR: nvidia-smi not found."
  echo "       Install the NVIDIA driver on Windows (>=525), then re-run."
  echo "       Download: https://www.nvidia.com/drivers/"
  exit 1
fi

echo "Detected GPU:"
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
echo ""

# --- Install NVIDIA Container Toolkit ---
echo "Installing NVIDIA Container Toolkit..."

# Import GPG key
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Add repository
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit

# --- Configure Docker runtime ---
echo ""
echo "Configuring Docker to use the NVIDIA runtime..."
sudo nvidia-ctk runtime configure --runtime=docker

# Restart Docker if running as a service
if systemctl is-active --quiet docker 2>/dev/null; then
  sudo systemctl restart docker
  echo "Docker service restarted."
elif service docker status &>/dev/null; then
  sudo service docker restart
  echo "Docker service restarted."
else
  echo "NOTE: Restart Docker manually (or Docker Desktop) to apply the new runtime."
fi

# --- Verify ---
echo ""
echo "=== Verification ==="
echo "Running test container (nvcr.io/nvidia/cuda:12.3.0-base-ubuntu22.04)..."
if docker run --rm --gpus all nvcr.io/nvidia/cuda:12.3.0-base-ubuntu22.04 nvidia-smi; then
  echo ""
  echo "SUCCESS: NVIDIA GPU is accessible inside Docker containers."
  echo "You can now run the GPU-accelerated deployments:"
  echo "  cd ollama && docker compose -f docker-compose.nvidia.yml up -d"
  echo "  cd stable-diffusion && docker compose -f docker-compose.nvidia.yml up -d"
else
  echo ""
  echo "ERROR: GPU test failed. Check the output above for details."
  echo "Troubleshooting: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/troubleshooting.html"
  exit 1
fi
