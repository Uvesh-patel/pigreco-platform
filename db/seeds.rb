# frozen_string_literal: true

# PIGRECO Platform - Main Seed File (Simplified)
# This file loads the minimal seed to ensure compatibility with any Decidim version

puts "==== PIGRECO Platform Seeding Started ===="

# Detect Decidim version
decidim_version = Decidim.version
puts "Detected Decidim version: #{decidim_version}"

# Create the basic system admin if needed
begin
  system_admin = Decidim::System::Admin.find_or_initialize_by(email: "system@pigreco.local")
  system_admin.update!(password: "decidim123456", password_confirmation: "decidim123456")
  puts "System admin created or updated"
rescue => e
  puts "Error creating system admin: #{e.message}"
  # Continue execution - this may be optional in some configurations
end

# Determine the organization's database structure
puts "Analyzing database structure..."
org_columns = ActiveRecord::Base.connection.columns("decidim_organizations").map(&:name)
puts "Organization table has the following columns: #{org_columns.join(', ')}"

# Required organization attributes for specific versions
required_attributes = [
  "name", "host", "default_locale", "available_locales"
]

# Check for specific required attributes based on version
required_attributes << "reference_prefix" if org_columns.include?("reference_prefix")

puts "Required organization attributes: #{required_attributes.join(', ')}"

# Create or update the organization
begin
  # First check if any organization exists
  organization = Decidim::Organization.first
  
  if organization.nil?
    puts "Creating organization..."
    
    # Create the organization directly using SQL to avoid any attribute issues
    connection = ActiveRecord::Base.connection
    
    # Determine the host - use environment variable if set, otherwise localhost
    org_host = ENV['PIGRECO_HOST'] || 'localhost'
    puts "Using host: #{org_host}"
    
    # We're including all the required and useful attributes directly in the SQL
    # This avoids any issues with attributes that don't exist in this Decidim version
    sql = <<-SQL
      INSERT INTO decidim_organizations (
        name, host, default_locale, available_locales, reference_prefix, 
        badges_enabled, send_welcome_notification, twitter_handler, 
        facebook_handler, instagram_handler, youtube_handler, github_handler,
        description, created_at, updated_at, colors
      ) VALUES (
        'PIGRECO', '#{org_host}', 'en', ARRAY['en'], 'PGRC',
        TRUE, TRUE, 'pigreco', 'pigreco', 'pigreco', 'pigreco', 'pigreco',
        '{"en":"PIGRECO - Platform for Integrated Governance of Risk and Enhancement of Community Organizations"}',
        NOW(), NOW(),
        '{"primary":"#2145a6","secondary":"#a85432","success":"#2e7d32","warning":"#c9562c","alert":"#c62828"}'
      ) RETURNING id;
    SQL
    # These colors provide higher contrast with white/light backgrounds to meet WCAG 2 AA standards
    
    puts "Executing organization creation SQL..."
    result = connection.execute(sql)
    org_id = result.first["id"]
    organization = Decidim::Organization.find(org_id)
    puts "Organization created via SQL with ID: #{org_id}"
    
    # Add welcome notification texts if needed via an update statement
    if org_columns.include?("welcome_notification_subject") && org_columns.include?("welcome_notification_body")
      update_sql = <<-SQL
        UPDATE decidim_organizations 
        SET welcome_notification_subject = '{"en":"Welcome to PIGRECO Platform"}',
            welcome_notification_body = '{"en":"Welcome to the PIGRECO Platform! Thank you for joining our community."}'
        WHERE id = #{org_id};
      SQL
      connection.execute(update_sql)
    end
    
    # Create necessary static pages (TOS, Privacy Policy, etc.)
    puts "Creating static pages..."
    
    # Set the TOS version for the organization
    if org_columns.include?("tos_version")
      current_time = Time.current.to_s
      update_sql = <<-SQL
        UPDATE decidim_organizations 
        SET tos_version = '#{current_time}'
        WHERE id = #{org_id};
      SQL
      connection.execute(update_sql)
      puts "Set TOS version to #{current_time}"
    end
    
    # First, create the Terms of Service page
    # In Decidim 0.28.6, the slug must be exactly 'terms-of-service' for the TOS page to work properly
    tos_page = Decidim::StaticPage.find_or_initialize_by(
      slug: "terms-of-service",
      organization: organization
    )
    
    unless tos_page.persisted?
      tos_page.update!(
        title: { en: "Terms and Conditions" },
        content: { en: "<h2>Terms and Conditions</h2><p>This is the Terms of Service for the PIGRECO Platform.</p><p>By using this platform, you agree to abide by these terms and conditions.</p>" },
        show_in_footer: true
      )
      puts "Created Terms of Service page"
    end
    
    # Create Privacy Policy page
    privacy_page = Decidim::StaticPage.find_or_initialize_by(
      slug: "privacy-policy",
      organization: organization
    )
    
    unless privacy_page.persisted?
      privacy_page.update!(
        title: { en: "Privacy Policy" },
        content: { en: "<h2>Privacy Policy</h2><p>This is the Privacy Policy for the PIGRECO Platform.</p><p>We are committed to protecting your personal data and respecting your privacy.</p>" },
        show_in_footer: true
      )
      puts "Created Privacy Policy page"
    end
    
    # Create Accessibility page
    accessibility_page = Decidim::StaticPage.find_or_initialize_by(
      slug: "accessibility",
      organization: organization
    )
    
    unless accessibility_page.persisted?
      accessibility_page.update!(
        title: { en: "Accessibility" },
        content: { en: "<h2>Accessibility</h2><p>The PIGRECO Platform is committed to being accessible to everyone.</p><p>This site is designed to meet WCAG 2 AA accessibility standards.</p>" },
        show_in_footer: true
      )
      puts "Created Accessibility page"
    end
    
    # Add show_statistics if it exists via an update statement
    if org_columns.include?("show_statistics")
      update_sql = <<-SQL
        UPDATE decidim_organizations 
        SET show_statistics = TRUE
        WHERE id = #{org_id};
      SQL
      connection.execute(update_sql)
    end
  else
    puts "Organization already exists with ID: #{organization.id}, host: #{organization.host}"
    # Update host if PIGRECO_HOST is set
    if ENV['PIGRECO_HOST'] && organization.host != ENV['PIGRECO_HOST']
      organization.update!(host: ENV['PIGRECO_HOST'], secondary_hosts: ['localhost'])
      puts "Updated organization host to: #{ENV['PIGRECO_HOST']}"
    end
  end
