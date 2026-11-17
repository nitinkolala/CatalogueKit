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

  it('returns 404 with a JSON error for unknown routes', async () => {
    const res = await request(appWith({ fetchProducts: async () => [] })).get('/nope');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe(ERROR_CODES.notFound);
  });
});
