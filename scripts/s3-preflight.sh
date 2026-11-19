#!/usr/bin/env bash
# From Code to Cluster: pre-flight check for Session 3 (operators and observability).
#
# Run it at home, on a good network, before Session 3:
#     bash scripts/s3-preflight.sh
# It checks Docker memory and Helm, adds the three Helm repositories the lessons use,
# and pulls every image of the monitoring stack onto your laptop, so the room's wifi
# does not have to. If your kind cluster "kind" is running, it also copies the images
# into it with `kind load`, so the node does not pull them again.
#
# Exit code 0 = every check passed (warnings are allowed). Non-zero = at least one ✘.

set -u

MIN_HELM="3.13"      # oldest Helm that understands --dry-run=client
WANT_HELM="4"        # the lessons were verified with Helm v4
MEM_WARN_GIB="5.5"   # a VM set to 6 GB reports roughly 5.7 GiB to Docker
CLUSTER="kind"

# Images of the Session 3 stack (kube-prometheus-stack 93.4.1, loki 7.7.0, alloy 1.16.0,
# podinfo 6.17.0), as listed by the running Pods on 2026-11-19.
IMAGES="
ghcr.io/stefanprodan/podinfo:6.17.0
prom/prometheus:v3.16.0
quay.io/prometheus-operator/prometheus-operator:v0.95.2
quay.io/prometheus-operator/prometheus-config-reloader:v0.95.2
quay.io/prometheus/prometheus:v3.16.0-distroless
quay.io/prometheus/alertmanager:v0.35.0
docker.io/grafana/grafana:13.3.1-distroless
quay.io/kiwigrid/k8s-sidecar:2.14.3
docker.io/grafana/loki:3.6.11
docker.io/kiwigrid/k8s-sidecar:2.5.0
docker.io/grafana/alloy:v1.22.0
quay.io/prometheus-operator/prometheus-config-reloader:v0.94.2
golang:1.27
gcr.io/distroless/static-debian13:nonroot
"

if [ -t 1 ]; then
  GREEN=$(printf '\033[32m'); RED=$(printf '\033[31m'); YELLOW=$(printf '\033[33m')
  BOLD=$(printf '\033[1m'); RESET=$(printf '\033[0m')
else
  GREEN=""; RED=""; YELLOW=""; BOLD=""; RESET=""
fi

PASS=0; WARN=0; FAIL=0
ok()   { PASS=$((PASS + 1)); printf '%s✔%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { WARN=$((WARN + 1)); printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
bad()  { FAIL=$((FAIL + 1)); printf '%s✘%s %s\n' "$RED" "$RESET" "$*"; }
hint() { printf '    → %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
# ver_lt A B: true if major.minor A < major.minor B
ver_lt() {
  awk -v a="$1" -v b="$2" 'BEGIN { split(a, x, "."); split(b, y, ".");
    if (x[1] + 0 != y[1] + 0) exit !(x[1] + 0 < y[1] + 0); exit !(x[2] + 0 < y[2] + 0) }'
}

printf '%sFrom Code to Cluster: Session 3 pre-flight%s\n' "$BOLD" "$RESET"

# ---------------------------------------------------------------- tools
printf '\n%sTools%s\n' "$BOLD" "$RESET"
for t in docker kind kubectl; do
  if have "$t"; then ok "$t found"; else bad "$t not found"; hint "see the Session 1 pre-flight lesson"; fi
done
if have helm; then
  hv=$(helm version --template '{{.Version}}' 2>/dev/null | sed -E 's/^v//')
  if ver_lt "$hv" "$MIN_HELM"; then
    bad "helm $hv is too old (need $MIN_HELM or newer)"; hint "https://helm.sh/docs/intro/install/"
  elif ver_lt "$hv" "$WANT_HELM.0"; then
    warn "helm $hv works, but the lessons were checked with Helm v4"
  else
    ok "helm $hv"
  fi
else
  bad "helm not found"; hint "macOS: brew install helm · others: https://helm.sh/docs/intro/install/"
fi

# ---------------------------------------------------------------- docker memory
printf '\n%sDocker engine%s\n' "$BOLD" "$RESET"
DOCKER_OK=0
if have docker && docker info >/dev/null 2>&1; then
  DOCKER_OK=1
  mem=$(docker info --format '{{.MemTotal}}' 2>/dev/null)
  gib=$(awk -v m="$mem" 'BEGIN { printf "%.1f", m / 1073741824 }')
  if awk -v g="$gib" -v w="$MEM_WARN_GIB" 'BEGIN { exit !(g < w) }'; then
    bad "Docker has ${gib} GiB of memory; the stack needs about 3 GiB on top of the cluster"
    hint "raise the Docker Desktop / Rancher Desktop VM memory to at least 6 GB"
  else
    ok "Docker has ${gib} GiB of memory"
  fi
else
  bad "Docker daemon not reachable"; hint "start Docker Desktop (or your engine) and run again"
fi

# ---------------------------------------------------------------- helm repos
printf '\n%sHelm repositories%s\n' "$BOLD" "$RESET"
if have helm; then
  for r in "podinfo https://stefanprodan.github.io/podinfo" \
           "prometheus-community https://prometheus-community.github.io/helm-charts" \
           "grafana https://grafana.github.io/helm-charts"; do
    set -- $r
    if helm repo add "$1" "$2" --force-update >/dev/null 2>&1; then ok "repo $1"; else bad "could not add repo $1 ($2)"; fi
  done
  if helm repo update >/dev/null 2>&1; then ok "repos updated"; else bad "helm repo update failed"; fi
fi

# ---------------------------------------------------------------- images
printf '\n%sImages (this is the slow part)%s\n' "$BOLD" "$RESET"
LOAD=0
if [ "$DOCKER_OK" = 1 ] && have kind && kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  LOAD=1; printf '    kind cluster "%s" is running: images will be loaded into it too\n' "$CLUSTER"
fi
if [ "$DOCKER_OK" = 1 ]; then
  for img in $IMAGES; do
    if docker pull -q "$img" >/dev/null 2>&1; then
      if [ "$LOAD" = 1 ]; then
        if kind load docker-image "$img" --name "$CLUSTER" >/dev/null 2>&1; then ok "$img (pulled, loaded)"
        else warn "$img pulled, but kind load failed (the node will pull it itself)"; fi
      else
        ok "$img"
      fi
    else
      bad "could not pull $img"
    fi
  done
fi

# ---------------------------------------------------------------- summary
printf '\n%s%d passed, %d warnings, %d failed%s\n' "$BOLD" "$PASS" "$WARN" "$FAIL" "$RESET"
if [ "$FAIL" -gt 0 ]; then
  printf '%s✘ PRE-FLIGHT FAILED.%s Fix the ✘ lines, run again, and ask your instructor if you are stuck.\n' "$RED" "$RESET"
  exit 1
fi
printf '%s✔ PRE-FLIGHT PASSED.%s You are ready for Session 3.\n' "$GREEN" "$RESET"
exit 0
