# RetroGarden production image — builds from local fork source
# syntax=docker/dockerfile:1

FROM ruby:3.2.3-bookworm AS base

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/opt/retrospring/bundle \
    RAILS_LOG_TO_STDOUT=true \
    MALLOC_ARENA_MAX=2

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libxml2-dev \
      libxslt1-dev \
      libmagickwand-dev \
      imagemagick \
      libidn11-dev \
      libicu-dev \
      libyaml-dev \
      curl \
      ca-certificates \
      git \
      nodejs \
      npm \
      shared-mime-info \
 && npm install -g yarn \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash justask \
 && mkdir -p /opt/retrospring/app /opt/retrospring/bundle \
 && chown -R justask:justask /opt/retrospring

WORKDIR /opt/retrospring/app

# Gems first (layer cache)
COPY --chown=justask:justask Gemfile Gemfile.lock ./
USER justask
RUN bundle install --jobs="$(nproc)"

# JS deps
COPY --chown=justask:justask package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# App source
COPY --chown=justask:justask . .

# Precompile assets with dummy config
ARG SECRET_KEY_BASE=build_only_not_for_runtime
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE
RUN cp config/justask.yml.example config/justask.yml \
 && cp config/database.yml.postgres config/database.yml \
 && bundle exec rails locale:generate \
 && bundle exec i18n export \
 && bundle exec rails assets:precompile \
 && rm -f config/justask.yml config/database.yml

USER root
COPY docker/entrypoint.sh /usr/local/bin/retrogarden-entrypoint
RUN chmod +x /usr/local/bin/retrogarden-entrypoint \
 && chown -R justask:justask /opt/retrospring/app
USER justask

EXPOSE 3000
ENTRYPOINT ["retrogarden-entrypoint"]
CMD ["web"]
