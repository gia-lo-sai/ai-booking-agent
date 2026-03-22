-- Schema database per AI Booking Agent

-- Tabella appuntamenti
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    notes TEXT,
    status VARCHAR(50) DEFAULT 'confirmed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indici per performance
CREATE INDEX idx_appointment_date ON appointments(appointment_date);
CREATE INDEX idx_customer_email ON appointments(customer_email);
CREATE INDEX idx_status ON appointments(status);

-- Tabella conversazioni (opzionale, per storico chat)
CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    user_message TEXT NOT NULL,
    assistant_message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_session_id ON conversations(session_id);

-- Tabella configurazione business
CREATE TABLE IF NOT EXISTS business_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserisci configurazione di default
INSERT INTO business_config (config_key, config_value) VALUES
    ('business_name', 'La Tua Azienda'),
    ('business_hours_start', '09:00'),
    ('business_hours_end', '18:00'),
    ('appointment_duration', '30'),
    ('max_appointments_per_day', '16')
ON CONFLICT (config_key) DO NOTHING;

-- Funzione per aggiornare updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger per aggiornare updated_at
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_config_updated_at BEFORE UPDATE ON business_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
