
#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
INFRA_DIR = ROOT / "infra"

REQUIRED_LABELS = {"env", "owner", "cost-center"}
PRIMITIVE_ROLES = {
    "roles/owner",
    "roles/editor",
    "roles/viewer",
}


def load_terraform_files(directory=INFRA_DIR):
    """Load Terraform source files from a specified directory."""
    files = {}

    for path in Path(directory).glob("*.tf"):
        files[path.name] = path.read_text(encoding="utf-8")

    return files


def check_service_account_keys(files):
    """Reject service-account key resources."""
    errors = []

    for filename, content in files.items():
        if re.search(r'resource\s+"google_service_account_key"\s+"', content):
            errors.append(
                f"{filename}: service account key resources are prohibited"
            )

    return errors



def check_required_labels(files):
    """Require mandatory labels, resolving local.common_labels."""
    errors = []

    # Resolve the shared labels defined in the locals block.
    main_content = files.get("main.tf", "")
    common_labels_match = re.search(
        r'common_labels\s*=\s*\{([^}]*)\}',
        main_content,
        re.DOTALL,
    )

    common_labels = set()

    if common_labels_match:
        common_labels = set(
            re.findall(
                r'^\s*([A-Za-z0-9_-]+)\s*=',
                common_labels_match.group(1),
                re.MULTILINE,
            )
        )

    resource_pattern = re.compile(
        r'resource\s+"([^"]+)"\s+"([^"]+)"\s*\{',
        re.MULTILINE,
    )

    for filename, content in files.items():
        for match in resource_pattern.finditer(content):
            resource_type = match.group(1)
            resource_name = match.group(2)

            if resource_type not in {
                "google_storage_bucket",
                "google_compute_instance"
            }:
                continue

            start = match.end()
            depth = 1
            index = start

            while index < len(content) and depth:
                if content[index] == "{":
                    depth += 1
                elif content[index] == "}":
                    depth -= 1
                index += 1

            block = content[start:index - 1]

            labels_match = re.search(
                r'labels\s*=\s*\{([^}]*)\}',
                block,
                re.DOTALL,
            )

            if labels_match:
                labels = set(
                    re.findall(
                        r'^\s*([A-Za-z0-9_-]+)\s*=',
                        labels_match.group(1),
                        re.MULTILINE,
                    )
                )
            elif re.search(r'labels\s*=\s*local\.common_labels\b', block):
                labels = common_labels
            else:
                labels = set()

            missing = REQUIRED_LABELS - labels

            if missing:
                errors.append(
                    f"{filename}: {resource_type}.{resource_name} "
                    f"is missing labels: {', '.join(sorted(missing))}"
                )

    return errors

def check_primitive_iam_roles(files):
    """Reject primitive project-level IAM roles."""
    errors = []

    for filename, content in files.items():
        if not re.search(
            r'resource\s+"google_project_iam_(?:member|binding|policy)"\s+"',
            content,
        ):
            continue

        for role in PRIMITIVE_ROLES:
            if re.search(
                rf'role\s*=\s*"{re.escape(role)}"',
                content,
            ):
                errors.append(
                    f"{filename}: primitive IAM role {role} is prohibited"
                )

    return errors


def check_public_principals(files):
    """Reject public IAM principals."""
    errors = []

    for filename, content in files.items():
        if re.search(r'"(?:allUsers|allAuthenticatedUsers)"', content):
            errors.append(
                f"{filename}: public IAM principal detected"
            )

    return errors


def check_wif_condition(files):
    """Require a repository-specific WIF trust condition."""
    content = files.get("wif.tf", "")

    if not content:
        return ["wif.tf: missing WIF configuration"]

    condition_match = re.search(
        r'attribute_condition\s*=\s*"([^"]*)"',
        content,
    )

    if not condition_match:
        return ["wif.tf: missing attribute_condition"]

    condition = condition_match.group(1)

    if "assertion.sub" not in condition:
        return ["wif.tf: trust condition must validate assertion.sub"]

    if "zeeshan40132/secure-gcp-foundation" not in condition:
        return ["wif.tf: trust condition must restrict the expected repository"]

    return []


def check_firewall_ingress(files):
    """Reject unrestricted SSH and RDP ingress rules."""
    errors = []

    for filename, content in files.items():
        resource_pattern = re.compile(
            r'resource\s+"google_compute_firewall"\s+"([^"]+)"\s*\{',
            re.MULTILINE,
        )

        for match in resource_pattern.finditer(content):
            resource_name = match.group(1)

            start = match.end()
            depth = 1
            index = start

            while index < len(content) and depth:
                if content[index] == "{":
                    depth += 1
                elif content[index] == "}":
                    depth -= 1
                index += 1

            block = content[start:index - 1]

            if not re.search(r'direction\s*=\s*"INGRESS"', block):
                continue

            unrestricted = re.search(
                r'source_ranges\s*=\s*\[\s*"0\.0\.0\.0/0"\s*\]',
                block,
            )

            if not unrestricted:
                continue

            ports = set(
                re.findall(r'ports\s*=\s*\[([^\]]*)\]', block)
            )

            port_values = set()
            for port_group in ports:
                port_values.update(re.findall(r'"(\d+)"', port_group))

            if "22" in port_values:
                errors.append(
                    f"{filename}: firewall {resource_name} "
                    "allows unrestricted SSH ingress"
                )

            if "3389" in port_values:
                errors.append(
                    f"{filename}: firewall {resource_name} "
                    "allows unrestricted RDP ingress"
                )

    return errors

def main():
    directory = Path(sys.argv[1]) if len(sys.argv) > 1 else INFRA_DIR
    files = load_terraform_files(directory)

    checks = [
        ("Service account keys", check_service_account_keys),
        ("Mandatory resource labels", check_required_labels),
        ("Primitive IAM roles", check_primitive_iam_roles),
        ("Public IAM principals", check_public_principals),
        ("WIF trust condition", check_wif_condition),
        ("Firewall ingress restrictions", check_firewall_ingress),
    ]

    failures = []

    print("Running custom Terraform security policies...\n")

    for name, check in checks:
        errors = check(files)

        if errors:
            print(f"[FAIL] {name}")
            for error in errors:
                print(f"  - {error}")
            failures.extend(errors)
        else:
            print(f"[PASS] {name}")

    print(f"\nResults: {len(checks) - sum(bool(check(files)) for _, check in checks)} "
          f"passed, {sum(bool(check(files)) for _, check in checks)} failed.")

    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
