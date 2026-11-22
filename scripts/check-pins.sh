#!/usr/bin/env bash
# Fails if any manifest uses a version that differs from versions.env.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source versions.env

fail=0
check() { # check <label> <expected> <grep pattern>
  local label=$1 expected=$2 pattern=$3 found
  while IFS= read -r found; do
    [[ -z $found ]] && continue
    if [[ $found != *"$expected"* ]]; then
      echo "MISMATCH $label: $found (expected $expected)"; fail=1
    fi
  done < <(grep -rhoE "$pattern" --include='*.yaml' [0-9][0-9]-*/ || true)
}

check "Postgres image" "$PG_IMAGE"     'ghcr\.io/cloudnative-pg/postgresql:[^" ]+'
check "curl image"     "$CURL_IMAGE"   'curlimages/curl:[^" ]+'
check "pgtools ref"    "$PGTOOLS_REF"  'value: [0-9a-f]{40}'

if ((fail)); then exit 1; fi
echo "All pins match versions.env"
