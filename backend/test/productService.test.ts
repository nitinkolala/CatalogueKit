import { describe, expect, it } from 'vitest';
import type { Product, ProductSource } from '../src/domain/product.js';
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

function countingSource(products: Product[]) {
  const source = { calls: 0, fetchProducts: async () => { source.calls += 1; return products; } };
  return source satisfies ProductSource & { calls: number };
}

describe('ProductService', () => {
  it('returns the top N products by rating', async () => {
    const service = new ProductService({
      source: countingSource([1, 2, 3, 4, 5, 6, 7].map((id) => product(id, id))),
      cacheTtlMs: 60_000,
    });
    const featured = await service.featuredProducts(5);
    expect(featured.map((p) => p.id)).toEqual([7, 6, 5, 4, 3]);
  });

  it('serves repeated reads from the cache until the TTL expires', async () => {
    let now = 0;
    const source = countingSource([product(1, 1)]);
    const service = new ProductService({ source, cacheTtlMs: 1000, now: () => now });

    await service.listProducts();
    await service.listProducts();
    expect(source.calls).toBe(1);

    now = 1000;
    await service.listProducts();
    expect(source.calls).toBe(2);
  });
});
