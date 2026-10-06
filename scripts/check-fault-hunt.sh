#!/usr/bin/env bash
# From Code to Cluster: self-check for Homework 2 (fault hunt).
# Usage, from the root of your hello repository:
#   bash ../kubernetes-and-devops/scripts/check-fault-hunt.sh
# Checks what runs on the kind cluster "fault-hunt" and whether ./fault-hunt/
# matches it. It reports symptoms, never causes. Nothing is changed.

set -u
CTX=kind-fault-hunt
DIR=fault-hunt
K="kubectl --context $CTX"

PASS=0; FAIL=0
ok()  { printf '\033[32m✔\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '\033[31m✘\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

PF=""
cleanup() { [ -n "$PF" ] && kill "$PF" 2>/dev/null; }
trap cleanup EXIT INT TERM

echo "Homework 2 self-check · context $CTX"
echo

if ! $K get deploy hello >/dev/null 2>&1; then
  bad "Deployment hello not found on $CTX (did you run fault-hunt-up.sh?)"
  exit 1
fi

want=$($K get deploy hello -o jsonpath='{.spec.replicas}')
if [ "$want" = 2 ]; then
  ok "Deployment asks for 2 replicas"
else
  bad "Deployment asks for $want replicas (want 2)"
fi

probes=$($K get deploy hello -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}{" "}{.spec.template.spec.containers[0].readinessProbe.httpGet.path}{" "}{.spec.template.spec.containers[0].livenessProbe.httpGet.path}{" "}{.spec.template.spec.containers[0].resources.limits.memory}')
set -- $probes
if [ $# = 4 ]; then
  ok "startup, readiness and liveness probes and a memory limit are still there"
else
  bad "a probe or the memory limit was removed (fix it, do not delete it)"
fi

pending=$($K get pods -l app=hello --field-selector=status.phase=Pending -o name | wc -l | tr -d ' ')
if [ "$pending" = 0 ]; then
  ok "no Pod is Pending"
else
  bad "$pending Pod(s) Pending"
fi

upd=$($K get deploy hello -o jsonpath='{.status.updatedReplicas}')
avail=$($K get deploy hello -o jsonpath='{.status.availableReplicas}')
if [ "${upd:-0}" = "$want" ] && [ "${avail:-0}" = "$want" ]; then
  ok "rollout complete: $avail/$want replicas up to date and available"
else
  bad "rollout not complete: ${upd:-0} up to date, ${avail:-0} available, $want wanted"
fi

restarts() { $K get pods -l app=hello -o jsonpath='{range .items[*]}{.metadata.name}={.status.containerStatuses[0].restartCount}{"\n"}{end}' | sort; }
before=$(restarts)
echo "  … watching restarts for 40 seconds"
sleep 40
after=$(restarts)
running=$($K get pods -l app=hello --field-selector=status.phase=Running -o name | wc -l | tr -d ' ')
if [ "$running" -lt "$want" ]; then
  bad "only $running of $want Pods are Running"
elif [ "$before" = "$after" ]; then
  ok "no container restarted in 40 seconds"
else
  bad "containers restarted (or Pods changed) during 40 seconds"
fi

ready=$($K get endpointslices -l kubernetes.io/service-name=hello -o jsonpath='{range .items[*].endpoints[*]}{.conditions.ready}{"\n"}{end}' | grep -c true)
if [ "$ready" = "$want" ]; then
  ok "Service hello has $ready ready endpoints"
else
  bad "Service hello has $ready ready endpoints (want $want)"
fi

$K port-forward svc/hello 18082:80 >/dev/null 2>&1 &
PF=$!
code=000
for _ in 1 2 3 4 5 6 7 8 9 10; do
  code=$(curl -s -o /dev/null -m 2 -w '%{http_code}' http://127.0.0.1:18082/) && [ "$code" = 200 ] && break
  sleep 0.5
done
if [ "$code" = 200 ]; then
  ok "GET / through the Service answers 200"
else
  bad "GET / through the Service did not answer 200 (got $code)"
fi

if [ ! -d "$DIR" ]; then
  bad "no $DIR/ folder here (run this from the root of your hello repo)"
elif $K diff -f "$DIR/" >/dev/null 2>&1; then
  ok "$DIR/ matches the cluster (kubectl diff is empty)"
else
  bad "$DIR/ differs from the cluster: put your fixes in the files and apply them"
fi

echo
echo "$PASS passed, $FAIL failed"
if [ "$FAIL" = 0 ]; then
  printf '\033[32m✔ ALL CHECKS PASSED.\033[0m Paste this output into your pull request.\n'
else
  exit 1
fi
