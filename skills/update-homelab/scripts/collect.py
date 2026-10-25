#!/usr/bin/env python3
"""Read-only candidate pin inventory and sanitized Kubernetes baseline."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys


def kubectl(*args):
    result = subprocess.run(
        ["kubectl", "--request-timeout=8s", *args, "-o", "json"],
        capture_output=True, text=True, timeout=30, check=True,
    )
    return json.loads(result.stdout)["items"]


def live_summary():
    probe = subprocess.run(
        ["kubectl", "--request-timeout=8s", "get", "--raw=/version"],
        capture_output=True, text=True, timeout=12, check=True,
    )
    out = {"kubernetes_version": json.loads(probe.stdout)["gitVersion"]}
    out["nodes"] = [
        {"name": n["metadata"]["name"], "conditions": n["status"]["conditions"]}
        for n in kubectl("get", "nodes")
    ]
    out["applications"] = []
    for app in kubectl("get", "applications.argoproj.io", "-n", "argocd"):
        status = app.get("status", {})
        out["applications"].append({
            "name": app["metadata"]["name"],
            "source": {k: app["spec"].get("source", {}).get(k)
                       for k in ("repoURL", "path", "targetRevision", "chart")},
            "health": status.get("health", {}).get("status"),
            "sync": status.get("sync", {}).get("status"),
            "revision": status.get("sync", {}).get("revision"),
            "automated": app["spec"].get("syncPolicy", {}).get("automated"),
            "images": status.get("summary", {}).get("images", []),
            "drift": [{k: r.get(k) for k in ("kind", "namespace", "name", "status")}
                      for r in status.get("resources", []) if r.get("status") == "OutOfSync"],
        })
    out["pods"] = []
    for pod in kubectl("get", "pods", "-A"):
        status = pod.get("status", {})
        if status.get("phase") == "Succeeded":
            continue
        containers = []
        for kind in ("initContainerStatuses", "containerStatuses"):
            for c in status.get(kind, []):
                containers.append({
                    "container_type": "init" if kind == "initContainerStatuses" else "regular",
                    **{k: c.get(k) for k in ("name", "image", "imageID", "ready", "restartCount")},
                })
        out["pods"].append({
            "namespace": pod["metadata"]["namespace"], "name": pod["metadata"]["name"],
            "phase": status.get("phase"),
            "pod_ready": any(c.get("type") == "Ready" and c.get("status") == "True"
                             for c in status.get("conditions", [])),
            "containers": containers,
        })
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--live", action="store_true")
    args = parser.parse_args()
    root = args.repo.resolve()
    if not (root / "kubernetes/apps").is_dir():
        parser.error("--repo must contain kubernetes/apps")
    scalar = re.compile(r"^\s*(?:-\s+)?(image|imageName|tag|newTag|version):\s*(\S.*?)\s*$")
    reference = re.compile(r"^\s*-\s+((?:https://|github\.com/|oci://)\S+)")
    pins = []
    for scope in ("apps", "core", "bootstrap/argocd"):
        for path in sorted((root / "kubernetes" / scope).rglob("*.yaml")):
            if path.is_symlink() or "secret" in path.name.lower() or path.name == "plans.yaml":
                continue
            for number, line in enumerate(path.read_text().splitlines(), 1):
                m = scalar.match(line)
                ref = reference.match(line)
                if m:
                    key, value = m.groups()
                    value = value.split(" #", 1)[0].strip().strip("\"'")
                    if value.startswith(("https://", "http://")) or value in ("{}", "|", "|-", ">-"):
                        continue
                elif ref:
                    key, value = "resource", ref.group(1)
                else:
                    continue
                pins.append({"path": str(path.relative_to(root)), "line": number,
                             "key": key, "value": value})
    output = {"repository": str(root), "candidate_pins": pins}
    failed = False
    if args.live:
        try:
            output["live"] = live_summary()
        except (OSError, subprocess.SubprocessError, ValueError, KeyError) as error:
            output["live_error"] = str(error)
            failed = True
    print(json.dumps(output, indent=2))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
