##GEval runned 10 times 
import json
import os
import re
from dotenv import load_dotenv
from openai import OpenAI

#  CONFIG
#json_path = r"D:\AndroByteUpdate\claims\claim3\expected\update_evaluation_dataset_cleaned.json"
#output_eval_path = r"D:\AndroByteUpdate\claims\claim3\expected\running_result\evaluation_results10.json"
# Base directory = the folder containing this script (claims/claim3/tools)
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "expected"))
json_path = os.path.join(BASE_DIR, "update_evaluation_dataset_cleaned.json")

# Create a subfolder "running_result" inside expected/ if it doesn't exist
output_dir = os.path.join(BASE_DIR, "running_result")
os.makedirs(output_dir, exist_ok=True)

output_eval_path = os.path.join(output_dir, "evaluation_results10.json")
OPENAI_API_KEY = "OPENAPI_KEY is needed"
# Load API Key from .env file
#load_dotenv("C:\\Eshita\\vs_project\\After\\AndroByte_13March2025\\AndrowithoutCallOpenAI\\api.env")
#api_key = os.getenv("OPENAI_API_KEY")
api_key =  OPENAI_API_KEY 
if not api_key:
    raise ValueError("API key not found in environment variables.")

client = OpenAI(api_key=api_key)

# Load Evaluation Dataset
with open(json_path, "r", encoding="utf-8") as f:
    evaluation_data = json.load(f)

# Container for results
results = {}

# Function to enforce or extract JSON
def extract_json_gently(raw_text: str) -> dict:
    """
    Attempt to parse JSON from raw_text.
    1) Try direct json.loads() if raw_text is purely JSON.
    2) If that fails, look for a fenced code block with JSON via regex.
    3) If that also fails, return {}.
    """
    raw_text = raw_text.strip()
    # Try direct parse
    try:
        return json.loads(raw_text)
    except json.JSONDecodeError:
        pass

    #  Attempt extracting a code block: ```json ... ```
    code_block_match = re.search(r"```json\s*(\{[\s\S]+?\})\s*```", raw_text)
    if code_block_match:
        possible_json = code_block_match.group(1).strip()
        try:
            return json.loads(possible_json)
        except json.JSONDecodeError:
            pass

    #  As a fallback, attempt to parse from first '{' to last '}'.
    first_brace = raw_text.find('{')
    last_brace = raw_text.rfind('}')
    if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
        possible_json = raw_text[first_brace:last_brace + 1].strip()
        try:
            return json.loads(possible_json)
        except json.JSONDecodeError:
            pass

    return {}

# Loop through each APK entry
for apk_name, data in evaluation_data.items():
    ground_truth_summary = data["ground_truth_summary"]
    model_output = data["model_summary"]

    
    prompt = f"""
You are a forensic AI evaluator assessing a model-generated summary of an apk file data leakage analysis.

Below are:
- Ground Truth Summary: The result of manual expert analysis.
- Model Output: The output from a language model.

Your evaluation should focus on **structured forensic accuracy**. Do not penalize the model for providing more detail if it is **factually aligned**.

### Evaluation Dimensions (score each 1–5):
1. **Data Type Identification** – Does the model correctly identify sensitive data types (e.g., deviceId)?
2. **Data Propagation Accuracy** – Is the data movement (source → transformation → sink) accurately described?
    - The ground truth summary may be brief or underspecified (e.g., "source -> data -> sink"). 
    - If the model provides **additional correct details** (e.g., intermediate steps, method calls) that logically match or expand on the ground truth, do **not** penalize it for being more specific.
    - Only penalize if the model’s data flow contradicts or incorrectly adds steps not implied by the ground truth.

3. **Sink Function Match** – Does the model correctly identify the final sink(s) or sink method(s)? 
    - Note that the model might use bytecode notation (e.g., `android/util/Log;->d:...`) whereas the ground truth might be in Java style (`Log.d(...)`). These should be considered the **same function**. 
   - Do not penalize the model if it uses different naming conventions, as long as the function is clearly the same in essence.
4. **Leakage Inference** – Does the model correctly determine whether sensitive data is leaked?
5. **Coherence & Fluency** – Is the output clear, logical, and grammatically fluent?
Please consider bytecode vs. Java method references as equivalent if they refer to the same underlying API call. 


---
Ground Truth Summary (JSON only, no explanation):
{json.dumps(ground_truth_summary)}

---
Model Output (JSON only, no explanation):
{json.dumps(model_output)}

---
Please respond **with valid JSON only** and no additional explanations, using this exact schema:
{{
  "data_type_identification": <integer 1-5>,
  "data_propagation_accuracy": <integer 1-5>,
  "sink_function_match": <integer 1-5>,
  "leakage_inference": <integer 1-5>,
  "coherence_and_fluency": <integer 1-5>
}}
"""

    # Run GPT-4o evaluation
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You are a professional evaluator for digital forensics and LLM outputs. Return JSON only."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.2
    )

    # Extract raw text from GPT
    raw_response = response.choices[0].message.content.strip()
    print(f"\n {apk_name} - GPT-4o Raw Output:")
    print(raw_response)

    # Attempt to parse JSON safely
    eval_json = extract_json_gently(raw_response)
    if not eval_json:
        print(f"Could not parse valid JSON for {apk_name}. Storing empty evaluation.")
        continue

    # G-Eval Mapping
    data_type = eval_json.get("data_type_identification", 0)
    data_prop = eval_json.get("data_propagation_accuracy", 0)
    sink_match = eval_json.get("sink_function_match", 0)
    leak_inf  = eval_json.get("leakage_inference", 0)
    co_flu    = eval_json.get("coherence_and_fluency", 0)

    g_eval_scores = {
        "coherence": co_flu,
        "consistency": round((data_type + data_prop + leak_inf) / 3),
        "relevance": round((data_prop + sink_match) / 2),
        "fluency": co_flu
    }

    results[apk_name] = {
        "apk_name": apk_name,
        "evaluation": eval_json,
        "g_eval_scores": g_eval_scores
    }

# Save results to file
with open(output_eval_path, "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)

print(f"\n Saved all evaluations to: {output_eval_path}")
