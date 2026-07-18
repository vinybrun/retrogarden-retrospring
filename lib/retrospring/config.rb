# frozen_string_literal: true

module Retrospring
  module Config
    module_function

    def config_hash = {}.with_indifferent_access.tap do |hash|
      # load yml config if it's present
      justask_yml_path = Rails.root.join("config/justask.yml")
      hash.merge!(YAML.load_file(justask_yml_path)) if File.exist?(justask_yml_path)

      # Hosting-friendly overrides from ENV (RetroGarden / multi-instance)
      env_config = {
        site_name: ENV.fetch("SITE_NAME", nil),
        site_tagline: ENV.fetch("SITE_TAGLINE", nil),
        hostname: ENV.fetch("INSTANCE_HOSTNAME", nil) || ENV.fetch("LOCAL_DOMAIN", nil),
        email_from: ENV.fetch("EMAIL_FROM", nil),
        contact_email: ENV.fetch("CONTACT_EMAIL", nil),
        anonymous_name: ENV.fetch("ANONYMOUS_NAME", nil),
        redis_url: ENV.fetch("REDIS_URL", nil),
        source_url: ENV.fetch("SOURCE_URL", nil),
        sentry_dsn: ENV.fetch("SENTRY_DSN", nil),
      }.compact

      if ENV.key?("INSTANCE_HTTPS")
        env_config[:https] = ActiveModel::Type::Boolean.new.cast(ENV["INSTANCE_HTTPS"])
      end

      if ENV.key?("ITEMS_PER_PAGE")
        env_config[:items_per_page] = ENV["ITEMS_PER_PAGE"].to_i
      end

      # Feature flags: FEATURE_REGISTRATION=true/false etc.
      %w[discover public registration advanced_frontpage readonly].each do |feature|
        env_key = "FEATURE_#{feature.upcase}"
        next unless ENV.key?(env_key)

        hash[:features] ||= {}
        hash[:features][feature] ||= {}
        hash[:features][feature][:enabled] = ActiveModel::Type::Boolean.new.cast(ENV[env_key])
      end

      hash.merge!(env_config)

      # Update rails config for mail
      Rails.application.config.action_mailer.default_url_options = {
        host: hash["hostname"],
        protocol: hash["https"] == false ? "http" : "https",
      }
    end

    def registrations_enabled? = feature_enabled?(:registration)

    def advanced_frontpage_enabled? = feature_enabled?(:advanced_frontpage)

    def readonly? = feature_enabled?(:readonly)

    def feature_enabled?(feature) = APP_CONFIG.dig(:features, feature, :enabled)
  end
end
