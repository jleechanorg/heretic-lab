#!/usr/bin/env bash
#
# runpod-setup.sh — Set up Heretic on a RunPod A100 instance
#
# Run this on a fresh RunPod pod with PyTorch base image.
# Installs CUDA torch + heretic-llm, clones the lab repo, and
# optionally starts an abliteration run.
#
# Usage:
#   curl -sL <raw-url> | bash
#   ./scripts/runpod-setup.sh                                          # defaults
#   ./scripts/runpod-setup.sh --model google/gemma-3-27b-it            # specify model
#   ./scripts/runpod-setup.sh --model google/gemma-3-27b-it --run      # start run immediately
#
set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
MODEL="${RUNPOD_MODEL:-google/gemma-3-12b-it}"
CONFIG="${RUNPOD_CONFIG:-}"
REPO_URL="${REPO_URL:-https://github.com/<your-user>/heretic-lab.git}"
BRANCH="${REPO_BRANCH:-feat/initial-setup}"
WORK_DIR="/workspace/heretic-lab"
RUN_AFTER_SETUP=false

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)  MODEL="$2"; shift 2 ;;
        --config) CONFIG="$2"; shift 2 ;;
        --repo)   REPO_URL="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --run)    RUN_AFTER_SETUP=true; shift ;;
        --help|-h)
            echo "Usage: $0 [--model <hf-model>] [--config <config.toml>] [--run] [--repo <url>] [--branch <name>]"
            exit 0
            ;;
        *) echo "⚠ Unknown arg: $1"; shift ;;
    esac
done

echo "🚀 RunPod Heretic Setup"
echo "   Model:  $MODEL"
echo "   Config: ${CONFIG:-auto}"
echo ""

# ── System packages ───────────────────────────────────────────────────────────
echo "📦 Installing system dependencies ..."
apt-get update -qq && apt-get install -y -qq git curl wget python3-venv > /dev/null 2>&1

# ── CUDA PyTorch ──────────────────────────────────────────────────────────────
echo "🔥 Installing PyTorch with CUDA 12.4 ..."
pip install --upgrade pip --quiet
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu124 --quiet

# Verify CUDA
python3 -c "import torch; print(f'PyTorch {torch.__version__}, CUDA available: {torch.cuda.is_available()}, GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"

# ── Install Heretic ───────────────────────────────────────────────────────────
echo "🔧 Installing heretic-llm ..."
pip install heretic-llm --quiet

# ── Clone lab repo ────────────────────────────────────────────────────────────
echo "📂 Cloning heretic-lab ..."
if [[ -d "$WORK_DIR" ]]; then
    echo "   $WORK_DIR already exists, pulling latest ..."
    cd "$WORK_DIR" && git pull --ff-only
else
    git clone -b "$BRANCH" "$REPO_URL" "$WORK_DIR"
    cd "$WORK_DIR"
fi

# ── Auto-select config ────────────────────────────────────────────────────────
if [[ -z "$CONFIG" ]]; then
    case "$MODEL" in
        *gemma-3-12b*)  CONFIG="configs/config.remote-a100.toml" ;;
        *gemma-3-27b*)  CONFIG="configs/config.remote-a100.toml" ;;
        *qwen3-4b*|*Qwen3-4B*) CONFIG="configs/config.qwen3-4b.toml" ;;
        *) CONFIG="configs/config.remote-a100.toml" ;;
    esac
fi

echo ""
echo "✅ Setup complete!"
echo "   Working dir: $WORK_DIR"
echo "   Model:       $MODEL"
echo "   Config:      $CONFIG"
echo ""

# ── Optional: start run ───────────────────────────────────────────────────────
if $RUN_AFTER_SETUP; then
    echo "▶ Starting Heretic run ..."
    cd "$WORK_DIR"
    exec heretic --model "$MODEL" --config "$CONFIG"
else
    echo "─── To start a run ──────────────────────────────────"
    echo "  cd $WORK_DIR"
    echo "  heretic --model $MODEL --config $CONFIG"
    echo "─────────────────────────────────────────────────────"
fi
