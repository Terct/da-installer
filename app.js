const express = require('express');
const app = express();
const path = require('path');
const fs = require('fs').promises;
const axios = require('axios'); // Importe a biblioteca axios
const dotenv = require('dotenv'); // Importe a biblioteca dotenv
const bodyParser = require('body-parser');
const cors = require('cors');

const port = 3000

const serverAuth = require("./auth");


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

app.get('/install', async (req, res) => {
  try {
    const { app, key } = req.query;

    // Validar a presença de app e key
    if (!app || !key) {
      return res.status(400).json({ error: 'Parâmetros app e key são obrigatórios.' });
    }

    // Fazer requisição para a rota /validate com os parâmetros app e key usando axios
    const validateResponse = await axios.post(`http://localhost:61512/validate`, {
      key_app: key,
      app,
    });

    // Verificar o status da resposta da rota /validate
    if (validateResponse.status === 200) {
      // Se chegou até aqui, a validação foi bem-sucedida, enviar o arquivo
      res.sendFile(path.join(__dirname, 'shells', 'applications', app, 'installer.sh'));
    }

  } catch (error) {

    if (error.response.status === 401) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'invalid_key.sh'));

    } else if (error.response.status === 402) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'app_mismatch.sh'));

    } else if (error.response.status === 403) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'expired_key.sh'));

    } else {
      console.error('Erro ao processar a solicitação:', error);
      return res.status(500).json({ error: 'Erro interno do servidor' });
    }

  }

});



app.get('/subscription-key', async (req, res) => {

  try {
    const { ip, key } = req.query;

    // Validar a presença de app e key
    if (!ip || !key) {
      return res.status(400).json({ error: 'Parâmetros ip e key são obrigatórios.' });
    }

    // Fazer requisição para a rota /validate com os parâmetros app e key usando axios
    const validateResponse = await axios.post(`http://localhost:61512/check-signature`, {
      key_app: key,
      user_ip: ip
    });

    // Verificar o status da resposta da rota /validate
    if (validateResponse.status === 200) {
      // Se chegou até aqui, a validação foi bem-sucedida, enviar o arquivo
      res.sendFile(path.join(__dirname, 'shells', 'actions', 'signature.sh'));
    }

  } catch (error) {

    if (error.response.status === 401) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'invalid_key.sh'));

    } else if (error.response.status === 402) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'app_mismatch.sh'));

    } else if (error.response.status === 403) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'expired_key.sh'));

    } else if (error.response.status === 404) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'key_aleary_assined'));

    } else if (error.response.status === 405) {
      res.sendFile(path.join(__dirname, 'shells', 'actions', 'loading.sh'));


    } else {
      console.error('Erro ao processar a solicitação:', error);
      return res.status(500).json({ error: 'Erro interno do servidor' });
    }

  }


});


app.get('/update-key-used', async (req, res) => {

  try {
    const { ip, key } = req.query;

    // Validar a presença de app e key
    if (!ip || !key) {
      return res.status(400).json({ error: 'Parâmetros ip e key são obrigatórios.' });
    }

    // Fazer requisição para a rota /validate com os parâmetros app e key usando axios
    const validateResponse = await axios.post(`http://localhost:61512/update-used`, {
      key_app: key,
      user_ip: ip
    });

    // Verificar o status da resposta da rota /validate
    if (validateResponse.status === 200) {
      // Se chegou até aqui, a validação foi bem-sucedida, enviar o arquivo
      return res.status(200).json({ success: 'Chave Assinada' });
    }

  } catch (error) {

    if (error.response.status === 401) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'invalid_key.sh'));

    } else if (error.response.status === 402) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'app_mismatch.sh'));

    } else if (error.response.status === 403) {
      res.sendFile(path.join(__dirname, 'shells', 'error', 'expired_key.sh'));

    } else {
      console.error('Erro ao processar a solicitação:', error);
      return res.status(500).json({ error: 'Erro interno do servidor' });
    }

  }


});


app.listen(port, () => {
  console.log(`Servidor rodando na porta ${port}`);
});


