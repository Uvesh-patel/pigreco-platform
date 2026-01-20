# frozen_string_literal: true

# Allow Cloudflare Tunnel hosts for remote access
# This enables accessing the platform via trycloudflare.com URLs

Rails.application.config.hosts << ".trycloudflare.com"
Rails.application.config.hosts << "localhost"