rescue => e
  puts "Error in organization setup: #{e.message}"
  puts e.backtrace.join("\n") if ENV["DEBUG"]
  # Try to continue with existing organization
  organization = Decidim::Organization.first
  if organization
    puts "Continuing with existing organization: #{organization.name} (ID: #{organization.id})"
  else
    puts "No organization found - cannot continue"
    exit 1
  end
end

# Create an admin user - using pure SQL approach to bypass any validation issues
begin
  # Check if admin user already exists first
  admin = Decidim::User.find_by(email: "admin@pigreco.local", organization: organization)
  
  if admin.nil?
    puts "Creating admin user..."
    
    # Get database connection
    connection = ActiveRecord::Base.connection
    
    # Get the columns from the decidim_users table
    user_columns = connection.columns("decidim_users").map(&:name)
    puts "User table has columns: #{user_columns.join(', ')}"
    
    # Create a secure password hash
    password = "decidim123456789"
    # Use the Devise hasher to encrypt the password properly
    require 'bcrypt'
    encrypted_password = BCrypt::Password.create(password)
    
    # Build the column and values arrays for the SQL query
    columns = [
      "email", "encrypted_password", "name", "nickname", 
      "organization_id", "confirmed_at", "admin", "locale",
      "tos_agreement", "created_at", "updated_at"
    ]
    
    # Make sure all columns exist in the table
    columns = columns.select { |col| user_columns.include?(col) }
    
    # Build the values array with proper timestamp format for confirmed_at
    current_time = Time.current.to_s(:db)
    values = [
      "'admin@pigreco.local'", 
      "'#{encrypted_password}'", 
      "'PIGRECO Admin'", 
      "'pigreco_admin'", 
      "#{organization.id}", 
      "'#{current_time}'", # confirmed_at as timestamp with proper format
      "TRUE", 
      "'en'", 
      "TRUE", 
      "'#{current_time}'", 
      "'#{current_time}'"
    ]
    
    # Match the values array to the columns array
    values = values.first(columns.size)
    
    # Create a simpler set of columns and values for the admin user
    admin_columns = [
      "email", "encrypted_password", "name", "nickname", 
      "decidim_organization_id", "confirmed_at", "admin", "locale",
      "tos_agreement", "created_at", "updated_at", "type"
    ]
    
    # Make sure all columns exist in the table
    admin_columns = admin_columns.select { |col| user_columns.include?(col) }
    
    # Create values with proper types for each column
    admin_values = []
    admin_columns.each do |col|
      case col
      when "email"
        admin_values << "'admin@pigreco.local'"
      when "encrypted_password"
        admin_values << "'#{encrypted_password}'"
      when "name"
        admin_values << "'PIGRECO Admin'"
      when "nickname"
        admin_values << "'pigreco_admin'"
      when "decidim_organization_id"
        admin_values << organization.id.to_s
      when "confirmed_at", "created_at", "updated_at"
        admin_values << "'#{current_time}'"
      when "admin", "tos_agreement"
        admin_values << "TRUE"
      when "locale"
        admin_values << "'en'"
      when "type"
        admin_values << "'Decidim::User'" # According to Decidim's model, the type should be 'Decidim::User'
      else
        admin_values << "NULL"
      end
    end
    
    # Build and execute the SQL query
    sql = "INSERT INTO decidim_users (#{admin_columns.join(', ')}) VALUES (#{admin_values.join(', ')}) RETURNING id;"
    
    puts "Executing SQL: #{sql}"
    result = connection.execute(sql)
    
    if result.first && result.first["id"]
      admin_id = result.first["id"]
      admin = Decidim::User.find(admin_id)
      puts "Admin user created successfully with ID: #{admin_id}"
      
      # Make the admin user accept the Terms of Service
      if connection.column_exists?("decidim_users", "accepted_tos_version")
        admin_user = Decidim::User.find(admin_id)
        admin_user.accepted_tos_version = organization.tos_version
        admin_user.save!(validate: false)
        puts "Admin user has accepted the Terms of Service"
      end
    else
      puts "Failed to create admin user via SQL"
    end
  else
    # Admin exists - reset password to ensure login works
    # Use reset_password method which properly encrypts via Devise
    admin.reset_password("decidim123456789", "decidim123456789")
    admin.confirmed_at ||= Time.current
    admin.failed_attempts = 0
    admin.locked_at = nil
    admin.accepted_tos_version = organization.tos_version
    admin.save!(validate: false)
    puts "Admin user already exists with ID: #{admin.id} (password reset)"
  end
