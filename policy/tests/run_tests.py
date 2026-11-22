
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "policy" / "check_terraform.py"
FIXTURES = ROOT / "policy" / "tests" / "fixtures"
NEGATIVE = FIXTURES / "negative"

NEGATIVE_TESTS = {
    "missing-labels.tf": "Mandatory resource labels",
    "primitive-iam-role.tf": "Primitive IAM roles",
    "public-ssh.tf": "Firewall ingress restrictions",
    "service-account-key.tf": "Service account keys",
    "wif-no-condition.tf": "WIF trust condition",
}


def run_checker(target):
    return subprocess.run(
        [sys.executable, str(CHECKER), str(target)],
        capture_output=True,
        text=True,
    )


def main():
    print("1. Testing actual infrastructure...")
    real_result = run_checker(ROOT / "infra")
    print(real_result.stdout)

    if real_result.returncode != 0:
        print("FAIL: Actual infrastructure did not pass.")
        sys.exit(1)

    print("2. Testing individual negative fixtures...")

    for filename, expected_policy in NEGATIVE_TESTS.items():
        fixture = NEGATIVE / filename

        with tempfile.TemporaryDirectory() as temp:
            temp_dir = Path(temp)

            if filename == "wif-no-condition.tf":
                (temp_dir / "wif.tf").write_text(
                    fixture.read_text(encoding="utf-8"),
                    encoding="utf-8",
                )
            else:
                (temp_dir / filename).write_text(
                    fixture.read_text(encoding="utf-8"),
                    encoding="utf-8",
                )

                (temp_dir / "wif.tf").write_text(
                    (FIXTURES / "wif.tf").read_text(encoding="utf-8"),
                    encoding="utf-8",
                )

            result = run_checker(temp_dir)

        expected_failure = f"[FAIL] {expected_policy}"
        failure_count = result.stdout.count("[FAIL]")

        if result.returncode == 0 or failure_count != 1:
            print(f"FAIL: {filename} did not produce exactly one policy failure.")
            print(result.stdout)
            sys.exit(1)

        if expected_failure not in result.stdout:
            print(f"FAIL: {filename} did not trigger {expected_policy}.")
            print(result.stdout)
            sys.exit(1)

        print(f"[PASS] {filename} correctly rejected by {expected_policy}")

    print("\nSUCCESS: Infrastructure passed and all five negative tests were detected.")


if __name__ == "__main__":
    main()
