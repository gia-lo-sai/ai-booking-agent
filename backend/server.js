require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { Pool } = require('pg');
const Anthropic = require('@anthropic-ai/sdk');

const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173'
}));
app.use(bodyParser.json());

// Database Pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Claude API Client
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
});

// Test connessione database
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Errore connessione database:', err);
  } else {
    console.log('✅ Database connesso:', res.rows[0].now);
  }
});

// ROUTES

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Chat endpoint - conversazione con Claude
app.post('/api/chat', async (req, res) => {
  try {
    const { message, conversationHistory = [] } = req.body;

    // Costruisci il contesto per Claude
    const systemPrompt = `Sei un assistente AI per ${process.env.BUSINESS_NAME}.
Il tuo compito è aiutare i clienti a:
1. Rispondere a domande generali
2. Prenotare appuntamenti
3. Modificare o cancellare appuntamenti esistenti

Orari di apertura: ${process.env.BUSINESS_HOURS_START} - ${process.env.BUSINESS_HOURS_END}
Durata appuntamento standard: ${process.env.APPOINTMENT_DURATION} minuti

Quando un cliente vuole prenotare, chiedi:
- Nome completo
- Email o telefono
- Data e ora preferita
- Motivo dell'appuntamento (opzionale)

Rispondi sempre in italiano in modo professionale e cordiale.`;

    // Prepara i messaggi per Claude
    const messages = [
      ...conversationHistory,
      { role: 'user', content: message }
    ];

    // Chiama Claude API
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      system: systemPrompt,
      messages: messages
    });

    const assistantMessage = response.content[0].text;

    // Analizza se il messaggio contiene una richiesta di prenotazione
    const bookingIntent = await detectBookingIntent(assistantMessage, message);

    res.json({
      message: assistantMessage,
      bookingIntent,
      conversationHistory: [...messages, { role: 'assistant', content: assistantMessage }]
    });

  } catch (error) {
    console.error('Errore chat:', error);
    res.status(500).json({ error: 'Errore nella conversazione' });
  }
});

// Funzione per rilevare intent di prenotazione
async function detectBookingIntent(assistantMessage, userMessage) {
  const bookingKeywords = ['prenotare', 'appuntamento', 'prenotazione', 'fissare', 'data', 'orario'];
  const hasBookingKeyword = bookingKeywords.some(keyword => 
    userMessage.toLowerCase().includes(keyword) || 
    assistantMessage.toLowerCase().includes(keyword)
  );

  return hasBookingKeyword ? { detected: true, confidence: 0.8 } : { detected: false };
}

// Crea appuntamento
app.post('/api/appointments', async (req, res) => {
  try {
    const { customerName, customerEmail, customerPhone, appointmentDate, appointmentTime, notes } = req.body;

    const result = await pool.query(
      `INSERT INTO appointments (customer_name, customer_email, customer_phone, appointment_date, appointment_time, notes, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'confirmed')
       RETURNING *`,
      [customerName, customerEmail, customerPhone, appointmentDate, appointmentTime, notes]
    );

    res.json({ success: true, appointment: result.rows[0] });
  } catch (error) {
    console.error('Errore creazione appuntamento:', error);
    res.status(500).json({ error: 'Errore nella creazione dell\'appuntamento' });
  }
});

// Ottieni appuntamenti
app.get('/api/appointments', async (req, res) => {
  try {
    const { date, email } = req.query;
    
    let query = 'SELECT * FROM appointments WHERE 1=1';
    const params = [];

    if (date) {
      params.push(date);
      query += ` AND appointment_date = $${params.length}`;
    }

    if (email) {
      params.push(email);
      query += ` AND customer_email = $${params.length}`;
    }

    query += ' ORDER BY appointment_date, appointment_time';

    const result = await pool.query(query, params);
    res.json({ appointments: result.rows });
  } catch (error) {
    console.error('Errore recupero appuntamenti:', error);
    res.status(500).json({ error: 'Errore nel recupero degli appuntamenti' });
  }
});

// Aggiorna appuntamento
app.put('/api/appointments/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { appointmentDate, appointmentTime, status, notes } = req.body;

    const result = await pool.query(
      `UPDATE appointments 
       SET appointment_date = COALESCE($1, appointment_date),
           appointment_time = COALESCE($2, appointment_time),
           status = COALESCE($3, status),
           notes = COALESCE($4, notes),
           updated_at = NOW()
       WHERE id = $5
       RETURNING *`,
      [appointmentDate, appointmentTime, status, notes, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Appuntamento non trovato' });
    }

    res.json({ success: true, appointment: result.rows[0] });
  } catch (error) {
    console.error('Errore aggiornamento appuntamento:', error);
    res.status(500).json({ error: 'Errore nell\'aggiornamento dell\'appuntamento' });
  }
});

// Cancella appuntamento
app.delete('/api/appointments/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'UPDATE appointments SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      ['cancelled', id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Appuntamento non trovato' });
    }

    res.json({ success: true, appointment: result.rows[0] });
  } catch (error) {
    console.error('Errore cancellazione appuntamento:', error);
    res.status(500).json({ error: 'Errore nella cancellazione dell\'appuntamento' });
  }
});

// Ottieni slot disponibili
app.get('/api/available-slots', async (req, res) => {
  try {
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({ error: 'Data richiesta' });
    }

    // Ottieni appuntamenti esistenti per la data
    const existing = await pool.query(
      'SELECT appointment_time FROM appointments WHERE appointment_date = $1 AND status != $2',
      [date, 'cancelled']
    );

    const bookedSlots = existing.rows.map(row => row.appointment_time);

    // Genera slot disponibili
    const slots = generateTimeSlots(
      process.env.BUSINESS_HOURS_START,
      process.env.BUSINESS_HOURS_END,
      parseInt(process.env.APPOINTMENT_DURATION)
    );

    const availableSlots = slots.filter(slot => !bookedSlots.includes(slot));

    res.json({ availableSlots });
  } catch (error) {
    console.error('Errore recupero slot:', error);
    res.status(500).json({ error: 'Errore nel recupero degli slot disponibili' });
  }
});

// Funzione helper per generare slot orari
function generateTimeSlots(startTime, endTime, duration) {
  const slots = [];
  const [startHour, startMinute] = startTime.split(':').map(Number);
  const [endHour, endMinute] = endTime.split(':').map(Number);

  let currentHour = startHour;
  let currentMinute = startMinute;

  while (currentHour < endHour || (currentHour === endHour && currentMinute < endMinute)) {
    const timeString = `${String(currentHour).padStart(2, '0')}:${String(currentMinute).padStart(2, '0')}`;
    slots.push(timeString);

    currentMinute += duration;
    if (currentMinute >= 60) {
      currentHour += Math.floor(currentMinute / 60);
      currentMinute = currentMinute % 60;
    }
  }

  return slots;
}

// Start server
app.listen(port, () => {
  console.log(`🚀 Server in ascolto su porta ${port}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV}`);
});
