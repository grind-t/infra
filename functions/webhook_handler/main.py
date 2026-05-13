import base64
import hashlib
import hmac
import json
import os
import time
import urllib.request

FOLDER_ID        = os.environ["FOLDER_ID"]
SUBNET_ID        = os.environ["SUBNET_ID"]
RUNNER_SA_ID     = os.environ["RUNNER_SA_ID"]
GITHUB_ORG         = os.environ["GITHUB_ORG"]
GITHUB_ENTITY_TYPE = os.environ.get("GITHUB_ENTITY_TYPE", "org")  # "org" or "user"
RUNNER_LABELS    = os.environ["RUNNER_LABELS"]
RUNNER_CORES     = int(os.environ["RUNNER_CORES"])
RUNNER_MEMORY_MB = int(os.environ["RUNNER_MEMORY_MB"])
RUNNER_DISK_GB   = int(os.environ["RUNNER_DISK_GB"])
RUNNER_DISK_TYPE = os.environ["RUNNER_DISK_TYPE"]
RUNNER_IMAGE_ID  = os.environ["RUNNER_IMAGE_ID"]
ZONE             = os.environ["ZONE"]
WEBHOOK_SECRET   = os.environ["WEBHOOK_SECRET"]
GITHUB_PAT       = os.environ["GITHUB_PAT"]

# Base64-embedded runner setup script to avoid YAML escaping issues in cloud-init
_RUNNER_SCRIPT_TEMPLATE = """\
#!/bin/bash
set -euo pipefail

useradd -m -s /bin/bash github-runner || true
mkdir -p /opt/actions-runner
chown github-runner:github-runner /opt/actions-runner
cd /opt/actions-runner

VER=$(curl -sf https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name[1:]')
curl -fsSL -o runner.tar.gz "https://github.com/actions/runner/releases/download/v${VER}/actions-runner-linux-x64-${VER}.tar.gz"
tar xzf runner.tar.gz && rm runner.tar.gz
chown -R github-runner:github-runner /opt/actions-runner

sudo -u github-runner /opt/actions-runner/config.sh \\
  --url https://github.com/__ORG__ \\
  --token __TOKEN__ \\
  --name __NAME__ \\
  --labels __LABELS__ \\
  --runnergroup Default \\
  --ephemeral \\
  --unattended \\
  --replace

sudo -u github-runner /opt/actions-runner/run.sh || true

IID=$(curl -sf -H 'Metadata-Flavor:Google' http://169.254.169.254/computeMetadata/v1/instance/id)
TOK=$(curl -sf -H 'Metadata-Flavor:Google' http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token | jq -r .access_token)
curl -sf -X DELETE -H "Authorization: Bearer $TOK" "https://compute.api.cloud.yandex.net/compute/v1/instances/$IID" || true

poweroff
"""


def handler(event, context):
    body_b64 = event.get("body", "")
    is_base64 = event.get("isBase64Encoded", False)
    raw_body = base64.b64decode(body_b64) if is_base64 else body_b64.encode()

    sig_header = event.get("headers", {}).get("X-Hub-Signature-256", "")
    if not _verify_signature(raw_body, sig_header, WEBHOOK_SECRET):
        return {"statusCode": 401, "body": "Invalid signature"}

    payload = json.loads(raw_body)
    action = payload.get("action")
    job = payload.get("workflow_job", {})

    if action != "queued":
        return {"statusCode": 200, "body": "ignored"}

    requested_labels = [label["name"] for label in job.get("labels", [])]
    if RUNNER_LABELS not in requested_labels:
        return {"statusCode": 200, "body": "label mismatch, skipped"}

    reg_token = _get_registration_token(GITHUB_ORG, GITHUB_PAT, GITHUB_ENTITY_TYPE)

    run_id = job.get("run_id", int(time.time()))
    job_id = job.get("id", 0)
    vm_name = f"gh-runner-{run_id}-{job_id}"[:60]

    user_data = _render_cloud_init(
        vm_name=vm_name,
        github_org=GITHUB_ORG,
        reg_token=reg_token,
        runner_labels=RUNNER_LABELS,
    )

    vm_id = _create_vm(vm_name, user_data)

    return {"statusCode": 200, "body": json.dumps({"vm_id": vm_id, "vm_name": vm_name})}


def _verify_signature(body: bytes, header: str, secret: str) -> bool:
    if not header.startswith("sha256="):
        return False
    expected = "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, header)


def _get_registration_token(org: str, pat: str, entity_type: str = "org") -> str:
    if entity_type == "user":
        url = "https://api.github.com/user/actions/runners/registration-token"
    else:
        url = f"https://api.github.com/orgs/{org}/actions/runners/registration-token"
    req = urllib.request.Request(
        url,
        method="POST",
        headers={
            "Authorization": f"Bearer {pat}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "yc-github-runner/1.0",
        },
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())["token"]


def _get_iam_token() -> str:
    req = urllib.request.Request(
        "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token",
        headers={"Metadata-Flavor": "Google"},
    )
    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.loads(resp.read())["access_token"]


def _create_vm(vm_name: str, user_data: str) -> str:
    token = _get_iam_token()
    body = {
        "folderId": FOLDER_ID,
        "name": vm_name,
        "zoneId": ZONE,
        "platformId": "standard-v3",
        "resourcesSpec": {
            "cores": RUNNER_CORES,
            "memory": RUNNER_MEMORY_MB * 1024 * 1024,
            "coreFraction": 100,
        },
        "bootDiskSpec": {
            "diskSpec": {
                "size": RUNNER_DISK_GB * 1024 ** 3,
                "typeId": RUNNER_DISK_TYPE,
                "imageId": RUNNER_IMAGE_ID,
            }
        },
        "networkInterfaceSpecs": [{
            "subnetId": SUBNET_ID,
            "primaryV4AddressSpec": {},
        }],
        "metadata": {
            "user-data": user_data,
            "serial-port-enable": "0",
        },
        "serviceAccountId": RUNNER_SA_ID,
        "labels": {
            "purpose": "github-runner",
            "github-org": GITHUB_ORG.lower().replace(".", "-"),
        },
        "schedulingPolicy": {"preemptible": False},
    }
    req = urllib.request.Request(
        "https://compute.api.cloud.yandex.net/compute/v1/instances",
        data=json.dumps(body).encode(),
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=25) as resp:
        result = json.loads(resp.read())
    return result.get("metadata", {}).get("instanceId", result.get("id", "unknown"))


def _render_cloud_init(vm_name: str, github_org: str, reg_token: str, runner_labels: str) -> str:
    script = (
        _RUNNER_SCRIPT_TEMPLATE
        .replace("__ORG__", github_org)
        .replace("__TOKEN__", reg_token)
        .replace("__NAME__", vm_name)
        .replace("__LABELS__", runner_labels)
    )
    script_b64 = base64.b64encode(script.encode()).decode()
    return f"""\
#cloud-config
package_update: true
packages:
  - curl
  - jq
  - git
  - libicu-dev
write_files:
  - path: /opt/runner-setup.sh
    permissions: '0755'
    encoding: b64
    content: {script_b64}
runcmd:
  - /opt/runner-setup.sh
"""
