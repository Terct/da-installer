const express = require('express');
const app = express();
const path = require('path');
const fs = require('fs').promises;
const axios = require('axios'); // Importe a biblioteca axios
const dotenv = require('dotenv'); // Importe a biblioteca dotenv
const bodyParser = require('body-parser');
const cors = require('cors');


const serverAuth = require("./auth")

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
  res.sendFile(path.join(__dirname, 'shells', 'dagestao-instaler.sh'));
})

// Rota /install com parâmetros app e key
app.get('/install', async (req, res) => {
  try {
    const { app, key } = req.query;

    // Fazer requisição para a rota /validate com os parâmetros app e key usando axios
    const validateResponse = await axios.post(`http://localhost:61512/validate`, {
      key_app: key,
      app,
    });

    // Verificar o status da resposta da rota /validate
    if (validateResponse.status !== 200) {
      return res.status(validateResponse.status).json(validateResponse.data);
    }

    // Se chegou até aqui, a validação foi bem-sucedida, enviar o arquivo
    res.sendFile(path.join(__dirname, 'shells', 'applications', app, 'installer.sh'));

  } catch (error) {

    console.error('Erro ao processar a solicitação:', error);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }

});


app.listen(PORT, () => {
  console.log(`Servidor principal rodando na porta ${PORT}`);
});



