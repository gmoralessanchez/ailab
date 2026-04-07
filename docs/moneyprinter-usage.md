# MoneyPrinterTurbo — Usage Guide

This guide covers how to use MoneyPrinterTurbo for AI-powered short video generation, including the WebUI workflow, prompt tips, configuration details, and API examples.

## Overview

MoneyPrinterTurbo automates the creation of short-form videos by:

1. **Script generation** — An LLM writes a video script from your topic or description
2. **Voice narration** — Text-to-speech converts the script into audio
3. **Video material** — Stock footage is automatically selected from Pexels/Pixabay to match the script
4. **Assembly** — Audio, video clips, and subtitles are merged into a final video

## Starting the service

```bash
docker compose -f moneyprinter/docker-compose.cpu.yml up -d
```

- **WebUI**: http://localhost:8501
- **API docs**: http://localhost:8080/docs

## WebUI workflow

### 1. Enter your topic

Provide a topic or a full script. Examples:

- `"5 tips for better sleep"`
- `"The history of coffee in 60 seconds"`
- `"Why cats are the best pets"`

### 2. Configure video settings

| Setting | Description | Recommended |
|---|---|---|
| **Video language** | Language for script and narration | Match your audience |
| **Video aspect ratio** | 16:9 (landscape), 9:16 (portrait/shorts), 1:1 (square) | 9:16 for short-form |
| **Video duration** | Target length in seconds | 30–60 for shorts |
| **Voice** | TTS voice to use for narration | Try different voices to find one you like |
| **Subtitle** | Enable/disable subtitles | Enable for better engagement |
| **Video source** | Pexels, Pixabay, or local | Pexels (more variety) |

### 3. Generate

Click **Generate Video** and wait. Typical generation takes 1–5 minutes depending on video length and LLM response time.

### 4. Review and download

The finished video appears in the WebUI. You can download it or find it in the storage volume.

## Prompt tips

**Be specific.** The more detail you provide, the better the LLM script and video material selection.

Good:

> "5 practical tips for getting better sleep: covering room temperature, screen time, caffeine cutoff, consistent schedule, and relaxation techniques"

Less effective:

> "sleep tips"

**Specify the tone.** Add tone guidance to your topic:

> "A fun and energetic video about the best street food in Tokyo"

**Include a target audience:**

> "Explain quantum computing to a 12-year-old in simple terms"

## Configuration reference

All settings are in `moneyprinter/config.toml`. See `moneyprinter/README.md` for setup instructions.

### Key settings

| Setting | Purpose |
|---|---|
| `llm_provider` | Which LLM to use for script generation |
| `pexels_api_keys` | API keys for Pexels stock footage |
| `pixabay_api_keys` | API keys for Pixabay stock footage |
| `subtitle_provider` | TTS engine: `"edge"` (free, recommended) or `"azure"` |
| `font_name` | Font for subtitle rendering |
| `font_size` | Subtitle font size |
| `project_dir` | Where generated projects are stored inside the container |

### Connecting to Ollama

If you run the `ollama/` deployment from this repo, MoneyPrinterTurbo can use it as the LLM backend:

```toml
llm_provider = "ollama"

[ollama]
api_key = "ollama"
model_name = "llama3.3"
base_url = "http://host.docker.internal:11434/v1"
```

The `host.docker.internal` hostname resolves to your host machine from inside the container (configured via `extra_hosts` in the compose file).

## REST API examples

The FastAPI service runs on port 8080 and provides programmatic access to video generation.

### Get API documentation

```bash
curl http://localhost:8080/docs
```

Opens the interactive Swagger UI in your browser.

### Generate a video via API

```bash
curl -X POST http://localhost:8080/api/v1/videos \
  -H "Content-Type: application/json" \
  -d '{
    "video_subject": "5 tips for better sleep",
    "video_language": "en",
    "video_aspect": "9:16"
  }'
```

> **Note:** The exact API schema may vary by version. Check `/docs` for the definitive endpoint list.

## Output files

Generated videos and intermediate files (scripts, audio, clips) are stored in the `mp_storage` Docker volume at `/app/storage` inside the container.

To find the volume on the host:

```bash
docker volume inspect thinkexponential-ailab-moneyprinter_mp_storage
```

## Troubleshooting

### Logs

```bash
# WebUI logs
docker compose -f moneyprinter/docker-compose.cpu.yml logs -f webui

# API logs
docker compose -f moneyprinter/docker-compose.cpu.yml logs -f api
```

### Common issues

| Symptom | Cause | Fix |
|---|---|---|
| "LLM provider not configured" | `llm_provider` is empty in config.toml | Set a provider and add the API key |
| Script generated but no video | Missing Pexels/Pixabay API key | Add at least one video material API key |
| Subtitle rendering fails | ImageMagick policy issue | Rebuild the image: `docker compose ... build --no-cache` |
| Can't connect to Ollama | Ollama not running or wrong URL | Verify Ollama is up on port 11434 and `base_url` uses `host.docker.internal` |
| Slow generation | LLM response time + video download | Normal for CPU; consider faster LLM API or shorter video |

### Rebuilding

If you need a clean rebuild:

```bash
docker compose -f moneyprinter/docker-compose.cpu.yml build --no-cache
docker compose -f moneyprinter/docker-compose.cpu.yml up -d
```
