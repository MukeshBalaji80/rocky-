import assert from 'node:assert/strict';

const base = `http://127.0.0.1:${process.env.ROCKY_TEST_PORT || 3123}`;

const health = await fetch(`${base}/health`);
assert.equal(health.status, 200);
assert.deepEqual(await health.json(), { ok: true });

const missingMessages = await fetch(`${base}/v1/chat/completions`, {
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify({}),
});
assert.equal(missingMessages.status, 503);

console.log('Rocky backend smoke test passed.');
