#!/usr/bin/env bash
# From Code to Cluster: set up Homework 2 (fault hunt).
# Usage, from the root of your hello repository:
#   bash ../kubernetes-and-devops/scripts/fault-hunt-up.sh [image]   (default hello:0.1.1)
# Creates the kind cluster "fault-hunt", loads your image into it, copies the
# manifests into ./fault-hunt/ (only if that folder does not exist yet) and
# applies them. Safe to run again: your edited files are kept and re-applied.

set -eu
IMAGE="${1:-hello:0.1.1}"
CLUSTER=fault-hunt
CTX="kind-$CLUSTER"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$HERE/examples/fault-hunt"
DEST="fault-hunt"

if [ ! -f go.mod ] || [ ! -d .git ]; then
  echo "Run this from the root of your hello repository (where go.mod is)." >&2
  exit 2
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop (or the Docker service on Linux) and try again." >&2
  exit 1
fi
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image $IMAGE not found locally. Build it as in lesson 07: docker build -t $IMAGE ." >&2
  exit 1
fi

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "Cluster $CLUSTER exists, reusing it."
else
  kind create cluster --name "$CLUSTER"
fi
kubectl config use-context "$CTX" >/dev/null
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null

kind load docker-image "$IMAGE" --name "$CLUSTER"

if [ -d "$DEST" ]; then
  echo "$DEST/ exists, keeping your files."
else
  mkdir "$DEST"
  cp "$SRC/deployment.yaml" "$SRC/service.yaml" "$SRC/REPORT.md" "$DEST/"
  echo "Copied the manifests and REPORT.md into $DEST/."
fi

kubectl apply -f "$DEST/"

echo
echo "Your kubectl now points at $CTX. The hunt is on: kubectl get pods"
echo "Back to your lesson cluster later: kubectl config use-context kind-kind"
