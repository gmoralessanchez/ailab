# Contributing to ThinkExponential AILab

Thanks for your interest in contributing.

This repository is a practical lab for running open-source AI workloads locally with Docker (Windows + WSL2), focused on:
- LLM deployments via Ollama
- Image generation via Stable Diffusion WebUI
- Compatibility across NVIDIA, AMD, and CPU-only environments

## What contributions are most helpful

- Fixes for deployment reliability (compose files, scripts, startup behavior)
- Hardware compatibility improvements (NVIDIA/AMD/CPU)
- Documentation updates (setup, troubleshooting, examples)
- Reproducible bug reports with logs and environment details

## Before you open a PR

1. Read [README.md](README.md) and relevant docs in [docs/](docs/).
2. Keep changes focused and minimal.
3. If behavior changes, update docs in the same PR.
4. Validate your change with the closest applicable flow (NVIDIA, AMD, or CPU).

## Development and validation expectations

Use the smallest validation scope that proves your change:
- **Docs-only changes**: verify links/commands and readability.
- **Compose/script changes**: run the affected deployment path and confirm container startup.
- **Usage changes**: verify commands in the related guide.

When possible, include in your PR description:
- Host OS + WSL version
- GPU type (NVIDIA/AMD/CPU-only)
- Docker/Compose versions
- Command(s) run
- Relevant logs or screenshots

## Pull request checklist

- [ ] Change is scoped to one clear purpose
- [ ] Related documentation is updated
- [ ] Commands/examples were validated
- [ ] No unrelated refactors included
- [ ] PR description includes environment details and repro/verification steps

## Issue reporting checklist

Please include:
- Expected behavior
- Actual behavior
- Exact command used
- Full error message/log excerpt
- Hardware and software details (OS, WSL, Docker, GPU)

## Licensing and AI model terms

By submitting a contribution, you agree your contribution is licensed under the repository license in [LICENSE](LICENSE) (Apache License 2.0).

Important: the repository license applies to this repository’s code, scripts, configuration, and documentation. Third-party AI models used with this project are governed by their own licenses/terms. Contributors and users must review and comply with model-specific licenses before using or distributing those models.

## Community standards and security

- This repository is maintained on a best-effort basis with no guaranteed support SLA (see [SUPPORT.md](SUPPORT.md)).
- Please follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- For vulnerabilities, see [SECURITY.md](SECURITY.md).
