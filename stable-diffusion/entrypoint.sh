#!/bin/bash
# Entrypoint for the SD WebUI container.
# Fixes ownership of volume-mounted directories (created as root by Docker)
# then drops back to sduser to run webui.sh.

set -e

# Ensure the volume-mounted dirs are writable by sduser
for dir in models models/Stable-diffusion outputs extensions; do
    if [ -d "/app/stable-diffusion-webui/$dir" ]; then
        chown -R sduser:sduser "/app/stable-diffusion-webui/$dir"
    fi
done

# Pre-create output subdirectories the WebUI expects
for sub in txt2img-images img2img-images extras-images txt2img-grids img2img-grids; do
    mkdir -p "/app/stable-diffusion-webui/outputs/$sub"
done
chown -R sduser:sduser /app/stable-diffusion-webui/outputs

# Drop privileges and launch the WebUI
exec gosu sduser bash -c "./webui.sh"
