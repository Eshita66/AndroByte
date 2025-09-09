<# 
 AndroByte Windows installer
 - Creates venv (.\venv)
 - Installs requirements.txt
 - Verifies Graphviz "dot" is available
 - Optionally pulls Ollama model (if Ollama is installed)

 Run from repo root:
   PowerShell (as user): 
     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
     .\install.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "[AndroByte Install] Starting setup..." -ForegroundColor Cyan

# --------
# 1) Locate Python 3
# --------
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
  $python = Get-Command py -ErrorAction SilentlyContinue
  if ($python) {
    $pythonCmd = "py -3"
  } else {
    Write-Host "Python 3 not found. Please install Python 3.10+ and re-run." -ForegroundColor Red
    exit 1
  }
} else {
  $pythonCmd = "python"
}

# --------
# 2) Create and activate venv
# --------
if (-not (Test-Path ".\venv")) {
  Write-Host "[AndroByte Install] Creating virtual environment (.\venv)..." -ForegroundColor Cyan
  & $pythonCmd -m venv venv
}

# Activate venv for this script session
$venvActivate = ".\venv\Scripts\Activate.ps1"
if (-not (Test-Path $venvActivate)) {
  Write-Host "Virtual environment activation script not found: $venvActivate" -ForegroundColor Red
  exit 1
}
Write-Host "[AndroByte Install] Activating venv..." -ForegroundColor Cyan
. $venvActivate

# --------
# 3) Upgrade pip/setuptools/wheel
# --------
Write-Host "[AndroByte Install] Upgrading pip/setuptools/wheel..." -ForegroundColor Cyan
pip install --upgrade pip setuptools wheel

# --------
# 4) Install Python dependencies
# --------
if (-not (Test-Path ".\requirements.txt")) {
  Write-Host "requirements.txt not found in repo root." -ForegroundColor Red
  exit 1
}
Write-Host "[AndroByte Install] Installing requirements..." -ForegroundColor Cyan
pip install -r requirements.txt

# --------
# 5) Check Graphviz (dot)
# --------
Write-Host "[AndroByte Install] Checking for Graphviz 'dot'..." -ForegroundColor Cyan
$dot = (Get-Command dot.exe -ErrorAction SilentlyContinue)
if (-not $dot) {
  Write-Host "Graphviz 'dot' not found on PATH." -ForegroundColor Yellow
  Write-Host "Please install Graphviz and re-run (then restart your shell so PATH updates):" -ForegroundColor Yellow
  Write-Host "  choco install graphviz   # (Chocolatey)" -ForegroundColor Yellow
  Write-Host "  winget install Graphviz.Graphviz" -ForegroundColor Yellow
  Write-Host "Download page: https://graphviz.org/download/" -ForegroundColor Yellow
  exit 1
} else {
  Write-Host "[AndroByte Install] Graphviz found at $($dot.Source)" -ForegroundColor Green
}

# --------
# 6) Ollama (optional)
# --------
Write-Host "[AndroByte Install] Checking for Ollama (optional)..." -ForegroundColor Cyan
$ollama = (Get-Command ollama.exe -ErrorAction SilentlyContinue)
if ($ollama) {
  try {
    Write-Host "[AndroByte Install] Pulling required model (llama3.1:latest)..." -ForegroundColor Cyan
    ollama pull llama3.1:latest
  } catch {
    Write-Host "Ollama present but model pull failed (you can pull manually later)." -ForegroundColor Yellow
  }
} else {
  Write-Host "Ollama not found. If you plan to run local LLM summaries, install Ollama:" -ForegroundColor Yellow
  Write-Host "  https://ollama.ai/" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[AndroByte Install] Setup complete!" -ForegroundColor Green
Write-Host "Activate the environment in this shell with:" -ForegroundColor Green
Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "Run a quick test:" -ForegroundColor Green
Write-Host "  python run_pipeline.py --config configs\settings.json --apk_name Clone1" -ForegroundColor Green
