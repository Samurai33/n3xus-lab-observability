#!/usr/bin/env bash
# Local checks in Docker (no hosted CI on purpose). Run from the repo root: ./scripts/ci-local.sh
set -euo pipefail
cd "$(dirname "$0")/.."
PROM=prom/prometheus:v3.13.4
AM=prom/alertmanager:v0.34.1
GITLEAKS=zricethezav/gitleaks:v8.30.1

echo "== promtool check config + rules"
docker run --rm --entrypoint promtool \
  -v "$PWD/prometheus:/etc/prometheus:ro" "$PROM" check config /etc/prometheus/prometheus.yml

echo "== amtool check-config"
docker run --rm --entrypoint amtool \
  -v "$PWD/alertmanager:/etc/alertmanager:ro" "$AM" check-config /etc/alertmanager/alertmanager.yml

echo "== gitleaks (full git history + working tree)"
docker run --rm -v "$PWD:/repo:ro" "$GITLEAKS" git /repo --redact --verbose
docker run --rm -v "$PWD:/repo:ro" "$GITLEAKS" dir /repo --redact --verbose

echo "== shell + python syntax"
docker run --rm -v "$PWD:/repo:ro" -w /repo python:3.13.15-slim sh -c \
  'python -m py_compile collectors/docker/n3x-docker-textfile collectors/vzdump/vzdump-textfile && sh -n collectors/nut/nut-textfile.sh collectors/lvm-thin/lvm-thin-textfile.sh'

echo "OK"
