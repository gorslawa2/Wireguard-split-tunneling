#!/usr/bin/env python3
"""
Verification script for Russian DevOps Mentor subagent configuration.
Checks that all required files exist and validates basic structure.
"""

import json
import os
import sys
from pathlib import Path

# Set stdout to UTF-8
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

def check_file_exists(filepath):
    """Check if a file exists."""
    if os.path.exists(filepath):
        print(f"[OK] {filepath}")
        return True
    else:
        print(f"[FAIL] {filepath} - MISSING")
        return False

def validate_json(filepath):
    """Validate JSON file structure."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Check required fields
        required_fields = ['agent', 'internal_process', 'output_rules', 'goal']
        missing = [field for field in required_fields if field not in data]
        
        if missing:
            print(f"[WARN] Missing fields in {filepath}: {missing}")
            return False
        
        print(f"[OK] {filepath} - Valid JSON structure")
        return True
    except json.JSONDecodeError as e:
        print(f"[FAIL] {filepath} - Invalid JSON: {e}")
        return False
    except Exception as e:
        print(f"[FAIL] {filepath} - Error: {e}")
        return False

def check_file_size(filepath, min_size=100):
    """Check if file has reasonable size."""
    size = os.path.getsize(filepath)
    if size >= min_size:
        print(f"[OK] {filepath} - {size} bytes")
        return True
    else:
        print(f"[WARN] {filepath} - Only {size} bytes (expected >{min_size})")
        return False

def main():
    base_path = Path(__file__).parent
    
    print("=" * 60)
    print("Russian DevOps Mentor - Configuration Verification")
    print("=" * 60)
    print()
    
    # Check required files
    print("Checking required files...")
    files_to_check = [
        base_path / "agent-config.json",
        base_path / "system-prompt.md",
        base_path / "README.md",
        base_path / "QUICKSTART.md",
        base_path / "examples" / "interaction-examples.md",
    ]
    
    all_exist = all(check_file_exists(f) for f in files_to_check)
    print()
    
    if not all_exist:
        print("[FAIL] Some required files are missing!")
        return False
    
    # Validate JSON configuration
    print("Validating configuration...")
    config_valid = validate_json(base_path / "agent-config.json")
    print()
    
    # Check file sizes
    print("Checking file sizes...")
    size_checks = [
        (base_path / "system-prompt.md", 1000),
        (base_path / "README.md", 500),
        (base_path / "QUICKSTART.md", 500),
    ]
    
    all_sized = all(check_file_size(f, s) for f, s in size_checks)
    print()
    
    # Summary
    print("=" * 60)
    if all_exist and config_valid and all_sized:
        print("[SUCCESS] All checks passed! Configuration is ready.")
        print()
        print("Next steps:")
        print("1. Review system-prompt.md")
        print("2. Test with example queries from examples/")
        print("3. Integrate with your LLM platform")
        return True
    else:
        print("[WARN] Some checks failed. Please review the issues above.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
