#!/bin/bash

# Helper script per comandi comuni
# Uso: bash scripts/helper.sh [comando]

COMMAND=$1

case $COMMAND in
  "init")
    echo "🔧 Inizializzazione progetto..."
    cp .env.example .env
    echo "✅ File .env creato. Modifica con le tue credenziali."
    ;;
    
  "install")
    echo "📦 Installazione dipendenze..."
    npm install
    cd backend && npm install && cd ..
    cd frontend && npm install && cd ..
    echo "✅ Dipendenze installate!"
    ;;
    
  "db:migrate")
    echo "🗄️ Esecuzione migrazioni database..."
    cd backend && npm run migrate && cd ..
    ;;
    
  "dev")
    echo "🚀 Avvio dev server..."
    npm run dev
    ;;
    
  "build")
    echo "📦 Build produzione..."
    npm run build
    ;;
    
  "deploy")
    echo "🚀 Deploy su hcloud..."
    bash scripts/deploy.sh
    ;;
    
  "logs")
    SERVER_IP=$(hcloud server ip ai-booking-agent 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
      echo "❌ Server non trovato"
      exit 1
    fi
    
    echo "📊 Logs dal server $SERVER_IP..."
    ssh root@$SERVER_IP "cd /opt/ai-booking-agent && docker-compose logs -f"
    ;;
    
  "ssh")
    SERVER_IP=$(hcloud server ip ai-booking-agent 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
      echo "❌ Server non trovato"
      exit 1
    fi
    
    echo "🔐 Connessione SSH a $SERVER_IP..."
    ssh root@$SERVER_IP
    ;;
    
  "status")
    SERVER_IP=$(hcloud server ip ai-booking-agent 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
      echo "❌ Server non trovato"
      exit 1
    fi
    
    echo "📊 Status server $SERVER_IP..."
    ssh root@$SERVER_IP "cd /opt/ai-booking-agent && docker-compose ps"
    ;;
    
  "restart")
    SERVER_IP=$(hcloud server ip ai-booking-agent 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
      echo "❌ Server non trovato"
      exit 1
    fi
    
    echo "🔄 Restart servizi su $SERVER_IP..."
    ssh root@$SERVER_IP "cd /opt/ai-booking-agent && docker-compose restart"
    echo "✅ Servizi riavviati!"
    ;;
    
  "backup")
    SERVER_IP=$(hcloud server ip ai-booking-agent 2>/dev/null)
    if [ -z "$SERVER_IP" ]; then
      echo "❌ Server non trovato"
      exit 1
    fi
    
    BACKUP_FILE="backup-$(date +%Y%m%d-%H%M%S).sql"
    echo "💾 Backup database in $BACKUP_FILE..."
    
    ssh root@$SERVER_IP "cd /opt/ai-booking-agent && docker-compose exec -T postgres pg_dump -U bookinguser booking_db" > "$BACKUP_FILE"
    
    echo "✅ Backup completato: $BACKUP_FILE"
    ;;
    
  "help"|*)
    echo "🤖 AI Booking Agent - Helper"
    echo ""
    echo "Comandi disponibili:"
    echo "  init        - Inizializza progetto (crea .env)"
    echo "  install     - Installa dipendenze"
    echo "  db:migrate  - Esegui migrazioni database"
    echo "  dev         - Avvia dev server"
    echo "  build       - Build produzione"
    echo "  deploy      - Deploy su hcloud"
    echo "  logs        - Mostra logs dal server"
    echo "  ssh         - Connetti al server via SSH"
    echo "  status      - Status servizi"
    echo "  restart     - Restart servizi"
    echo "  backup      - Backup database"
    echo "  help        - Mostra questo messaggio"
    echo ""
    echo "Uso: bash scripts/helper.sh [comando]"
    ;;
esac
