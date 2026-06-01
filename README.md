# heretic-lab

Experiment configs and scripts for running [Heretic](https://github.com/FailSpy/heretic) — an LLM _abliteration_ tool that removes built-in safety refusal behaviors from instruction-tuned models. Outputs can be converted to GGUF for use with Ollama, llama.cpp, and other local inference engines.

> **⚠️ Responsibility Notice:** Abliterated models may produce harmful outputs. Use responsibly and in compliance with applicable laws and platform policies. This repo is for research and personal experimentation only.

---

## Local Setup (macOS M4 Pro 48GB)

### Prerequisites

- macOS 15+ on Apple Silicon (M4 Pro with 48 GB unified memory)
- Python 3.11+
- [Homebrew](https://brew.sh)

### Install

```bash
# Clone this repo
git clone https://github.com/<your-user>/heretic-lab.git
cd heretic-lab

# Create venv and install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install heretic-llm
```

> **Note on PyTorch + MPS:** Heretic uses Hugging Face Transformers which relies on PyTorch. On Apple Silicon, install the latest PyTorch with MPS (Metal Performance Shaders) support:
> ```bash
> pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
> # or for nightly MPS improvements:
> pip install --pre torch torchvision --index-url https://download.pytorch.org/whl/nightly/cpu
> ```

### Quick Start

```bash
# Default: abliterate gemma-3-12b-it
./scripts/run-heretic.sh

# Quick test with a smaller model
./scripts/run-heretic.sh --model Qwen/Qwen3-4B-Instruct-2507 --config configs/config.qwen3-4b.toml

# Specify model and config explicitly
./scripts/run-heretic.sh --model google/gemma-3-12b-it --config configs/config.gemma-3-12b.toml
```

### Convert & Run with Ollama

```bash
# After heretic produces output safetensors:
./scripts/convert-to-gguf.sh output/google--gemma-3-12b-it-abliterated
ollama create my-model -f output/google--gemma-3-12b-it-abliterated/Modelfile
ollama run my-model
```

---

## Model Recommendations

| Model | Params | Memory (FP16) | Quality | Speed | Notes |
|---|---|---|---|---|---|
| **Qwen/Qwen3-4B-Instruct-2507** | 4B | ~8 GB | ⭐⭐⭐ | 🚀 Fastest | Best for quick testing & iteration |
| **google/gemma-3-12b-it** | 12B | ~24 GB | ⭐⭐⭐⭐⭐ | 🐢 Moderate | **Best quality on 48 GB Mac** — fits comfortably in memory |
| **google/gemma-3-27b-it** | 27B | ~54 GB | ⭐⭐⭐⭐⭐ | 🐌 Slowest | Needs 4-bit quantization (GPTQ/AWQ) to fit in 48 GB |

### Tips for M4 Pro 48 GB

- **gemma-3-12b-it** at FP16 uses ~24 GB — leaves plenty of headroom for the abliteration process (which loads model + activations).
- **gemma-3-27b-it** requires quantization. Use `quantization = "4bit"` or `quantization = "8bit"` in the config TOML, or use a pre-quantized GGUF as input.
- **Qwen3-4B** is ideal for verifying your pipeline works before committing hours to a larger model.

---

## Remote GPU Hosting

For larger models (27B+) or faster iteration, run on cloud GPU:

| Provider | GPU | Cost/hr | Notes |
|---|---|---|---|
| **[RunPod](https://runpod.io)** | A100 80GB / H100 | ~$1.50–3.50 | Best value, community cloud. Use `scripts/runpod-setup.sh` |
| **[Hugging Face Spaces](https://huggingface.co/spaces)** | A100 (T4 free tier) | Free–$4.40 | Easy deploy with Docker, limited to HF ecosystem |
| **[Modal](https://modal.com)** | A100 / H100 | ~$1.50–3.50 | Serverless, pay-per-second. Great for batch jobs |
| **[Vast.ai](https://vast.ai)** | Various (RTX 4090, A100) | ~$0.30–2.00 | Cheapest option, variable reliability |

### RunPod Quick Start

```bash
# 1. Launch an A100 80GB pod on RunPod with PyTorch base image
# 2. Copy & run the setup script:
curl -sL https://raw.githubusercontent.com/<your-user>/heretic-lab/feat/initial-setup/scripts/runpod-setup.sh | bash
```

Or connect via SSH and run manually:

```bash
./scripts/runpod-setup.sh --model google/gemma-3-27b-it --config configs/config.remote-a100.toml
```

---

## Repository Structure

```
heretic-lab/
├── configs/                        # Heretic TOML configs
│   ├── config.gemma-3-12b.toml     # gemma-3-12b-it on M4 Pro
│   ├── config.qwen3-4b.toml        # Qwen3-4B quick test
│   └── config.remote-a100.toml     # A100 80GB cloud config
├── scripts/
│   ├── run-heretic.sh              # Main runner (local + venv)
│   ├── convert-to-gguf.sh          # Convert safetensors → GGUF + Ollama
│   └── runpod-setup.sh             # RunPod A100 setup
├── results/                        # Output artifacts (gitkept)
├── requirements.txt                # Python dependencies
└── .gitignore
```

---

## Links

- **Heretic repo:** [github.com/FailSpy/heretic](https://github.com/FailSpy/heretic)
- **Heretic PyPI:** [pypi.org/project/heretic-llm](https://pypi.org/project/heretic-llm)
- **Paper:** [“Abliteration” technique](https://arxiv.org/abs/2406.01248) — Removing Refusal Behavior from LLMs
- **llama.cpp (GGUF conversion):** [github.com/ggerganov/llama.cpp](https://github.com/ggerganov/llama.cpp)
- **Ollama:** [ollama.com](https://ollama.com)

---

## License

This repo is for research purposes. The Heretic tool is licensed under its own terms — see [the heretic repo](https://github.com/FailSpy/heretic) for details.
