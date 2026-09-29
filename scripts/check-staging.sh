#!/usr/bin/env bash
set -euo pipefail

failures=0

check_json() {
  local name="$1" url="$2" expression="$3"
  if ! body=$(curl --fail --silent --show-error --max-time 5 "$url"); then
    echo "FAIL $name: $url"
    failures=$((failures + 1))
    return
  fi
  if ! python3 -c "import json,sys; value=json.load(sys.stdin); assert $expression" <<<"$body"; then
    echo "FAIL $name: unexpected response: $body"
    failures=$((failures + 1))
    return
  fi
  echo "OK   $name"
}

check_http() {
  local name="$1" url="$2"
  if curl --fail --silent --show-error --max-time 5 "$url" >/dev/null; then
    echo "OK   $name"
  else
    echo "FAIL $name: $url"
    failures=$((failures + 1))
  fi
}

check_http "1lotus documentation" "http://127.0.0.1:7771/"
check_json "2lotus readiness" "http://127.0.0.1:7772/ready" "value['status'] == 'ready' and value['strategies'] >= 1 and value['execution_enabled'] is False"
check_json "2lotus telemetry outbox" "http://127.0.0.1:7772/api/metrics" "value['telemetry_outbox_pending'] == 0"
check_json "3lotus readiness" "http://127.0.0.1:7773/ready" "value['status'] == 'ready'"
check_json "4lotus readiness" "http://127.0.0.1:7774/ready" "value['status'] == 'ready' and len(value['bundles']) >= 1"
check_json "5lotus readiness" "http://127.0.0.1:7775/ready" "value['status'] == 'ready'"
check_http "6lotus presentation" "http://127.0.0.1:7776/"

for index in 1 2 3 4 5 6; do
  if systemctl --user is-active --quiet "lotus-next-${index}.service"; then
    echo "OK   lotus-next-${index}.service"
  else
    echo "FAIL lotus-next-${index}.service"
    failures=$((failures + 1))
  fi
done

if ((failures)); then
  echo "$failures staging check(s) failed"
  exit 1
fi

echo "All staging checks passed"
