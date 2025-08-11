# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.1.2
FROM ruby:$RUBY_VERSION-slim AS base

LABEL fly_launch_runtime="rails"

WORKDIR /rails

# Upgrade RubyGems and install bundler 2.6.9
RUN gem update --system 3.4.15 --no-document && \
    gem install bundler -v 2.6.9

# Install required packages for runtime and build
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      postgresql-client \
      build-essential \
      libpq-dev \
      libyaml-dev \
      libxml2-dev \
      libxslt-dev \
      zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV="production"

# Build stage for compiling gems
FROM base AS build

COPY Gemfile Gemfile.lock ./

RUN bundle _2.6.9_ install --verbose && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# Final image for running app
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R 1000:1000 db log storage tmp

USER 1000:1000

ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true"

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
