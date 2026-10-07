#!/usr/bin/env bash
set -Eeuo pipefail

NS="${NS:-bluegreen}"
SVC="${SVC:-web}"
TIMEOUT="${TIMEOUT:-120s}"

fail() {
  echo "error: $*" >&2
  exit 1
}

live_slot() {
  kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.slot}'
}

main() {
  command -v kubectl >/dev/null 2>&1 || fail "kubectl not found"

  local target="${1:-}"
  case "$target" in
    status)
      echo "live: $(live_slot)"
      return 0
      ;;
    blue | green) ;;
    *)
      echo "usage: $0 blue|green|status" >&2
      exit 2
      ;;
  esac

  local live
  live="$(live_slot)"
  if [[ "$live" == "$target" ]]; then
    echo "already live: $target"
    return 0
  fi

  kubectl -n "$NS" get "deploy/web-$target" >/dev/null 2>&1 || fail "deployment web-$target not found"
  kubectl -n "$NS" rollout status "deploy/web-$target" --timeout="$TIMEOUT" || fail "web-$target is not healthy, traffic not switched"

  local ready
  ready="$(kubectl -n "$NS" get "deploy/web-$target" -o jsonpath='{.status.readyReplicas}')"
  [[ "${ready:-0}" -gt 0 ]] || fail "web-$target has no ready pods, traffic not switched"

  kubectl -n "$NS" patch svc "$SVC" --type merge \
    -p "{\"spec\":{\"selector\":{\"app\":\"web\",\"slot\":\"$target\"}}}" >/dev/null

  echo "switched: $live -> $target"
}

main "$@"
