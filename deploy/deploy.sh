#!/usr/bin/env bash

set -Eeuo pipefail

app_dir="${APP_DIR:-/srv/biltongssh}"
compose_file="$app_dir/compose.yaml"
env_file="$app_dir/.env"
new_image="${1:-}"

if [[ ! "$new_image" =~ ^ghcr\.io/.+@sha256:[a-f0-9]{64}$ ]]; then
  echo "usage: $0 ghcr.io/owner/image@sha256:<digest>" >&2
  exit 2
fi

if [[ ! -f "$compose_file" ]]; then
  echo "missing $compose_file" >&2
  exit 1
fi

old_image=""
if [[ -f "$env_file" ]]; then
  old_image="$(sed -n 's/^IMAGE=//p' "$env_file" | head -n 1)"
fi

rollback() {
  if [[ -n "$old_image" ]]; then
    echo "Deployment failed; rolling back to $old_image" >&2
    printf 'IMAGE=%s\n' "$old_image" > "$env_file"
    docker compose --env-file "$env_file" -f "$compose_file" up -d --force-recreate
  fi
}

trap rollback ERR

printf 'IMAGE=%s\n' "$new_image" > "$env_file"
docker compose --env-file "$env_file" -f "$compose_file" pull
docker compose --env-file "$env_file" -f "$compose_file" up -d --force-recreate

for attempt in {1..30}; do
  if docker inspect --format '{{.State.Running}}' biltongssh 2>/dev/null | grep -q '^true$' \
    && (exec 3<>"/dev/tcp/127.0.0.1/23234") 2>/dev/null; then
    trap - ERR
    echo "Deployed $new_image"
    exit 0
  fi
  sleep 1
done

echo "The container did not become reachable on port 23234" >&2
exit 1
