# frozen_string_literal: true

# PIGRECO Content Seed Script
# This script creates the initial content for the PIGRECO platform.
# It includes:
# - Participatory processes
# - Proposals
# - Meetings
# - Assemblies
# - Comments and votes

require "faker"

# Clear existing demo content if needed
puts "Cleaning existing demo content..."
# We don't delete existing processes to avoid breaking the application if run multiple times
# Just be aware that running this script multiple times will create duplicate content

# Create admin users if they don't exist
puts "Ensuring admin users exist..."
admin_email = "admin@pigreco.local"
admin = Decidim::User.find_or_initialize_by(email: admin_email)
if admin.new_record?
  admin.assign_attributes(
    name: "PIGRECO Admin",
    nickname: "pigreco_admin",
    password: "DecidimStrongPassword123!@#",
    password_confirmation: "DecidimStrongPassword123!@#",
    organization: Decidim::Organization.first,
    confirmed_at: Time.current,
    locale: "en",
    admin: true,
    tos_agreement: true,
    personal_url: "",
    about: "PIGRECO platform administrator",
    accepted_tos_version: Time.current
  )
  admin.skip_confirmation! if admin.respond_to?(:skip_confirmation!)
  admin.save!
  puts "Created admin user: #{admin_email}"
else
  puts "Admin user already exists: #{admin_email}"
end

# Create test users (10 users)
puts "Creating test users..."
test_users = []
10.times do |i|
  email = "user#{i+1}@pigreco.local"
  user = Decidim::User.find_or_initialize_by(email: email)
  if user.new_record?
    user.assign_attributes(
      name: "Test User #{i+1}",
      nickname: "test_user_#{i+1}",
      password: "DecidimStrongPassword123!@#",
      password_confirmation: "DecidimStrongPassword123!@#",
      organization: Decidim::Organization.first,
      confirmed_at: Time.current,
      locale: "en",
      tos_agreement: true,
      personal_url: "",
      about: "Test user for PIGRECO platform",
      accepted_tos_version: Time.current
    )
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.save!
    puts "Created test user: #{email}"
  else
    puts "Test user already exists: #{email}"
  end
  test_users << user
end

# Find or create organization and users - don't exit if not found, try to work with what we have

# Get the organization
organization = Decidim::Organization.first

if organization.nil?
  puts "WARNING: No organization found! Will attempt to create a basic one."
  
  begin
    organization = Decidim::Organization.create!(
      name: "PIGRECO",
      host: "localhost",
      default_locale: "en",
      available_locales: ["en"],
      reference_prefix: "PGRC"
    )
    puts "Created a basic organization"
  rescue => e
    puts "ERROR: Could not create organization: #{e.message}"
    organization = nil
  end
else
  puts "Found organization: #{organization.name}"
end

# Get admin user
admin = Decidim::User.find_by(email: "admin@pigreco.local", organization: organization)

if admin.nil?
  puts "WARNING: No admin user found with email admin@pigreco.local"
  # Try to find any admin user
  admin = Decidim::User.where(admin: true, organization: organization).first
  
  if admin.nil?
    puts "WARNING: No admin users found at all, creating a default one"
    begin
      # Create a secure password that meets Decidim's requirements
      secure_password = "DecidimStrongPassword123!@#"
      
      # Try to create the admin user with direct SQL to bypass validation issues
      connection = ActiveRecord::Base.connection
      
      # Get the columns from the decidim_users table
      user_columns = connection.columns("decidim_users").map(&:name)
      
      # Create a secure password hash
      require 'bcrypt'
      encrypted_password = BCrypt::Password.create(secure_password)
      
      # Create the admin user with SQL
      current_time = Time.current.to_s(:db)
      sql = <<-SQL
        INSERT INTO decidim_users (
          email, encrypted_password, name, nickname, 
          organization_id, confirmed_at, admin, locale,
          tos_agreement, created_at, updated_at
        ) VALUES (
          'admin@pigreco.local', '#{encrypted_password}', 'PIGRECO Admin', 'pigreco_admin', 
          #{organization.id}, '#{current_time}', TRUE, 'en',
          TRUE, '#{current_time}', '#{current_time}'
        ) RETURNING id;
      SQL
      
      begin
        result = connection.execute(sql)
        admin_id = result.first["id"]
        admin = Decidim::User.find(admin_id)
        puts "Created admin user via SQL with ID: #{admin_id}"
      rescue => e
        puts "Error creating admin via SQL: #{e.message}"
        # If SQL fails, try the regular approach with the secure password
        admin = Decidim::User.new(
          email: "admin@pigreco.local",
          name: "PIGRECO Admin",
          nickname: "pigreco_admin",
          password: secure_password,
          password_confirmation: secure_password,
          organization: organization,
          confirmed_at: Time.current,
          locale: "en",
          admin: true,
          tos_agreement: true
        )
        admin.save(validate: false) # Try to bypass validation
      end
      puts "Created a default admin user"
    rescue => e
      puts "ERROR: Could not create admin: #{e.message}"
      # Continue with admin as nil
    end
  else
    puts "Found admin user: #{admin.name} (#{admin.email})"
  end
else
  puts "Found admin user: #{admin.name}"
end

# Get test users
test_users = Decidim::User.where("email LIKE 'user%@pigreco.local'").to_a

if test_users.empty?
  puts "WARNING: No test users found. Will create some basic test users."
  
  # Create at least 2 test users using SQL to bypass validation
  2.times do |i|
    begin
      # Create a secure password that meets Decidim's requirements
      secure_password = "DecidimStrongPassword123!@#"
      
      # Try to create the test user with direct SQL to bypass validation issues
      connection = ActiveRecord::Base.connection
      
      # Create a secure password hash
      require 'bcrypt'
      encrypted_password = BCrypt::Password.create(secure_password)
      
      # Create the test user with SQL
      current_time = Time.current.to_s(:db)
      sql = <<-SQL
        INSERT INTO decidim_users (
          email, encrypted_password, name, nickname, 
          organization_id, confirmed_at, locale,
          tos_agreement, created_at, updated_at
        ) VALUES (
          'user#{i+1}@pigreco.local', '#{encrypted_password}', 'Test User #{i+1}', 'test_user_#{i+1}', 
          #{organization.id}, '#{current_time}', 'en',
          TRUE, '#{current_time}', '#{current_time}'
        ) RETURNING id;
      SQL
      
      begin
        result = connection.execute(sql)
        user_id = result.first["id"]
        user = Decidim::User.find(user_id)
        test_users << user
        puts "Created test user via SQL with ID: #{user_id} - #{user.name}"
      rescue => e
        puts "Error creating test user via SQL: #{e.message}"
        # If SQL fails, try the regular approach with the secure password
        user = Decidim::User.new(
          email: "user#{i+1}@pigreco.local",
          name: "Test User #{i+1}",
          nickname: "test_user_#{i+1}",
          password: secure_password,
          password_confirmation: secure_password,
          organization: organization,
          confirmed_at: Time.current,
          locale: "en",
          tos_agreement: true
        )
        if user.save(validate: false) # Try to bypass validation
          test_users << user
          puts "Created test user with regular approach: #{user.name}"
        else
          puts "Failed to create test user: #{user.errors.full_messages.join(', ')}"
        end
      end
    rescue => e
      puts "ERROR creating test user #{i+1}: #{e.message}"
    end
  end
else
  puts "Found #{test_users.size} test users"
end

# Create a participatory process for PIGRECO
puts "Creating PIGRECO participatory process..."
# Check if process already exists first
pigreco_process_slug = "pigreco-risk-assessment"
process = Decidim::ParticipatoryProcess.find_by(slug: pigreco_process_slug)

if process
  puts "Process already exists with slug: #{pigreco_process_slug}"
else
  begin
    process_attributes = {
      slug: pigreco_process_slug,
      organization: organization,
      title: { en: "Community-Driven Multi-Risk Assessment" },
      subtitle: { en: "Collaborative risk management through participatory mapping" },
      short_description: { 
        en: "PIGRECO invites stakeholders to map and evaluate multiple hazards—earthquake, flood, landslide—using GIS tools and local knowledge."
      },
      description: { 
        en: "PIGRECO invites stakeholders to map and evaluate multiple hazards—earthquake, flood, landslide—using GIS tools and local knowledge. This participatory process brings together communities, experts, and authorities to co-design disaster risk reduction strategies."
      },
      published_at: Time.current
    }
    
    # Add optional attributes if they are supported by this Decidim version
    if Decidim::ParticipatoryProcess.new.respond_to?(:start_date)
      process_attributes[:start_date] = 2.days.ago
    end
    
    if Decidim::ParticipatoryProcess.new.respond_to?(:end_date)
      process_attributes[:end_date] = 30.days.from_now
    end
    
    if Decidim::ParticipatoryProcess.new.respond_to?(:promoted)
      process_attributes[:promoted] = true
    end
    
    process = Decidim::ParticipatoryProcess.create!(process_attributes)
    puts "Created new process with slug: #{pigreco_process_slug}"
  rescue => e
    puts "Error creating participatory process: #{e.message}"
    puts e.backtrace.join("\n") if ENV["DEBUG"]
  end
