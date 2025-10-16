#!/usr/bin/env python3
"""
Anki Deck Viewer - Flask Web Application
Simple flashcard viewer for Batocera
"""

from flask import Flask, render_template, jsonify, request
import os
import json
import random

app = Flask(__name__)

# Configuration
ANKI_DECK_PATH = "/userdata/roms/anki/decks"
APP_VERSION = "0.2.0"

# Simple in-memory storage for demo cards
# In a real app, you'd load these from Anki files
DEMO_CARDS = [
    {"front": "Hello", "back": "こんにちは (Konnichiwa)"},
    {"front": "Thank you", "back": "ありがとう (Arigatou)"},
    {"front": "Good morning", "back": "おはよう (Ohayou)"},
    {"front": "Good night", "back": "おやすみ (Oyasumi)"},
    {"front": "Yes", "back": "はい (Hai)"},
    {"front": "No", "back": "いいえ (Iie)"},
    {"front": "Water", "back": "水 (Mizu)"},
    {"front": "Food", "back": "食べ物 (Tabemono)"},
]


@app.route('/')
def index():
    """Main page - deck selection"""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Anki Deck Viewer</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                flex-direction: column;
                color: white;
            }
            .header {
                background-color: rgba(0, 0, 0, 0.3);
                padding: 20px;
                text-align: center;
            }
            .header h1 {
                font-size: 2.5em;
                margin-bottom: 10px;
            }
            .container {
                flex: 1;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                padding: 40px 20px;
            }
            .deck-list {
                background: white;
                color: #333;
                border-radius: 15px;
                padding: 30px;
                max-width: 600px;
                width: 100%;
                box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            }
            .deck-list h2 {
                margin-bottom: 20px;
                color: #667eea;
            }
            .deck-button {
                display: block;
                width: 100%;
                padding: 20px;
                margin: 10px 0;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 10px;
                font-size: 1.2em;
                cursor: pointer;
                transition: transform 0.2s, box-shadow 0.2s;
            }
            .deck-button:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
            }
            .info {
                margin-top: 30px;
                padding: 20px;
                background: rgba(255, 255, 255, 0.1);
                border-radius: 10px;
                text-align: center;
            }
            .info code {
                background: rgba(0, 0, 0, 0.2);
                padding: 2px 8px;
                border-radius: 4px;
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🎴 Anki Deck Viewer</h1>
            <p>v""" + APP_VERSION + """ - Running on Batocera</p>
        </div>
        <div class="container">
            <div class="deck-list">
                <h2>Select a Deck</h2>
                <button class="deck-button" onclick="location.href='/flashcards/demo'">
                    📚 Demo Deck (Japanese Basics)
                </button>
                <button class="deck-button" onclick="location.href='/api/decks'">
                    📊 View Available Decks (API)
                </button>
            </div>
            <div class="info">
                <p>Add your Anki decks to: <code>""" + ANKI_DECK_PATH + """</code></p>
                <p style="margin-top: 10px;">Supported formats: .apkg, .anki2, .db</p>
            </div>
        </div>
    </body>
    </html>
    """


@app.route('/flashcards/<deck_name>')
def flashcards(deck_name):
    """Flashcard study interface"""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Flashcards - """ + deck_name + """</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                flex-direction: column;
            }
            .header {
                background-color: rgba(0, 0, 0, 0.3);
                padding: 15px 20px;
                display: flex;
                justify-content: space-between;
                align-items: center;
                color: white;
            }
            .header a {
                color: white;
                text-decoration: none;
                font-size: 1.2em;
            }
            .progress {
                background: rgba(0, 0, 0, 0.2);
                padding: 10px 20px;
                text-align: center;
                color: white;
            }
            .container {
                flex: 1;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                padding: 20px;
            }
            .card-container {
                perspective: 1000px;
                width: 100%;
                max-width: 800px;
                height: 400px;
            }
            .card {
                width: 100%;
                height: 100%;
                position: relative;
                transform-style: preserve-3d;
                transition: transform 0.6s;
                cursor: pointer;
            }
            .card.flipped {
                transform: rotateY(180deg);
            }
            .card-face {
                position: absolute;
                width: 100%;
                height: 100%;
                backface-visibility: hidden;
                display: flex;
                align-items: center;
                justify-content: center;
                background: white;
                border-radius: 20px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.3);
                padding: 40px;
                font-size: 2.5em;
                font-weight: bold;
                color: #333;
                text-align: center;
            }
            .card-back {
                transform: rotateY(180deg);
                background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                color: white;
            }
            .controls {
                margin-top: 30px;
                display: flex;
                gap: 20px;
            }
            .btn {
                padding: 15px 30px;
                font-size: 1.2em;
                border: none;
                border-radius: 10px;
                cursor: pointer;
                transition: transform 0.2s, box-shadow 0.2s;
                font-weight: bold;
            }
            .btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 20px rgba(0,0,0,0.3);
            }
            .btn-flip {
                background: white;
                color: #667eea;
            }
            .btn-prev {
                background: #f093fb;
                color: white;
            }
            .btn-next {
                background: #667eea;
                color: white;
            }
            .btn-shuffle {
                background: #764ba2;
                color: white;
            }
            @media (max-width: 768px) {
                .card-face {
                    font-size: 1.8em;
                    padding: 20px;
                }
                .btn {
                    padding: 12px 20px;
                    font-size: 1em;
                }
            }
        </style>
    </head>
    <body>
        <div class="header">
            <a href="/">← Back to Decks</a>
            <h2>📚 """ + deck_name + """</h2>
            <div></div>
        </div>
        <div class="progress">
            <span id="progress">Card <span id="current">1</span> of <span id="total">0</span></span>
        </div>
        <div class="container">
            <div class="card-container">
                <div class="card" id="flashcard" onclick="flipCard()">
                    <div class="card-face card-front" id="card-front">
                        Loading...
                    </div>
                    <div class="card-face card-back" id="card-back">
                        ...
                    </div>
                </div>
            </div>
            <div class="controls">
                <button class="btn btn-prev" onclick="prevCard()">◀ Previous</button>
                <button class="btn btn-flip" onclick="flipCard()">🔄 Flip</button>
                <button class="btn btn-next" onclick="nextCard()">Next ▶</button>
                <button class="btn btn-shuffle" onclick="shuffle()">🎲 Shuffle</button>
            </div>
        </div>
        <script>
            let cards = [];
            let currentIndex = 0;
            let isFlipped = false;

            async function loadDeck() {
                try {
                    const response = await fetch('/api/cards/""" + deck_name + """');
                    const data = await response.json();
                    cards = data.cards;
                    updateCard();
                    updateProgress();
                } catch (error) {
                    console.error('Error loading deck:', error);
                    document.getElementById('card-front').textContent = 'Error loading deck';
                }
            }

            function updateCard() {
                if (cards.length === 0) return;
                const card = cards[currentIndex];
                document.getElementById('card-front').textContent = card.front;
                document.getElementById('card-back').textContent = card.back;
                document.getElementById('flashcard').classList.remove('flipped');
                isFlipped = false;
            }

            function updateProgress() {
                document.getElementById('current').textContent = currentIndex + 1;
                document.getElementById('total').textContent = cards.length;
            }

            function flipCard() {
                const card = document.getElementById('flashcard');
                card.classList.toggle('flipped');
                isFlipped = !isFlipped;
            }

            function nextCard() {
                currentIndex = (currentIndex + 1) % cards.length;
                updateCard();
                updateProgress();
            }

            function prevCard() {
                currentIndex = (currentIndex - 1 + cards.length) % cards.length;
                updateCard();
                updateProgress();
            }

            function shuffle() {
                for (let i = cards.length - 1; i > 0; i--) {
                    const j = Math.floor(Math.random() * (i + 1));
                    [cards[i], cards[j]] = [cards[j], cards[i]];
                }
                currentIndex = 0;
                updateCard();
                updateProgress();
            }

            // Keyboard controls
            document.addEventListener('keydown', (e) => {
                if (e.key === 'ArrowLeft') prevCard();
                if (e.key === 'ArrowRight') nextCard();
                if (e.key === ' ' || e.key === 'ArrowUp' || e.key === 'ArrowDown') {
                    e.preventDefault();
                    flipCard();
                }
                if (e.key === 's' || e.key === 'S') shuffle();
            });

            // Load deck on page load
            loadDeck();
        </script>
    </body>
    </html>
    """


@app.route('/api/cards/<deck_name>')
def get_cards(deck_name):
    """API endpoint - get cards for a deck"""
    # For demo, return demo cards
    # In a real app, you'd load from the actual Anki deck
    if deck_name == 'demo':
        return jsonify({'cards': DEMO_CARDS})
    else:
        return jsonify({'cards': [], 'error': 'Deck not found'}), 404


@app.route('/api/status')
def api_status():
    """API endpoint - return app status"""
    return jsonify({
        'status': 'running',
        'version': APP_VERSION,
        'deck_path': ANKI_DECK_PATH,
        'deck_path_exists': os.path.exists(ANKI_DECK_PATH)
    })


@app.route('/api/decks')
def api_decks():
    """API endpoint - list available deck files"""
    decks = []

    if os.path.exists(ANKI_DECK_PATH):
        for filename in os.listdir(ANKI_DECK_PATH):
            if filename.endswith(('.apkg', '.anki2', '.db')):
                filepath = os.path.join(ANKI_DECK_PATH, filename)
                decks.append({
                    'filename': filename,
                    'path': filepath,
                    'size': os.path.getsize(filepath)
                })

    return jsonify({
        'deck_path': ANKI_DECK_PATH,
        'count': len(decks),
        'decks': decks
    })


if __name__ == '__main__':
    # Create deck directory if it doesn't exist
    os.makedirs(ANKI_DECK_PATH, exist_ok=True)

    # Run the Flask app
    print(f"Starting Anki Deck Viewer v{APP_VERSION}")
    print(f"Deck path: {ANKI_DECK_PATH}")
    app.run(host='0.0.0.0', port=5000, debug=True)
