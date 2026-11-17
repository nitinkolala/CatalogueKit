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

  it('caps the admin-curated list at the configured count, keeping the admin order', async () => {
    const service = new ProductService({
      source: countingSource([1, 2, 3, 4].map((id) => product(id, id))),
      cacheTtlMs: 60_000,
      featuredEntries: [{ id: 4 }, { id: 2 }, { id: 1 }, { id: 3 }],
    });
    const featured = await service.featuredProducts(2);
    expect(featured.map((p) => p.id)).toEqual([4, 2]);
  });

  it('splits a category into top rated and the rest, and returns undefined for unknown categories', async () => {
    const service = new ProductService({
      source: countingSource([
        { ...product(1, 2), category: 'a' },
        { ...product(2, 5), category: 'a' },
        { ...product(3, 4), category: 'b' },
      ]),
      cacheTtlMs: 60_000,
    });
    const page = await service.productsInCategory('a', 1);
    expect(page?.topRated.map((p) => p.id)).toEqual([2]);
    expect(page?.more.map((p) => p.id)).toEqual([1]);
    expect(await service.productsInCategory('missing', 1)).toBeUndefined();
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
