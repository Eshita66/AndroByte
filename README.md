# AndroByteTool: Android Privacy Analysis Framework

**AndroByteTool** is a static analysis tool designed to extract sensitive API call paths and summarize user data flow from Android APKs using bytecode-level analysis combined with LLM-based reasoning.

## Project Structure
```text
AndroByteTool/
├── run_pipeline.py              # Main entry point
├── parser/
│   └── apk_parser.py            # APK parsing and extracts bytecode instructions
├── summarizer/
│   └── llm_summarizer.py        # Summarization module + Ollama API + helper functions
├── resources/
│   └── API.json                 # JSON list of sensitive API signatures
├── outputs/
│   └── <apk_name>/              # Output per APK


## ⚠️ Ollama Installation (Required)

This artifact uses [Ollama](https://ollama.com/download) to run local LLMs.

Please install Ollama for your platform.
**Run the following commands in your system terminal (Terminal on macOS/Linux, PowerShell on Windows).**

For macOS:  
Download and run the installer from Ollama for MacOS


For Linux:
curl -fsSL https://ollama.com/install.sh | sh

For Windows:
Download and run the installer from Ollama for Windows
.After installation, ensure ollama is on your PATH:

ollama --version

Finally pull the required model

ollama run gemma3

check the model is installed in your system

ollama list 


Step1: Open a terminal in the project root (bash/zsh on Linux/macOS, PowerShell on Windows)
make scripts executable & clean env
For Linux/macOS
  chmod +x install.sh
  rm -rf venv

Step 2: Create new Virtual Environment and activate
  python3 -m venv venv
  source venv/bin/activate

Step3: Install dependencies 
  ./install.sh

Step 3. Run pipeline on a sample APK (per-APK mode, primary)
We provide a small demo APK (ArrayAccess1.apk) in the APKs/ folder.

python run_pipeline.py  --config configs/settings.json --apk_name <apk_filename_without_extension>

Excample:
  python run_pipeline.py --config configs/settings.json --apk_name ArrayAccess1

Step 4. Verify outputs

outputs/ArrayAccess1/
  ├─ ArrayAccess1_bytecode_instructions.json
  └─ output/
       ├─ method_summaries.json
       ├─ refined_method_summaries.json
       ├─ sensitive_calls.json
       ├─ sensitive_only.json
       ├─ visited_graph.png
       └─ console_output.txt


For Quick validation:

cat outputs/ArrayAccess1/output/sensitive_only.json
Step 5. (Optional) Run batch mode

python run_pipeline.py --config configs/settings.json --all

---

## Outputs
Each APK folder under `outputs/` will contain:

- `method_summaries.json` — summaries of each method 
- `refined_method_summaries.json` — summaries of each subgraph
- `sensitive_only.json` — subgraphs labeled as leak
- `visited_graph.png` — graph of analyzed paths
- `console_output.txt` — logs for debugging

---

## Notes
- Supports large context windows via chunked instruction summarization.

---

## Contact
For issues or feature requests, please reach out to the tool maintainer or contribute via GitHub.

Note: Since this tool uses LLMs, outputs may vary slightly between runs, though core detection of sensitive API flows remains consistent.
