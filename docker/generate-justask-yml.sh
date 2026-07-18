#!/usr/bin/env bash
# Minimal fallback generator. Prefer control-plane generated justask.yml.
set -euo pipefail

HOSTNAME="${INSTANCE_HOSTNAME:-localhost}"
HTTPS="${INSTANCE_HTTPS:-true}"
SITE_NAME="${SITE_NAME:-RetroGarden Instance}"
SITE_TAGLINE="${SITE_TAGLINE:-Ask questions, give answers.}"
EMAIL_FROM="${EMAIL_FROM:-noreply@${HOSTNAME}}"
CONTACT_EMAIL="${CONTACT_EMAIL:-contact@${HOSTNAME}}"
REDIS_URL="${REDIS_URL:-redis://localhost:6379/0}"
SOURCE_URL="${SOURCE_URL:-https://github.com/Retrospring/retrospring}"

# Escape for double-quoted YAML scalars
yq_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

cat <<YAML
site_name: "$(yq_escape "$SITE_NAME")"
site_tagline: "$(yq_escape "$SITE_TAGLINE")"
use_svg_logo: false
hostname: "$(yq_escape "$HOSTNAME")"
https: ${HTTPS}
email_from: "$(yq_escape "$EMAIL_FROM")"
contact_email: "$(yq_escape "$CONTACT_EMAIL")"
anonymous_name: "Anonymous"
items_per_page: ${ITEMS_PER_PAGE:-10}
redis_url: "$(yq_escape "$REDIS_URL")"
source_url: "$(yq_escape "$SOURCE_URL")"
otp_drift_period: 30
sentry_dsn: ""

forbidden_screen_names:
  - admin
  - administrator
  - moderation
  - moderator
  - mod
  - help
  - retrogarden
  - retrospring
  - justask
  - system
  - support

about: |
  # About

  Hosted on **RetroGarden**.

features:
  discover:
    enabled: ${FEATURE_DISCOVER:-true}
  public:
    enabled: ${FEATURE_PUBLIC:-true}
  registration:
    enabled: ${FEATURE_REGISTRATION:-true}
  advanced_frontpage:
    enabled: ${FEATURE_ADVANCED_FRONTPAGE:-false}
  readonly:
    enabled: ${FEATURE_READONLY:-false}

hcaptcha:
  enabled: ${HCAPTCHA_ENABLED:-false}
  site_key: "${HCAPTCHA_SITE_KEY:-}"
  secret_key: "${HCAPTCHA_SECRET_KEY:-}"

allowed_hosts_in_markdown:
  - twitter.com
  - youtube.com
  - youtu.be
  - github.com
YAML

if [[ "${FOG_ENABLED:-false}" == "true" ]]; then
cat <<YAML

fog:
  credentials:
    provider: "AWS"
    aws_access_key_id: "${FOG_ACCESS_KEY_ID}"
    aws_secret_access_key: "${FOG_SECRET_ACCESS_KEY}"
    region: "${FOG_REGION:-us-east-1}"
    endpoint: "${FOG_ENDPOINT}"
    path_style: ${FOG_PATH_STYLE:-true}
  directory: "${FOG_DIRECTORY:-retrogarden}"
YAML
fi
