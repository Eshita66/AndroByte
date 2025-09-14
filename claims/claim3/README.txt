Claim 3 — Explainability (RQ3)

Claim: AndroByte produces structured, natural language summaries of privacy data flows that align with expert ground truth, as measured using G-Eval.

Paper Mapping: Section 5.2.3 (RQ3 – Explainability), Table 5.

What this script does:
This evaluation checks whether AndroByte’s generated method summaries are align with ground-truth summaries.

Inputs:

update_evaluation_dataset_cleaned.json — contains pairs of ground truth summaries (manual expert annotation) and model summaries (AndroByte output).

Process:

Each pair is sent to GPT-4 for scoring along 5 forensic dimensions:

Data Type Identification, Data Propagation Accuracy, Sink Function Match, Leakage Inference, Coherence & Fluency

The script enforces JSON-only scoring output.

This procedure is repeated 10 times to reduce variance.

Outputs:

Per-APK evaluation JSON with raw scores and aggregated G-Eval metrics (coherence, consistency, relevance, fluency).

Example output file:
\claims\claim3\expected\running_result\evaluation_results10.json
Requirement:
To run below file File OPEN_API Key is required as we use GEval framework

Execution Guidelines
Linux / macOS
cd /path/to/AndroByte
pip install -r requirements-claim3.txt
python claims/claim3/tools/Gevaluation.py

Windows
cd \path\to\AndroByte
.\venv\Scripts\Activate.ps1
pip install -r requirements-claim3.txt
python claims\claim3\tools\Gevaluation.py

For Manual Verification


Open the reference demo summary: claims/claim3/expected/demo_summaries/Clone1_summary.json
Compare it to the generated refined_method_summaries.json under: outputs/Clone1/output/refined_method_summaries.json
