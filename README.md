# 🤖 AI Booking Agent

Sistema completo di prenotazione appuntamenti con intelligenza artificiale, sviluppato con Claude API, React e PostgreSQL.

## 🌟 Caratteristiche

- ✅ **Chat AI Intelligente**: Conversazioni naturali con Claude per gestire appuntamenti
- ✅ **Gestione Appuntamenti**: Crea, modifica e cancella prenotazioni
- ✅ **Web App Responsive**: Interfaccia moderna e user-friendly
- ✅ **Database PostgreSQL**: Storage affidabile su hcloud
- ✅ **Deploy Automatico**: Script per deployment su hcloud via Termux
- ✅ **Docker Ready**: Containerizzazione completa con Docker Compose

## 🏗️ Architettura

```
┌─────────────────────────────────────────┐
│  Frontend (React + Vite)                │
│  - Interfaccia chat                     │
│  - Gestione appuntamenti                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Backend (Node.js + Express)            │
│  - API REST                             │
│  - Integrazione Claude API              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Database (PostgreSQL)                  │
│  - Appuntamenti                         │
│  - Conversazioni                        │
└─────────────────────────────────────────┘
```

## 📋 Prerequisiti

### Per Termux (Android)
- Termux installato
- Connessione internet
- Account Hetzner Cloud (per deploy)
- API Key Anthropic Claude

### Per sviluppo locale
- Node.js 18+
- PostgreSQL 15+
- Git

## 🚀 Quick Start

### 1. Setup su Termux

```bash
# Clona il repository
git clone https://github.com/gia-lo-sai/ai-booking-agent.git
cd ai-booking-agent

# Esegui setup automatico
bash scripts/setup-termux.sh

# Configura environment
cp .env.example .env
nano .env  # Modifica con le tue credenziali
```

### 2. Configurazione

Modifica `.env` con le tue credenziali:

```env
# Claude API
ANTHROPIC_API_KEY=sk-ant-...

# Hetzner Cloud
HCLOUD_TOKEN=...

# Database
POSTGRES_PASSWORD=una_password_sicura

# Business
BUSINESS_NAME=Il Tuo Business
BUSINESS_HOURS_START=09:00
BUSINESS_HOURS_END=18:00
```

### 3. Ottieni le API Keys

#### Anthropic Claude API
1. Vai su https://console.anthropic.com
2. Crea un account o fai login
3. Vai su API Keys
4. Crea una nuova API key
5. Copia la key nel file `.env`

#### Hetzner Cloud Token
1. Vai su https://console.hetzner.cloud
2. Crea un progetto
3. Vai su Security → API Tokens
4. Genera un nuovo token (Read & Write)
5. Copia il token nel file `.env`

### 4. Deploy su hcloud

```bash
# Deploy completo
npm run deploy

# Oppure manualmente
bash scripts/deploy.sh
```

### 5. Sviluppo Locale

```bash
# Installa dipendenze
npm install

# Avvia PostgreSQL locale
# (Oppure usa Docker: docker-compose up postgres -d)

# Esegui migrazioni database
cd backend
npm run migrate

# Avvia dev server (backend + frontend)
cd ..
npm run dev
```

Apri http://localhost:5173 nel browser.

## 🔧 Comandi Utili

### Sviluppo
```bash
npm run dev              # Avvia dev server completo
npm run dev:backend      # Solo backend
npm run dev:frontend     # Solo frontend
npm run build            # Build produzione
```

### Deploy
```bash
npm run deploy           # Deploy completo su hcloud
bash scripts/deploy.sh   # Deploy con script bash
```

### Database
```bash
cd backend
npm run migrate          # Esegui migrazioni
```

### Docker
```bash
docker-compose up -d              # Avvia tutti i servizi
docker-compose down               # Ferma tutti i servizi
docker-compose logs -f backend    # Logs backend
docker-compose logs -f frontend   # Logs frontend
docker-compose restart            # Restart servizi
```

### hcloud CLI
```bash
# Gestione server
hcloud server list
hcloud server ssh ai-booking-agent
hcloud server delete ai-booking-agent

# Verifica IP
hcloud server ip ai-booking-agent
```

