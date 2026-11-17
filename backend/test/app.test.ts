import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { ERROR_CODES, ROUTES, createApp } from '../src/http/app.js';
import type { Product, ProductSource } from '../src/domain/product.js';
import { UpstreamError } from '../src/data/fakeStoreClient.js';
import { ProductService } from '../src/services/productService.js';

const product = (id: number, rate: number): Product => ({
  id,
  title: `P${id}`,
  price: 1,
  description: '',
  category: 'c',
  imageUrl: '',
  rating: { rate, count: 1 },
});

const appWith = (source: ProductSource, featuredCount = 5) =>
  createApp({
    productService: new ProductService({ source, cacheTtlMs: 60_000 }),
    featuredCount,
  });

describe('HTTP API', () => {
  it('GET /health returns ok', async () => {
    const res = await request(appWith({ fetchProducts: async () => [] })).get(ROUTES.health);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('GET /products/featured returns the 5 top-rated products', async () => {
    const source: ProductSource = {
      fetchProducts: async () => [1, 2, 3, 4, 5, 6].map((id) => product(id, id)),
    };
    const res = await request(appWith(source)).get(ROUTES.featured);
    expect(res.status).toBe(200);
    expect(res.body.items.map((p: Product) => p.id)).toEqual([6, 5, 4, 3, 2]);
  });

  it('GET /products returns all products', async () => {
    const source: ProductSource = { fetchProducts: async () => [product(1, 1), product(2, 2)] };
    const res = await request(appWith(source)).get(ROUTES.products);
    expect(res.status).toBe(200);
    expect(res.body.items).toHaveLength(2);
  });

  it('returns 502 with a stable error code when the upstream fails', async () => {
    const source: ProductSource = {
      fetchProducts: async () => {
        throw new UpstreamError('down', 500);
      },
    };
    const res = await request(appWith(source)).get(ROUTES.featured);
    expect(res.status).toBe(502);
    expect(res.body.error.code).toBe(ERROR_CODES.upstreamUnavailable);
  });

  it('GET /products/categories returns distinct sorted categories', async () => {
    const source: ProductSource = {
      fetchProducts: async () => [
        { ...product(1, 1), category: 'jewelery' },
        { ...product(2, 1), category: 'electronics' },
        { ...product(3, 1), category: 'jewelery' },
      ],
    };
    const res = await request(appWith(source)).get(ROUTES.categories);
    expect(res.status).toBe(200);
    expect(res.body.items).toEqual(['electronics', 'jewelery']);
  });

  it('GET /products/categories/:name returns top rated first, then the rest', async () => {
    const source: ProductSource = {
      fetchProducts: async () => [
        { ...product(1, 3), category: 'jewelery' },
        { ...product(2, 5), category: 'jewelery' },
        { ...product(3, 4), category: 'jewelery' },
        { ...product(4, 5), category: 'electronics' },
      ],
    };
    const res = await request(appWith(source, 2)).get(`${ROUTES.categories}/jewelery`);
    expect(res.status).toBe(200);
    expect(res.body.topRated.map((p: Product) => p.id)).toEqual([2, 3]);
    expect(res.body.more.map((p: Product) => p.id)).toEqual([1]);
  });

  it('GET /products/categories/:name returns 404 for an unknown category', async () => {
    const source: ProductSource = { fetchProducts: async () => [{ ...product(1, 1), category: 'jewelery' }] };
    const res = await request(appWith(source)).get(`${ROUTES.categories}/${encodeURIComponent('nope')}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ERROR_CODES.notFound);
  });

  it('GET /products/search matches title and description, best rated first', async () => {
    const source: ProductSource = {
      fetchProducts: async () => [
        { ...product(1, 2), title: 'Gaming drive' },
        { ...product(2, 5), title: 'Lamp', description: 'gaming light' },
        { ...product(3, 4), title: 'Kettle' },
      ],
    };
    const res = await request(appWith(source)).get(`${ROUTES.search}?q=${encodeURIComponent('  GAMING ')}`);
    expect(res.status).toBe(200);
    expect(res.body.items.map((p: Product) => p.id)).toEqual([2, 1]);
    expect(res.body.total).toBe(2);
    expect(res.body.hasMore).toBe(false);
  });

  it('GET /products/search pages results with offset and limit', async () => {
    const source: ProductSource = {
      fetchProducts: async () => [1, 2, 3].map((id) => ({ ...product(id, id), title: `widget ${id}` })),
    };
    const res = await request(appWith(source)).get(`${ROUTES.search}?q=widget&offset=0&limit=2`);
    expect(res.body.items).toHaveLength(2);
    expect(res.body.total).toBe(3);
    expect(res.body.hasMore).toBe(true);
  });

  it('GET /products/search can be limited to one category', async () => {
    const source: ProductSource = {
      fetchProducts: async () => [
        { ...product(1, 1), title: 'ring', category: 'jewelery' },
        { ...product(2, 1), title: 'ring light', category: 'electronics' },
      ],
    };
    const res = await request(appWith(source)).get(`${ROUTES.search}?q=ring&category=jewelery`);
    expect(res.body.items.map((p: Product) => p.id)).toEqual([1]);
  });

  it('GET /products/search returns 400 with a stable code for a too-short query', async () => {
    const res = await request(appWith({ fetchProducts: async () => [] })).get(`${ROUTES.search}?q=a`);
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ERROR_CODES.invalidQuery);
  });

  it('GET /products/search returns 400 when the query is missing', async () => {
    const res = await request(appWith({ fetchProducts: async () => [] })).get(ROUTES.search);
    expect(res.status).toBe(400);
  });

  it('GET /products/search handles symbols, accents and emoji in the query', async () => {
    const source: ProductSource = {
      fetchProducts: async () => [{ ...product(1, 1), title: 'Café 🍎 & more' }],
    };
    const res = await request(appWith(source)).get(
      `${ROUTES.search}?q=${encodeURIComponent('café 🍎 &')}`,
    );
    expect(res.status).toBe(200);
    expect(res.body.items.map((p: Product) => p.id)).toEqual([1]);
  });

  it('returns 404 with a JSON error for unknown routes', async () => {
    const res = await request(appWith({ fetchProducts: async () => [] })).get('/nope');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ERROR_CODES.notFound);
  });
});
