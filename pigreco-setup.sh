#!/bin/bash
# PIGRECO Platform Setup and Reset Script
# This script sets up the complete PIGRECO platform including the Lomellina case study

echo ""
echo "============================================================"
echo "  PIGRECO Platform Setup - Complete Installation"
echo "============================================================"
echo ""

# Ensure proper directory structure
echo "[1/7] Creating directory structure..."
mkdir -p storage log tmp

# Stop containers if running
echo "[2/7] Stopping any existing containers..."
docker-compose down 2>/dev/null

# Start containers
echo "[3/7] Starting Docker containers..."
docker-compose up -d

# Wait for containers to be ready
echo "[4/7] Waiting for services to initialize (30 seconds)..."
sleep 30

# Reset database and run migrations and main seeds
echo "[5/7] Setting up database and running main seeds..."
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails db:drop db:create db:migrate db:seed"

# Explicitly run the Lomellina scenario to ensure it's loaded
echo "[6/7] Loading Lomellina Flood Risk Case Study..."
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails runner \"load '/code/db/seeds/lomellina_scenario.rb'\""

# Verify the seeding results
echo "[7/7] Verifying installation..."
echo ""
docker-compose exec -T decidim bash -c "cd /code && bundle exec rails runner \"puts '=== VERIFICATION ==='; puts 'User Groups: ' + Decidim::UserGroup.count.to_s + '/6'; puts 'Assemblies: ' + Decidim::Assembly.count.to_s; puts 'Processes: ' + Decidim::ParticipatoryProcess.count.to_s; a = Decidim::Assembly.find_by(slug: 'lomellina-flood-risk-assembly'); puts 'Lomellina: ' + (a ? 'OK' : 'MISSING')\""

echo ""
echo "============================================================"
echo "  SETUP COMPLETE - PIGRECO Platform Ready"
echo "============================================================"
echo ""
echo "Platform URL: http://localhost:3000"
echo ""
echo "============================================================"
echo "  ADMIN LOGIN"
echo "============================================================"
echo "  Email:    admin@pigreco.local"
echo "  Password: decidim123456789"
echo ""
echo "============================================================"
echo "  LOMELLINA STAKEHOLDER LOGINS"
echo "============================================================"
echo "  Password for ALL stakeholders: Lomellina2024!Secure"
echo ""
echo "  CIVIL PROTECTION:"
echo "    User:  Marco Bianchi"
echo "    Email: marco.bianchi@protezione-civile.local"
echo "    Group: Protezione Civile - Lomellina"
echo ""
echo "  AGRICULTURAL COOPERATIVE:"
echo "    User:  Giulia Rossi"
echo "    Email: giulia.rossi@terradriso.local"
echo "    Group: Terra di Riso - Cooperativa Agricola"
echo ""
echo "  UNIVERSITY RESEARCH:"
echo "    User:  Prof. Alessandro Ferri"
echo "    Email: alessandro.ferri@polimi.local"
echo "    Group: Politecnico di Milano - Dip. Ingegneria Idraulica"
echo ""
echo "  TRADE ASSOCIATION:"
echo "    User:  Francesca Colombo"
echo "    Email: francesca.colombo@confcommercio.local"
echo "    Group: Confcommercio Lomellina"
echo ""
echo "  ENVIRONMENTAL NGO:"
echo "    User:  Luca Martinelli"
echo "    Email: luca.martinelli@ecomuseo.local"
echo "    Group: Ecomuseo del Paesaggio Lomellino"
echo ""
echo "  CITIZEN COLLECTIVE:"
echo "    User:  Maria Teresa Galli"
echo "    Email: maria.galli@connessionidivita.local"
echo "    Group: Connessioni di Vita - Comunita Anziani"
echo ""
echo "============================================================"
echo "  KEY URLS FOR LOMELLINA USE CASE"
echo "============================================================"
echo "  Process Group:      http://localhost:3000/processes_groups/1"
echo "  Assembly Home:      http://localhost:3000/assemblies/lomellina-flood-risk-assembly"
echo "  Assembly Members:   http://localhost:3000/assemblies/lomellina-flood-risk-assembly/members"
echo "  Levee Process:      http://localhost:3000/processes/valutazione-misura-arginature"
echo "  Delocalization:     http://localhost:3000/processes/valutazione-delocalizzazione-popolazione"
echo ""
echo "============================================================"
echo "  USE CASE WORKFLOW"
echo "============================================================"
echo "  1. Login as any stakeholder user above"
echo "  2. Navigate to processes or assembly"
echo "  3. Create proposals as the user's organization"
echo "  4. Comment and vote on other proposals"
echo "  5. Register for meetings"
echo "  6. Assembly members deliberate on final decisions"
echo "============================================================"
