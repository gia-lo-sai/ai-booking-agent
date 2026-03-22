#!/data/data/com.termux/files/usr/bin/bash

# Script di setup per Termux
# Installa tutte le dipendenze necessarie per il progetto

echo "📱 Setup ambiente Termux per AI Booking Agent"

# Aggiorna pacchetti
pkg update -y
pkg upgrade -y

# Installa dipendenze base
echo "📦 Installazione dipendenze base..."
pkg install -y \
    nodejs \
    git \
    openssh \
    postgresql \
    wget \
    curl

# Installa hcloud CLI
echo "☁️ Installazione hcloud CLI..."
npm install -g @hetznercloud/cli

# Verifica installazioni
echo "✅ Verifico installazioni..."
node --version
npm --version
git --version
hcloud version

# Configura Git
echo "🔧 Configurazione Git..."
echo "Inserisci il tuo nome per Git:"
read GIT_NAME
echo "Inserisci la tua email per Git:"
read GIT_EMAIL

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Genera chiave SSH se non esiste
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "🔑 Generazione chiave SSH..."
    ssh-keygen -t rsa -b 4096 -C "$GIT_EMAIL" -f ~/.ssh/id_rsa -N ""
    
    echo ""
    echo "📋 Chiave pubblica SSH generata:"
    cat ~/.ssh/id_rsa.pub
    echo ""
    echo "Aggiungi questa chiave a:"
    echo "  • GitHub: https://github.com/settings/keys"
    echo "  • hcloud: https://console.hetzner.cloud/"
fi

# Installa dipendenze del progetto
echo "📦 Installazione dipendenze progetto..."
cd ~/ai-booking-agent || exit

# Backend
if [ -d "backend" ]; then
    cd backend
    npm install
    cd ..
fi

# Frontend
if [ -d "frontend" ]; then
    cd frontend
    npm install
    cd ..
fi

# Root
npm install

echo ""
echo "✅ Setup completato!"
echo ""
echo "Prossimi passi:"
echo "1. Copia .env.example a .env e configura le variabili"
echo "2. Ottieni API key da https://console.anthropic.com"
echo "3. Configura hcloud token da https://console.hetzner.cloud"
echo "4. Esegui: npm run dev (sviluppo locale)"
echo "5. Esegui: npm run deploy (deploy su hcloud)"
