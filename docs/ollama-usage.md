# ThinkExponential AILab — Ollama LLM Usage Guide

This guide covers how to pull, run, and interact with language models using [Ollama](https://ollama.com/) and [Open WebUI](https://github.com/open-webui/open-webui).

> **Prerequisite:** Complete [environment-setup.md](environment-setup.md) and start the Ollama stack before following this guide.

---

## Table of contents

1. [Start the stack](#1-start-the-stack)
2. [Pull a model](#2-pull-a-model)
3. [Open WebUI — browser chat interface](#3-open-webui--browser-chat-interface)
4. [Ollama REST API — curl examples](#4-ollama-rest-api--curl-examples)
5. [OpenAI-compatible API](#5-openai-compatible-api)
6. [Python client examples](#6-python-client-examples)
7. [Per-model examples and use cases](#7-per-model-examples-and-use-cases)
   - [Llama 3.3 — general-purpose chat](#llama-33--general-purpose-chat)
   - [Llama 3.2 — lightweight chat](#llama-32--lightweight-chat)
   - [Mistral 7B — fast inference](#mistral-7b--fast-inference)
   - [Gemma 3 — reasoning and analysis](#gemma-3--reasoning-and-analysis)
   - [DeepSeek-R1 — chain-of-thought reasoning](#deepseek-r1--chain-of-thought-reasoning)
   - [Qwen 2.5 — multilingual](#qwen-25--multilingual)
   - [Phi-4 — small but capable](#phi-4--small-but-capable)
   - [CodeLlama — code generation](#codellama--code-generation)
   - [DeepSeek-Coder V2 — advanced coding](#deepseek-coder-v2--advanced-coding)
8. [Customizing model parameters](#8-customizing-model-parameters)
9. [Managing models](#9-managing-models)

---

## 1. Start the stack

From the repository root:

```bash
# NVIDIA GPU
docker compose -f ollama/docker-compose.nvidia.yml up -d

# AMD GPU
docker compose -f ollama/docker-compose.amd.yml up -d

# CPU only
docker compose -f ollama/docker-compose.cpu.yml up -d
```

Wait for both containers to be healthy:

```bash
docker ps   # both 'ollama' and 'open-webui' should show as "Up"
```

---

## 2. Pull a model

Models are stored in a Docker volume (`ollama_data`) so they persist across restarts.

```bash
# Pull via docker exec
docker exec -it ollama ollama pull llama3.3

# Or pull using the Ollama CLI if installed on the host
ollama pull mistral
```

### Available models

| Model | Pull command | Size | Best for |
|---|---|---|---|
| Llama 3.3 70B | `ollama pull llama3.3` | ~43 GB | Best overall quality |
| Llama 3.2 3B | `ollama pull llama3.2` | ~2 GB | Fast, low-memory |
| Mistral 7B | `ollama pull mistral` | ~4 GB | Speed + quality balance |
| Mistral Small 3.1 | `ollama pull mistral-small:3.1` | ~15 GB | Latest Mistral |
| Gemma 3 | `ollama pull gemma3` | ~5 GB | Reasoning, analysis |
| DeepSeek-R1 | `ollama pull deepseek-r1` | ~4 GB | Step-by-step reasoning |
| Qwen 2.5 | `ollama pull qwen2.5` | ~4 GB | Multilingual |
| Phi-4 | `ollama pull phi4` | ~9 GB | Compact, capable |
| CodeLlama | `ollama pull codellama` | ~4 GB | Code generation |
| DeepSeek-Coder V2 | `ollama pull deepseek-coder-v2` | ~9 GB | Advanced coding |

Browse all available models at [ollama.com/library](https://ollama.com/library).

---

## 3. Open WebUI — browser chat interface

Open **http://localhost:3000** in your browser.

### First time setup

1. Click **Sign up** and create a local admin account.
2. In the chat input, click the model selector (top bar) → choose a model you have pulled.
3. Type a message and press **Enter** to start chatting.

### Pulling models from the UI

**Settings → Admin Panel → Models → Pull a model from Ollama.com**

Type the model name (e.g. `llama3.3`) and click **Pull**.

### Useful Open WebUI features

- **System prompt** — set a persistent system instruction for the conversation
- **Temperature / context length** — adjust per-conversation in the model settings panel
- **Multi-model comparison** — open multiple chats side by side
- **RAG (Retrieval-Augmented Generation)** — upload documents and ask questions about them
- **Web search integration** — enable in Settings to augment responses with live search results

---

## 4. Ollama REST API — curl examples

The Ollama server exposes a REST API at **http://localhost:11434**.

### Generate a single response

```bash
curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.3",
    "prompt": "Explain quantum entanglement in simple terms.",
    "stream": false
  }'
```

### Streaming response

```bash
curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral",
    "prompt": "Write a haiku about mountains.",
    "stream": true
  }'
```

### Multi-turn conversation (chat endpoint)

```bash
curl http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.3",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user",   "content": "What is the capital of France?"},
      {"role": "assistant", "content": "The capital of France is Paris."},
      {"role": "user",   "content": "What is its population?"}
    ],
    "stream": false
  }'
```

### List downloaded models

```bash
curl http://localhost:11434/api/tags
```

### Show model information

```bash
curl http://localhost:11434/api/show \
  -d '{"name": "llama3.3"}'
```

---

## 5. OpenAI-compatible API

Ollama exposes an OpenAI-compatible endpoint at **http://localhost:11434/v1**. This means any tool that supports the OpenAI API (LangChain, LlamaIndex, Continue.dev, etc.) works with Ollama by changing the base URL.

### curl — chat completions

```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.3",
    "messages": [
      {"role": "user", "content": "Summarize the theory of relativity in 3 sentences."}
    ]
  }'
```

### curl — list models (OpenAI format)

```bash
curl http://localhost:11434/v1/models
```

---

## 6. Python client examples

### Using the `ollama` Python library

```bash
pip install ollama
```

```python
import ollama

# Simple generate
response = ollama.generate(model="llama3.3", prompt="Why is the sky blue?")
print(response["response"])

# Streaming
for chunk in ollama.generate(model="mistral", prompt="Tell me a joke.", stream=True):
    print(chunk["response"], end="", flush=True)

# Chat conversation
messages = [
    {"role": "user", "content": "What is machine learning?"},
]
response = ollama.chat(model="gemma3", messages=messages)
print(response["message"]["content"])
```

### Using the `openai` Python library (OpenAI-compatible)

```bash
pip install openai
```

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama",  # required but ignored by Ollama
)

response = client.chat.completions.create(
    model="llama3.3",
    messages=[
        {"role": "system", "content": "You are a concise assistant."},
        {"role": "user",   "content": "What are the main differences between Python and Go?"},
    ],
)
print(response.choices[0].message.content)
```

---

## 7. Per-model examples and use cases

### Llama 3.3 — general-purpose chat

Meta's flagship open-weights model. Excellent for general chat, writing, analysis, and instruction following.

```bash
# Pull
docker exec -it ollama ollama pull llama3.3

# Example — creative writing
curl http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{
  "model": "llama3.3",
  "prompt": "Write a short story (200 words) about an astronaut who discovers a library on Mars.",
  "stream": false
}'

# Example — summarization
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "llama3.3",
  "messages": [
    {"role": "system", "content": "Summarize the following text in 3 bullet points."},
    {"role": "user", "content": "The James Webb Space Telescope (JWST) is a space telescope designed to conduct infrared astronomy. Its high-resolution and high-sensitivity instruments allow it to view objects too old, distant, or faint for the Hubble Space Telescope. It is located at the Sun–Earth L2 Lagrange point, about 1.5 million kilometres from Earth."}
  ],
  "stream": false
}'
```

**Recommended parameters:** temperature 0.7, context 4096+

---

### Llama 3.2 — lightweight chat

The 3B parameter variant — fast even on CPU, ideal for quick responses and low-VRAM scenarios.

```bash
docker exec -it ollama ollama pull llama3.2

curl http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{
  "model": "llama3.2",
  "prompt": "Give me 5 tips for better sleep.",
  "stream": false
}'
```

---

### Mistral 7B — fast inference

High quality for its size. Very fast on GPU and excellent at following instructions.

```bash
docker exec -it ollama ollama pull mistral

# Example — structured output
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "mistral",
  "messages": [
    {"role": "user", "content": "List the top 5 programming languages in 2025 as a JSON array with name and use_case fields."}
  ],
  "stream": false
}'

# Example — translation
curl http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{
  "model": "mistral",
  "prompt": "Translate to French: The quick brown fox jumps over the lazy dog.",
  "stream": false
}'
```

---

### Gemma 3 — reasoning and analysis

Google's Gemma 3 model. Strong at multi-step reasoning, mathematical thinking, and analytical tasks.

```bash
docker exec -it ollama ollama pull gemma3

# Example — mathematical reasoning
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "gemma3",
  "messages": [
    {"role": "user", "content": "A store sells apples for $1.20 each and offers a 15% discount if you buy 10 or more. How much do 12 apples cost?"}
  ],
  "stream": false
}'

# Example — logical analysis
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "gemma3",
  "messages": [
    {"role": "system", "content": "Analyze the argument and identify any logical fallacies."},
    {"role": "user", "content": "Everyone I know who exercises regularly is healthy, so exercise must cause good health."}
  ],
  "stream": false
}'
```

---

### DeepSeek-R1 — chain-of-thought reasoning

DeepSeek-R1 is trained with reinforcement learning for complex reasoning. It outputs explicit `<think>` blocks showing its step-by-step reasoning before giving a final answer.

```bash
docker exec -it ollama ollama pull deepseek-r1

# Example — multi-step problem solving
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "deepseek-r1",
  "messages": [
    {"role": "user", "content": "I have a 3-liter jug and a 5-liter jug. How do I measure exactly 4 liters of water?"}
  ],
  "stream": false
}'

# Example — logical puzzle
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "deepseek-r1",
  "messages": [
    {"role": "user", "content": "Three boxes contain apples, oranges, and a mix of both. All labels are wrong. You can pick one fruit from one box. How do you correctly label all three boxes?"}
  ],
  "stream": false
}'
```

> **Tip:** DeepSeek-R1 is slower than other models due to its extended reasoning process, but significantly more accurate on complex tasks. Use `"stream": true` to see the thinking unfold in real time.

---

### Qwen 2.5 — multilingual

Alibaba's Qwen 2.5 supports over 29 languages and is especially strong in Chinese, Japanese, Korean, and Arabic alongside English.

```bash
docker exec -it ollama ollama pull qwen2.5

# Example — English to Chinese translation + explanation
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "qwen2.5",
  "messages": [
    {"role": "user", "content": "Translate to Chinese and explain the cultural context: '\''Time is money.'\''"}
  ],
  "stream": false
}'

# Example — multilingual Q&A (Japanese input)
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "qwen2.5",
  "messages": [
    {"role": "user", "content": "東京の人口はどのくらいですか？"}
  ],
  "stream": false
}'

# Example — code + explanation in Spanish
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "qwen2.5",
  "messages": [
    {"role": "system", "content": "Responde siempre en español."},
    {"role": "user", "content": "Escribe una función Python que calcule números de Fibonacci."}
  ],
  "stream": false
}'
```

---

### Phi-4 — small but capable

Microsoft's Phi-4 punches well above its weight class. Despite being small (~9 GB), it is competitive with much larger models on reasoning and instruction following tasks.

```bash
docker exec -it ollama ollama pull phi4

# Example — concise factual Q&A
curl http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{
  "model": "phi4",
  "prompt": "What is the difference between supervised and unsupervised learning? Answer in 4 sentences.",
  "stream": false
}'

# Example — document classification
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "phi4",
  "messages": [
    {"role": "system", "content": "Classify the sentiment as positive, negative, or neutral. Reply with only one word."},
    {"role": "user", "content": "The product works exactly as described and arrived on time. Very happy with the purchase."}
  ],
  "stream": false
}'
```

---

### CodeLlama — code generation

Meta's Code Llama specializes in code generation, completion, and debugging across many programming languages.

```bash
docker exec -it ollama ollama pull codellama

# Example — generate a function
curl http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{
  "model": "codellama",
  "prompt": "Write a Python function that takes a list of integers and returns a new list with duplicates removed, preserving the original order.",
  "stream": false
}'

# Example — explain code
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "codellama",
  "messages": [
    {"role": "system", "content": "Explain the following code step by step."},
    {"role": "user", "content": "```python\ndef flatten(lst):\n    return [x for sub in lst for x in (flatten(sub) if isinstance(sub, list) else [sub])]\n```"}
  ],
  "stream": false
}'

# Example — debug code
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "codellama",
  "messages": [
    {"role": "user", "content": "Find and fix the bug:\n```python\ndef binary_search(arr, target):\n    left, right = 0, len(arr)\n    while left < right:\n        mid = (left + right) // 2\n        if arr[mid] == target:\n            return mid\n        elif arr[mid] < target:\n            left = mid\n        else:\n            right = mid - 1\n    return -1\n```"}
  ],
  "stream": false
}'
```

---

### DeepSeek-Coder V2 — advanced coding

DeepSeek-Coder V2 is a mixture-of-experts coding model supporting 338 programming languages. It outperforms GPT-4 on several coding benchmarks.

```bash
docker exec -it ollama ollama pull deepseek-coder-v2

# Example — generate a REST API
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "deepseek-coder-v2",
  "messages": [
    {"role": "user", "content": "Write a minimal FastAPI application with endpoints to create, read, update, and delete items stored in a dictionary. Include type hints and docstrings."}
  ],
  "stream": false
}'

# Example — code review
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "deepseek-coder-v2",
  "messages": [
    {"role": "system", "content": "Review the code for bugs, security issues, and style improvements."},
    {"role": "user", "content": "```javascript\napp.get('\''/user'\'', async (req, res) => {\n  const query = `SELECT * FROM users WHERE id = ${req.query.id}`;\n  const result = await db.execute(query);\n  res.json(result);\n});\n```"}
  ],
  "stream": false
}'

# Example — convert code between languages
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "deepseek-coder-v2",
  "messages": [
    {"role": "user", "content": "Convert this Python code to Go:\n```python\ndef fibonacci(n: int) -> list[int]:\n    a, b = 0, 1\n    result = []\n    for _ in range(n):\n        result.append(a)\n        a, b = b, a + b\n    return result\n```"}
  ],
  "stream": false
}'
```

---

## 8. Customizing model parameters

Parameters can be set per-request in the API or configured with a custom `Modelfile`.

### Via the API (per-request)

```bash
curl http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{
  "model": "llama3.3",
  "prompt": "Write a poem about the ocean.",
  "options": {
    "temperature": 0.9,
    "top_p": 0.95,
    "top_k": 50,
    "num_predict": 200,
    "num_ctx": 8192,
    "repeat_penalty": 1.1
  },
  "stream": false
}'
```

### Key parameters

| Parameter | Default | Effect |
|---|---|---|
| `temperature` | 0.8 | Creativity (0 = deterministic, 2 = very random) |
| `top_p` | 0.9 | Nucleus sampling — filters low-probability tokens |
| `top_k` | 40 | Limits vocabulary to top K tokens at each step |
| `num_predict` | 128 | Max tokens to generate (-1 = unlimited) |
| `num_ctx` | 2048 | Context window size (raise for long conversations) |
| `repeat_penalty` | 1.1 | Penalizes repeating the same tokens |
| `seed` | -1 | Set a fixed seed for reproducible outputs |

### Custom Modelfile

Create a model variant with a baked-in system prompt and custom parameters:

```bash
# Create a Modelfile
cat > /tmp/Modelfile <<'EOF'
FROM llama3.3

SYSTEM """
You are a senior software engineer who always writes clean, well-documented code.
Respond concisely and include type hints in all code examples.
"""

PARAMETER temperature 0.3
PARAMETER num_ctx 8192
EOF

# Build the custom model
docker exec -i ollama ollama create code-assistant -f - < /tmp/Modelfile

# Use it
docker exec -it ollama ollama run code-assistant "Implement a binary search tree in Python"
```

---

## 9. Managing models

```bash
# List downloaded models
docker exec -it ollama ollama list

# Show model details (size, parameters, format)
docker exec -it ollama ollama show llama3.3

# Show currently running models and their device (GPU/CPU)
docker exec -it ollama ollama ps

# Remove a model to free disk space
docker exec -it ollama ollama rm mistral

# Copy a model under a new name
docker exec -it ollama ollama cp llama3.3 my-llama
```
