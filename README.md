# PIGRECO Risk Governance Platform

![Decidim](https://img.shields.io/badge/Decidim-0.28.6-red)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-AGPL--3.0-green)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20Mac-lightgrey)

## Overview

The PIGRECO Risk Governance Platform is a participatory decision-support system built on [Decidim 0.28.6](https://decidim.org/) to facilitate structured collaboration between citizens, experts, stakeholders, and administrators in multi-risk assessment and governance. 

This repository includes the **Lomellina Flood Risk Use Case** - a complete implementation demonstrating participatory flood risk management in the Lomellina region of Lombardy, Italy, featuring 6 stakeholder groups, 2 participatory processes, and a deliberative assembly.

## 🌐 Live Demo

A live demonstration is available at:

**https://partial-mechanical-stored-estimates.trycloudflare.com/**

> ⚠️ **Note:** This URL is temporary and may not remain active. If unavailable, follow the Quick Start guide below to deploy your own instance.

## Table of Contents
- [Quick Start](#quick-start)
- [Lomellina Use Case](#lomellina-flood-risk-use-case)
- [Architecture](#architecture)
- [Development Setup](#development-setup)
- [Cloudflare Tunnel Deployment](#cloudflare-tunnel-deployment)
- [User Credentials](#user-credentials)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Quick Start

### Prerequisites
- **Docker Desktop** (4.0+ recommended)
- **Git**
- 4GB RAM minimum
- 20GB free disk space

### Windows Users (Recommended)

```batch
# Clone the repository
git clone https://github.com/Uvesh-patel/pigreco-platform.git
cd pigreco-platform

# Download cloudflared.exe first (required for remote access)
# Download from: https://github.com/cloudflare/cloudflared/releases/latest
# Place cloudflared.exe in the project root folder

# Terminal 1: Start Cloudflare Tunnel (for remote access)
1-start-tunnel.bat

# Terminal 2: Deploy the platform (copy URL from tunnel output)
2-deploy.bat
```

### Linux/Mac Users

```bash
# Clone the repository
git clone https://github.com/Uvesh-patel/pigreco-platform.git
cd pigreco-platform

# Make scripts executable
chmod +x 1-start-tunnel.sh 2-deploy.sh

# Terminal 1: Start Cloudflare Tunnel
./1-start-tunnel.sh

# Terminal 2: Deploy the platform
./2-deploy.sh
```

### Local-Only Setup (No Remote Access)

```bash
# Clone and enter directory
git clone https://github.com/Uvesh-patel/pigreco-platform.git
cd pigreco-platform

# Start containers
docker-compose up -d

# Wait 45 seconds, then setup database
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails db:create db:migrate db:seed"

# Access at http://localhost:3000
```

## Lomellina Flood Risk Use Case

The platform includes a complete implementation of the **Lomellina Flood Risk** participatory governance scenario:

### Stakeholder Groups (6)

| Category | Organization | Representative |
|----------|--------------|----------------|
| 🛡️ Civil Protection | Protezione Civile - Lomellina | Marco Bianchi |
| 🌾 Agricultural | Terra di Riso - Cooperativa Agricola | Giulia Rossi |
| 🎓 University | Politecnico di Milano | Prof. Alessandro Ferri |
| 🏪 Trade Association | Confcommercio Lomellina | Francesca Colombo |
| 🌿 Environmental NGO | Ecomuseo del Paesaggio Lomellino | Luca Martinelli |
| 👥 Citizen Collective | Connessioni di Vita - Comunità Anziani | Maria Teresa Galli |

### Participatory Spaces

- **Assembly:** Lomellina Flood Risk Decision Assembly
- **Process 1:** Levee & Embankment Operations Evaluation
- **Process 2:** Population Delocalization Strategy Evaluation
- **Process Group:** Gestione Rischio Idrogeologico Lomellina 2025

### Key URLs (after deployment)

| Page | URL Path |
|------|----------|
| Home | `/` |
| Login | `/users/sign_in` |
| Assembly | `/assemblies/lomellina-flood-risk-assembly` |
| Assembly Members | `/assemblies/lomellina-flood-risk-assembly/members` |
| All Processes | `/processes` |
| Process Group | `/processes_groups/1` |

## Architecture

PIGRECO runs in a containerized environment using Docker:

| Container | Service | Port |
|-----------|---------|------|
| **decidim** | Ruby on Rails 6.1 + Puma | 3000 |
| **db** | PostgreSQL 14 | 5432 |
| **redis** | Redis Cache/Sessions | 6379 |

### Volumes
- `/code` - Application source code (mounted)
- `postgres-data` - Database persistence
- `redis-data` - Cache persistence

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

## User Credentials

### Administrator

| Field | Value |
|-------|-------|
| Email | `admin@pigreco.local` |
| Password | `decidim123456789` |
| Role | Platform Administrator |

### Lomellina Stakeholders

**Password for ALL stakeholders:** `Lomellina2024!Secure`

| Name | Email | Organization |
|------|-------|--------------|
| Marco Bianchi | `marco.bianchi@protezione-civile.local` | Protezione Civile |
| Giulia Rossi | `giulia.rossi@terradriso.local` | Terra di Riso |
| Prof. Alessandro Ferri | `alessandro.ferri@polimi.local` | Politecnico di Milano |
| Francesca Colombo | `francesca.colombo@confcommercio.local` | Confcommercio |
| Luca Martinelli | `luca.martinelli@ecomuseo.local` | Ecomuseo Lomellino |
| Maria Teresa Galli | `maria.galli@connessionidivita.local` | Connessioni di Vita |

### Test Users

| Email Pattern | Password |
|---------------|----------|
| `user1@pigreco.local` - `user10@pigreco.local` | `decidim123456` |

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

```
pigreco-platform/
├── app/
│   ├── services/pigreco/       # PIGRECO-specific services
│   ├── packs/images/           # Frontend images
│   └── views/                  # View overrides
├── config/
│   ├── initializers/pigreco.rb # Platform configuration
│   └── locales/                # Localization (EN/IT)
├── db/
│   ├── seeds.rb                # Main seed file
│   └── seeds/
│       ├── pigreco_content.rb  # Base PIGRECO content
│       └── lomellina_scenario.rb # Lomellina use case data
├── 1-start-tunnel.bat/.sh      # Cloudflare tunnel scripts
├── 2-deploy.bat/.sh            # Automated deployment scripts
├── docker-compose.yml          # Docker configuration
└── README.md
```

## Cloudflare Tunnel Deployment

Expose your local platform to the internet for demos and remote access.

### Step 1: Download Cloudflared

**Windows (Manual Download - Recommended):**
1. Go to: https://github.com/cloudflare/cloudflared/releases/latest
2. Download `cloudflared-windows-amd64.exe`
3. Rename to `cloudflared.exe`
4. Place in the project root folder

**Windows (winget):**
```batch
winget install --id Cloudflare.cloudflared
```

**macOS:**
```bash
brew install cloudflared
```

**Linux:**
```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
```

### Step 2: Deploy with Tunnel

```bash
# Terminal 1: Start tunnel
./1-start-tunnel.sh   # or 1-start-tunnel.bat on Windows

# Copy the URL shown (e.g., https://abc-xyz.trycloudflare.com)

# Terminal 2: Deploy with that URL
./2-deploy.sh         # or 2-deploy.bat on Windows
```

> **Note:** Keep the tunnel terminal open. The URL changes each restart.

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

```bash
# Application logs
docker-compose logs -f decidim

# All logs
docker-compose logs -f
```

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on [Decidim](https://decidim.org/) - Free Open-Source participatory democracy platform
- Developed as part of the PIGRECO project at University of Messina
- Lomellina Flood Risk Use Case - Lombardy, Italy

---

**PIGRECO** - Participatory Integrated Governance for Risk Evaluation and Community Outcomes

© 2025 University of Messina
