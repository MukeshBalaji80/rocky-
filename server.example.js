// Example Node backend contract. Put your real provider SDK/API call here.
// This deliberately does not contain a secret or provider-specific credential.
import express from 'express';

const app = express();
app.use(express.json());

app.post('/v1/chat/completions', async (req, res) => {
  const { model, messages, temperature } = req.body;
  if (!model || !Array.isArray(messages)) return res.status(400).json({ error: 'Invalid request' });

  // Replace this section with your server-side model provider call.
  // Keep provider credentials in server environment variables, never in the Flutter app.
  const reply = 'Backend connected. Replace this placeholder with your model provider.';
  res.json({ choices: [{ message: { content: reply } }], model, temperature });
});

app.listen(3000, () => console.log('Rocky backend listening on :3000'));
