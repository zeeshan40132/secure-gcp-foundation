
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "policy" / "check_terraform.py"
FIXTURE = ROOT / "policy" / "tests" / "fixtures"

def run_checker(target):
    return subprocess.run(
        [sys.executable, str(CHECKER), str(target)],
        capture_output=True,
        text=True,
    )

def main():
    print("Testing actual infrastructure...")
    real_result = run_checker(ROOT / "infra")
    print(real_result.stdout)

    if real_result.returncode != 0:
        print("FAIL: Actual infrastructure did not pass.")
        sys.exit(1)

    print("Testing intentionally insecure fixture...")
    fixture_result = run_checker(FIXTURE)
    print(fixture_result.stdout)

    if fixture_result.returncode == 0:
        print("FAIL: Insecure fixture unexpectedly passed.")
        sys.exit(1)

    expected_failures = [
        "Service account keys",
        "Mandatory resource labels",
        "Primitive IAM roles",
        "Public IAM principals",
        "Firewall ingress restrictions",
    ]

    missing = [
        name for name in expected_failures
        if f"[FAIL] {name}" not in fixture_result.stdout
    ]

    if missing:
        print(f"FAIL: Expected violations not detected: {missing}")
        sys.exit(1)

    if "[PASS] WIF trust condition" not in fixture_result.stdout:
        print("FAIL: Valid WIF configuration did not pass.")
        sys.exit(1)

    print("SUCCESS: All custom policy tests behaved as expected.")

if __name__ == "__main__":
    main()