end

if process
  puts "Participatory process created: #{process.title["en"]}"

  # Create components for the process
  # 1. Proposals component
  puts "Creating Proposals component..."
  begin
    proposals_component = nil
    # Check if component already exists
    existing_component = Decidim::Component.where(participatory_space: process, manifest_name: "proposals").first
    
    if existing_component
      puts "Proposals component already exists"
      proposals_component = existing_component
    else
      component_attributes = {
        participatory_space: process,
        name: { en: "Proposals" },
        manifest_name: "proposals",
        published_at: Time.current
      }
      
      # Add settings if the component supports them
      component_attributes[:settings] = {
        vote_limit: 10,
        comments_enabled: true
      }
      
      proposals_component = Decidim::Component.create!(component_attributes)
      puts "Proposals component created successfully"
    end
  rescue => e
    puts "Error creating proposals component: #{e.message}"
    puts e.backtrace.join("\n") if ENV["DEBUG"]
  end

  # 2. Meetings component
  puts "Creating Meetings component..."
  begin
    meetings_component = nil
    # Check if component already exists
    existing_component = Decidim::Component.where(participatory_space: process, manifest_name: "meetings").first
    
    if existing_component
      puts "Meetings component already exists"
      meetings_component = existing_component
    else
      component_attributes = {
        participatory_space: process,
        name: { en: "Meetings" },
        manifest_name: "meetings",
        published_at: Time.current
      }
      
      # Add settings if the component supports them
      component_attributes[:settings] = {
        comments_enabled: true
      }
      
      meetings_component = Decidim::Component.create!(component_attributes)
      puts "Meetings component created successfully"
    end
  rescue => e
    puts "Error creating meetings component: #{e.message}"
    puts e.backtrace.join("\n") if ENV["DEBUG"]
  end

  # Create proposals if proposals component exists
  if defined?(proposals_component) && proposals_component.present?
    puts "Creating proposals..."
    proposal_data = [
      {
        title: "Earthquake Vulnerability Mapping",
        body: "Deploy community sensors and GIS surveys to identify building vulnerabilities in high-risk areas. This collaborative effort will bring together engineering experts, local residents, and public officials to create detailed vulnerability maps using both technical assessments and local knowledge."
      },
      {
        title: "Flood Impact Simulation Workshop",
        body: "Use AI-powered flood models to run scenario workshops with citizens and experts to better understand potential flood impacts under various climate scenarios. These workshops will combine scientific hydrological models with local knowledge to create more accurate and contextually relevant flood risk maps."
      },
      {
        title: "Public Services Continuity Plan",
        body: "Design backup routes and service hubs for healthcare and transport under multi-hazard conditions to ensure that essential services remain accessible during emergencies. This plan will identify vulnerable service points, create redundancy in critical systems, and establish clear protocols for service provision during different types of disasters."
      },
      {
        title: "Long-Term Urban Resilience Strategy",
        body: "Integrate retrofitting, green infrastructure, and land-use planning over decades to transform our communities into multi-hazard resilient environments. This comprehensive strategy will address not only immediate risks but also long-term challenges posed by climate change and urbanization."
      }
    ]

    proposals = []
    proposal_data.each do |data|
      puts "Creating proposal: #{data[:title]}"
      
      # Check if proposal already exists
      existing_proposals = Decidim::Proposals::Proposal.where(component: proposals_component)
                          .select { |p| p.title["en"] == data[:title] }
      
      if existing_proposals.any?
        puts "Proposal already exists: #{data[:title]}"
        next
      end
      
      begin
        # Ensure we have an author for the proposal
        author = test_users.sample || admin
        raise "No author available for proposal" unless author
        
        # In newer Decidim versions, we need to create the proposal with a coauthor
        # Check which API is available
        if Decidim::Proposals::Proposal.respond_to?(:create_with_author)
          # Use the create_with_author API
          proposal = Decidim::Proposals::Proposal.create_with_author(
            author: author,
            component: proposals_component,
            title: { en: data[:title] },
            body: { en: data[:body] },
            published_at: Time.current
          )
        elsif Decidim::Proposals::ProposalBuilder.respond_to?(:create)
          # Use the ProposalBuilder API
          proposal = Decidim::Proposals::ProposalBuilder.create(
            attributes: {
              component: proposals_component,
              title: { en: data[:title] },
              body: { en: data[:body] },
              published_at: Time.current
            },
            author: author,
            action_user: author
          )
        else
          # Create the proposal first
          proposal = Decidim::Proposals::Proposal.new(
            component: proposals_component,
            title: { en: data[:title] },
            body: { en: data[:body] }
          )
          
          # Set the author and create coauthorship
          proposal.add_coauthor(author) if proposal.respond_to?(:add_coauthor)
          proposal.save!
        end
        
        proposals << proposal
        puts "Created proposal: #{data[:title]}"
        
        # Try to add comments if the Comments module exists
        if defined?(Decidim::Comments) && defined?(Decidim::Comments::Comment) && author
          begin
            commenter = test_users.sample
            next unless commenter # Skip if no commenter available
            
            Decidim::Comments::Comment.create!(
              author: commenter,
              commentable: proposal,
              root_commentable: proposal,
              body: { en: "This is a great proposal that would benefit our community!" }
            )
            puts "Added comment to proposal: #{data[:title]}"
          rescue => e
            puts "Error creating comment: #{e.message}"
          end
        end
      rescue => e
        puts "Error creating proposal: #{e.message}"
        puts e.backtrace.join("\n") if ENV["DEBUG"]
      end
    end
  end

  # Create meetings if meetings component exists
  if defined?(meetings_component) && meetings_component.present?
    puts "Creating meetings..."
    meeting_data = [
      {
        title: "GIS Data Review Session",
        description: "Review the preliminary GIS layers for hazard mapping. In this session, we'll examine the data collected so far, identify gaps, and plan the next steps for community data collection.",
        start_time: 1.day.from_now.change(hour: 15, min: 0),
        end_time: 1.day.from_now.change(hour: 17, min: 0),
        address: "Online via Jitsi",
        location: { en: "Online via Jitsi" },
        location_hints: { en: "Link will be sent to registered participants" }
      },
      {
        title: "Stakeholder Deliberation Meetup",
        description: "Gather NGOs, businesses, and citizens to discuss mitigation scenarios. This in-person session will bring together diverse stakeholders to deliberate on different risk mitigation options, considering their costs, benefits, and social implications.",
        start_time: 7.days.from_now.change(hour: 17, min: 0),
        end_time: 7.days.from_now.change(hour: 19, min: 30),
        address: "City Hall, Room 204, Main Street",
        location: { en: "City Hall, Room 204" },
        location_hints: { en: "Enter through the main entrance, take the elevator to the second floor" }
      }
    ]

    meetings = []
    meeting_data.each do |data|
      puts "Creating meeting: #{data[:title]}"
      
      # Check if meeting already exists
      existing_meetings = Decidim::Meetings::Meeting.where(component: meetings_component)
                        .select { |m| m.title["en"] == data[:title] }
      
      if existing_meetings.any?
        puts "Meeting already exists: #{data[:title]}"
        next
      end
      
      begin
        # Ensure we have an author for the meeting
        author = admin || test_users.first
        raise "No author available for meeting" unless author
        
        meeting_attributes = {
          component: meetings_component,
          title: { en: data[:title] },
          description: { en: data[:description] },
          start_time: data[:start_time],
          end_time: data[:end_time],
          address: data[:address],
          location: data[:location],
          location_hints: data[:location_hints]
        }
        
        # Add author if the model has an author association
        if Decidim::Meetings::Meeting.new.respond_to?(:author=) || 
           Decidim::Meetings::Meeting.new.respond_to?(:author)
          meeting_attributes[:author] = author
        end
        
        # Add organizer if the model has organizer association
        if Decidim::Meetings::Meeting.new.respond_to?(:organizer=) || 
           Decidim::Meetings::Meeting.new.respond_to?(:organizer)
          meeting_attributes[:organizer] = author
        end

        # Add decidim_author_type if the model has this field
        if Decidim::Meetings::Meeting.column_names.include?("decidim_author_type")
          meeting_attributes[:decidim_author_type] = author.class.name
        end
        
        # In Decidim 0.28.6, we need to avoid any published_at references completely
        # Create the meeting using a different approach to avoid the published_at error
        
        # Create meeting instance first without saving
        meeting = Decidim::Meetings::Meeting.new
        
        # Set attributes individually to avoid any method_missing errors
        meeting.component = meetings_component
        meeting.title = { en: data[:title] }
        meeting.description = { en: data[:description] }
        meeting.start_time = data[:start_time]
        meeting.end_time = data[:end_time]
        meeting.address = data[:address]
        meeting.location = data[:location]
        meeting.location_hints = data[:location_hints]
        meeting.decidim_author_id = author.id if author
        meeting.decidim_author_type = author.class.name if author
        
        begin
          # Save the meeting with validation
          meeting.save!
          meetings << meeting
          puts "Created meeting: #{data[:title]}"
        rescue => e
          puts "Error creating meeting: #{e.message}"
          puts "Trying fallback method..."
          
          begin
            # Fallback to SQL insertion if needed
            connection = ActiveRecord::Base.connection
            sql = <<-SQL
              INSERT INTO decidim_meetings_meetings (
                decidim_component_id, title, description, start_time, end_time,
                address, location, location_hints, decidim_author_id, decidim_author_type,
                created_at, updated_at
              ) VALUES (
                #{meetings_component.id}, 
                '#{connection.quote_string(data[:title].to_json)}', 
                '#{connection.quote_string(data[:description].to_json)}',
                '#{data[:start_time].utc.strftime("%Y-%m-%d %H:%M:%S")}',
                '#{data[:end_time].utc.strftime("%Y-%m-%d %H:%M:%S")}',
                '#{connection.quote_string(data[:address])}',
                '#{connection.quote_string(data[:location].to_json)}',
                '#{connection.quote_string(data[:location_hints].to_json)}',
                #{author.id},
                '#{author.class.name}',
                NOW(), NOW()
              ) RETURNING id;
            SQL
            
            result = connection.execute(sql)
            meeting_id = result.first["id"]
            meeting = Decidim::Meetings::Meeting.find(meeting_id)
            meetings << meeting
            puts "Created meeting via SQL: #{data[:title]}"
          rescue => e2
            puts "SQL fallback also failed: #{e2.message}"
            puts e2.backtrace.join("\n") if ENV["DEBUG"]
          end
        end
      rescue => e
        puts "Error in meeting creation process: #{e.message}"
        puts e.backtrace.join("\n") if ENV["DEBUG"]
      end
    end
  end
