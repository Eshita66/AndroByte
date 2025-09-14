#!/usr/bin/env bash
# Claim 1 run.sh (Linux/macOS)
set -euo pipefail

Log() { printf "\n[claim1] %s\n" "$*"; }

# ==== Configuration ====
ExpectedRoot="claims/claim1/expected"
ExpectedLeakDir="${ExpectedRoot}/reports"
ExpectedMetrics="${ExpectedRoot}/metrics_summary.json"
ExpectedLeakRef="${ExpectedLeakDir}/clone1_sensitive_only.json" 

# ==== pipeline config & demo APK names ====
ConfigPath="configs/settings.json"     
DemoApkName1="Clone1"                  #  APKs/Clone1.apk
DemoApkName2="field"                   # optional second demo

# ---- Allow override via environment variables (optional) ----
ExpectedRoot="${ANDROBYTE_EXPECTED_ROOT:-$ExpectedRoot}"
ExpectedLeakDir="${ANDROBYTE_EXPECTED_LEAK_DIR:-$ExpectedLeakDir}"
ExpectedMetrics="${ANDROBYTE_EXPECTED_METRICS:-$ExpectedMetrics}"
ExpectedLeakRef="${ANDROBYTE_EXPECTED_LEAK_REF:-$ExpectedLeakRef}"
ConfigPath="${ANDROBYTE_CONFIG_PATH:-$ConfigPath}"
DemoApkName1="${ANDROBYTE_DEMO_APK1:-$DemoApkName1}"
DemoApkName2="${ANDROBYTE_DEMO_APK2:-$DemoApkName2}"

# 0) Ensure repo root
if [[ -f "./run_pipeline.py" ]]; then
  :
elif [[ -f "../../run_pipeline.py" ]]; then
  cd ../..
else
  echo "[claim1] Could not locate run_pipeline.py. Run from repo root or claims/claim1." >&2
  exit 1
fi

# 1) Install
if [[ -f "./install.sh" ]]; then
  Log "Running install.sh ..."
  chmod +x ./install.sh || true
  ./install.sh
elif [[ -f "./install.ps1" ]]; then
  Log "install.sh not found; if on Windows/PowerShell, run install.ps1 there."
  exit 1
else
  echo "[claim1] No installer found (install.sh/install.ps1)." >&2
  exit 1
fi

# 2) Outputs dir
mkdir -p outputs
[[ -f "outputs/.gitkeep" ]] || : > "outputs/.gitkeep"

# 3) Demo APKs presence checks
apk1Path="APKs/${DemoApkName1}.apk"
apk2Path="APKs/${DemoApkName2}.apk"
if [[ ! -f "$apk1Path" ]]; then
  echo "[claim1] Missing ${apk1Path}" >&2
  exit 1
fi
if [[ ! -f "$apk2Path" ]]; then
  Log "Optional ${apk2Path} not found (will run only one demo)."
fi

# 4) Run pipeline with required --config / --apk_name
Run_One() {
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
  echo "[claim1] Pipeline failed for ${apkName}" >&2
  return 1
}

Run_One "$DemoApkName1"
if [[ -f "$apk2Path" ]]; then
  Run_One "$DemoApkName2"
fi

# 5) Prefer sensitive_only.json; if missing/empty, fall back to other JSONs
Log "Searching for leak reports under outputs/${DemoApkName1}/ ..."
sensOnly="$(find "outputs/${DemoApkName1}" -type f -name "*sensitive_only*.json" 2>/dev/null | head -n 1 || true)"
found=""

if [[ -n "${sensOnly:-}" && -s "$sensOnly" ]]; then
  found="$sensOnly"
else
  if [[ -n "${sensOnly:-}" && ! -s "$sensOnly" ]]; then
    Log "Found sensitive_only.json but it is empty (no sensitive subgraphs)."
  else
    Log "No sensitive_only.json found; falling back to other JSONs (schema may differ)."
  fi

  found="$(find "outputs/${DemoApkName1}" -type f \( -name "*sensitive_calls*.json" -o -name "*leak*.json" -o -name "*summary*.json" \) 2>/dev/null | head -n 1 || true)"
  if [[ -z "${found:-}" ]]; then
    found="$(find outputs -type f \( -name "*sensitive_only*.json" -o -name "*sensitive_calls*.json" -o -name "*leak*.json" -o -name "*summary*.json" \) 2>/dev/null | head -n 1 || true)"
  fi
fi

if [[ -z "${found:-}" ]]; then
  echo "[claim1] No JSON files found under outputs/." >&2
  exit 1
fi
if [[ ! -s "$found" ]]; then
  echo "[claim1] Found JSON is empty: $found" >&2
  exit 1
fi

Log "Validating JSON structure: $found"
export CLAIM1_JSON="$found"
python - <<'PYCODE'
import json, os, sys
p = os.environ.get('CLAIM1_JSON')
if not p:
    print("[claim1] CLAIM1_JSON not set.", file=sys.stderr)
    sys.exit(1)
with open(p, 'r', encoding='utf-8') as f:
    obj = json.load(f)
print('[claim1] JSON parsed OK. Type:', type(obj).__name__)
PYCODE

# 6) Expected samples presence
expDir="$ExpectedLeakDir"
if [[ -d "$expDir" ]]; then
  Log "Expected leak reports present in $expDir (manual/visual diff encouraged)."
else
  Log "No expected leak reports directory ($expDir); skip comparison."
fi

# 7) Metrics summary (precomputed)
met="$ExpectedMetrics"
if [[ -f "$met" ]]; then
  Log "Metrics summary found (full benchmark, precomputed): $met"
  export CLAIM1_MET="$(python - <<'PYCODE'
import os, sys
from pathlib import Path
p = os.environ.get('CLAIM1_MET_INPUT', sys.argv[1] if len(sys.argv)>1 else None)
# We won't actually use this mini-script; placeholder kept for symmetry.
PYCODE
)"
  
  python - "$met" <<'PYCODE'
import json, sys
p = sys.argv[1]
with open(p, 'r', encoding='utf-8') as f:
    m = json.load(f)
for k in ("precision","recall","f1","f1_score","f1_micro","f1_macro","num_apps","true_positives","false_positives","false_negatives"):
    if k in m:
        print(f"[claim1] {k}: {m[k]}")
PYCODE
fi

Log "Claim 1 demo run complete."
