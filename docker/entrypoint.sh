#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-web}"

log() { echo "[retrogarden-entrypoint] $*"; }

# Prefer REDIS_URL / DATABASE_URL from env (control plane injects these)
export RAILS_ENV="${RAILS_ENV:-production}"

if [[ -n "${JUSTASK_YML_B64:-}" ]]; then
  log "Writing config/justask.yml from JUSTASK_YML_B64"
  echo "$JUSTASK_YML_B64" | base64 -d > config/justask.yml
elif [[ -f /config/justask.yml ]]; then
  log "Using mounted /config/justask.yml"
  cp /config/justask.yml config/justask.yml
elif [[ ! -f config/justask.yml ]]; then
  log "Generating config/justask.yml from environment"
  /opt/retrospring/app/docker/generate-justask-yml.sh > config/justask.yml
fi

if [[ -z "${SECRET_KEY_BASE:-}" ]]; then
  log "ERROR: SECRET_KEY_BASE is required"
  exit 1
fi

if [[ -z "${DATABASE_URL:-}" && ! -f config/database.yml ]]; then
  log "ERROR: DATABASE_URL or config/database.yml is required"
  exit 1
fi

wait_for_db() {
  log "Waiting for database..."
  local i=0
  until bundle exec rails runner 'ActiveRecord::Base.connection.execute("SELECT 1")' >/dev/null 2>&1; do
    i=$((i + 1))
    if [[ $i -gt 60 ]]; then
      log "Database not ready after 60 attempts"
      exit 1
    fi
    sleep 2
  done
  log "Database is ready"
}

case "$ROLE" in
  web)
    wait_for_db
    log "Running migrations"
    bundle exec rake db:migrate
    log "Starting Puma"
    exec bundle exec puma -C config/puma.rb
    ;;
  sidekiq)
    wait_for_db
    log "Starting Sidekiq"
    # Density-friendly default; override with SIDEKIQ_CONCURRENCY
    export SIDEKIQ_CONCURRENCY="${SIDEKIQ_CONCURRENCY:-5}"
    exec bundle exec sidekiq -e production -C config/sidekiq.yml -c "$SIDEKIQ_CONCURRENCY"
    ;;
  migrate)
    wait_for_db
    bundle exec rake db:migrate
    ;;
  console)
    wait_for_db
    exec bundle exec rails console
    ;;
  admin)
    # Usage: admin <username>
    wait_for_db
    USERNAME="${2:-}"
    if [[ -z "$USERNAME" ]]; then
      log "Usage: admin <username>"
      exit 1
    fi
    bundle exec rake "justask:admin[${USERNAME}]"
    ;;
  *)
    exec "$@"
    ;;
esac
