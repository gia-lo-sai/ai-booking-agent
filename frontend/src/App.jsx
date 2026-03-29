import { useState, useRef, useEffect } from 'react'
import axios from 'axios'
import { Analytics } from '@vercel/analytics/react'
import './App.css'

function App() {
  const [messages, setMessages] = useState([
    {
      role: 'assistant',
      content: '👋 Ciao! Sono il tuo assistente AI. Posso aiutarti a prenotare un appuntamento, rispondere a domande o gestire le tue prenotazioni esistenti. Come posso aiutarti oggi?'
    }
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [conversationHistory, setConversationHistory] = useState([])
  const messagesEndRef = useRef(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const sendMessage = async (e) => {
    e.preventDefault()
    if (!input.trim() || loading) return

    const userMessage = input.trim()
    setInput('')
    setLoading(true)

    // Aggiungi messaggio utente
    setMessages(prev => [...prev, { role: 'user', content: userMessage }])

    try {
      const response = await axios.post('/api/chat', {
        message: userMessage,
        conversationHistory
      })

      // Aggiungi risposta assistente
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: response.data.message
      }])

      // Aggiorna storico conversazione
      setConversationHistory(response.data.conversationHistory)

      // Se viene rilevato un intent di prenotazione, mostra suggerimento
      if (response.data.bookingIntent?.detected) {
        console.log('Intent prenotazione rilevato')
      }

    } catch (error) {
      console.error('Errore invio messaggio:', error)
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: '❌ Mi dispiace, si è verificato un errore. Riprova tra poco.'
      }])
    } finally {
      setLoading(false)
    }
  }

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage(e)
    }
  }

  return (
    <div className="app">
      <header className="header">
        <h1>🤖 AI Booking Agent</h1>
        <p>Assistente intelligente per appuntamenti</p>
      </header>

      <div className="chat-container">
        <div className="messages">
          {messages.map((msg, index) => (
            <div
              key={index}
              className={`message ${msg.role === 'user' ? 'user-message' : 'assistant-message'}`}
            >
              <div className="message-avatar">
                {msg.role === 'user' ? '👤' : '🤖'}
              </div>
              <div className="message-content">
                <div className="message-text">{msg.content}</div>
              </div>
            </div>
          ))}
          {loading && (
            <div className="message assistant-message">
              <div className="message-avatar">🤖</div>
              <div className="message-content">
                <div className="typing-indicator">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <form onSubmit={sendMessage} className="input-form">
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Scrivi un messaggio..."
            disabled={loading}
            rows="1"
          />
          <button type="submit" disabled={loading || !input.trim()}>
            {loading ? '⏳' : '📤'}
          </button>
        </form>
      </div>

      <footer className="footer">
        <p>Powered by Claude AI & PostgreSQL su hcloud</p>
      </footer>
      <Analytics />
    </div>
  )
}

export default App
