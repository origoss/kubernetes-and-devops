#!/usr/bin/env bash
# From Code to Cluster: self-check for Homework 1 (twelve-factor server).
# Usage: ./scripts/check-12factor.sh <image>      e.g. ghcr.io/<you>/hello:0.2.0
# Part 1 runs your image in Docker. Part 2 checks what you deployed with
# kubectl apply -f k8s/ on your current kind cluster. Nothing is changed except
# your visit counter, which the admin-process check resets.

set -u
IMAGE="${1:-}"
if [ -z "$IMAGE" ]; then
  echo "usage: $0 <image>   (the image your k8s/deployment.yaml runs)" >&2
  exit 2
fi

PASS=0; FAIL=0
ok()   { printf '\033[32m✔\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '\033[31m✘\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
hint() { printf '    → %s\n' "$1"; }

NAME="hw1-check-$$"
PORT=18080
TMP=$(mktemp -d)
cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1
  kubectl delete pod hw1-reset hw1-curl --ignore-not-found --wait=false >/dev/null 2>&1
  rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

echo "Homework 1 self-check · image $IMAGE"
echo
echo "Part 1: the process (Docker, no backing service reachable)"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  bad "image $IMAGE not found locally"
  hint "build it first: docker build -t $IMAGE ."
  exit 1
fi

# REDIS_URL points at a port where nothing listens: the backing service is "down".
docker run -d --name "$NAME" -p "127.0.0.1:$PORT:8080" \
  -e REDIS_URL=redis://127.0.0.1:1/0 "$IMAGE" >/dev/null

up=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if [ "$(curl -s -m 2 "http://127.0.0.1:$PORT/healthz")" = "ok" ]; then up=1; break; fi
  sleep 0.5
done
if [ "$up" = 1 ]; then
  ok "IX  starts fast and answers /healthz, even without its backing service"
else
  bad "IX  /healthz did not answer 'ok' within 5 seconds"
  hint "/healthz must not depend on Redis, and the server must start without it"
fi

code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "http://127.0.0.1:$PORT/")
if [ "$code" = "503" ]; then
  ok "IV  GET / answers 503 while the backing service is unreachable"
else
  bad "IV  GET / answered $code while Redis is unreachable (want 503)"
fi

# Graceful shutdown: a 3-second request must finish although we stop the container.
curl -s -o "$TMP/slow.body" -m 15 -w '%{http_code}' "http://127.0.0.1:$PORT/slow" >"$TMP/slow.code" 2>/dev/null &
cpid=$!
sleep 1
docker stop -t 10 "$NAME" >/dev/null
wait "$cpid" 2>/dev/null
exit_code=$(docker inspect -f '{{.State.ExitCode}}' "$NAME")
if [ "$(cat "$TMP/slow.code" 2>/dev/null)" = "200" ] && [ "$exit_code" = "0" ]; then
  ok "IX  SIGTERM: the in-flight /slow request finished and the process exited 0"
else
  bad "IX  SIGTERM: /slow got '$(cat "$TMP/slow.code" 2>/dev/null)', exit code $exit_code (want 200 and 0)"
  hint "catch SIGTERM, then call http.Server.Shutdown so running requests can finish"
fi

docker logs "$NAME" >"$TMP/out" 2>"$TMP/err"
lines=$(grep -c . "$TMP/out")
errlines=$(grep -c . "$TMP/err")
nonjson=$(grep -v -c '^{.*}$' "$TMP/out")
if command -v jq >/dev/null 2>&1; then
  jq -e . "$TMP/out" >/dev/null 2>&1 || nonjson=$((nonjson+1))
fi
if [ "$lines" -gt 0 ] && [ "$nonjson" = 0 ] && [ "$errlines" = 0 ] && grep -q '"path"' "$TMP/out"; then
  ok "XI  logs: $lines JSON events on stdout, nothing on stderr, requests are logged"
else
  bad "XI  logs: $lines lines on stdout ($nonjson not JSON), $errlines on stderr, request log present: $(grep -q '"path"' "$TMP/out" && echo yes || echo no)"
  hint "one JSON object per line on stdout (log/slog JSONHandler), one event per request with its path"
fi

echo
echo "Part 2: the deployment (kubectl context: $(kubectl config current-context 2>/dev/null))"

missing=""
for obj in deployment/hello service/hello service/redis; do
  kubectl get "$obj" >/dev/null 2>&1 || missing="$missing $obj"
done
if [ -n "$missing" ]; then
  bad "objects missing:$missing"
  hint "kubectl apply -f k8s/   (see the homework brief for the expected names)"
  echo; echo "$PASS passed, $FAIL failed"; exit 1
fi

kubectl rollout status deployment/hello --timeout=90s >/dev/null 2>&1
ready=$(kubectl get deployment hello -o jsonpath='{.status.readyReplicas}')
if [ "${ready:-0}" -ge 2 ]; then
  ok "VIII $ready replicas of hello are ready"
else
  bad "VIII only ${ready:-0} replica(s) ready (want at least 2)"
fi

c='{.spec.template.spec.containers[0]'
sp=$(kubectl get deployment hello -o jsonpath="$c.startupProbe.httpGet.path}")
rp=$(kubectl get deployment hello -o jsonpath="$c.readinessProbe.httpGet.path}")
lp=$(kubectl get deployment hello -o jsonpath="$c.livenessProbe.httpGet.path}")
ml=$(kubectl get deployment hello -o jsonpath="$c.resources.limits.memory}")
if [ -n "$sp" ] && [ -n "$rp" ] && [ -n "$lp" ] && [ -n "$ml" ]; then
  ok "     startup, readiness and liveness probes set ($rp), memory limit $ml"
else
  bad "     probes or memory limit missing (startup '$sp', readiness '$rp', liveness '$lp', limit '$ml')"
  hint "set startupProbe, readinessProbe and livenessProbe (httpGet /healthz) and resources.limits.memory"
fi

redis_url=$(kubectl get deployment hello -o jsonpath="$c.env[?(@.name==\"REDIS_URL\")].value}")
greeting=$(kubectl get deployment hello -o jsonpath="$c.env[?(@.name==\"GREETING\")].value}")
if [ -n "$redis_url" ] && [ -n "$greeting" ]; then
  ok "III REDIS_URL and GREETING come from the Deployment's env"
else
  bad "III env missing in deployment.yaml (REDIS_URL '$redis_url', GREETING '$greeting')"
fi

# A server that ignores "reset" would run forever, so wait at most 60 seconds.
kubectl run hw1-reset --restart=Never --image="$IMAGE" --env="REDIS_URL=$redis_url" -- reset >/dev/null 2>&1
if kubectl wait pod/hw1-reset --for=jsonpath='{.status.phase}'=Succeeded --timeout=60s >/dev/null 2>&1; then
  reset_ok=1
else
  reset_ok=0
fi
kubectl delete pod hw1-reset --wait=false >/dev/null 2>&1

kubectl run hw1-curl --restart=Never --image=curlimages/curl:8.17.0 -- \
  sh -c 'for i in 1 2 3 4 5 6 7 8; do curl -s -m 5 http://hello/; done' >/dev/null 2>&1
kubectl wait pod/hw1-curl --for=jsonpath='{.status.phase}'=Succeeded --timeout=90s >/dev/null 2>&1
kubectl logs hw1-curl >"$TMP/traffic" 2>/dev/null
kubectl delete pod hw1-curl --wait=false >/dev/null 2>&1

visits=$(sed -n 's/.*visit \([0-9][0-9]*\).*/\1/p' "$TMP/traffic" | tr '\n' ' ')
hosts=$(sed -n 's/.*served by \([^)]*\)).*/\1/p' "$TMP/traffic" | sort -u | grep -c .)
first=$(echo "$visits" | awk '{print $1}')
increasing=$(echo "$visits" | awk '{for(i=2;i<=NF;i++) if ($i<=$(i-1)) {print "no"; exit} print "yes"}')

if [ "$reset_ok" = 1 ] && [ "$first" = "1" ]; then
  ok "XII one-off admin process 'reset' ran with the same image, and the counter restarted at 1"
else
  bad "XII 'reset' admin process: exit ok=$reset_ok, first visit afterwards '$first' (want 1)"
  hint "running your image with the argument 'reset' must clear the counter in Redis and exit 0"
fi
if [ -n "$visits" ] && [ "$increasing" = "yes" ] && [ "$hosts" -ge 2 ]; then
  ok "VI  8 requests across $hosts pods counted $visits: state lives in the backing service"
else
  bad "VI  visits '$visits' across $hosts pod(s) (want one rising count across 2+ pods)"
  hint "keep the counter in Redis, not in a variable; response format: <greeting> (visit <n>, served by <hostname>)"
fi
if grep -q "$greeting" "$TMP/traffic" 2>/dev/null && [ -n "$greeting" ]; then
  ok "III responses use GREETING from the environment"
else
  bad "III responses do not contain the GREETING value '$greeting'"
fi

echo
echo "$PASS passed, $FAIL failed"
if [ "$FAIL" = 0 ]; then
  printf '\033[32m✔ ALL CHECKS PASSED.\033[0m Paste this output into your pull request.\n'
  exit 0
fi
exit 1
