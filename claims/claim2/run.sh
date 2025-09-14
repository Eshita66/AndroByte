#!/usr/bin/env bash
# Claim 2 run.sh (Linux/macOS) — RQ2 D2CFG / Call-Graph Accuracy
set -euo pipefail

Log(){ printf "\n[claim2] %s\n" "$*"; }

# ==== Configuration ====
ExpectedRoot="claims/claim2/expected"
ExpectedGraphDir="${ExpectedRoot}/graphs"          
ExpectedMetrics="${ExpectedRoot}/metrics_summary.json"

# ====  config & demo APK name ====
ConfigPath="configs/settings.json"                 # settings.json
DemoApkName="ap-news"                              # APKs/ap-news.apk

# ---- Allow override via environment variables (optional) ----
ExpectedRoot="${ANDROBYTE_EXPECTED_ROOT:-$ExpectedRoot}"
ExpectedGraphDir="${ANDROBYTE_EXPECTED_GRAPH_DIR:-$ExpectedGraphDir}"
ExpectedMetrics="${ANDROBYTE_EXPECTED_METRICS:-$ExpectedMetrics}"
ConfigPath="${ANDROBYTE_CONFIG_PATH:-$ConfigPath}"
DemoApkName="${ANDROBYTE_DEMO_APK:-$DemoApkName}"

# 0) Ensure repo root
if [[ -f "./run_pipeline.py" ]]; then
  :
elif [[ -f "../../run_pipeline.py" ]]; then
  cd ../..
else
  echo "[claim2] Could not locate run_pipeline.py. Run from repo root or claims/claim2." >&2
  exit 1
fi

# 1) Install
if [[ -f "./install.sh" ]]; then
  Log "Running install.sh ..."
  chmod +x ./install.sh || true
  ./install.sh
elif [[ -f "./install.ps1" ]]; then
  Log "install.sh not found; if using Windows/PowerShell, run install.ps1 there."
  exit 1
else
  echo "[claim2] No installer found (install.sh/install.ps1)." >&2
  exit 1
fi

# 2) Outputs dir
mkdir -p outputs
[[ -f "outputs/.gitkeep" ]] || : > "outputs/.gitkeep"

# 3) Demo APK presence check
apkPath="APKs/${DemoApkName}.apk"
if [[ ! -f "$apkPath" ]]; then
  echo "[claim2] Missing $apkPath" >&2
  exit 1
fi

# 4) Run pipeline with required --config / --apk_name
Run_One(){
  local apkName="$1"
  Log "Running pipeline on ${apkName} ..."
  if python run_pipeline.py --config "$ConfigPath" --apk_name "$apkName"; then
    return 0
  fi
  Log "Fallback: python run_pipeline.py --config $ConfigPath"
  if python run_pipeline.py --config "$ConfigPath"; then
    return 0
  fi
  Log "Fallback: python run_pipeline.py (last resort)"
  if python run_pipeline.py; then
    return 0
  fi
  echo "[claim2] Pipeline failed for ${apkName}" >&2
  return 1
}

Run_One "$DemoApkName"

# 5) Locate generated graph visualization (PNG)
graphImg="outputs/${DemoApkName}/output/visited_graph.png"
if [[ -f "$graphImg" ]]; then
  Log "Call graph visualization generated: $graphImg"
else
  echo "[claim2] Expected call graph image not found at $graphImg" >&2
  exit 1
fi

# 7) Metrics summary (precomputed, optional)
met="$ExpectedMetrics"
if [[ -f "$met" ]]; then
  Log "Metrics summary found (precomputed): $met"
  python - "$met" <<'PYCODE'
import json, sys
p = sys.argv[1]
with open(p, "r", encoding="utf-8") as f:
    m = json.load(f)
for k in ("precision","recall","f1","num_apps","true_positives","false_positives","false_negatives"):
    if k in m:
        print(f"[claim2] {k}: {m[k]}")
PYCODE
fi

Log "Claim 2 (RQ2) demo run complete."
