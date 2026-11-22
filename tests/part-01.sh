#!/usr/bin/env bash
# End-to-end check for Part 1. Run after `make up load`.
set -euo pipefail

pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*" >&2; exit 1; }
sql()  { kubectl exec deploy/pgtools -- env PGHOST="$1" psql -XAtq -v ON_ERROR_STOP=1 -c "$2"; }

ready=$(kubectl get cluster pg-lab -o jsonpath='{.status.readyInstances}')
[[ $ready == 3 ]] || fail "expected 3 ready instances, got ${ready:-0}"
pass "3 instances ready"

zones=$(kubectl get pods -l cnpg.io/podRole=instance -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' \
  | xargs -I{} kubectl get node {} -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}{"\n"}' \
  | sort -u | wc -l | tr -d ' ')
[[ $zones == 3 ]] || fail "instances should be spread over 3 zones, found $zones"
pass "one instance per zone"

[[ $(sql pg-lab-rw 'SELECT pg_is_in_recovery()') == f ]] || fail "pg-lab-rw is not the primary"
pass "pg-lab-rw points at the primary"

[[ $(sql pg-lab-rw "SELECT count(*) FROM pg_stat_replication WHERE state = 'streaming'") == 2 ]] \
  || fail "expected 2 streaming replicas"
pass "2 replicas streaming"

marker=$(date +%s)
sql pg-lab-rw "CREATE TABLE IF NOT EXISTS smoke (marker bigint); INSERT INTO smoke VALUES ($marker);" >/dev/null
for _ in $(seq 1 30); do
  if [[ $(sql pg-lab-ro "SELECT pg_is_in_recovery() AND EXISTS (SELECT 1 FROM smoke WHERE marker = $marker)") == t ]]; then
    pass "write on primary is readable on a replica"; break
  fi
  sleep 1
done || true
[[ $(sql pg-lab-ro "SELECT count(*) FROM smoke WHERE marker = $marker") == 1 ]] || fail "replica never saw the write"

for script in top-queries.sql activity.sql cache-hit.sql replication.sql; do
  kubectl exec deploy/pgtools -- psql -X -v ON_ERROR_STOP=1 -f "$script" >/dev/null || fail "pgtools $script failed"
done
pass "pgtools scripts run from the toolbox"

echo "Part 1 OK"