## 📁 Struttura Progetto

```
ai-booking-agent/
├── backend/                 # Backend Node.js
│   ├── server.js           # Server Express principale
│   ├── database/           # Schema SQL
│   ├── migrations/         # Script migrazioni
│   └── package.json
├── frontend/               # Frontend React
│   ├── src/
│   │   ├── App.jsx        # Componente principale
│   │   ├── App.css        # Stili
│   │   └── main.jsx       # Entry point
│   └── package.json
├── scripts/                # Script deployment
│   ├── deploy.sh          # Deploy hcloud
│   └── setup-termux.sh    # Setup Termux
├── docker-compose.yml      # Orchestrazione Docker
├── Dockerfile.backend      # Docker backend
├── Dockerfile.frontend     # Docker frontend
├── nginx.conf             # Config Nginx
├── .env.example           # Template environment
└── README.md              # Questa guida
```

## 🔌 API Endpoints

### Chat
- `POST /api/chat` - Invia messaggio a Claude AI

### Appuntamenti
- `GET /api/appointments` - Lista appuntamenti
- `POST /api/appointments` - Crea appuntamento
- `PUT /api/appointments/:id` - Aggiorna appuntamento
- `DELETE /api/appointments/:id` - Cancella appuntamento

### Utility
- `GET /api/health` - Health check
- `GET /api/available-slots?date=2026-03-25` - Slot disponibili

## 🎨 Personalizzazione

### Modifica colori interfaccia
Edita `frontend/src/App.css`:

```css
/* Gradiente principale */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Colori messaggio utente */
.user-message .message-text {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
```

### Modifica prompt Claude
Edita `backend/server.js`:

```javascript
const systemPrompt = `Sei un assistente AI per ${process.env.BUSINESS_NAME}.
// ... personalizza il comportamento
`;
```

### Aggiungi funzionalità
- Email notifications: Integra Nodemailer
- SMS reminders: Integra Twilio
- Calendar sync: Integra Google Calendar API
- Payment: Integra Stripe

## 🐛 Troubleshooting

### Errore connessione database
```bash
# Verifica che PostgreSQL sia avviato
docker-compose ps

# Verifica logs
docker-compose logs postgres

# Reset database
docker-compose down -v
docker-compose up -d
```

### Errore Claude API
```bash
# Verifica API key
echo $ANTHROPIC_API_KEY

# Test manuale
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01"
```

### Frontend non carica
```bash
# Rebuild frontend
cd frontend
npm run build

# Verifica nginx
docker-compose logs frontend
```

## 📊 Monitoring

### Logs in tempo reale
```bash
# Su server hcloud
ssh root@SERVER_IP
cd /opt/ai-booking-agent

# Backend logs
docker-compose logs -f backend

# Database logs
docker-compose logs -f postgres

# Tutti i logs
docker-compose logs -f
```

### Metriche server
```bash
# CPU e memoria
docker stats

# Spazio disco
df -h

# Connessioni database
docker-compose exec postgres psql -U bookinguser -d booking_db -c "SELECT count(*) FROM appointments;"
```

## 🔒 Sicurezza

- ✅ Non committare file `.env`
- ✅ Usa password forti per database
- ✅ Rinnova API keys regolarmente
- ✅ Abilita HTTPS in produzione (Let's Encrypt)
- ✅ Limita accesso SSH (firewall hcloud)
- ✅ Backup database regolari

## 📝 License

MIT

## 🤝 Contributi

Pull request benvenute! Per modifiche importanti, apri prima un issue.

## 💬 Supporto

- Issues: https://github.com/gia-lo-sai/ai-booking-agent/issues
- Email: mr.wolf311@proton.me 

## 🙏 Credits

- [Claude AI](https://www.anthropic.com/claude) - AI conversazionale
- [Hetzner Cloud](https://www.hetzner.com/cloud) - Hosting
- [React](https://react.dev/) - Frontend framework
- [Node.js](https://nodejs.org/) - Backend runtime
- [PostgreSQL](https://www.postgresql.org/) - Database

---

Sviluppato con ❤️ su Termux da gia-lo-sai & Antropic-claude 
