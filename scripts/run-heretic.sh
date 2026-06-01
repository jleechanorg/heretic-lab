#!/usr/bin/env bash
#
# run-heretic.sh — Run Heretic abliteration locally or on remote GPU
#
# Creates .venv if needed, installs deps, then runs heretic CLI.
#
# Usage:
#   ./scripts/run-heretic.sh                                          # defaults: gemma-3-12b-it
#   ./scripts/run-heretic.sh --model Qwen/Qwen3-4B-Instruct-2507      # quick test
#   ./scripts/run-heretic.sh --model google/gemma-3-12b-it --config configs/config.gemma-3-12b.toml
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Defaults ──────────────────────────────────────────────────────────────────
MODEL="${HERETIC_MODEL:-google/gemma-3-12b-it}"
CONFIG="${HERETIC_CONFIG:-}"
EXTRA_ARGS=()

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --config)
            CONFIG="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--model <hf-model-id>] [--config <config.toml>] [extra heretic args...]"
            echo ""
            echo "Defaults:"
            echo "  --model  google/gemma-3-12b-it"
            echo "  --config (none — heretic uses config.default.toml in working dir)"
            exit 0
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

# ── Resolve config ────────────────────────────────────────────────────────────
# If no --config given, auto-select based on model name
if [[ -z "$CONFIG" ]]; then
    case "$MODEL" in
        *gemma-3-12b*)  CONFIG="$PROJECT_ROOT/configs/config.gemma-3-12b.toml" ;;
        *qwen3-4b*|*Qwen3-4B*) CONFIG="$PROJECT_ROOT/configs/config.qwen3-4b.toml" ;;
        *gemma-3-27b*)  CONFIG="$PROJECT_ROOT/configs/config.remote-a100.toml" ;;
        *) echo "⚠ No config auto-match for model '$MODEL'. Using heretic defaults." ;;
    esac
fi

# ── Virtual environment ───────────────────────────────────────────────────────
VENV_DIR="$PROJECT_ROOT/.venv"

if [[ ! -d "$VENV_DIR" ]]; then
    echo "🐍 Creating virtual environment at $VENV_DIR ..."
    python3 -m venv "$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"

# Install / update dependencies
echo "📦 Installing dependencies ..."
pip install --upgrade --quiet pip
pip install --quiet -r "$PROJECT_ROOT/requirements.txt"

# ── Run Heretic ────────────────────────────────────────────────────────────────
echo ""
echo "🔧 Running Heretic abliteration"
echo "   Model:  $MODEL"
echo "   Config: ${CONFIG:-heretic defaults}"
echo ""

cd "$PROJECT_ROOT"

# Build the heretic command
CMD=(heretic --model "$MODEL")
if [[ -n "$CONFIG" && -f "$CONFIG" ]]; then
    CMD+=(--config "$CONFIG")
fi

# Append any extra args
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    CMD+=("${EXTRA_ARGS[@]}")
fi

echo "▶ ${CMD[*]}"
echo ""
exec "${CMD[@]}"
