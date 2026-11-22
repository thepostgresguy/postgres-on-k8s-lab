#!/usr/bin/env bash
# Usage: retry.sh <attempts> <seconds-between> <command...>
# Used for the first apply after installing the operator, while its
# admission webhook is still starting.
set -euo pipefail
attempts=$1; delay=$2; shift 2
for ((i = 1; i <= attempts; i++)); do
  if "$@"; then exit 0; fi
  echo "Attempt $i/$attempts failed, retrying in ${delay}s..." >&2
  sleep "$delay"
done
echo "Gave up after $attempts attempts: $*" >&2
exit 1
