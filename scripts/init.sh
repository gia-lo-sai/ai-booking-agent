#!/bin/bash

# Script di inizializzazione completa ai-booking-agent
# Esegue tutti i passaggi necessari per avviare il progetto

echo "🚀 Inizializzazione ai-booking-agent"
echo "====================================="
echo ""

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# STEP 1: Crea .env
step 1 "Configurazione environment..."
if [ ! -f .env ]; then
    cp .env.example .env
    success ".env creato"
    info "IMPORTANTE: Modifica .env con le tue credenziali!"
    echo ""
    echo "Apri .env e configura:"
    echo "  • HCLOUD_TOKEN (da https://console.hetzner.cloud)"
    echo "  • ANTHROPIC_API_KEY (da https://console.anthropic.com)"
    echo "  • POSTGRES_PASSWORD (scegli una password sicura)"
    echo ""
    read -p "Premi INVIO dopo aver configurato .env..." 
else
    success ".env già esistente"
fi
echo ""

# STEP 2: Setup hcloud
step 2 "Configurazione hcloud CLI..."
bash scripts/setup-hcloud.sh
echo ""

# STEP 3: Installa dipendenze (opzionale, per sviluppo locale)
read -p "Vuoi installare le dipendenze per sviluppo locale? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    step 3 "Installazione dipendenze..."
    
    info "Installazione root..."
    npm install
    
    info "Installazione backend..."
    cd backend && npm install && cd ..
    
    info "Installazione frontend..."
    cd frontend && npm install && cd ..
    
    success "Dipendenze installate"
else
    info "Dipendenze saltate (non necessarie per deploy su hcloud)"
fi
echo ""

# STEP 4: Verifica configurazione
step 4 "Verifica configurazione..."
bash scripts/check-status.sh
echo ""

# STEP 5: Pronto per deploy
echo "====================================="
success "Inizializzazione completata!"
echo "====================================="
echo ""
echo "🎯 Prossimi passi:"
echo ""
echo "  Deploy su hcloud:"
echo "    npm run deploy"
echo ""
echo "  Oppure sviluppo locale:"
echo "    1. Avvia PostgreSQL: docker-compose up postgres -d"
echo "    2. Esegui migrazioni: cd backend && npm run migrate"
echo "    3. Avvia dev server: npm run dev"
echo ""
echo "  Comandi utili:"
echo "    npm run hcloud:status  - Verifica stato"
echo "    npm run hcloud:logs    - Visualizza logs"
echo "    npm run hcloud:ssh     - Connetti via SSH"
echo "    npm run hcloud:backup  - Backup database"
echo ""
echo "📚 Documentazione:"
echo "    cat README.md"
echo "    cat QUICKSTART.md"
echo ""
