@echo off
REM STEP 2: Setup PIGRECO with Cloudflare URL

echo =========================================================
echo PIGRECO Platform Setup
echo =========================================================
echo.
echo Make sure you have:
echo   1. Started the tunnel (1-start-tunnel.bat)
echo   2. Copied the Cloudflare URL
echo.

REM Ask for the Cloudflare tunnel URL
set /p TUNNEL_URL="Enter your Cloudflare URL (e.g., abc-xyz.trycloudflare.com): "

if "%TUNNEL_URL%"=="" (
    echo ERROR: URL cannot be empty!
    pause
    exit /b 1
)

REM Strip https:// or http:// if user included it
set TUNNEL_URL=%TUNNEL_URL:https://=%
set TUNNEL_URL=%TUNNEL_URL:http://=%
REM Also strip trailing slash
if "%TUNNEL_URL:~-1%"=="/" set TUNNEL_URL=%TUNNEL_URL:~0,-1%

echo.
echo Setting up PIGRECO with URL: %TUNNEL_URL%
echo.

REM Ensure proper directory structure
mkdir storage 2>nul
mkdir log 2>nul

REM Create .env file
echo Creating configuration...
(
echo # PIGRECO Platform Configuration
echo DATABASE_HOST=db
echo DATABASE_USERNAME=postgres
echo DATABASE_PASSWORD=password
echo RAILS_ENV=development
echo DECIDIM_ORGANIZATION_HOST=%TUNNEL_URL%
) > .env

REM Update the configuration initializer to allow tunnel hosts
echo Creating Cloudflare host support...
(
echo # frozen_string_literal: true
echo.
echo # PIGRECO Platform configuration
echo.
echo Rails.application.config.to_prepare do
echo   Rails.autoloaders.main.push_dir^(Rails.root.join^("app", "services", "pigreco"^)^)
echo end
echo.
echo # Allow Cloudflare tunnel hosts
echo Rails.application.configure do
echo   config.hosts ^<^< /.*\.trycloudflare\.com$/
echo   config.hosts ^<^< "localhost"
echo   config.hosts.clear if Rails.env.development?
echo end
) > config\initializers\pigreco.rb

REM Stop any existing containers
echo.
echo Stopping existing containers...
docker-compose down -v

REM Start containers
echo Starting Docker containers...
docker-compose up -d

REM Wait for services
echo Waiting for services to start (45 seconds)...
timeout /t 45 /nobreak > nul

REM Create database
echo.
echo ===================================================
echo Creating database...
echo ===================================================
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails db:create db:migrate"

REM Create or update organization with the Cloudflare URL as host
echo.
echo ===================================================
echo Configuring organization with Cloudflare host...
echo ===================================================
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails runner 'org = Decidim::Organization.first; if org; org.host = \"%TUNNEL_URL%\"; org.secondary_hosts = [\"localhost\"]; org.save!; puts \"Organization configured with host: \" + org.host; else; puts \"No organization found - will be created by seeds\"; end'"

REM Create system admin
echo.
echo Creating system admin...
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails runner \"admin = Decidim::System::Admin.find_or_initialize_by(email: 'system@pigreco.local'); admin.password = 'decidim123456'; admin.password_confirmation = 'decidim123456'; admin.save!; puts 'System admin ready'\""

REM Create Terms of Service page
echo.
echo Creating required static pages...
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails runner \"org = Decidim::Organization.first; tos = Decidim::StaticPage.find_or_initialize_by(slug: 'terms-of-service', organization: org); tos.title = {'en': 'Terms of Service'}; tos.content = {'en': 'Terms of Service for PIGRECO Platform'}; tos.show_in_footer = true; tos.save!; org.update!(tos_version: Time.current); puts 'Static pages created'\""

REM Seed with Cloudflare URL
echo.
echo ===================================================
echo Seeding database (this takes 2-3 minutes)...
echo ===================================================
docker-compose exec -T -e PIGRECO_HOST=%TUNNEL_URL% decidim bash -c "cd /code && bundle exec rails db:seed"

