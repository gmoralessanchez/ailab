#!/bin/bash
# Entrypoint for the SD WebUI container.
# Fixes ownership of volume-mounted directories (created as root by Docker)
# then drops back to sduser to run webui.sh.

set -e

# Ensure the volume-mounted dirs are writable by sduser
for dir in models outputs extensions; do
    if [ -d "/app/stable-diffusion-webui/$dir" ]; then
        chown -R sduser:sduser "/app/stable-diffusion-webui/$dir"
    fi
done

# Drop privileges and launch the WebUI
exec gosu sduser bash -c "./webui.sh"