end

# Create an assembly
puts "Creating assembly..."
# Check if assembly already exists first
pigreco_assembly_slug = "pigreco-governance-assembly"
assembly = Decidim::Assembly.find_by(slug: pigreco_assembly_slug)

if assembly
  puts "Assembly already exists with slug: #{pigreco_assembly_slug}"
else
  begin
    assembly_attributes = {
      slug: pigreco_assembly_slug,
      organization: organization,
      title: { en: "Inter-Municipal Risk Governance Assembly" },
      subtitle: { en: "Collaborative governance across municipal boundaries" },
      short_description: { 
        en: "Regional authorities and community representatives co-design multi-risk frameworks for collaborative governance." 
      },
      description: { 
        en: "This assembly brings together representatives from multiple municipalities, regional authorities, community organizations, and subject matter experts to co-design governance frameworks for addressing risks that cross jurisdictional boundaries." 
      },
      published_at: Time.current
    }
    
    # Add optional attributes if they are supported by this Decidim version
    if Decidim::Assembly.new.respond_to?(:promoted)
      assembly_attributes[:promoted] = true
    end
    
    if Decidim::Assembly.new.respond_to?(:show_statistics)
      assembly_attributes[:show_statistics] = true
    end
    
    # Create in two steps to avoid any announcement-related issues
    assembly = Decidim::Assembly.new(assembly_attributes)
    
    # Skip any problematic attributes if needed
    if assembly.respond_to?(:announcement) 
      # The announcement field exists but might be causing issues,
      # in v0.28.6 it's defined as a translatable field but might not be properly initialized
      assembly.announcement = { en: "" } 
    end
    
    begin
      assembly.save!
      puts "Created new assembly with slug: #{pigreco_assembly_slug}"
    rescue => e
      if e.message.include?("announcement")
        # If the error is specifically about announcement, try saving without validation
        assembly.save(validate: false)
        puts "Created assembly with bypassed validations"
      else
        # Re-raise the error for other issues
        raise e
      end
    end
  rescue => e
    puts "Error creating assembly: #{e.message}"
    puts e.backtrace.join("\n") if ENV["DEBUG"]
  end
end

if assembly
  puts "Assembly created: #{assembly.title["en"]}"
end

puts "PIGRECO content seeding completed successfully!"

# Create participatory processes for PIGRECO
puts "Creating participatory processes..."

# Multi-risk assessment process
multi_risk_process = Decidim::ParticipatoryProcess.find_or_initialize_by(
  slug: "multi-risk-assessment",
  organization: organization
)

