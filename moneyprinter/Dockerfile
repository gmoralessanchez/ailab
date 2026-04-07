###################################################################################
#                                                                                 #
#  _____ _     _       _    _____                                  _   _       _  #
# |_   _| |   (_)     | |  |  ___|                                | | (_)     | | #
#   | | | |__  _ _ __ | | _| |____  ___ __   ___  _ __   ___ _ __ | |_ _  __ _| | #
#   | | | '_ \| | '_ \| |/ /  __\ \/ / '_ \ / _ \| '_ \ / _ \ '_ \| __| |/ _` | | #
#   | | | | | | | | | |   <| |___>  <| |_) | (_) | | | |  __/ | | | |_| | (_| | | #
#   \_/ |_| |_|_|_| |_|_|\_\____/_/\_\ .__/ \___/|_| |_|\___|_| |_|\__|_|\__,_|_| #
#                                    | |                                          #
#                                    |_|                                          #
#                                                                                 #
#   MoneyPrinterTurbo  ::  AI Short Video Generation                              #
#                                                                                 #
###################################################################################

FROM python:3.11-slim

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        imagemagick \
        ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Fix ImageMagick security policy — allow reading/writing all paths
RUN if [ -f /etc/ImageMagick-6/policy.xml ]; then \
        sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@*"/' \
            /etc/ImageMagick-6/policy.xml; \
    fi

WORKDIR /app

# Clone MoneyPrinterTurbo at a pinned release
RUN git clone --depth 1 --branch v1.2.6 \
        https://github.com/harry0703/MoneyPrinterTurbo.git /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Upgrade edge-tts to the supported 7.x series (updated GEC tokens — 6.x tokens expired, causing 403)
# and patch back the mktimestamp function removed in 7.0
RUN pip install --no-cache-dir --upgrade "edge-tts>=7,<8"
COPY patch_edge_tts.py /app/patch_edge_tts.py
RUN SITE_DIR=$(python3 -c "import site; print(site.getsitepackages()[0])") && \
    echo "import importlib, sys; sys.path.insert(0, '/app'); import patch_edge_tts" \
    >> "${SITE_DIR}/sitecustomize.py"

# Create storage directories for persistent data
RUN mkdir -p /app/storage

ENV PYTHONPATH="/app"

EXPOSE 8501 8080
