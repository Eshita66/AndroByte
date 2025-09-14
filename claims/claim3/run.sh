#!/usr/bin/env bash
# Claim 3 run.sh (Linux/macOS)


set -euo pipefail

Log() { printf "\n[claim3] %s\n" "$*"; }

# === Configuration ===
ConfigPath="configs/settings.json"
DemoApkName="Clone1"  # APKs/Clone1.apk
DatasetPath="claims/claim3/expected/update_evaluation_dataset_cleaned.json"
GevalScript="claims/claim3/tools/Gevaluation.py"
GevalAggScript="claims/claim3/tools/GevalAvgCalculation.py"
ExpectedDir="claims/claim3/expected"
DemoExpected="claims/claim3/expected/demo_summaries/Clone1_summary.json"
PrecomputedAgg="claims/claim3/expected/geval_aggregated_results.json"

# === 0) Ensure repo root ===
if [[ -f "./run_pipeline.py" ]]; then
  :
elif [[ -f "../../run_pipeline.py" ]]; then
  cd ../..
else
  echo "[claim3] Could not locate run_pipeline.py. Run from repo root or claims/claim3." >&2
  exit 1
fi

# === 1) Install ===
if [[ -f "./install.sh" ]]; then
  Log "Running install.sh ..."
  chmod +x ./install.sh || true
  ./install.sh
elif [[ -f "./install.ps1" ]]; then
  Log "install.sh not found; if using Windows/PowerShell, run install.ps1 there."
  exit 1
else
  echo "No installer found (install.sh/install.ps1)." >&2
  exit 1
fi

# === 2) Check demo APK and outputs dir ===
apkPath="APKs/${DemoApkName}.apk"
if [[ ! -f "$apkPath" ]]; then
  echo "[claim3] Missing $apkPath" >&2
  exit 1
fi
mkdir -p outputs
[[ -f "outputs/.gitkeep" ]] || : > "outputs/.gitkeep"

# === 3) Run pipeline for summaries ===
Log "Running pipeline to produce summaries for $DemoApkName ..."
python run_pipeline.py --config "$ConfigPath" --apk_name "$DemoApkName"

# === 4) Validate summary JSONs exist ===
sum1="outputs/${DemoApkName}/output/refined_method_summaries.json"
sum2="outputs/${DemoApkName}/output/sensitive_only.json"
if [[ ! -f "$sum1" ]]; then
  echo "[claim3] Missing $sum1" >&2
  exit 1
fi
if [[ ! -f "$sum2" ]]; then
  Log "Note: $sum2 not found (ok for RQ3)."
fi

# Quick parse check
Log "Validating JSON structure: $sum1"
python - "$sum1" <<'PYCODE'
import json, sys
p = sys.argv[1]
with open(p, "r", encoding="utf-8") as f:
    obj = json.load(f)
print("[claim3] refined_method_summaries.json parsed OK. Type:", type(obj).__name__)
PYCODE

# === 5) Print manual check guidance ===
Log "Manual check: open $sum1 and confirm it (a) mentions the sensitive source, (b) shows propagation, (c) names a sink, (d) explains the flow clearly."
if [[ -f "$DemoExpected" ]]; then
  Log "Reference example available at: $DemoExpected (format/content to compare)."
else
  Log "No reference example found at $DemoExpected (optional)."
fi

Log "Claim 3 (RQ3) demo complete."
