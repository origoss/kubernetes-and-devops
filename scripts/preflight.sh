#!/usr/bin/env bash
# From Code to Cluster: pre-flight check for Session 1.
#
# Run it on your own laptop, on your own network, a few days before Session 1:
#     bash preflight.sh
# Works on macOS (bash 3.2+), Linux and WSL2. It changes nothing permanently:
# it starts one throwaway kind cluster in a temporary kubeconfig and deletes it again.
#
# Exit code 0 = every check passed (warnings are allowed). Non-zero = at least one ✘.
#
# Environment overrides (you normally need none):
#   PREFLIGHT_CLUSTER   name of the throwaway kind cluster (default: preflight)
#   PREFLIGHT_SKIP_KIND set to 1 to skip the cluster test (not accepted as a pass on the day)

set -u

# Versions the course was written against (RESOURCES.md, 2026-10-05).
WANT_KIND="0.33"     # kind v0.33.x
WANT_KUBECTL="1.37"  # kubectl within one minor of Kubernetes 1.37
WANT_GO="1.27"       # Go 1.27.x
MIN_GO="1.22"        # older Go lacks the "GET /path" routing the lessons use
NODE_IMAGE="kindest/node:v1.37.0"
IMAGES="golang:1.27 gcr.io/distroless/static-debian13:nonroot alpine python:3.12-slim python:3.13-slim $NODE_IMAGE"
MEM_WARN_GIB="5.5"   # a VM set to 6 GB reports roughly 5.7 GiB to Docker

CLUSTER="${PREFLIGHT_CLUSTER:-preflight}"

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

# major.minor of a version string such as "v1.37.1", "go1.27.1" or "0.33.0"
minor_of() { printf '%s\n' "$1" | sed -E 's/^[^0-9]*//; s/^([0-9]+)\.([0-9]+).*/\1.\2/'; }
# ver_lt A B: true if major.minor A < major.minor B
ver_lt() {
  awk -v a="$1" -v b="$2" 'BEGIN { split(a, x, "."); split(b, y, ".");
    if (x[1] + 0 != y[1] + 0) exit !(x[1] + 0 < y[1] + 0); exit !(x[2] + 0 < y[2] + 0) }'
}

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t preflight)
KCFG="$TMP/kubeconfig"
CLUSTER_UP=0
cleanup() {
  if [ "$CLUSTER_UP" = 1 ]; then
    kind delete cluster --name "$CLUSTER" --kubeconfig "$KCFG" >/dev/null 2>&1
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# ---------------------------------------------------------------- header
OS="$(uname -s) $(uname -m)"
if [ -r /proc/version ] && grep -qi microsoft /proc/version; then OS="$OS (WSL2)"; fi
printf '%sFrom Code to Cluster: pre-flight check%s\n' "$BOLD" "$RESET"
printf '%s · %s · user %s\n\n' "$(date '+%Y-%m-%d %H:%M')" "$OS" "$(id -un)"

# ---------------------------------------------------------------- 1. tools
printf '%sTools%s\n' "$BOLD" "$RESET"

DOCKER_OK=0
if have docker; then
  ok "docker CLI $(docker version --format '{{.Client.Version}}' 2>/dev/null)"
else
  bad "docker CLI not found"
  if have nerdctl; then hint "Rancher Desktop seems to use containerd: switch the engine to dockerd (moby)"; fi
  hint "see 'Install your tools' in the pre-flight lesson"
fi

if have kind; then
  v=$(kind version 2>/dev/null | awk '{print $2}')
  if [ "$(minor_of "$v")" = "$WANT_KIND" ]; then ok "kind $v"
  elif ver_lt "$(minor_of "$v")" "0.31"; then bad "kind $v is too old (want v$WANT_KIND.x)"
  else warn "kind $v (the course uses v$WANT_KIND.x; this should work)"; fi
else
  bad "kind not found"; hint "install kind v$WANT_KIND.0"
fi

if have kubectl; then
  v=$(kubectl version --client 2>/dev/null | sed -n 's/^Client Version: //p')
  m=$(minor_of "$v")
  if [ -z "$v" ]; then bad "kubectl found but 'kubectl version --client' failed"
  elif ver_lt "$m" "1.36" || ver_lt "1.38" "$m"; then
    warn "kubectl $v (the course uses $WANT_KUBECTL; keep it within one minor version)"
  else ok "kubectl $v"; fi
else
  bad "kubectl not found"
fi

if have go; then
  v=$(cd / && go env GOVERSION 2>/dev/null | sed "s/^go//")
  m=$(minor_of "$v")
  if [ -z "$v" ]; then bad "go found but 'go env GOVERSION' failed"
  elif ver_lt "$m" "$MIN_GO"; then bad "Go $v is too old (want $WANT_GO)"
  elif ver_lt "$m" "$WANT_GO"; then warn "Go $v (the course uses $WANT_GO; Go will download $WANT_GO when a project asks for it)"
  else ok "Go $v"; fi
else
  bad "go not found"
fi

if have git; then
  ok "git $(git --version | awk '{print $3}')"
  if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
    warn "git has no user.email yet"
    hint "git config --global user.name \"Your Name\"; git config --global user.email you@example.com"
  fi
else
  bad "git not found"
fi

# ---------------------------------------------------------------- 2. docker engine
printf '\n%sDocker engine%s\n' "$BOLD" "$RESET"

if have docker; then
  if err=$(docker info --format '{{.ServerVersion}}' 2>&1) && [ -n "$err" ]; then
    DOCKER_OK=1
    os=$(docker info --format '{{.OperatingSystem}}' 2>/dev/null)
    ok "daemon reachable: Docker Engine $err on $os"
  else
    bad "cannot reach the Docker daemon"
    case "$err" in
      *ermission*) hint "Linux/WSL: sudo usermod -aG docker \$USER, then log out and back in" ;;
      *) hint "start Docker Desktop (or Rancher Desktop; on Linux/WSL: sudo systemctl start docker)" ;;
    esac
  fi
