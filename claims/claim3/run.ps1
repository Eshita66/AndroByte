#Requires -Version 5
$ErrorActionPreference = "Stop"
function Log($m){ Write-Host "`n[claim3] $m" }

# === Configuration ===
$ConfigPath      = "configs\settings.json"
$DemoApkName     = "Clone1"  #  APKs\Clone1.apk
$DatasetPath     = "claims\claim3\expected\update_evaluation_dataset_cleaned.json"
$GevalScript     = "claims\claim3\tools\Gevaluation.py"
$GevalAggScript  = "claims\claim3\tools\GevalAvgCalculation.py"
$ExpectedDir     = "claims\claim3\expected"
$DemoExpected    = "claims\claim3\expected\demo_summaries\Clone1_summary.json"
$PrecomputedAgg  = "claims\claim3\expected\geval_aggregated_results.json"

# === 0) Ensure repo root ===
if (Test-Path ".\run_pipeline.py") { }
elseif (Test-Path "..\..\run_pipeline.py") { Set-Location ..\.. }
else { throw "[claim3] Could not locate run_pipeline.py. Run from repo root or claims\claim3." }

# === 1) Install ===
if (Test-Path ".\install.ps1") {
  Log "Running install.ps1 ..."
  ./install.ps1
} elseif (Test-Path ".\install.sh") {
  Log "install.ps1 not found; if using WSL/Git Bash, run install.sh there."
  throw
} else { throw "No installer found (install.ps1/install.sh)." }

# === 2) Check demo APK and outputs dir ===
$apkPath = "APKs\${DemoApkName}.apk"
if (-not (Test-Path $apkPath)) { throw "[claim3] Missing $apkPath" }
New-Item -ItemType Directory -Force -Path outputs | Out-Null
if (-not (Test-Path "outputs\.gitkeep")) { New-Item -ItemType File -Path "outputs\.gitkeep" | Out-Null }

# === 3) Run pipeline for summaries ===
Log "Running pipeline to produce summaries for $DemoApkName ..."
python run_pipeline.py --config $ConfigPath --apk_name $DemoApkName

# === 4) Validate summary JSONs exist ===
$sum1 = "outputs\$DemoApkName\output\refined_method_summaries.json"
$sum2 = "outputs\$DemoApkName\output\sensitive_only.json"
if (-not (Test-Path $sum1)) { throw "[claim3] Missing $sum1" }
if (-not (Test-Path $sum2)) { Log "Note: $sum2 not found (ok for RQ3)."; }

# Quick parse check (use temp file to avoid quoting issues)
$env:CLAIM3_SUM = $sum1
$py_validate = @'
import json, os
p = os.environ["CLAIM3_SUM"]
with open(p, "r", encoding="utf-8") as f:
    obj = json.load(f)
print("[claim3] refined_method_summaries.json parsed OK. Type:", type(obj).__name__)
'@

$tmpValidate = New-TemporaryFile
Set-Content -Path $tmpValidate -Value $py_validate -Encoding UTF8
python $tmpValidate
Remove-Item $tmpValidate -ErrorAction SilentlyContinue



# === 5) Print manual check guidance ===
Log "Manual check: open $sum1 and confirm it (a) mentions the sensitive source, (b) shows propagation, (c) names a sink, (d) explains the flow clearly."
if (Test-Path $DemoExpected) {
  Log "Reference example available at: $DemoExpected (format/content to compare)."
} else {
  Log "No reference example found at $DemoExpected (optional)."
}


Log "Claim 3 (RQ3) demo complete."
