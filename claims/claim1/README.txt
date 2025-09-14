Claim 1 — Leak Detection Accuracy

Claim: AndroByte can accurately detect privacy leaks in Android applications without relying on predefined sink lists.
Paper Mapping: Section 5.2.1 (RQ1 — Leak Detection Accuracy), Table 3.

What this script does:
Running Claim 1 executes the AndroByte pipeline on a small demo subset of DroidBench/UBCBench. It produces summary under outputs/ for manual inspection and comparison with the paper’s Table 3.


Execution Guideline: 
Linux/macOs:
cd /path/to/AndroByte
chmod +x claims/claim1/run.sh
./claims/claim1/run.sh


windows(Powershell):
cd \path\to\AndroByte
.\venv\Scripts\Activate.ps1
.\claims\claim1\run.ps1


Expected Outputs: 
After a successful run, you should see:
outputs/<APK_NAME>/*refined_method_summaries*.json — per-app summary artifacts
outputs/<APK_NAME>/*sensitive_only*.json (if any) — sensitive subgraphs/leak reports


Manual Inspection: 
To verify correctness, compare the generated outputs against the expected reference files located under:
/claims/claim1/expected

Reports: 
claims/claim1/expected/reports/Clone1_sensitive_only.json
This file contains the expected dataflow report for the demo app Clone1.
After running the pipeline, open the generated JSON files under:
outputs/Clone1/
 
Benchmark Metrics Summary:
claims/claim1/expected/metrics_summary.json provides precomputed metrics (precision, recall, F1-score, etc.) for the full benchmark set (DroidBench and UBCBench) 
These correspond to the results reported in Table 3 (Section 5.2.1) of the paper.





