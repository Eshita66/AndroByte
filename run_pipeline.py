# AndroByteTool/run_pipeline.py

import os
import argparse
import json
os.environ.setdefault("ANDROGUARD_LOG_LEVEL", "ERROR")
from parser.apk_parser import process_apk

def load_settings(config_path: str):
    with open(config_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def run_pipeline(config_path: str, apk_name: str | None = None, run_all: bool = False):
    # Make config visible to summarizer
    os.environ["CONFIG"] = config_path
    from summarizer.llm_summarizer import main as summarizer_main

    settings = load_settings(config_path)
    apk_folder   = settings.get("apk_folder", "APKs")
    output_base  = settings.get("output_base", "outputs")

    failed_apks, empty_apks = [], []

    if run_all:
        # Iterate over every .apk in apk_folder
        for file in os.listdir(apk_folder):
            if file.endswith(".apk"):
                apk_name = os.path.splitext(file)[0]
                apk_path = os.path.join(apk_folder, file)
                print(f"\n[Batch mode] Processing {apk_name}")
                process_apk(apk_path, output_base, failed_apks, empty_apks)
                summarizer_main(target_apk=apk_name)
    else:
        if not apk_name:
            raise ValueError("You must provide --apk_name in per-APK mode.")

        apk_path = os.path.join(apk_folder, apk_name + ".apk")
        if not os.path.isfile(apk_path):
            raise FileNotFoundError(f"APK not found: {apk_path}")

        print(f"\n[Per-APK mode] Processing {apk_name}")
        process_apk(apk_path, output_base, failed_apks, empty_apks)
        summarizer_main(target_apk=apk_name)

    # Report
    print("\n=== Summary Report ===")
    if failed_apks:
        print(f"APKs that failed to process ({len(failed_apks)}):")
        for apk in failed_apks:
            print(f"   - {apk}")
    else:
        print("No APK failed to process.")

    if empty_apks:
        print(f"APKs with no bytecode extracted ({len(empty_apks)}):")
        for apk in empty_apks:
            print(f"   - {apk}")
    else:
        print("All APKs had extracted bytecode.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run the full AndroByteTool pipeline.")
    parser.add_argument("--config", required=True, help="Path to the settings JSON file.")
    parser.add_argument("--apk_name", help="Name of the APK (without extension). Required in per-APK mode.")
    parser.add_argument("--all", action="store_true", help="Process all APKs in apk_folder (batch mode).")

    args = parser.parse_args()
    run_pipeline(args.config, apk_name=args.apk_name, run_all=args.all)
