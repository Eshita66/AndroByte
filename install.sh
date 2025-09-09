#!/usr/bin/env bash
set -e

echo "[AndroByte Install] Starting setup..."

# --------
# 1. Python environment
# --------
if ! command -v python3 &> /dev/null; then
    echo "Python3 not found. Please install Python 3.10+ before continuing."
    exit 1
fi

# Create virtual environment if not exists
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip wheel setuptools

# --------
# 2. Install Python dependencies
# --------
if [ ! -f "requirements.txt" ]; then
    echo "requirements.txt not found! Please ensure it exists."
    exit 1
fi

echo "[AndroByte Install] Installing Python dependencies..."
pip install -r requirements.txt

# --------
# 3. Check Graphviz
# --------
if ! command -v dot &> /dev/null; then
    echo "Graphviz 'dot' command not found!"
    echo "Please install Graphviz manually:"
    echo "  Ubuntu/Debian: sudo apt-get install graphviz"
    echo "  macOS: brew install graphviz"
    echo "  Windows (choco): choco install graphviz"
    exit 1
fi
echo "[AndroByte Install] Graphviz found."

# --------
# 4. Ollama model check (optional)
# --------
if command -v ollama &> /dev/null; then
    echo "[AndroByte Install] Ollama detected. Pulling required model..."
    ollama pull llama3.1:latest || true
else
    echo "Ollama not installed. Please install Ollama if you want to run with local models."
    echo "See: https://ollama.ai/"
fi

# --------
# 5. Done
# --------
echo ""
echo "[AndroByte Install] Setup complete!"
echo "Activate the environment with:"
echo "  source venv/bin/activate"
echo ""
echo "You can now run the pipeline, e.g.:"
echo "  python run_pipeline.py --config configs/settings.json --apk_name Clone1"
