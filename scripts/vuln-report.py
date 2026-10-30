#!/usr/bin/env python3
"""Turn a Trivy JSON report into release-note markdown and a shields.io badge.

Usage: python scripts/vuln-report.py dist/vuln-report.json dist/
Writes <outdir>/vuln-summary.md and <outdir>/vuln-badge.json. Stdlib only.
"""
import json
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

SEVERITIES = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]
DETAIL = {"CRITICAL", "HIGH"}
MAX_ROWS = 50


def load(path):
    report = json.loads(Path(path).read_text(encoding="utf-8"))
    vulns = []
    for result in report.get("Results") or []:
        for v in result.get("Vulnerabilities") or []:
            vulns.append({**v, "Target": result.get("Target", "")})
    return report, vulns


def summary(report, vulns):
    total = Counter(v["Severity"] for v in vulns)
    fixable = Counter(v["Severity"] for v in vulns if v.get("FixedVersion"))
    version = (report.get("Trivy") or {}).get("Version", "")
    scanned = report.get("CreatedAt") or datetime.now(timezone.utc).isoformat()

    out = [
        "## Vulnerability scan",
        "",
        f"Scanned `{report.get('ArtifactName', 'image')}` with Trivy {version} on {scanned[:10]}. "
        "Findings accepted in `.trivyignore` and `tests/trivy-ignore.rego` are excluded. "
        "Only fixable HIGH/CRITICAL findings in Ubuntu packages block a release; "
        "findings inside prebuilt tools are listed for visibility.",
        "",
        "| Severity | Found | Fix available |",
        "|---|--:|--:|",
    ]
    out += [f"| {s} | {total[s]} | {fixable[s]} |" for s in SEVERITIES if total[s] or s in DETAIL]

    serious = sorted(
        (v for v in vulns if v["Severity"] in DETAIL),
        key=lambda v: (SEVERITIES.index(v["Severity"]), v["VulnerabilityID"]),
    )
    out.append("")
    if not serious:
        out.append("No HIGH or CRITICAL vulnerabilities.")
    else:
        out += [
            "<details><summary>HIGH and CRITICAL findings</summary>",
            "",
            "| ID | Severity | Package | Installed | Fixed in | Where |",
            "|---|---|---|---|---|---|",
        ]
        for v in serious[:MAX_ROWS]:
            vid = v["VulnerabilityID"]
            link = f"[{vid}]({v['PrimaryURL']})" if v.get("PrimaryURL") else vid
            out.append(
                f"| {link} | {v['Severity']} | {v.get('PkgName', '')} | {v.get('InstalledVersion', '')} "
                f"| {v.get('FixedVersion') or 'no fix yet'} | {v['Target']} |"
            )
        if len(serious) > MAX_ROWS:
            out.append(f"\n{len(serious) - MAX_ROWS} more in `vuln-report.json`.")
        out += ["", "</details>"]
    out += ["", "Full results: `vuln-report.json` (Trivy) and `vuln-report.sarif` attached below.", ""]
    return "\n".join(out), total


def badge(total):
    crit, high = total["CRITICAL"], total["HIGH"]
    color = "red" if crit else "orange" if high else "brightgreen"
    return {"schemaVersion": 1, "label": "vulnerabilities", "message": f"{crit} critical · {high} high", "color": color}


def main():
    src, outdir = sys.argv[1], Path(sys.argv[2])
    report, vulns = load(src)
    md, total = summary(report, vulns)
    (outdir / "vuln-summary.md").write_text(md, encoding="utf-8")
    (outdir / "vuln-badge.json").write_text(json.dumps(badge(total)), encoding="utf-8")
    print("vuln-report: " + ", ".join(f"{total[s]} {s.lower()}" for s in SEVERITIES[:3]))


if __name__ == "__main__":
    main()
