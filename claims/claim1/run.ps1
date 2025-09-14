#Requires -Version 5
$ErrorActionPreference = "Stop"
function Log($m){ Write-Host "`n[claim1] $m" }

# ==== Configuration path ====
$ExpectedRoot    = "claims\claim1\expected"
$ExpectedLeakDir = Join-Path $ExpectedRoot "reports"
$ExpectedMetrics = Join-Path $ExpectedRoot "metrics_summary.json"
$ExpectedLeakRef = Join-Path $ExpectedLeakDir "clone1_sensitive_only.json"

# ===pipeline config & demo APK  ====
$ConfigPath   = "configs\settings.json"    
$DemoApkName1 = "Clone1"                   #  APKs\Clone1.apk
$DemoApkName2 = "field"                   # optional second demo

# Allow override via environment variables (optional)
if ($env:ANDROBYTE_EXPECTED_ROOT)     { $ExpectedRoot    = $env:ANDROBYTE_EXPECTED_ROOT }
if ($env:ANDROBYTE_EXPECTED_LEAK_DIR) { $ExpectedLeakDir = $env:ANDROBYTE_EXPECTED_LEAK_DIR }
if ($env:ANDROBYTE_EXPECTED_METRICS)  { $ExpectedMetrics = $env:ANDROBYTE_EXPECTED_METRICS }
if ($env:ANDROBYTE_EXPECTED_LEAK_REF) { $ExpectedLeakRef = $env:ANDROBYTE_EXPECTED_LEAK_REF }
if ($env:ANDROBYTE_CONFIG_PATH)       { $ConfigPath      = $env:ANDROBYTE_CONFIG_PATH }
if ($env:ANDROBYTE_DEMO_APK1)         { $DemoApkName1    = $env:ANDROBYTE_DEMO_APK1 }
if ($env:ANDROBYTE_DEMO_APK2)         { $DemoApkName2    = $env:ANDROBYTE_DEMO_APK2 }

# 0) Ensure repo root
if (Test-Path ".\run_pipeline.py") { }
elseif (Test-Path "..\..\run_pipeline.py") { Set-Location ..\.. }
else { throw "[claim1] Could not locate run_pipeline.py. Run from repo root or claims\claim1." }

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

# 3) Demo APKs presence checks
$apk1Path = "APKs\${DemoApkName1}.apk"
$apk2Path = "APKs\${DemoApkName2}.apk"
if (-not (Test-Path $apk1Path)) { throw "[claim1] Missing $apk1Path" }
if (-not (Test-Path $apk2Path)) { Log "Optional $apk2Path not found (will run only one demo)." }

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
  if (-not $ok) { throw "[claim1] Pipeline failed for $apkName" }
}

Run-One $DemoApkName1
if (Test-Path $apk2Path) { Run-One $DemoApkName2 }

# 5) Prefer sensitive_only.json; if missing/empty, fall back to other JSONs
Log "Searching for leak reports under outputs\${DemoApkName1}\ ..."
$sensOnly = Get-ChildItem -Path ("outputs\" + $DemoApkName1) -Recurse -Include *sensitive_only*.json -ErrorAction SilentlyContinue | Select-Object -First 1
if ($sensOnly -and $sensOnly.Length -gt 0) {
  $found = $sensOnly
} else {
  if ($sensOnly -and $sensOnly.Length -le 0) {
    Log "Found sensitive_only.json but it is empty (no sensitive subgraphs)."
  } else {
    Log "No sensitive_only.json found; falling back to other JSONs (schema may differ)."
  }
  $found = Get-ChildItem -Path ("outputs\" + $DemoApkName1) -Recurse -Include *sensitive_calls*.json, *leak*.json, *summary*.json -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $found) {
    $found = Get-ChildItem -Path outputs -Recurse -Include *sensitive_only*.json, *sensitive_calls*.json, *leak*.json, *summary*.json -ErrorAction SilentlyContinue | Select-Object -First 1
  }
}

if (-not $found) { throw "[claim1] No JSON files found under outputs/." }
if ($found.Length -le 0) { throw "[claim1] Found JSON is empty: $($found.FullName)" }

Log "Validating JSON structure: $($found.FullName)"
$env:CLAIM1_JSON = $found.FullName
$py_validate = @'
import json, os
p = os.environ.get('CLAIM1_JSON')
with open(p, 'r', encoding='utf-8') as f:
    obj = json.load(f)
print('[claim1] JSON parsed OK. Type:', type(obj).__name__)
'@
python -c $py_validate

# 6) Expected samples presence
$expDir = $ExpectedLeakDir
if (Test-Path $expDir) {
  Log "Expected leak reports present in $expDir (manual/visual diff encouraged)."
} else {
  Log "No expected leak reports directory ($expDir); skip comparison."
}


# 7) Metrics summary
$met = $ExpectedMetrics
if (Test-Path $met) {
  Log "Metrics summary found (full benchmark, precomputed): $met"
  $env:CLAIM1_MET = (Resolve-Path $met).Path

  $py_metrics = @'
import json, os
p = os.environ.get("CLAIM1_MET")
with open(p, "r", encoding="utf-8") as f:
    m = json.load(f)
for k in ("precision","recall","f1","f1_score","f1_micro","f1_macro","num_apps","true_positives","false_positives","false_negatives"):
    if k in m:
        print(f"[claim1] {k}: {m[k]}")
'@
  $tmpMetrics = New-TemporaryFile
  Set-Content -Path $tmpMetrics -Value $py_metrics -Encoding UTF8
  python $tmpMetrics
  Remove-Item $tmpMetrics -ErrorAction SilentlyContinue
}
Log "Claim 1 demo run complete."
