#Requires -Version 5
$ErrorActionPreference = "Stop"
function Log($m){ Write-Host "`n[claim2] $m" }

# ==== Configuration ====
$ExpectedRoot     = "claims\claim2\expected"
$ExpectedGraphDir = Join-Path $ExpectedRoot "graphs"            
$ExpectedMetrics  = Join-Path $ExpectedRoot "metrics_summary.json"

# ==== config & demo APK name ====
$ConfigPath  = "configs\settings.json"   # settings.json
$DemoApkName = "ap-news"                 # APKs\ap-news.apk

# ---- Allow override via environment variables (optional) ----
if ($env:ANDROBYTE_EXPECTED_ROOT)      { $ExpectedRoot     = $env:ANDROBYTE_EXPECTED_ROOT }
if ($env:ANDROBYTE_EXPECTED_GRAPH_DIR) { $ExpectedGraphDir = $env:ANDROBYTE_EXPECTED_GRAPH_DIR }
if ($env:ANDROBYTE_EXPECTED_METRICS)   { $ExpectedMetrics  = $env:ANDROBYTE_EXPECTED_METRICS }
if ($env:ANDROBYTE_CONFIG_PATH)        { $ConfigPath       = $env:ANDROBYTE_CONFIG_PATH }
if ($env:ANDROBYTE_DEMO_APK)           { $DemoApkName      = $env:ANDROBYTE_DEMO_APK }

# 0) Ensure repo root
if (Test-Path ".\run_pipeline.py") { }
elseif (Test-Path "..\..\run_pipeline.py") { Set-Location ..\.. }
else { throw "[claim2] Could not locate run_pipeline.py. Run from repo root or claims\claim2." }

# 1) Install
if (Test-Path ".\install.ps1") {
  Log "Running install.ps1 ..."
  ./install.ps1
} elseif (Test-Path ".\install.sh") {
  Log "install.ps1 not found; if using WSL/Git Bash, run install.sh there."
  throw
} else { throw "No installer found (install.ps1/install.sh)." }

# 2) Outputs dir
New-Item -ItemType Directory -Force -Path outputs | Out-Null
if (-not (Test-Path "outputs\.gitkeep")) { New-Item -ItemType File -Path "outputs\.gitkeep" | Out-Null }

# 3) Demo APK presence check
$apkPath = "APKs\${DemoApkName}.apk"
if (-not (Test-Path $apkPath)) { throw "[claim2] Missing $apkPath" }

# 4) Run pipeline with required --config / --apk_name
function Run-One($apkName){
  Log "Running pipeline on $apkName ..."
  $ok = $false
  try {
    python run_pipeline.py --config $ConfigPath --apk_name $apkName
    $ok = $true
  } catch {
    try {
      Log "Fallback: python run_pipeline.py --config $ConfigPath"
      python run_pipeline.py --config $ConfigPath
      $ok = $true
    } catch {
      Log "Fallback: python run_pipeline.py (last resort)"
      python run_pipeline.py
      $ok = $true
    }
  }
  if (-not $ok) { throw "[claim2] Pipeline failed for $apkName" }
}

Run-One $DemoApkName

# 5) Locate generated graph visualization (PNG)
$graphImg = "outputs\$DemoApkName\output\visited_graph.png"
if (Test-Path $graphImg) {
  Log "Call graph visualization generated: $graphImg"
} else {
  throw "[claim2] Expected call graph image not found at $graphImg"
}


# 7) Metrics summary (precomputed, optional)
$met = $ExpectedMetrics
if (Test-Path $met) {
  Log "Metrics summary found (precomputed): $met"
  $env:CLAIM2_MET = (Resolve-Path $met).Path

  $py_metrics = @'
import json, os
p = os.environ.get("CLAIM2_MET")
with open(p, "r", encoding="utf-8") as f:
    m = json.load(f)
for k in ("precision","recall","f1","num_apps","true_positives","false_positives","false_negatives"):
    if k in m:
        print(f"[claim2] {k}: {m[k]}")
'@
  $tmpMetrics = New-TemporaryFile
  Set-Content -Path $tmpMetrics -Value $py_metrics -Encoding UTF8
  python $tmpMetrics
  Remove-Item $tmpMetrics -ErrorAction SilentlyContinue
}

Log "Claim 2 (RQ2) demo run complete."
