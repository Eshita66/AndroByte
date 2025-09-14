# AndroByteTool: Android Privacy Analysis Framework

**AndroByteTool** is a static analysis tool designed to extract sensitive API call paths and summarize user data flow from Android APKs using bytecode-level analysis combined with LLM-based reasoning.
#### Requirements:
 ```text
Python 3.10–3.12
~8 GB RAM recommended
(Optional) Graphviz for graph images
Ollama for local LLMs (e.g., gemma3)
 ```
### Step1: Clone the Repository
     git clone https://github.com/<anonymous-or-real-link>/AndroByte.git
     cd AndroByte
### Step 2: Ollama Installation (Required)
This artifact uses [Ollama](https://ollama.com/download) to run local LLMs. Please install Ollama for your platform before running AndroByte.

#### For macOS (Bash/zsh in Terminal):  
Download and install the macOS package from the official Ollama site: [Download Ollama for macOS](https://ollama.com/download)

#### For Linux(run in Bash/zsh shell):
      curl -fsSL https://ollama.com/install.sh | sh
      
#### For Windows (PowerShell):
Download and run the installer from Ollama for Windows. [Download Ollama for Windows](https://ollama.com/download)
After installation, ensure ollama is on your PATH.
Check that Ollama is installed correctly using the command:
```bash
ollama --version
```  
Next, pull the required local Large Language Model (e.g., gemma3).
You can browse available models here:(https://ollama.com/search)

Run the following command to download and start the gemma3 model:
```bash
ollama run gemma3
```
Finally, verify that the model is installed on your system:
```bash
    ollama list
``` 
To exit, using command:
```bash
    /exit
```
### Step3: Install Dependencies:
#### Return to AndroByte folder
      cd AndroByte
**For Linux/macOS:**
  ##### Make install script executable and remove any old environment
  ```bash
      chmod +x install.sh
      rm -rf venv
   ```
  ##### Create and activate a new virtual environment
   
          python3 -m venv venv
          source venv/bin/activate
  
  ##### Install dependencies

        ./install.sh
   

**For Windows (PowerShell):**
#### Allow script execution and remove any old environment if it exists
 ```bash
   Set-ExecutionPolicy -Scope Process Bypass -Force
   Remove-Item -Recurse -Force venv -ErrorAction SilentlyContinue
 ```

####  Create and activate a new virtual environment
  ```bash
      python -m venv venv
      .\venv\Scripts\Activate.ps1
  ```
####  Install dependencies
   
          .\install.ps1
     
### Step 4: Run pipeline on a sample APK (per-APK mode)
We provide a small demo APK (Clone1.apk) in the APKs/ folder.
Run the pipeline as follows:

  python run_pipeline.py  --config configs/settings.json --apk_name <apk_filename_without_extension>
 
Excample Command:
 ```bash
       python run_pipeline.py --config configs/settings.json --apk_name Clone1
 ```
### Step 5. Verify outputs
After running the pipeline, results will be created under:
 ```text
outputs/Clone1/output
  ├─ Clone1_bytecode_instructions.json
  └─ output/
       ├─ method_summaries.json
       ├─ refined_method_summaries.json
       ├─ sensitive_calls.json
       ├─ sensitive_only.json
       ├─ visited_graph.png
  ```    
For Quick output validation using command:
cat outputs/Clone1/output/sensitive_only.json

### Step 6. (Optional) Run batch mode
You can analyze multiple APKs at once using batch mode.
 ```bash
 python run_pipeline.py --config configs/settings.json --all
 ```
Results for each APK will be stored separately under outputs/<apk_name>/output/.

---
#### Outputs
Each APK folder under `outputs/` will contain:

- `method_summaries.json` — summaries of each method 
- `refined_method_summaries.json` — summaries of each subgraph
- `sensitive_only.json` — subgraphs labeled as leak
- `visited_graph.png` — graph of analyzed paths

---


#### Contact
For issues or feature requests, please reach out to the tool maintainer or contribute via GitHub.



