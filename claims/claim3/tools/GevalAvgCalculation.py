import os
import json
import math
import statistics
from glob import glob

# === CONFIG ===

results_folder = r"D:\ACSEC_Artifacts\RQ3\UCBench"
output_aggregated_json = r"d:\ACSEC_Artifacts\RQ3\UCBenchResult\aggregated_UC_results.json"
# once for Droidbench and once for UCBench
# results_folder= r"path of Droidbench"
# output_aggregated_json = r"Path of output file .json"

# Define  metrics to compute from "evaluation" and "g_eval_scores"
evaluation_metrics = [
    "data_type_identification",
    "data_propagation_accuracy",
    "sink_function_match",
    "leakage_inference",
    "coherence_and_fluency"
]

g_eval_metrics = [
    "coherence",
    "consistency",
    "relevance",
    "fluency"
]

def safe_get(d, key, default=0):
    """Returns d[key] if it exists, otherwise default."""
    return d[key] if key in d else default

# 1) Load All JSON Files ===
# For example, "evaluation_results_run1.json", "evaluation_results_run2.json", ...
json_files = glob(os.path.join(results_folder, "droidbench*.json"))
#json_files = glob(os.path.join(results_folder, "ucBench*.json"))
json_files.sort()

all_runs_data = []  

for fpath in json_files:
    with open(fpath, "r", encoding="utf-8") as f:
        data = json.load(f)
        all_runs_data.append(data)

print(f"Found {len(all_runs_data)} runs in {results_folder}")

# 2) Collect Scores Per APK Per Run 
# Structure: aggregated[apk_name]["evaluation" or "g_eval_scores"][metric] = [list of run values]
aggregated = {}

for run_index, run_data in enumerate(all_runs_data):
    for apk_name, apk_result in run_data.items():
        if apk_name not in aggregated:
            aggregated[apk_name] = {
                "apk_name": apk_name,
                "evaluation_runs": {m: [] for m in evaluation_metrics},
                "g_eval_runs": {m: [] for m in g_eval_metrics}
            }

        # Extract evaluation metrics
        evaluation = apk_result.get("evaluation", {})
        for m in evaluation_metrics:
            aggregated[apk_name]["evaluation_runs"][m].append(safe_get(evaluation, m, 0))

        # Extract G-Eval metrics
        g_eval = apk_result.get("g_eval_scores", {})
        for m in g_eval_metrics:
            aggregated[apk_name]["g_eval_runs"][m].append(safe_get(g_eval, m, 0))

# 3) Compute Mean & Std for Each APK


for apk_name, apk_data in aggregated.items():
    apk_data["evaluation_mean"] = {}
    apk_data["evaluation_std"] = {}
    apk_data["g_eval_mean"] = {}
    apk_data["g_eval_std"] = {}

    # Compute stats for evaluation metrics
    for m in evaluation_metrics:
        values = apk_data["evaluation_runs"][m]
        if values:
            apk_data["evaluation_mean"][m] = statistics.mean(values)
            apk_data["evaluation_std"][m]  = statistics.pstdev(values) if len(values) > 1 else 0.0
        else:
            apk_data["evaluation_mean"][m] = 0.0
            apk_data["evaluation_std"][m]  = 0.0

    # Compute stats for g_eval metrics
    for m in g_eval_metrics:
        values = apk_data["g_eval_runs"][m]
        if values:
            apk_data["g_eval_mean"][m] = statistics.mean(values)
            apk_data["g_eval_std"][m]  = statistics.pstdev(values) if len(values) > 1 else 0.0
        else:
            apk_data["g_eval_mean"][m] = 0.0
            apk_data["g_eval_std"][m]  = 0.0

# 4) Compute Overall Averages Across All APKs
# Stored "overall_evaluation_mean/std" and "overall_g_eval_mean/std"

all_evaluation_values = {m: [] for m in evaluation_metrics}
all_g_eval_values     = {m: [] for m in g_eval_metrics}

for apk_name, apk_data in aggregated.items():
    for m in evaluation_metrics:
        all_evaluation_values[m].append(apk_data["evaluation_mean"][m])
    for m in g_eval_metrics:
        all_g_eval_values[m].append(apk_data["g_eval_mean"][m])

overall = {
    "evaluation_mean": {},
    "evaluation_std": {},
    "g_eval_mean": {},
    "g_eval_std": {}
}

for m in evaluation_metrics:
    vals = all_evaluation_values[m]
    if vals:
        overall["evaluation_mean"][m] = statistics.mean(vals)
        overall["evaluation_std"][m]  = statistics.pstdev(vals) if len(vals) > 1 else 0.0
    else:
        overall["evaluation_mean"][m] = 0.0
        overall["evaluation_std"][m]  = 0.0

for m in g_eval_metrics:
    vals = all_g_eval_values[m]
    if vals:
        overall["g_eval_mean"][m] = statistics.mean(vals)
        overall["g_eval_std"][m]  = statistics.pstdev(vals) if len(vals) > 1 else 0.0
    else:
        overall["g_eval_mean"][m] = 0.0
        overall["g_eval_std"][m]  = 0.0

# 5) Save Aggregated Output
output_data = {
    "apks": aggregated,
    "overall": overall
}

with open(output_aggregated_json, "w", encoding="utf-8") as f:
    json.dump(output_data, f, indent=2)

print(f"\n Aggregation complete. Saved to {output_aggregated_json}")
print("Overall Averages:")
print(json.dumps(overall, indent=2))