REM Ensure organization host is correct
echo.
echo Verifying organization host...
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails runner \"org = Decidim::Organization.first; if org.nil?; puts 'ERROR: No organization found!'; exit 1; end; org.host = '%TUNNEL_URL%'; org.secondary_hosts = ['localhost']; org.save!; puts 'Organization host verified: ' + org.host\""

REM Set admin password using Devise reset_password method
echo.
echo Setting admin password...
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails runner 'admin = Decidim::User.find_by(email: \"admin@pigreco.local\"); if admin; admin.reset_password(\"decidim123456789\", \"decidim123456789\"); admin.failed_attempts = 0; admin.locked_at = nil; admin.save!(validate: false); puts \"Admin password set\"; end'"

REM Also reset stakeholder passwords
echo.
echo Setting stakeholder passwords...
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails runner 'Decidim::User.where.not(email: \"admin@pigreco.local\").each do |u|; next if u.email.nil? || u.email.include?(\"@\") == false; u.reset_password(\"Lomellina2024!Secure\", \"Lomellina2024!Secure\") rescue nil; end; puts \"Stakeholder passwords set\"'"

echo.
echo.
echo ###########################################################
echo ###########################################################
echo ###                                                     ###
echo ###          PIGRECO PLATFORM SETUP COMPLETE!           ###
echo ###                                                     ###
echo ###########################################################
echo ###########################################################
echo.
echo ===========================================================
echo   YOUR PLATFORM URL
echo ===========================================================
echo.
echo   https://%TUNNEL_URL%
echo.
echo ===========================================================
echo   ADMIN LOGIN
echo ===========================================================
echo.
echo   Email:    admin@pigreco.local
echo   Password: decidim123456789
echo.
echo ===========================================================
echo   LOMELLINA STAKEHOLDER LOGINS
echo ===========================================================
echo.
echo   PASSWORD FOR ALL STAKEHOLDERS: Lomellina2024!Secure
echo.
echo   1. CIVIL PROTECTION
echo      Name:  Marco Bianchi
echo      Email: marco.bianchi@protezione-civile.local
echo      Group: Protezione Civile - Lomellina
echo.
echo   2. AGRICULTURAL COOP
echo      Name:  Giulia Rossi
echo      Email: giulia.rossi@terradriso.local
echo      Group: Terra di Riso - Cooperativa Agricola
echo.
echo   3. UNIVERSITY
echo      Name:  Prof. Alessandro Ferri
echo      Email: alessandro.ferri@polimi.local
echo      Group: Politecnico di Milano - Dipartimento Ingegneria Idraulica
echo.
echo   4. TRADE ASSOCIATION
echo      Name:  Francesca Colombo
echo      Email: francesca.colombo@confcommercio.local
echo      Group: Confcommercio Lomellina
echo.
echo   5. ENVIRONMENTAL NGO
echo      Name:  Luca Martinelli
echo      Email: luca.martinelli@ecomuseo.local
echo      Group: Ecomuseo del Paesaggio Lomellino
echo.
echo   6. CITIZEN COLLECTIVE
echo      Name:  Maria Teresa Galli
echo      Email: maria.galli@connessionidivita.local
echo      Group: Connessioni di Vita - Comunita Anziani
echo.
echo ===========================================================
echo   KEY URLS
echo ===========================================================
echo.
echo   Home Page:
echo   https://%TUNNEL_URL%
echo.
echo   Login Page:
echo   https://%TUNNEL_URL%/users/sign_in
echo.
echo   Lomellina Assembly:
echo   https://%TUNNEL_URL%/assemblies/lomellina-flood-risk-assembly
echo.
echo   Assembly Members:
echo   https://%TUNNEL_URL%/assemblies/lomellina-flood-risk-assembly/members
echo.
echo   Processes:
echo   https://%TUNNEL_URL%/processes
echo.
echo   Process Group:
echo   https://%TUNNEL_URL%/processes_groups/1
echo.
echo ===========================================================
echo   IMPORTANT REMINDER
echo ===========================================================
echo.
echo   Keep the tunnel terminal window (1-start-tunnel.bat) OPEN!
echo   Closing it will disconnect the public URL.
echo.
echo ###########################################################
echo ###########################################################
echo.
pause
