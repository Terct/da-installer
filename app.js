const express = require('express');
const app = express();
const path = require('path');
const fs = require('fs').promises;
const axios = require('axios'); // Importe a biblioteca axios
const dotenv = require('dotenv'); // Importe a biblioteca dotenv
const bodyParser = require('body-parser');
const cors = require('cors');

const serverAuth = require("./auth")
const functionStreamTicks = require("./functions/deriv/ticks-stream")

const execClientLogin = require("./functions/server/client-login")
const execSessionVerific = require("./functions/server/sessions-verific")

const PORT = 3000;

// Carregue as variáveis de ambiente do arquivo .env
dotenv.config();

app.use(express.static(path.join(__dirname, 'shells')));
app.use(express.json({ limit: '5000mb' }));
app.use(express.urlencoded({ limit: '5000mb', extended: true }));
app.use(bodyParser.json());

app.use(cors());

// Habilitar o CORS para uma origem específica
app.use(cors({
  origin: '*',
  optionsSuccessStatus: 200 // Algumas configurações adicionais, se necessário
}));



app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'shells', 'index.html'));
});


app.get('/install', (req, res) => {
  res.sendFile(path.join(__dirname, 'shells', 'dagestao-instaler.sh'));
})



app.listen(PORT, () => {
  console.log(`Servidor principal rodando na porta ${PORT}`);
});



