# frozen_string_literal: true

# PIGRECO Platform configuration

Rails.application.config.to_prepare do
  Rails.autoloaders.main.push_dir(Rails.root.join("app", "services", "pigreco"))
end

# Allow Cloudflare tunnel hosts
Rails.application.configure do
  config.hosts << /.*\.trycloudflare\.com$/
  config.hosts << "localhost"
  config.hosts.clear if Rails.env.development?
end