if multi_risk_process.new_record?
  multi_risk_process.assign_attributes(
    title: { en: "Multi-Risk Assessment" },
    subtitle: { en: "Collaborative platform for community-driven risk assessment" },
    short_description: { en: "A participatory process to collect and analyze risk data across multiple hazards including earthquakes, floods, landslides, and wildfires." },
    description: { en: "<p>The <strong>Multi-Risk Assessment</strong> participatory process aims to harness collective intelligence to develop comprehensive risk assessments for our territory. This innovative approach combines scientific expertise with local knowledge.</p>

<p>Through this process, we will:</p>
<ul>
  <li>Map vulnerable areas using GIS and community input</li>
  <li>Develop multi-hazard scenarios that consider cascading effects</li>
  <li>Create risk matrices for different sectors (housing, infrastructure, economy)</li>
  <li>Design community-validated risk reduction strategies</li>
  <li>Establish early warning systems that reach all community members</li>
</ul>

<p>The process is structured in four phases:</p>
<ol>
  <li><strong>Data Collection</strong>: Gathering hazard, exposure, vulnerability, and capacity information</li>
  <li><strong>Risk Analysis</strong>: Processing data to identify risk patterns and hotspots</li>
  <li><strong>Risk Evaluation</strong>: Prioritizing risks based on potential impact and likelihood</li>
  <li><strong>Risk Treatment</strong>: Developing strategies to mitigate, transfer, or accept risks</li>
</ol>

<p>We invite all community members, technical experts, local authorities, and interested stakeholders to participate in this process. Your knowledge and perspective are invaluable for building a more resilient community.</p>" },
    start_date: 2.days.ago,
    end_date: 1.year.from_now,
    hero_image: nil, # Would be set to a real image in production
    banner_image: nil, # Would be set to a real image in production
    promoted: true,
    scopes_enabled: true,
    private_space: false,
    developer_group: { en: "PIGRECO Research Team" },
    local_area: { en: "Regional" },
    target: { en: "Citizens, Local authorities, Researchers, Civil Protection, Critical Infrastructure Operators" },
    participatory_scope: { en: "Open participation with moderated working groups" },
    participatory_structure: { en: "Thematic working groups organized by hazard type and cross-cutting issues" },
    meta_scope: { en: "Territory-wide with special focus on high-risk areas" },
    announcement: { en: "<p><strong>Join us in building a safer community through participatory risk assessment!</strong> The first Data Collection phase is now open for contributions. Attend our upcoming workshops or submit information through our online forms.</p>" }
  )
  multi_risk_process.save!
  puts "Created multi-risk assessment process"
else
  puts "Multi-risk assessment process already exists"
end

# Add an admin for the participatory process
admin_role = Decidim::ParticipatoryProcessUserRole.find_or_initialize_by(
  participatory_process: multi_risk_process,
  user: admin,
  role: "admin"
)
admin_role.save! if admin_role.new_record?

# Territorial Planning process
territorial_process = Decidim::ParticipatoryProcess.find_or_initialize_by(
  slug: "territorial-planning",
  organization: organization
)

if territorial_process.new_record?
  territorial_process.assign_attributes(
    title: { en: "Risk-Informed Territorial Planning" },
    subtitle: { en: "Integrating multi-risk assessment into spatial planning" },
    short_description: { en: "A collaborative process to develop innovative approaches for incorporating risk considerations into territorial and urban planning decisions." },
    description: { en: "<p>The <strong>Risk-Informed Territorial Planning</strong> process represents a paradigm shift in how we plan our communities. Traditional planning often treats risks as separate considerations, addressed through zoning or building codes. This process aims to integrate multi-risk assessment directly into the core of planning practice.</p>

<p>Through this participatory process, we will:</p>

<ul>
  <li><strong>Develop risk-sensitive land use guidelines</strong> that consider multiple hazards and their interactions</li>
  <li><strong>Create planning tools</strong> that help visualize risk scenarios and their implications for development</li>
  <li><strong>Design risk-informed infrastructure standards</strong> that enhance resilience while promoting sustainability</li>
  <li><strong>Establish participatory mechanisms</strong> for risk governance in planning decisions</li>
  <li><strong>Draft policy recommendations</strong> for integrating risk assessment into legal frameworks</li>
</ul>

<p>This process will involve multiple stakeholders including:</p>

<ul>
  <li>Urban and regional planners</li>
  <li>Architects and engineers</li>
  <li>Local and regional authorities</li>
  <li>Civil protection agencies</li>
  <li>Community representatives</li>
  <li>Environmental organizations</li>
  <li>Economic development agencies</li>
  <li>Academic and research institutions</li>
</ul>

<p>We will work through a series of collaborative workshops, technical sessions, and public consultations to develop guidelines that are both scientifically sound and practically implementable.</p>

<p>The ultimate goal is to transform how territorial planning addresses risk - moving from reactive approaches focused on disaster response to proactive strategies that prevent risk creation in the first place.</p>" },
    start_date: 1.month.ago,
    end_date: 8.months.from_now,
    hero_image: nil,
    banner_image: nil,
    promoted: true,
    scopes_enabled: true,
    private_space: false,
    developer_group: { en: "PIGRECO Urban Planning and Risk Integration Team" },
    local_area: { en: "Regional - Covering Urban, Peri-urban and Rural Areas" },
    target: { en: "Urban planners, Architects, Engineers, Local authorities, Civil protection agencies, Citizens, Environmental organizations" },
    participatory_scope: { en: "Structured participation with technical working groups and public consultation phases" },
    participatory_structure: { en: "Thematic working groups, Expert panels, Public forums, Online consultation" },
    meta_scope: { en: "Territorial and Urban Planning with Risk Integration" },
    announcement: { en: "<p><strong>Help shape the future of resilient territorial planning!</strong> Join our kickoff workshop on June 15th where we'll present the initial risk mapping results and begin collaborative planning exercises.</p>" }
  )
  territorial_process.save!
  puts "Created territorial planning process"
else
  puts "Territorial planning process already exists"
end

# Create participatory process phases for multi-risk process
puts "Creating process phases..."

phases = [
  {
    title: { en: "Data Collection" },
    description: { en: "<p>Collect data on hazards, exposure, vulnerability, and capacity across the territory.</p>" },
    start_date: 2.days.ago,
    end_date: 3.months.from_now,
    position: 0,
    active: true
  },
  {
    title: { en: "Risk Analysis" },
    description: { en: "<p>Analyze collected data to identify and characterize multi-risk scenarios.</p>" },
    start_date: 3.months.from_now,
    end_date: 6.months.from_now,
    position: 1,
    active: false
  },
  {
    title: { en: "Risk Evaluation" },
    description: { en: "<p>Evaluate risk levels and priorities for different areas and sectors.</p>" },
    start_date: 6.months.from_now,
    end_date: 9.months.from_now,
    position: 2,
    active: false
  },
  {
    title: { en: "Risk Treatment" },
    description: { en: "<p>Develop and prioritize risk reduction measures and strategies.</p>" },
    start_date: 9.months.from_now,
    end_date: 1.year.from_now,
    position: 3,
    active: false
  }
]

phases.each do |phase_attrs|
  phase = Decidim::ParticipatoryProcessStep.find_or_initialize_by(
    participatory_process: multi_risk_process,
    position: phase_attrs[:position]
  )
  
  if phase.new_record?
    phase.assign_attributes(
      title: phase_attrs[:title],
      description: phase_attrs[:description],
      start_date: phase_attrs[:start_date],
      end_date: phase_attrs[:end_date],
      active: phase_attrs[:active]
    )
    phase.save!
    puts "Created phase: #{phase_attrs[:title][:en]}"
  else
    puts "Phase already exists: #{phase_attrs[:title][:en]}"
  end
end

# Create assemblies
puts "Creating assemblies..."

# Risk Governance Assembly
risk_governance_assembly = Decidim::Assembly.find_or_initialize_by(
  slug: "risk-governance-assembly",
  organization: organization
)

if risk_governance_assembly.new_record?
  # First, find or create the assembly type
  assembly_type = Decidim::AssembliesType.find_or_create_by!(organization: organization, title: { en: "Others" })
  
  # Create assembly with only basic attributes first, then we'll try to update with additional attributes
  assembly_attributes = {
    title: { en: "Multi-Stakeholder Risk Governance Assembly" },
    subtitle: { en: "Permanent coordination body for integrated risk governance" },
    short_description: { en: "A permanent assembly that brings together diverse stakeholders to coordinate risk governance activities, ensure transparency, and build consensus around multi-risk management policies and actions." },
    description: { en: "<p>The <strong>Multi-Stakeholder Risk Governance Assembly</strong> serves as the central coordination body for our territory's risk management approach. It represents a paradigm shift from fragmented, sector-specific approaches to an integrated, multi-hazard governance framework.</p>" },
    organization: organization,
    slug: "risk-governance-assembly",
    published_at: Time.current,
    promoted: true,
    scopes_enabled: false,
    private_space: false
  }
  
  # Only add assembly_type if the association exists
  if risk_governance_assembly.respond_to?(:assembly_type) && defined?(Decidim::AssembliesType)
    assembly_attributes[:assembly_type] = assembly_type
  end
  
  # Get database connection for direct SQL
  connection = ActiveRecord::Base.connection
  
  # Create assembly directly via SQL to avoid announcement issues completely
  sql = <<-SQL
    INSERT INTO decidim_assemblies (
      title, subtitle, slug, short_description, description,
      decidim_organization_id, published_at, promoted, scopes_enabled,
      private_space, decidim_assemblies_type_id, created_at, updated_at
    ) VALUES (
      '#{connection.quote_string({ en: "Multi-Stakeholder Risk Governance Assembly" }.to_json)}',
      '#{connection.quote_string({ en: "Permanent coordination body for integrated risk governance" }.to_json)}',
      'risk-governance-assembly',
      '#{connection.quote_string({ en: "A permanent assembly that brings together diverse stakeholders to coordinate risk governance activities, ensure transparency, and build consensus around multi-risk management policies and actions." }.to_json)}',
      '#{connection.quote_string({ en: "<p>The <strong>Multi-Stakeholder Risk Governance Assembly</strong> serves as the central coordination body for our territory's risk management approach. It represents a paradigm shift from fragmented, sector-specific approaches to an integrated, multi-hazard governance framework.</p>" }.to_json)}',
      #{organization.id},
      NOW(),
      TRUE,
      FALSE,
      FALSE,
      #{assembly_type.id},
      NOW(), NOW()
    ) RETURNING id;
  SQL
  
  begin
    result = connection.execute(sql)
    assembly_id = result.first["id"]
    risk_governance_assembly = Decidim::Assembly.find(assembly_id)
    puts "Created risk governance assembly via SQL with ID: #{assembly_id}"
  rescue => e
    puts "SQL insertion failed: #{e.message}"
    puts e.backtrace.join("\n") if ENV["DEBUG"]
  end
else
  puts "Risk governance assembly already exists"
end

# Create components for the multi-risk process
puts "Creating components for multi-risk process..."

# Proposals component
proposals_component = Decidim::Component.find_or_initialize_by(
  participatory_space: multi_risk_process,
  manifest_name: "proposals"
)

if proposals_component.new_record?
  proposals_component.assign_attributes(
    name: { en: "Risk Assessment Proposals" },
    settings: {
      vote_limit: 10,
      proposal_length: 5000,
      proposal_edit_before_minutes: 60,
      threshold_per_proposal: 0,
      can_accumulate_supports_beyond_threshold: true,
      proposal_answering_enabled: true,
      official_proposals_enabled: true,
      comments_enabled: true,
      geocoding_enabled: true,
      attachments_allowed: true,
      resources_permissions_enabled: true,
      collaborative_drafts_enabled: true,
      participatory_texts_enabled: false
    },
    step_settings: {
      multi_risk_process.active_step.id => {
        votes_enabled: true,
        votes_blocked: false,
        votes_hidden: false,
        comments_enabled: true,
        creation_enabled: true,
        amendment_creation_enabled: true,
        amendment_reaction_enabled: true,
        amendment_promotion_enabled: true
      }
    },
    weight: 0,
    published_at: Time.current
  )
  proposals_component.save!
  puts "Created proposals component"
else
  puts "Proposals component already exists"
end

# Meetings component
meetings_component = Decidim::Component.find_or_initialize_by(
  participatory_space: multi_risk_process,
  manifest_name: "meetings"
)

if meetings_component.new_record?
  meetings_component.assign_attributes(
    name: { en: "Risk Assessment Meetings" },
    settings: {
      comments_enabled: true,
      resources_permissions_enabled: true,
      announcement: { en: "<p>Join our meetings to discuss risk assessment methodologies and results.</p>" },
      default_registration_terms: { en: "I agree to participate constructively in this meeting." }
    },
    weight: 1,
    published_at: Time.current
  )
  meetings_component.save!
  puts "Created meetings component"
else
  puts "Meetings component already exists"
end

# Create some sample proposals
puts "Creating sample proposals..."

proposals = [
  {
    title: { en: "Integrated Earthquake Risk Assessment Framework" },
    body: { en: "<h3>Proposal for a Community-Driven Earthquake Risk Assessment Framework</h3>

<p>Our region faces significant seismic hazards that require a comprehensive approach to risk assessment. Current methods often focus solely on hazard analysis without adequately addressing vulnerability and exposure, or they operate in technical silos disconnected from community knowledge.</p>

<h4>Proposed Framework Components</h4>

<ol>
  <li><strong>Advanced Hazard Analysis</strong>
    <ul>
      <li>Detailed fault mapping and characterization using LiDAR and field surveys</li>
      <li>Probabilistic Seismic Hazard Analysis (PSHA) incorporating latest ground motion prediction equations</li>
      <li>Site-specific amplification studies based on microzonation</li>
      <li>Secondary hazard assessment (liquefaction, landslides, tsunami potential)</li>
      <li>Climate change considerations for hydro-meteorological triggers</li>
    </ul>
  </li>
  
  <li><strong>Comprehensive Exposure Database</strong>
    <ul>
      <li>Building inventory with structural typology, age, height, and materials</li>
      <li>Critical infrastructure mapping (hospitals, schools, bridges, utilities)</li>
      <li>Population distribution and dynamics (day/night, seasonal variations)</li>
      <li>Economic assets and production facilities</li>
      <li>Cultural heritage sites and environmental assets</li>
    </ul>
  </li>
  
  <li><strong>Multi-dimensional Vulnerability Assessment</strong>
    <ul>
      <li>Physical vulnerability: Building fragility curves based on local construction practices</li>
      <li>Social vulnerability: Demographic factors affecting capacity to prepare, respond, and recover</li>
      <li>Systemic vulnerability: Dependencies and cascading effects between systems</li>
      <li>Economic vulnerability: Business interruption and long-term recovery challenges</li>
      <li>Institutional vulnerability: Governance and coordination capabilities</li>
    </ul>
  </li>
  
  <li><strong>Integrated Risk Modeling</strong>
    <ul>
      <li>Multi-criteria risk assessment incorporating all dimensions</li>
      <li>Scenario-based analysis for emergency planning</li>
      <li>Probabilistic risk assessment for long-term planning</li>
      <li>Cost-benefit analysis for prioritizing mitigation measures</li>
      <li>Dynamic risk modeling accounting for temporal changes</li>
    </ul>
  </li>
</ol>

<h4>Community Integration Methods</h4>

<ul>
  <li>Participatory mapping sessions with local residents to identify vulnerable areas</li>
  <li>Citizen science initiatives for building inventory and vulnerability data collection</li>
  <li>Local knowledge documentation on historical events and impacts</li>
  <li>Community validation workshops for risk assessment results</li>
  <li>Joint scenario exercises with emergency responders and community groups</li>
</ul>

<h4>Implementation Timeline</h4>

<ul>
  <li><strong>Phase 1 (3 months):</strong> Data collection and community engagement setup</li>
  <li><strong>Phase 2 (6 months):</strong> Hazard, exposure, and vulnerability assessment</li>
  <li><strong>Phase 3 (3 months):</strong> Risk modeling and scenario development</li>
  <li><strong>Phase 4 (6 months):</strong> Risk reduction strategy development and implementation planning</li>
  <li><strong>Phase 5 (ongoing):</strong> Monitoring, evaluation, and updating</li>
</ul>

<h4>Expected Outcomes</h4>

<ul>
  <li>Comprehensive earthquake risk atlas accessible to all stakeholders</li>
  <li>Community-validated priority areas for structural and non-structural interventions</li>
  <li>Targeted risk reduction strategies with clear implementation pathways</li>
  <li>Enhanced community risk awareness and preparedness</li>
  <li>Decision-support system for land use planning and building regulations</li>
</ul>

<p>This framework will transform our approach to earthquake risk by combining scientific rigor with local knowledge and creating actionable information for all stakeholders. I propose establishing a multi-disciplinary working group to develop the detailed implementation plan.</p>" }
  },
  {
    title: { en: "Multi-Dimensional Flood Risk Mapping System" },
    body: { en: "<h3>Proposal for an Innovative Flood Risk Mapping System</h3>

<p>Traditional flood maps often fail to capture the complex nature of flood risk, particularly in a changing climate with multiple hazard interactions. I propose developing a next-generation flood risk mapping system that integrates multiple dimensions of flood hazard with detailed vulnerability and exposure data.</p>

<h4>Key Innovations</h4>

<ol>
  <li><strong>Multi-Hazard Flood Characterization</strong>
    <ul>
      <li>Fluvial (riverine) flooding using 2D hydraulic models</li>
      <li>Pluvial (surface water) flooding with high-resolution urban drainage modeling</li>
      <li>Coastal flooding including storm surge and sea level rise scenarios</li>
      <li>Groundwater flooding in susceptible areas</li>
      <li>Flash flood potential in steep catchments</li>
      <li>Dam and levee failure scenarios</li>
    </ul>
  </li>
  
  <li><strong>Climate Change Integration</strong>
    <ul>
      <li>Downscaled climate projections for multiple time horizons (2030, 2050, 2100)</li>
      <li>Changes in rainfall intensity and patterns</li>
      <li>Sea level rise considerations for coastal areas</li>
      <li>Land use change scenarios affecting runoff characteristics</li>
      <li>Uncertainty visualization and communication</li>
    </ul>
  </li>
  
  <li><strong>Dynamic Exposure Mapping</strong>
    <ul>
      <li>High-resolution building and infrastructure database</li>
      <li>Critical facilities with service areas and dependencies</li>
      <li>Population distribution with temporal variations</li>
      <li>Mobile assets (vehicles, livestock, equipment)</li>
      <li>Environmental and cultural assets</li>
    </ul>
  </li>
  
  <li><strong>Vulnerability Profiling</strong>
    <ul>
      <li>Building-specific depth-damage functions calibrated to local conditions</li>
      <li>Infrastructure fragility considering cascading failures</li>
      <li>Social vulnerability indices at neighborhood level</li>
      <li>Business vulnerability including supply chain disruptions</li>
      <li>Adaptation capacity indicators</li>
    </ul>
  </li>
</ol>

<h4>Technical Implementation</h4>

<ul>
  <li>High-resolution digital elevation model (1m or better) using LiDAR</li>
  <li>Integration of gray and green infrastructure in hydraulic models</li>
  <li>Machine learning techniques for vulnerability classification</li>
  <li>Web-based GIS platform with interactive visualization</li>
  <li>API for integration with planning and emergency management systems</li>
  <li>Mobile data collection tools for ground-truthing and updating</li>
</ul>

<h4>Participatory Elements</h4>

<ul>
  <li>Community mapping of historical flood extents and impacts</li>
  <li>Citizen science monitoring of precipitation and water levels</li>
  <li>Local knowledge integration on drainage problems and vulnerable areas</li>
  <li>Collaborative scenario development with stakeholders</li>
  <li>User-friendly interfaces for non-technical stakeholders</li>
</ul>

<h4>Applications</h4>

<ul>
  <li>Risk-informed urban planning and zoning</li>
  <li>Prioritization of structural and nature-based flood defense investments</li>
  <li>Early warning system enhancement with impact-based forecasting</li>
  <li>Insurance premium calculation and risk transfer mechanisms</li>
  <li>Evacuation planning and emergency response</li>
  <li>Climate adaptation strategy development</li>
</ul>

<p>This mapping system will transform how we understand and communicate flood risk, moving from simple hazard maps to comprehensive risk intelligence that supports better decision-making across all sectors.</p>" }
  },
  {
    title: { en: "Integrated Multi-Hazard Early Warning System" },
    body: { en: "<h3>Proposal for a Next-Generation Multi-Hazard Early Warning System</h3>

<p>Current early warning systems in our region operate in silos, with separate systems for different hazards, inconsistent messaging, and gaps in reaching vulnerable populations. I propose developing an integrated multi-hazard early warning system (MHEWS) that leverages modern technology and social science to create a comprehensive, people-centered approach.</p>

<h4>System Architecture</h4>

<ol>
  <li><strong>Monitoring and Detection</strong>
    <ul>
      <li>Integration of existing monitoring networks (meteorological, seismic, hydrological)</li>
      <li>Deployment of additional IoT sensors in high-risk/low-coverage areas</li>
      <li>Satellite data integration for wide-area monitoring</li>
      <li>Social media and crowdsourced data analysis</li>
      <li>Automated anomaly detection using AI algorithms</li>
    </ul>
  </li>
  
  <li><strong>Forecasting and Risk Analysis</strong>
    <ul>
      <li>Multi-hazard modeling including cascading and compound events</li>
      <li>Impact-based forecasting linked to vulnerability databases</li>
      <li>Ensemble predictions with uncertainty quantification</li>
      <li>Machine learning for pattern recognition and prediction enhancement</li>
      <li>Continuous recalibration based on observed events</li>
    </ul>
  </li>
  
  <li><strong>Warning Generation and Dissemination</strong>
    <ul>
      <li>Common alerting protocol implementation across all hazards</li>
      <li>Multi-channel dissemination (mobile apps, SMS, radio, TV, sirens, social media)</li>
      <li>Targeted messaging based on location and vulnerability profiles</li>
      <li>Automated translation into multiple languages and accessible formats</li>
      <li>Feedback mechanisms to confirm receipt and understanding</li>
    </ul>
  </li>
  
  <li><strong>Response Capacity</strong>
    <ul>
      <li>Pre-defined response protocols linked to warning levels</li>
      <li>Evacuation route mapping and real-time updates</li>
      <li>Integration with emergency services dispatch systems</li>
      <li>Activation of community response teams</li>
      <li>Business continuity triggering for critical services</li>
    </ul>
  </li>
</ol>

<h4>People-Centered Approach</h4>

<ul>
  <li>Tailored communication strategies for different demographic groups</li>
  <li>Special provisions for vulnerable populations (elderly, disabled, non-native speakers)</li>
  <li>Community engagement in system design and testing</li>
  <li>Indigenous and local knowledge integration</li>
  <li>Regular drills and educational campaigns</li>
  <li>Two-way communication channels for questions and reports</li>
</ul>

<h4>Governance Structure</h4>

<ul>
  <li>Multi-agency coordination platform with clear roles and responsibilities</li>
  <li>Standard operating procedures for different warning levels</li>
  <li>Cross-border information sharing protocols</li>
  <li>Public-private partnerships for infrastructure and service provision</li>
  <li>Legal framework ensuring mandate and sustainability</li>
</ul>

<h4>Technical Specifications</h4>

<ul>
  <li>Cloud-based architecture with edge computing for critical components</li>
  <li>Open standards and APIs for interoperability</li>
  <li>Redundant systems and backup power for critical infrastructure</li>
  <li>Cybersecurity measures against false alerts and system compromise</li>
  <li>Mobile-first design for public interfaces</li>
</ul>

<p>This integrated MHEWS will transform our capacity to anticipate and respond to multiple hazards, significantly reducing casualties and damages while building community resilience. I recommend establishing a multi-stakeholder steering committee to oversee its development and implementation.</p>" }
  },
  {
    title: { en: "Community-Based Risk Assessment Toolkit" },
    body: { en: "<h3>Proposal for a Community-Based Risk Assessment Toolkit</h3>

<p>Professional risk assessments often fail to capture local realities and knowledge, while many communities lack the tools to systematically assess and document their risk perceptions and experiences. I propose developing a comprehensive toolkit that empowers communities to conduct their own risk assessments while generating data that can inform official risk management processes.</p>

<h4>Toolkit Components</h4>

<ol>
  <li><strong>Participatory Mapping Tools</strong>
    <ul>
      <li>Physical mapping kits with base maps, transparent overlays, and markers</li>
      <li>Mobile mapping application with offline capability</li>
      <li>3D physical modeling tools for terrain representation</li>
      <li>Historical timeline mapping templates</li>
      <li>Seasonal calendar templates for temporal hazard patterns</li>
      <li>Transect walk guidelines and documentation forms</li>
    </ul>
  </li>
  
  <li><strong>Vulnerability and Capacity Assessment Methods</strong>
    <ul>
      <li>Household survey questionnaires (digital and paper versions)</li>
      <li>Focus group discussion guides for different demographic groups</li>
      <li>Community asset inventory templates</li>
      <li>Livelihood analysis tools</li>
      <li>Institutional capacity assessment checklists</li>
      <li>Social network mapping tools</li>
    </ul>
  </li>
  
  <li><strong>Risk Analysis and Prioritization</strong>
    <ul>
      <li>Hazard characterization matrices</li>
      <li>Risk scoring and ranking templates</li>
      <li>Problem tree analysis guides</li>
      <li>Scenario development workshop materials</li>
      <li>Multi-criteria decision analysis tools</li>
      <li>Cost-benefit analysis simplified templates</li>
    </ul>
  </li>
  
  <li><strong>Action Planning and Implementation</strong>
    <ul>
      <li>Community risk reduction planning templates</li>
      <li>Project design and budgeting tools</li>
      <li>Monitoring and evaluation frameworks</li>
      <li>Advocacy and communication strategy guides</li>
      <li>Funding proposal templates</li>
      <li>Implementation tracking tools</li>
    </ul>
  </li>
</ol>

<h4>Format and Accessibility</h4>

<ul>
  <li>Modular design allowing communities to select relevant components</li>
  <li>Multiple formats: physical toolbox, mobile application, web platform</li>
  <li>Visual-heavy design with minimal text dependency</li>
  <li>Multilingual versions with local language adaptations</li>
  <li>Accessible versions for different abilities</li>
  <li>Scalable complexity levels for different community capacities</li>
</ul>

<h4>Integration with Official Systems</h4>

<ul>
  <li>Data export formats compatible with government risk assessment systems</li>
  <li>Validation protocols to incorporate community data into official databases</li>
  <li>Connection pathways to relevant authorities and technical experts</li>
  <li>Framework for combining scientific and local knowledge</li>
  <li>Guidelines for authorities on using community-generated data</li>
</ul>

<h4>Capacity Building Components</h4>

<ul>
  <li>Facilitator training materials and certification process</li>
  <li>Training-of-trainers methodology for local multiplication</li>
  <li>Video tutorials and interactive learning materials</li>
  <li>Peer learning and exchange platform</li>
  <li>Regular refresher content and methodology updates</li>
</ul>

<p>This toolkit will transform risk assessment from a technical, expert-driven process to an inclusive dialogue that values local knowledge while maintaining scientific rigor. It will empower communities to take ownership of their risk reduction strategies while providing valuable ground-truth data to enhance official risk management efforts.</p>

<p>I propose piloting this toolkit in 3-5 diverse communities to refine its components before wider deployment.</p>" }
  }
]

proposals.each_with_index do |proposal_attrs, index|
  author = index.zero? ? admin : test_users[index % test_users.size] unless test_users.empty?
  author ||= admin
  
  proposal = Decidim::Proposals::Proposal.find_or_initialize_by(
    component: proposals_component,
    title: proposal_attrs[:title]
  )
  
  if proposal.new_record?
    # First prepare the proposal attributes
    proposal.assign_attributes(
      body: proposal_attrs[:body],
      state: "accepted",
      answer: { en: "Thank you for your valuable proposal. We will incorporate this into our risk assessment framework." },
      answered_at: Time.current,
      published_at: Time.current
    )
    
    # Add the coauthor before saving
    proposal.add_coauthor(author)
    
    # Now save the proposal with its coauthor
    proposal.save!
    
    puts "Created proposal: #{proposal_attrs[:title][:en]}"
    
    # After the proposal is saved, add votes and comments if we have test users
    unless test_users.empty?
      # Add votes to the proposal
      vote_count = rand(5..15)
      voters = test_users.sample([test_users.size, vote_count].min)
      votes_added = 0
      
      voters.each do |voter|
        begin
          next if voter == author # Skip the author to avoid self-voting
          Decidim::Proposals::ProposalVote.create!(
            proposal: proposal,
            author: voter,
            created_at: rand(1..2).days.ago,
            updated_at: Time.current
          )
          votes_added += 1
        rescue ActiveRecord::RecordInvalid => e
          # Ignore if vote already exists (unique constraint violation)
          puts "  - Skipped duplicate vote from #{voter.name}"
        end
      end
      puts "  Added #{votes_added} votes to the proposal"
      
      # Add comments to the proposal
      comment_count = rand(2..4)
      commenters = test_users.sample([test_users.size, comment_count].min)
      comments_added = 0
      
      commenters.each do |commenter|
        begin
          next if commenter == author # Skip the author to avoid self-commenting
          comment_text = [
            "This is a great proposal for improving risk assessment!",
            "I particularly like the focus on community engagement in this proposal.",
            "The technical aspects of this proposal are well thought out.",
            "This approach could really help our vulnerable communities.",
            "I think we should prioritize this for implementation."
          ].sample
          
          Decidim::Comments::Comment.create!(
            author: commenter,
            commentable: proposal,
            root_commentable: proposal,
            body: { en: comment_text },
            created_at: rand(1..3).days.ago,
            updated_at: Time.current
          )
          comments_added += 1
        rescue => e
          puts "  - Error creating comment: #{e.message}"
        end
      end
      puts "  Added #{comments_added} comments to the proposal"
    end
  else
    puts "Proposal already exists: #{proposal_attrs[:title][:en]}"
  end
end

puts "Creating sample meetings..."

meetings = [
  {
    title: { en: "Multi-Stakeholder Risk Assessment Coordination Workshop" },
    description: { en: "<h3>Risk Assessment Coordination Workshop</h3>

<p>This full-day workshop brings together key stakeholders from across sectors to establish a coordinated approach to multi-risk assessment in our territory. The workshop aims to break down silos between different risk domains and create a unified framework for assessing multiple, interacting hazards.</p>

<h4>Workshop Objectives</h4>
<ul>
  <li>Establish a common understanding of multi-risk assessment concepts and methodologies</li>
  <li>Map existing risk assessment initiatives and identify gaps and overlaps</li>
  <li>Agree on data-sharing protocols and standards for interoperability</li>
  <li>Develop a roadmap for integrated risk assessment activities</li>
  <li>Define roles and responsibilities for different stakeholders</li>
  <li>Create working groups for specific hazards and cross-cutting issues</li>
</ul>

<h4>Agenda</h4>
<ul>
  <li><strong>9:30-10:00</strong>: Registration and coffee</li>
  <li><strong>10:00-10:30</strong>: Welcome and introduction to the PIGRECO platform</li>
  <li><strong>10:30-11:15</strong>: Keynote presentation on multi-risk assessment</li>
  <li><strong>11:15-12:30</strong>: Panel discussion: Current state of risk assessment practices</li>
  <li><strong>12:30-13:30</strong>: Networking lunch</li>
  <li><strong>13:30-14:45</strong>: World Café: Mapping stakeholder capacities and needs</li>
  <li><strong>14:45-15:00</strong>: Coffee break</li>
  <li><strong>15:00-16:00</strong>: Working groups: Developing the roadmap</li>
  <li><strong>16:00-16:30</strong>: Plenary: Presentation of group results and next steps</li>
</ul>

<h4>Who Should Attend</h4>
<p>This workshop is open to representatives from:</p>
<ul>
  <li>Government agencies responsible for different hazards</li>
  <li>Civil protection and emergency management</li>
  <li>Research institutions and universities</li>
  <li>Spatial planning authorities</li>
  <li>Infrastructure operators and utilities</li>
  <li>Insurance and financial sector</li>
  <li>Civil society organizations</li>
  <li>Community representatives</li>
</ul>

<p>Participants should have some responsibility for or involvement in risk assessment, management, or governance in their respective organizations.</p>

<h4>Materials to Bring</h4>
<p>Participants are encouraged to bring information about their current risk assessment practices, including:</p>
<ul>
  <li>Examples of risk maps or assessments they have produced</li>
  <li>Documentation of methodologies used</li>
  <li>Lists of data sources they currently use or need</li>
  <li>Information about ongoing or planned risk assessment initiatives</li>
</ul>

<p>Please register by [date] to help us prepare adequate materials and catering.</p>" },
    address: "Main Conference Center, PIGRECO Research Institute, 45 Science Avenue",
    location: { en: "PIGRECO Research Center Main Conference Hall" },
    location_hints: { en: "The conference hall is located on the first floor of the main building. Enter through the main entrance and follow signs for 'Conference Center'. Parking is available in Lot B with shuttle service to the main entrance." },
    start_time: 2.days.from_now.change(hour: 9, min: 30),
    end_time: 2.days.from_now.change(hour: 16, min: 30)
  },
  {
    title: { en: "Participatory Community Risk Mapping Exercise" },
    description: { en: "<h3>Community Risk Mapping Workshop</h3>

<p>This participatory workshop invites local community members to share their knowledge about risks and vulnerabilities in their neighborhoods. Using innovative mapping techniques, we will capture local perceptions and experiences of hazards to complement technical risk assessments.</p>

<h4>Workshop Purpose</h4>
<p>Local communities often possess detailed knowledge about hazards, vulnerabilities, and coping mechanisms that is not captured in technical assessments. This workshop aims to:</p>
<ul>
  <li>Document community perceptions of different hazards and their spatial distribution</li>
  <li>Identify vulnerable groups, locations, and assets from a community perspective</li>
  <li>Map local resources and capacities for disaster risk reduction</li>
  <li>Understand historical experiences with disasters and changes over time</li>
  <li>Build community awareness about multiple risks and their interactions</li>
</ul>

<h4>Workshop Format</h4>
<p>This will be a highly interactive session using various participatory tools:</p>
<ul>
  <li><strong>3D Model Mapping</strong>: A physical terrain model where participants can identify hazard zones</li>
  <li><strong>Historical Timeline</strong>: Documenting past events and their impacts</li>
  <li><strong>Seasonal Calendar</strong>: Mapping temporal patterns of different hazards</li>
  <li><strong>Social Vulnerability Mapping</strong>: Identifying where vulnerable groups are located</li>
  <li><strong>Resource Mapping</strong>: Documenting critical infrastructure and emergency resources</li>
</ul>

<h4>Who Should Participate</h4>
<p>We encourage participation from diverse community members, including:</p>
<ul>
  <li>Long-term residents with historical knowledge</li>
  <li>Community leaders and representatives</li>
  <li>Members of vulnerable groups (elderly, disabled, etc.)</li>
  <li>Local business owners</li>
  <li>School teachers and healthcare workers</li>
  <li>Youth representatives</li>
</ul>

<p>No special knowledge or preparation is required - just your experience living in the community!</p>

<h4>How the Information Will Be Used</h4>
<p>The knowledge collected will be:</p>
<ul>
  <li>Digitized and integrated with technical risk assessments</li>
  <li>Used to improve emergency planning</li>
  <li>Shared with planning authorities to inform development decisions</li>
  <li>Used to design community-based risk reduction projects</li>
</ul>

<p>All participants will receive a summary of the findings. Refreshments will be provided, and childcare is available upon request.</p>" },
    address: "Municipal Community Center, 123 Main Street",
    location: { en: "Downtown Community Center - Multipurpose Hall" },
    location_hints: { en: "The Community Center is located opposite the public library. The Multipurpose Hall is on the ground floor, with wheelchair access via the side entrance. Street parking is available, and the center is served by bus routes 10 and 14 (Community Center stop)." },
    start_time: 1.week.from_now.change(hour: 14),
    end_time: 1.week.from_now.change(hour: 17, min: 30)
  },
  {
    title: { en: "Technical Working Group on Integrated Flood Risk Modeling" },
    description: { en: "<h3>Technical Working Group: Integrated Flood Risk Modeling</h3>

<p>This technical session brings together specialists in flood risk modeling to develop an integrated approach that accounts for multiple flood types, climate change, and interactions with other hazards.</p>

<h4>Meeting Objectives</h4>
<ul>
  <li>Review the state-of-the-art in flood modeling for different flood types (fluvial, pluvial, coastal)</li>
  <li>Identify key data requirements and availability for the region</li>
  <li>Define modeling approaches that can account for compound flood events</li>
  <li>Establish methods for incorporating climate change projections</li>
  <li>Develop protocols for model validation and uncertainty communication</li>
  <li>Create a roadmap for developing an integrated flood risk model</li>
</ul>

<h4>Technical Topics to Be Covered</h4>
<ul>
  <li><strong>Hydrological Modeling</strong>: Rainfall-runoff models, continuous simulation approaches</li>
  <li><strong>Hydraulic Modeling</strong>: 1D vs 2D models, coupled modeling approaches</li>
  <li><strong>Climate Change Integration</strong>: Downscaling techniques, ensemble approaches</li>
  <li><strong>Compound Event Modeling</strong>: Statistical dependencies, copula methods</li>
  <li><strong>Data Management</strong>: Sources, quality control, processing pipelines</li>
  <li><strong>Uncertainty Analysis</strong>: Monte Carlo methods, sensitivity analysis</li>
</ul>

<h4>Expected Outputs</h4>
<ul>
  <li>Technical specification for an integrated flood modeling framework</li>
  <li>Data inventory and gap analysis</li>
  <li>Model selection criteria and evaluation framework</li>
  <li>Implementation plan with milestones and responsibilities</li>
  <li>Formation of ongoing collaborative modeling group</li>
</ul>

<h4>Who Should Attend</h4>
<p>This working group is designed for technical specialists including:</p>
<ul>
  <li>Hydrologists and hydraulic engineers</li>
  <li>Climate scientists</li>
  <li>GIS and remote sensing specialists</li>
  <li>Risk modelers and statisticians</li>
  <li>Representatives from agencies responsible for flood risk management</li>
  <li>Academic researchers in relevant fields</li>
</ul>

<p>Participants are encouraged to bring examples of their current modeling approaches and challenges for discussion.</p>

<h4>Pre-meeting Materials</h4>
<p>Registered participants will receive a background paper on integrated flood risk modeling approaches one week before the meeting. Please review this material to ensure productive discussions.</p>" },
    address: "Regional Hydrological Institute, 78 River Research Avenue",
    location: { en: "Regional Hydrological Institute - Advanced Modeling Laboratory" },
    location_hints: { en: "The Advanced Modeling Laboratory is located in the east wing of the Hydrological Institute (Building B). Enter through the main reception and take the elevator to the second floor. Sign in at the security desk is required for all visitors. Limited parking available in the institute's parking garage - please carpool if possible." },
    start_time: 2.weeks.from_now.change(hour: 9),
    end_time: 2.weeks.from_now.change(hour: 13, min: 30)
  },
  {
    title: { en: "Risk Communication and Public Engagement Seminar" },
    description: { en: "<h3>Seminar: Effective Risk Communication and Public Engagement</h3>

<p>This interactive seminar focuses on strategies and best practices for communicating complex risk information to diverse audiences and engaging the public in risk governance processes.</p>

<h4>Seminar Focus</h4>
<p>Effective risk communication is essential for translating technical risk assessments into actionable information for decision-makers and the public. This seminar will explore:</p>

<ul>
  <li>Psychological aspects of risk perception and how they influence communication needs</li>
  <li>Evidence-based approaches to communicating uncertainty and probability</li>
  <li>Visual and narrative techniques for making risk information accessible</li>
  <li>Inclusive communication strategies that reach vulnerable and marginalized groups</li>
  <li>Digital and traditional media approaches for different audiences</li>
  <li>Methods for fostering two-way communication and meaningful public engagement</li>
</ul>

<h4>Program</h4>
<ul>
  <li><strong>9:00-9:30</strong>: Welcome and introduction to risk communication challenges</li>
  <li><strong>9:30-10:30</strong>: Keynote presentation on risk communication</li>
  <li><strong>10:30-10:45</strong>: Coffee break</li>
  <li><strong>10:45-12:15</strong>: Panel: Case studies of successful risk communication campaigns</li>
  <li><strong>12:15-13:15</strong>: Lunch</li>
  <li><strong>13:15-14:45</strong>: Workshop: Developing audience-specific communication strategies</li>
  <li><strong>14:45-15:00</strong>: Break</li>
  <li><strong>15:00-16:00</strong>: Practical exercise: Translating technical risk information for different audiences</li>
  <li><strong>16:00-16:30</strong>: Discussion and takeaway messages</li>
</ul>

<h4>Who Should Attend</h4>
<p>This seminar will benefit:</p>
<ul>
  <li>Public information officers and communication specialists</li>
  <li>Emergency managers and civil protection officials</li>
  <li>Risk analysts and researchers who need to communicate their findings</li>
  <li>Planners and policy-makers working with risk information</li>
  <li>Community engagement specialists</li>
  <li>Journalists covering risk and disaster topics</li>
  <li>NGO representatives involved in risk reduction</li>
</ul>

<h4>Speakers</h4>
<p>The seminar features expert speakers from risk communication research, emergency management, media, and community engagement practice.</p>

<h4>Materials Provided</h4>
<ul>
  <li>Risk Communication Handbook with practical guidelines and templates</li>
  <li>Visual library of effective risk communication examples</li>
  <li>Checklist for inclusive communication planning</li>
  <li>Resource list for further learning</li>
</ul>

<p>Registration includes lunch and refreshments. Please indicate any dietary requirements when registering.</p>" },
    address: "Media and Communications Center, 30 Dialogue Boulevard",
    location: { en: "Regional Media and Communications Center - Auditorium" },
    location_hints: { en: "The auditorium is located on the ground floor of the Media Center. The building features a distinctive glass facade and is adjacent to Central Park. Public transportation recommended as parking is limited. The nearest metro station is 'Central Plaza' (5 minute walk)." },
    start_time: 3.weeks.from_now.change(hour: 9),
    end_time: 3.weeks.from_now.change(hour: 16, min: 30)
  }
]

meetings.each_with_index do |meeting_attrs, index|
  # Determine the organizer/creator of the meeting
  organizer = index.zero? ? admin : test_users[index % test_users.size] unless test_users.empty?
  organizer ||= admin
  
  meeting = Decidim::Meetings::Meeting.find_or_initialize_by(
    component: meetings_component,
    title: meeting_attrs[:title]
  )
  
  if meeting.new_record?
    meeting.assign_attributes(
      description: meeting_attrs[:description],
      start_time: meeting_attrs[:start_time],
      end_time: meeting_attrs[:end_time],
      address: meeting_attrs[:address],
      location: meeting_attrs[:location],
      location_hints: meeting_attrs[:location_hints],
      # In Decidim 0.28.6, meetings don't have published_at attribute
      # They are published via the Publicable concern instead
      registration_terms: { en: "I agree to participate constructively in this meeting." },
      registrations_enabled: true,
      available_slots: 50,
      registration_form_enabled: true,
      private_meeting: false,
      transparent: true
    )
    
    # Try to set organizer if the method exists
    if meeting.respond_to?(:organizer=)
      meeting.organizer = organizer
    end
    
    # Try to set author if the method exists (for backwards compatibility)
    if meeting.respond_to?(:author=)
      meeting.author = organizer
    end
    
    meeting.save!
    puts "Created meeting: #{meeting_attrs[:title][:en]}"
    
    # After the meeting is saved, add attendees and comments if we have test users
    unless test_users.empty?
      # Add some attendees to the meeting
      attendee_count = rand(3..10)
      attendees = test_users.sample([test_users.size, attendee_count].min)
      attendees_added = 0
      
      attendees.each do |attendee|
        begin
          next if attendee == organizer # Skip the organizer
          
          # Create registration for the attendee
          if meeting.respond_to?(:registrations) && meeting.registrations_enabled?
            Decidim::Meetings::Registration.create!(
              meeting: meeting,
              user: attendee,
              created_at: rand(1..5).days.ago,
              updated_at: Time.current
            )
            attendees_added += 1
          end
        rescue => e
          puts "  - Error registering attendee: #{e.message}"
        end
      end
      puts "  Added #{attendees_added} attendees to the meeting"
      
      # Add comments to the meeting
      comment_count = rand(2..4)
      commenters = test_users.sample([test_users.size, comment_count].min)
      comments_added = 0
      
      commenters.each do |commenter|
        begin
          next if commenter == organizer # Skip the organizer
          comment_text = [
            "Looking forward to this meeting!",
            "Will this be recorded for those who can't attend?",
            "I have some specific questions about risk mapping methods.",
            "This is exactly the kind of training our community needs.",
            "Will there be follow-up sessions after this workshop?"
          ].sample
          
          # In Decidim 0.28.6, we should check the component settings for comments_enabled
          # rather than the individual meeting
          meetings_component = meeting.component
          comments_enabled = meetings_component.settings.comments_enabled if meetings_component.respond_to?(:settings)
          comments_enabled = true if comments_enabled.nil? # Default to enabled if setting doesn't exist
          
          if comments_enabled
            Decidim::Comments::Comment.create!(
              author: commenter,
              commentable: meeting,
              root_commentable: meeting,
              body: { en: comment_text },
              created_at: rand(1..3).days.ago,
              updated_at: Time.current
            )
          else
            puts "  - Skipping comment: comments are not enabled for this meeting"
          end
          comments_added += 1
        rescue => e
          puts "  - Error creating comment: #{e.message}"
        end
      end
      puts "  Added #{comments_added} comments to the meeting"
    end
  else
    puts "Meeting already exists: #{meeting_attrs[:title][:en]}"
  end
end

puts "=== PIGRECO Content Creation Completed ==="

# Load Lomellina Flood Risk Scenario (from D8 report case study)
begin
  puts "\nLoading Lomellina Flood Risk Scenario..."
  require_relative "lomellina_scenario"
rescue => e
  puts "Error loading Lomellina scenario: #{e.message}"
  puts e.backtrace.first(5).join("\n") if ENV["DEBUG"]
end
