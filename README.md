# PIGRECO Risk Governance Platform

## Overview

The PIGRECO Risk Governance Platform is a GIS-enabled participatory decision-support system built to facilitate structured collaboration between citizens, experts, stakeholders, and administrators in multi-risk assessment and governance. The platform extends the Decidim framework with specialized components for risk evaluation, participatory decision-making, and transparent governance.

## Table of Contents
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Development Setup](#development-setup)
- [Production Deployment](#production-deployment)
- [Customization Guide](#customization-guide)
- [Data Seeding](#data-seeding)
- [Security](#security)
- [Branding](#branding)
- [Troubleshooting](#troubleshooting)
- [Release Process](#release-process)
- [Contact](#contact)

## Quick Start

If you're in a hurry and just want to get the platform running:

### Windows Users
```batch
# Clone the repository
git clone https://github.com/Pigreco-project/pigreco-decidim.git
cd pigreco-decidim

# Run the automated setup script
pigreco-setup.bat

# This will take approximately 3-5 minutes for all migrations and seeding

# Access the platform at http://localhost:3000
# Admin credentials: admin@pigreco.local / decidim123456789
```

### Linux/Mac Users
```bash
# Clone the repository
git clone https://github.com/Pigreco-project/pigreco-decidim.git
cd pigreco-decidim

# Run the automated setup script
./pigreco-setup.sh

# This will take approximately 3-5 minutes for all migrations and seeding

# Access the platform at http://localhost:3000
# Admin credentials: admin@pigreco.local / decidim123456
```

### Manual Setup
```bash
# Clone the repository
git clone https://https://github.com/Pigreco-project/pigreco-decidim.git
cd pigreco-decidim

# Start the containers
docker-compose up -d

# Wait for services to initialize (about 30-45 seconds)
# Then seed the database
docker-compose exec decidim bash -c "cd /code && bundle exec rake db:seed"

# Access the platform at http://localhost:3000
# Admin credentials: admin@pigreco.local / decidim123456
```

## Architecture

PIGRECO runs in a containerized environment using Docker to ensure consistency across development, testing, and production. The architecture consists of three main containers:

1. **Decidim Container**: Rails application with the PIGRECO extensions
2. **PostgreSQL Container**: Database for persistent storage
3. **Redis Container**: Caching and background jobs

The system uses mounted volumes to customize:
- Branding assets (in `public/`)
- View overrides (in `app/views/`)
- Configuration files (in `config/`)

## Development Setup

### Prerequisites
- Docker & Docker Compose (Docker Desktop 4.0+ recommended)
- Git
- 4GB RAM minimum (8GB+ recommended)
- 20GB free disk space

> **Note**: You may see a warning about the `version` attribute being obsolete in docker-compose.yml. This can be safely ignored, as it doesn't affect functionality.

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/Pigreco-project/pigreco-decidim.git
   cd pigreco-decidim
   ```

2. **Configure environment**
   
   Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your settings. For development, defaults should work fine.

3. **Start the containers**
   ```bash
   docker-compose up -d
   ```
   
   This starts the Decidim application, PostgreSQL database, and Redis server.

4. **Initialize the database**
   ```bash
   # Run migrations
   docker-compose exec decidim bash -c "cd /code && bundle exec rake db:migrate"
   
   # Seed the database
   docker-compose exec decidim bash -c "cd /code && bundle exec rake db:seed"
   ```

### Accessing the Platform

After successful setup, the platform will be accessible at:

- **Web interface**: [http://localhost:3000](http://localhost:3000)
- **Admin interface**: [http://localhost:3000/admin/](http://localhost:3000/admin/)

### Admin Access

Use the following credentials to access the admin panel:

- **Email**: admin@pigreco.local
- **Password**: decidim123456789 (Windows) or decidim123456 (Linux/Mac)

> **Note:** It's recommended to change this password to a strong one after first login.

### Test Users

The setup process creates several test users you can use to explore the platform:

- **Admin**: admin@pigreco.local (use admin password above)
- **Regular users**: user1@pigreco.local through user10@pigreco.local (password: `decidim123456`)

### Demo Content

The platform is pre-populated with demo content for risk assessment:

- **Participatory process**: Community-Driven Multi-Risk Assessment
- **Proposals**: Several example risk assessment proposals including:
  - Earthquake Vulnerability Mapping
  - Flood Impact Simulation Workshop
  - Public Services Continuity Plan
  - Long-Term Urban Resilience Strategy
- **Meetings**: Sample risk assessment related meetings

5. **Access the platform**
   
   Open http://localhost:3000 in your browser.
   
   **Admin credentials:**
   - Email: admin@pigreco.local
   - Password: 
     - Windows setup: decidim123456789
     - Linux/Mac setup: decidim123456
     - Recommended after first login: DecidimStrongPassword123!@#
   
   **Test user credentials:**
   - Citizen: citizen@pigreco.local / decidim123456
   - Expert: expert@pigreco.local / decidim123456
   
   **System admin credentials:**
   - Email: system@pigreco.local
   - Password: decidim123456

### Development Commands

```bash
# View logs
docker-compose logs -f decidim

# Rails console
docker-compose exec decidim bash -c "cd /code && bundle exec rails console"

# Run tests
docker-compose exec decidim bash -c "cd /code && bundle exec rake pigreco:test:all"

# Database tasks
docker-compose exec decidim bash -c "cd /code && bundle exec rake pigreco:db:quick_check"
docker-compose exec decidim bash -c "cd /code && bundle exec rake pigreco:db:detailed_check"

# Homepage configuration
docker-compose exec decidim bash -c "cd /code && bundle exec rake pigreco:homepage:configure"
docker-compose exec decidim bash -c "cd /code && bundle exec rake pigreco:homepage:verify"
docker-compose exec decidim bash -c "cd /code && bundle exec rake pigreco:homepage:reset"

# Restart application
docker-compose restart decidim
```

## Project Structure

The project follows the standard Decidim structure with additional PIGRECO-specific components:

```
pigreco-decidim/
├── app/                      # Application code
│   ├── services/             # Service objects
│   │   └── pigreco/          # PIGRECO-specific services
│   ├── packs/                # JavaScript packs
│   │   └── images/           # Frontend images
│   └── views/                # View overrides
├── assets/                   # Custom assets and branding
├── config/
│   ├── initializers/         # Rails initializers
│   │   └── pigreco.rb        # PIGRECO specific initializers
│   └── locales/              # Localization files
├── db/
│   ├── seeds/                # Seed data files
│   │   └── pigreco_content.rb # PIGRECO-specific seed data
│   └── seeds.rb              # Main seed file
├── lib/
│   └── tasks/                # Rake tasks
│       ├── homepage.rake     # Homepage configuration tasks
│       └── pigreco_db.rake   # Database tasks
├── log/                      # Log files
├── pigreco-setup.bat         # Windows setup script
├── pigreco-setup.sh          # Linux/Mac setup script
├── run.sh                    # Development run script
├── fix_and_reset.sh          # Maintenance script
├── storage/                  # Storage for uploads and generated files
├── docker-compose.yml        # Docker configuration
└── .env.example              # Example environment configuration
```

## Production Deployment

For production deployment, follow these additional steps:

1. **Update security settings**
   
   Edit `config/initializers/pigreco.rb` and update:
   - Admin password requirements
   - Session timeout (currently 3600 seconds)
   - Max login attempts (currently 5)
   - SSL configuration

2. **Configure external database (optional)**
   
   For larger deployments, consider using an external managed PostgreSQL instance.

3. **Set up monitoring**
   
   Integrate with your monitoring solution using the `/health` endpoint.

4. **Configure backups**
   
   Set up automated backups for the PostgreSQL database and uploaded files in `storage/`.

5. **Start production environment**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

6. **Verify deployment**
   ```bash
   ./scripts/verify_deployment.sh
   ```

## Customization Guide

### Branding and Theme

PIGRECO uses the following brand elements:
- Primary Color: #005b4f (Teal)
- Secondary Color: #ff6d00 (Orange)
- Typography: Montserrat for headings, Roboto for body
- Logo: 'PIGRECO' in Montserrat Bold

To customize the branding:

1. Update CSS variables in `app/assets/stylesheets/pigreco_theme.scss`
2. Replace logo files in `app/assets/images/`
3. Apply custom fonts by modifying `app/views/layouts/decidim/_head.html.erb`

### Localization

Modify translations in `config/locales/pigreco.en.yml` and `config/locales/pigreco.it.yml`.

Guidelines:
- Always use full platform name 'PIGRECO Risk Governance Platform'
- Use consistent risk terminology (high/medium/low)
- Email templates should use [PIGRECO] prefix
- Navigation should use risk-specific terms

### Adding New Components

To add a custom component:

1. Create a new module in `decidim-module-your_component`
2. Generate required files using the component generator
3. Implement the component logic
4. Add to your Gemfile and install

## Data Seeding

The platform uses a structured seed process to initialize the database with demo content:

```bash
# Full seed (organization, admin, demo content)
docker-compose exec decidim bash -c "cd /code && bundle exec rake db:seed"

# Alternatively, use the provided setup scripts
# For Windows:
.\pigreco-setup.bat

# For Linux/Mac:
./pigreco-setup.sh

# Just create admin (keeps existing data)
docker-compose exec decidim bash -c "cd /code && bundle exec rake pigreco:create_admin"

# Reset and start fresh
docker-compose exec decidim bash -c "cd /code && bundle exec rake db:reset"
```

### Seeding Process

The seeding workflow follows these steps:
1. Environment check
2. Database migration
3. Organization creation
4. Admin user creation
5. Test users creation
6. Static content (pages, T&C)
7. Homepage configuration
8. Demo content (processes, proposals, meetings)
9. Risk data
10. GIS data references
11. Verification

For more details, see `db/seeds.rb` and `db/seeds/pigreco_content.rb`.

## Security

PIGRECO implements the following security measures:

- **Password Policy**:
  - Minimum length: 12 characters
  - Stores history of 5 previous passwords
  - Locks account after 5 failed attempts

- **Session Security**:
  - Timeout after 3600 seconds (1 hour)
  - Secure and HttpOnly flags for cookies

- **Authentication**:
  - bcrypt for password hashing
  - CSRF protection on all forms

- **Transport Layer Security**:
  - HTTPS required in production
  - Strict security headers

## Troubleshooting

### Common Issues

**Container won't start**
```bash
# Check for port conflicts
netstat -tuln | grep 3000
netstat -tuln | grep 5432

# Verify Docker has enough resources
docker info
```

**Database connection issues**
```bash
# Reset database
docker-compose down -v
docker-compose up -d
docker-compose exec decidim bash -c "cd /code && bundle exec rake db:setup"
```

**Assets not loading**
```bash
# Recompile assets
docker-compose exec decidim bash -c "cd /code && bundle exec rake assets:precompile"
```

### Logs

Check logs for specific containers:
```bash
# Application logs
docker-compose logs -f decidim

# Database logs
docker-compose logs -f db

# All logs
docker-compose logs -f
```

## Release Process

Before releasing to production, complete this checklist:

1. Complete branding verification
2. Execute test account creation
3. Run automated tests
4. Perform security review
5. Update documentation
6. Tag v1.0 release

## Development Notes

- All files in the project directory are mounted into the Docker container
- Changes to files will be reflected in the running application
- Logs are stored in the `log` directory
- Uploaded files are stored in the `storage` directory

---

Developed as part of the PIGRECO project at University of Messina, 2025.
