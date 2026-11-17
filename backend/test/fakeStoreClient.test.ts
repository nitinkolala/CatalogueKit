import { describe, expect, it } from 'vitest';
import { FakeStoreClient, UpstreamError } from '../src/data/fakeStoreClient.js';

const raw = {
  id: 7,
  title: 'Bag',
  price: 9.5,
  description: 'Nice bag',
  category: 'bags',
  image: 'https://img/7.jpg',
  rating: { rate: 4.4, count: 120 },
};

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

describe('FakeStoreClient', () => {
  it('maps upstream products to the backend product shape', async () => {
    const client = new FakeStoreClient({
      baseUrl: 'https://upstream.test/',
      timeoutMs: 1000,
      fetchImpl: async () => jsonResponse([raw]),
    });
    const [product] = await client.fetchProducts();
    expect(product).toEqual({
      id: 7,
      title: 'Bag',
      price: 9.5,
      description: 'Nice bag',
      category: 'bags',
      imageUrl: 'https://img/7.jpg',
      available: true,
      rating: { rate: 4.4, count: 120 },
    });
  });

  it('requests the /products path without a double slash', async () => {
    let requested = '';
    const client = new FakeStoreClient({
      baseUrl: 'https://upstream.test//',
      timeoutMs: 1000,
      fetchImpl: async (url) => {
        requested = String(url);
        return jsonResponse([]);
      },
    });
    await client.fetchProducts();
    expect(requested).toBe('https://upstream.test/products');
  });

  it('throws UpstreamError on a non-2xx response', async () => {
    const client = new FakeStoreClient({
      baseUrl: 'https://upstream.test',
      timeoutMs: 1000,
      fetchImpl: async () => new Response('nope', { status: 503 }),
    });
    await expect(client.fetchProducts()).rejects.toMatchObject({ name: 'UpstreamError', status: 503 });
  });

  it('throws UpstreamError when the network fails', async () => {
    const client = new FakeStoreClient({
      baseUrl: 'https://upstream.test',
      timeoutMs: 1000,
      fetchImpl: async () => {
        throw new TypeError('fetch failed');
      },
    });
    await expect(client.fetchProducts()).rejects.toBeInstanceOf(UpstreamError);
  });

  it('throws UpstreamError when the payload is not an array', async () => {
    const client = new FakeStoreClient({
      baseUrl: 'https://upstream.test',
      timeoutMs: 1000,
      fetchImpl: async () => jsonResponse({ oops: true }),
    });
    await expect(client.fetchProducts()).rejects.toBeInstanceOf(UpstreamError);
  });
});