fi

if [ "$DOCKER_OK" = 1 ]; then
  mem=$(docker info --format '{{.MemTotal}}' 2>/dev/null)
  cpu=$(docker info --format '{{.NCPU}}' 2>/dev/null)
  gib=$(awk -v m="${mem:-0}" 'BEGIN { printf "%.1f", m / 1073741824 }')
  if awk -v g="$gib" -v w="$MEM_WARN_GIB" 'BEGIN { exit !(g < w) }'; then
    warn "Docker sees only $gib GiB RAM and $cpu CPUs (want a 6–8 GB VM)"
    hint "Docker Desktop: Settings → Resources → Advanced → Memory limit (Rancher Desktop: Preferences → Virtual Machine → Hardware → Memory)"
  else
    ok "Docker sees $gib GiB RAM and $cpu CPUs"
  fi

  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^k8s_'; then
    warn "Kubernetes containers are running inside Docker: Docker Desktop's (or Rancher Desktop's) own Kubernetes looks ON"
    hint "Docker Desktop: Settings → Kubernetes → untick 'Enable Kubernetes' (Rancher Desktop: Preferences → Kubernetes)"
  fi

  cfg="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
  hub=0
  if [ -r "$cfg" ] && grep -q 'index.docker.io' "$cfg"; then hub=1; fi
  store=$( [ -r "$cfg" ] && sed -n 's/.*"credsStore"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -n 1)
  if [ "$hub" = 0 ] && [ -n "$store" ] && have "docker-credential-$store"; then
    if "docker-credential-$store" list 2>/dev/null | grep -q 'index.docker.io'; then hub=1; fi
  fi
  if [ "$hub" = 1 ]; then ok "logged in to Docker Hub"
  else
    warn "not logged in to Docker Hub (anonymous pulls: 100 per 6 hours per IP, shared by the whole room)"
    hint "docker login   (free Docker Hub account)"
  fi

  if out=$(docker run --rm alpine echo container-ok 2>&1) && printf '%s' "$out" | grep -q container-ok; then
    ok "can run a container (alpine)"
  else
    bad "cannot run a container"; printf '%s\n' "$out" | tail -n 3 | sed 's/^/    /'
  fi

  missing=""
  for img in $IMAGES; do
    docker image inspect "$img" >/dev/null 2>&1 || missing="$missing $img"
  done
  if [ -z "$missing" ]; then ok "all Session 1 images are pulled"
  else warn "images not pulled yet:$missing"; hint "run the docker pull step of the lesson"; fi
fi

# ---------------------------------------------------------------- 3. kind cluster
printf '\n%sKubernetes in Docker (kind)%s\n' "$BOLD" "$RESET"

if [ "${PREFLIGHT_SKIP_KIND:-0}" = 1 ]; then
  warn "cluster test skipped (PREFLIGHT_SKIP_KIND=1)"
elif [ "$DOCKER_OK" = 1 ] && have kind && have kubectl; then
  if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
    bad "a kind cluster called '$CLUSTER' already exists"
    hint "kind delete cluster --name $CLUSTER   (or set PREFLIGHT_CLUSTER=another-name)"
  else
    printf '  creating a throwaway cluster "%s" (about a minute)...\n' "$CLUSTER"
    start=$(date +%s)
    CLUSTER_UP=1
    if kind create cluster --name "$CLUSTER" --kubeconfig "$KCFG" --wait 180s >"$TMP/kind.log" 2>&1; then
      secs=$(( $(date +%s) - start ))
      ready=$(kubectl --kubeconfig "$KCFG" get nodes --no-headers 2>/dev/null | awk '{print $2}')
      if [ "$ready" = "Ready" ]; then ok "kind created a cluster in ${secs}s and its node is Ready"
      else bad "cluster created but node is '${ready:-unknown}'"; fi
    else
      bad "kind create cluster failed"
      tail -n 8 "$TMP/kind.log" | sed 's/^/    /'
      hint "check the 'If something fails' box in the lesson"
    fi
    if kind delete cluster --name "$CLUSTER" --kubeconfig "$KCFG" >"$TMP/kind-del.log" 2>&1; then
      CLUSTER_UP=0; ok "throwaway cluster deleted"
    else
      bad "could not delete the throwaway cluster"; hint "kind delete cluster --name $CLUSTER"
    fi
  fi
else
  bad "cluster test not run (needs a reachable Docker daemon, kind and kubectl)"
fi

# ---------------------------------------------------------------- summary
printf '\n%s%d passed, %d warnings, %d failed%s\n' "$BOLD" "$PASS" "$WARN" "$FAIL" "$RESET"
if [ "$FAIL" -gt 0 ]; then
  printf '%s✘ PRE-FLIGHT FAILED.%s Fix the ✘ lines, run again, and ask your instructor if you are stuck.\n' "$RED" "$RESET"
  exit 1
fi
printf '%s✔ PRE-FLIGHT PASSED.%s Screenshot this and send it to your instructor.\n' "$GREEN" "$RESET"
exit 0
