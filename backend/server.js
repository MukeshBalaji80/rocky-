import express from 'express';

const app = express();
app.use(express.json({ limit: '1mb' }));

const providerBase = (process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1').replace(/\/$/, '');
const apiKey = process.env.OPENAI_API_KEY;
const defaultModel = process.env.ROCKY_MODEL || 'gpt-4o-mini';

if (!apiKey) console.warn('OPENAI_API_KEY is not set. /v1/chat/completions will return 503.');

app.get('/health', (_, res) => res.json({ ok: true }));

app.post('/v1/chat/completions', async (req, res) => {
  if (!apiKey) return res.status(503).json({ error: 'Server model credentials are not configured.' });
  const { messages, temperature = 0.75 } = req.body ?? {};
  const model = req.body?.model || defaultModel;
  if (!Array.isArray(messages) || messages.length === 0) return res.status(400).json({ error: 'messages is required.' });

  try {
    const upstream = await fetch(`${providerBase}/chat/completions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({ model, messages, temperature }),
    });
    const body = await upstream.text();
    res.status(upstream.status).type('application/json').send(body);
  } catch (error) {
    res.status(502).json({ error: 'Model provider unavailable.', detail: String(error) });
  }
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => console.log(`Rocky backend listening on :${port}`));
