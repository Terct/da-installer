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

// Registro de cliente
app.post('/signup', async (req, res) => {
  try {
    const { name, email, password, confirmPassword } = req.body;

    // Verificar se as senhas coincidem
    if (password !== confirmPassword) {
      return res.status(400).json({ error: 'As senhas não são iguais' });
    }

    // Verificar se o e-mail já está cadastrado
    const existingUser = await supabase
      .from('users')
      .select('id')
      .eq('email', email);

    if (existingUser.data && existingUser.data.length > 0) {
      return res.status(400).json({ error: 'Este e-mail já está cadastrado' });
    }

    // Hash da senha
    const hashedPassword = await bcrypt.hash(password, 10);

    // Inserir usuário em Supabase
    const { data, error } = await supabase.from('users').insert([
      { name, email, password: hashedPassword },
    ]);

    if (error) {
      return res.status(500).json({ error: 'Erro ao registrar o usuário' });
    }

    res.status(201).json({ message: 'Usuário registrado com sucesso' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno' });
  }
});



// Início de sessão
app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Buscar usuário
    const { data, error } = await supabase
      .from('users')
      .select()
      .eq('email', email);

    if (error) {
      return res.status(500).json({ error: 'Erro ao fazer login' });
    }

    // Verificar se o usuário existe
    if (data.length === 0) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }

    // Verificar a senha
    const match = await bcrypt.compare(password, data[0].password);

    if (!match) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }

    // Gerar token
    const token = jwt.sign({ userId: data[0].id }, process.env.JWT_SECRET, {
      expiresIn: '1h',
    });

    // Verificar se a sessão já existe para este user_id
    const existingSession = await supabase
      .from('sessions')
      .select('user_id, created_at')
      .eq('user_id', data[0].id);

    if (existingSession.data && existingSession.data.length > 0) {
      // Atualizar a coluna 'created_at' na tabela 'sessions'
      const { data: updateResult, error: updateError } = await supabase
        .from('sessions')
        .update({ created_at: moment().tz('America/Sao_Paulo').format(), token })
        .eq('user_id', data[0].id);

      if (updateError) {
        console.error(updateError);
        return res.status(500).json({ error: 'Erro ao atualizar a sessão' });
      }
    } else {
      // Inserir dados de sessão na tabela 'sessions'
      const sessionData = {
        user_id: data[0].id,
        token,
        created_at: moment().tz('America/Sao_Paulo').format(),
      };

      const { data: insertResult, error: insertError } = await supabase
        .from('sessions')
        .insert([sessionData], { onConflict: ['user_id'] }); // Adicione onConflict para lidar com conflitos

      if (insertError) {
        console.error(insertError);
        return res.status(500).json({ error: 'Erro ao criar sessão' });
      }
    }

    res.json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno' });
  }
});


// Rota para procurar por um valor na coluna 'token' na tabela 'sessions'
app.get('/search-sid', async (req, res) => {
  try {
    const { searchValue } = req.query;

    // Verificar se o parâmetro de consulta 'searchValue' está presente
    if (!searchValue) {
      return res.status(400).json({ error: 'O parâmetro de consulta searchValue é obrigatório' });
    }

    // Buscar sessões com base no valor fornecido na coluna 'token'
    const { data, error } = await supabase
      .from('sessions')
      .select('user_id, token, created_at')
      .ilike('token', `%${searchValue}%`); // Utilize ilike para pesquisa de substring sem diferenciar maiúsculas e minúsculas

    if (error) {
      console.error(error);
      return res.status(500).json({ error: 'Erro ao buscar sessões' });
    }

    res.json({ sessions: data });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno' });
  }
});

// Rota para procurar por um valor na coluna 'token' na tabela 'sessions'
app.get('/search-machine-ticks', async (req, res) => {
  try {
    const { searchValue } = req.query;

    // Verificar se o parâmetro de consulta 'searchValue' está presente
    if (!searchValue) {
      return res.status(400).json({ error: 'O parâmetro de consulta searchValue é obrigatório' });
    }

    // Buscar sessões com base no valor fornecido na coluna 'token'
    const { data, error } = await supabase
      .from('machine_ticks')
      .select('id, name, online, linked_users')
      .ilike('name', `%${searchValue}%`); // Utilize ilike para pesquisa de substring sem diferenciar maiúsculas e minúsculas

    if (error) {
      console.error(error);
      return res.status(500).json({ error: 'Erro ao buscar maquinas' });
    }

    res.json({ machines: data });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro interno' });
  }
});


app.listen(port, () => {
  console.log(`Servidor db rodando na porta ${port}`);
});
