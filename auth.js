const express = require('express');
const bodyParser = require('body-parser');
const { createClient } = require('@supabase/supabase-js');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
require('dotenv').config();
const moment = require('moment-timezone');

const app = express();
const port = 61512

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

app.use(bodyParser.json());


// Início de sessão
app.post('/validate', async (req, res) => {
  try {
    const { key_app, app } = req.body;

    // Buscar usuário
    const { data, error } = await supabase
      .from('keys_installer')
      .select()
      .eq('key_app', key_app);

    if (error) {
      return res.status(500).json({ error: 'Erro ao localizar a chave.' });
    }

    // Verificar se o usuário existe
    if (data.length === 0) {
      return res.status(401).json({ error: 'A chave é inválida.' });
    }

    if (data[0].app !== app) {
      return res.status(401).json({ error: 'O app não corresponde.' });
    }

    // Verificar se o status da chave é "actived"
    if (data[0].status !== 'actived') {
      return res.status(401).json({ error: 'A chave não está ativa.' });
    }

    // Se chegou até aqui, as credenciais e o status são válidos
    return res.status(200).json({ success: 'A chave é válida.' });

  } catch (e) {
    console.error('Erro ao processar a solicitação:', e);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
});



app.listen(port, () => {
  console.log(`Servidor db rodando na porta ${port}`);
});
