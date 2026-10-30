# Trivy ignore policy: findings matched here are dropped from every scan and report.
# Use .trivyignore for single CVEs; use this for whole packages.
package trivy

import rego.v1

default ignore := false

# Kernel headers (pulled in by build-essential). Their CVEs are bugs in the Linux
# kernel; WSL runs Microsoft's kernel and headers are never executed.
ignore if input.PkgName == "linux-libc-dev"
