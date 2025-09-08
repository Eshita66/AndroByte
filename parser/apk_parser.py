
import os
import json
from pathlib import Path
from androguard.misc import AnalyzeAPK

os.environ["ANDROGUARD_LOG_LEVEL"] = "ERROR" 
try:
    from loguru import logger
    # Remove default Loguru sink and re-add at ERROR level
    logger.remove()
    logger.add(sys.stderr, level="ERROR")
except Exception:
    pass
# --- Settings loader ---
REPO_ROOT = Path(__file__).resolve().parents[1]

def load_settings(config_file=None):
    """
    Load settings.json from path or default to configs/settings.json.
    """
    config_file = config_file or os.getenv("CONFIG", "configs/settings.json")
    settings_path = (REPO_ROOT / config_file).resolve()
    with settings_path.open("r", encoding="utf-8") as f:
        return json.load(f)

SETTINGS = load_settings()

APK_FOLDER = SETTINGS.get("apk_folder", "APKs")
OUTPUT_FOLDER = SETTINGS.get("output_base", "outputs")

# APK_FOLDER = r"D:\Testapk"
# OUTPUT_FOLDER = r"D:\UBCBAPK_Methods"


# External libraries to exclude
EXTERNAL_LIBS = [
    "android/", "androidx/", "kotlin/", "kotlinx/"
    #"java/", "javax/"
    # "com/google/", "io/reactivex/", "org/apache/", "okio/", "org/slf4j/",
    # "com/facebook/", "com/crashlytics/", "dagger/", "retrofit/", "volley/"
]

# Libraries to include even if they match blacklist
ALLOWED_LIBS = [
   # "android/location/", "android/telecom/", "android/telephony/TelephonyManager;",
   #"android/provider/Settings$Secure;", "android/os/Build;"
]

def setup_output_folder(path):
    """Ensure the output folder exists."""
    os.makedirs(path, exist_ok=True)

def list_apk_files(apk_folder):
    """List all APK files in the specified folder."""
    return [f for f in os.listdir(apk_folder) if f.endswith('.apk')]

def is_external_library(method_class_name):
    """Determine if a method belongs to an external library."""
    if any(allowed in method_class_name for allowed in ALLOWED_LIBS):
        return False  
    return any(external in method_class_name for external in EXTERNAL_LIBS)

def method_signature(method):
    """Generate a unique signature for a method."""
    return f"{method.get_class_name()}->{method.get_name()}:{method.get_descriptor()}"


#bytecode instructionextrcation
def extract_bytecode(dx):
    """Extract bytecode instructions for each method with node_id starting from 0."""
    bytecode_data = {}
    node_id = 0  

    for method_analysis in dx.get_methods():
        method = method_analysis.get_method()

        class_name = method.get_class_name()
        if "R$" in class_name or "R;" in class_name:
            continue
        if method_analysis.is_external() or is_external_library(method.get_class_name()):
            continue
        sig = method_signature(method)

        # Extract bytecode instructions
        instructions = []
        if method.get_code():
            instructions = [f"{ins.get_name()} {ins.get_output()}" 
                            for ins in method.get_code().get_bc().get_instructions()]
        if instructions:
            bytecode_data[sig] = {
                "node_id": node_id, 
                "method_signature": sig,
                "instructions": instructions
            }
            node_id += 1  

    return bytecode_data


def save_to_json(data, output_path):
    """Save data to a JSON file."""
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)

def process_apk(apk_path, output_folder, failed_apks, empty_apks):
    """Analyze the APK and extract bytecode instructions."""
    apk_name = os.path.splitext(os.path.basename(apk_path))[0]
    #print(f"Analyzing APK: {apk_name}")
    print(f"[Per-APK] Analyzing: {apk_name}")
    print(f"[Bytecode] Collecting bytecode instructions...") 

    try:
        a, d, dx = AnalyzeAPK(apk_path)
        bytecode_data = extract_bytecode(dx)

        if not bytecode_data:
            print(f"No bytecode instructions extracted for: {apk_name}")
            empty_apks.append(apk_name)
            return  

        apk_output_folder = os.path.join(output_folder, apk_name)
        os.makedirs(apk_output_folder, exist_ok=True)

        bytecode_output_path = os.path.join(apk_output_folder, f"{apk_name}_bytecode_instructions.json")
        save_to_json(bytecode_data, bytecode_output_path)
        print(f"Bytecode instructions saved to {bytecode_output_path}")

    except Exception as e:
        print(f"Failed to process {apk_name}: {e}")
        failed_apks.append(apk_name)

def main():
    """Main execution flow."""
    setup_output_folder(OUTPUT_FOLDER)

    apk_files = list_apk_files(APK_FOLDER)

    if not apk_files:
        print("No APK files found in the folder.")
        return

    failed_apks = []
    empty_apks = []

    for apk_file in apk_files:
        apk_path = os.path.join(APK_FOLDER, apk_file)
        process_apk(apk_path, OUTPUT_FOLDER, failed_apks, empty_apks)

    print("\n=== Summary Report ===")
    if failed_apks:
        print(f"APKs that failed to process ({len(failed_apks)}):")
        for apk in failed_apks:
            print(f"   - {apk}")
    else:
        print("No APK failed to process.")

    if empty_apks:
        print(f"\nAPKs with no bytecode extracted ({len(empty_apks)}):")
        for apk in empty_apks:
            print(f"   - {apk}")
    else:
        print("All APKs had extracted bytecode.")

    print("\n All APK files have been processed.")

# RUN 
if __name__ == "__main__":
    main()
