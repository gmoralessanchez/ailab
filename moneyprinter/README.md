# MoneyPrinterTurbo — AI Short Video Generation

Generate short-form videos automatically using LLMs for scripting, text-to-speech for narration, and stock footage from Pexels/Pixabay.

| Port | Service |
|---|---|
| 8501 | Streamlit WebUI |
| 8080 | FastAPI REST API |

## Quick start

```bash
# 1. Edit the config file with your API keys
nano moneyprinter/config.toml

# 2. Build and start
docker compose -f moneyprinter/docker-compose.cpu.yml up -d

# 3. Open the WebUI
# http://localhost:8501
```

> **No GPU required.** MoneyPrinterTurbo uses external LLM APIs for script generation and does not run local GPU inference.

## Configuration

All settings live in `moneyprinter/config.toml`. Edit this file **before** starting the container. Changes require a container restart to take effect.

### LLM provider (required)

Set `llm_provider` to one of the supported providers and fill in the matching `[section]`:

| Provider | `llm_provider` value | What you need |
|---|---|---|
| OpenAI | `"openai"` | API key from [platform.openai.com](https://platform.openai.com/) |
| DeepSeek | `"deepseek"` | API key from [platform.deepseek.com](https://platform.deepseek.com/) |
| Gemini | `"gemini"` | API key from [aistudio.google.com](https://aistudio.google.com/) |
| Ollama (local) | `"ollama"` | Ollama running on the host (see below) |
| Azure OpenAI | `"azure"` | Azure endpoint + key |
| Moonshot | `"moonshot"` | API key |
| g4f | `"g4f"` | No key needed (free, less reliable) |

### Video material API keys (required for most use cases)

Get a **free** API key from one or both providers:

- **Pexels** — [pexels.com/api](https://www.pexels.com/api/) → add to `pexels_api_keys`
- **Pixabay** — [pixabay.com/api/docs](https://pixabay.com/api/docs/) → add to `pixabay_api_keys`

Example:

```toml
pexels_api_keys = ["your-key-here"]
pixabay_api_keys = ["your-key-here"]
```

### Using Ollama as the LLM provider

If you are already running Ollama from the `ollama/` deployment in this repo, MoneyPrinterTurbo can use it directly:

1. Set `llm_provider = "ollama"` in `config.toml`
2. The `[ollama]` section is pre-configured to reach the host via `host.docker.internal:11434`
3. Make sure Ollama has a model pulled (e.g. `llama3.3`)

```toml
llm_provider = "ollama"

[ollama]
api_key = "ollama"
model_name = "llama3.3"
base_url = "http://host.docker.internal:11434/v1"
```

## Usage

1. Open **http://localhost:8501**
2. Enter a topic or script for your video
3. Select voice, language, video aspect ratio, and other options
4. Click **Generate Video**
5. The generated video appears in the WebUI and is saved to the `storage/` volume

## API access

The FastAPI REST API is available at **http://localhost:8080**.

Interactive API docs: **http://localhost:8080/docs**

## Outputs

Generated videos and project files are stored in the `mp_storage` Docker volume, mounted at `/app/storage` inside the container.

To access files from the host:

```bash
docker volume inspect thinkexponential-ailab-moneyprinter_mp_storage
```

## Troubleshooting

| Problem | Solution |
|---|---|
| WebUI won't start | Check logs: `docker compose -f moneyprinter/docker-compose.cpu.yml logs webui` |
| API not responding | Check logs: `docker compose -f moneyprinter/docker-compose.cpu.yml logs api` |
| "LLM provider not configured" | Edit `config.toml` and set `llm_provider` + the matching API key section |
| Can't reach Ollama | Make sure Ollama is running on the host and port 11434 is accessible |
| No video footage found | Add a valid Pexels or Pixabay API key to `config.toml` |
| ImageMagick errors | The Dockerfile patches the security policy — rebuild: `docker compose -f moneyprinter/docker-compose.cpu.yml build --no-cache` |

## Stopping

```bash
docker compose -f moneyprinter/docker-compose.cpu.yml down
```

To also remove the storage volume:

```bash
docker compose -f moneyprinter/docker-compose.cpu.yml down -v
```