rescue => e
  puts "Error creating admin user: #{e.message}"
  puts e.backtrace.join("\n") if ENV["DEBUG"]
  # Continue with the rest of the seeds even if admin creation fails
end

# Create test users for the PIGRECO platform
begin
  puts "Creating test users..."
  3.times do |i|
    user = Decidim::User.find_or_initialize_by(email: "user#{i+1}@pigreco.local", organization: organization)
    
    if user.new_record?
      user.name = "Test User #{i+1}"
      user.nickname = "test_user_#{i+1}"
      user.password = "decidim123456"
      user.password_confirmation = "decidim123456"
      user.organization = organization
      user.confirmed_at = Time.current
      user.locale = "en"
      user.tos_agreement = true
      user.save!
      puts "Test user created: #{user.name}"
    else
      # Reset password for existing test user using Devise method
      user.reset_password("decidim123456", "decidim123456")
      user.confirmed_at ||= Time.current
      user.failed_attempts = 0
      user.locked_at = nil
      user.save!(validate: false)
      puts "Test user already exists: #{user.name} (password reset)"
    end
  rescue => e
    puts "Error creating test user: #{e.message}"
  end
end

# Only load PIGRECO content if we have an organization and we're able to find at least one user
if Decidim::Organization.exists? && Decidim::User.exists?
  begin
    puts "Loading PIGRECO content..."
    require_relative "seeds/pigreco_content"
  rescue => e
    puts "Error loading PIGRECO content: #{e.message}"
    puts e.backtrace.join("\n") if ENV["DEBUG"]
  end

  # Try to configure the homepage if the HomepageConfigurator exists
  if defined?(Pigreco::HomepageConfigurator)
    begin
      puts "Configuring homepage..."
      Pigreco::HomepageConfigurator.configure(Decidim::Organization.first)
      puts "Homepage configured successfully"
    rescue => e
      puts "Error configuring homepage: #{e.message}"
    end
  end
else
  puts "WARNING: Cannot load PIGRECO content because either organization or admin user is missing"
end

puts "==== PIGRECO Platform Seeding Completed ===="
