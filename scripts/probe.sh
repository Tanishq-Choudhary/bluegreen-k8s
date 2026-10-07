#!/usr/bin/env bash
set -Eeuo pipefail

NS="${NS:-bluegreen}"
IMAGE="${IMAGE:-bluegreen-demo:blue}"

command -v kubectl >/dev/null 2>&1 || { echo "error: kubectl not found" >&2; exit 1; }

kubectl -n "$NS" delete pod probe --ignore-not-found --wait=true >/dev/null

exec kubectl -n "$NS" run probe --rm -i --quiet --restart=Never \
  --image="$IMAGE" --image-pull-policy=IfNotPresent --command -- \
  sh -c "while true; do printf '%s  ' \"\$(date +%T)\"; wget -q -T 2 -O- http://web/version || echo FAIL; sleep 0.5; done"
