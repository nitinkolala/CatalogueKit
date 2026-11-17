import { describe, expect, it } from 'vitest';
import { parseFeaturedEntries, type Product, type ProductSource } from '../src/domain/product.js';
import { ProductService } from '../src/services/productService.js';

const product = (id: number, rate: number, available = true): Product => ({
  id,
  title: `P${id}`,
  price: 1,
  description: '',
  category: 'c',
  imageUrl: '',
  available,
  rating: { rate, count: 1 },
});

const source = (products: Product[]): ProductSource => ({ fetchProducts: async () => products });

describe('curated featured list', () => {
  const products = [product(1, 5), product(2, 4), product(3, 3), product(4, 2), product(5, 1), product(6, 0)];

  it('returns products in the admin order, not rating order', async () => {
    const service = new ProductService({
      source: source(products),
      cacheTtlMs: 60_000,
      featuredEntries: [{ id: 4 }, { id: 1 }, { id: 6 }, { id: 2 }, { id: 3 }],
    });
    const featured = await service.featuredProducts(5);
    expect(featured.map((p) => p.id)).toEqual([4, 1, 6, 2, 3]);
  });

  it('returns exactly the listed products, ignoring the count fallback', async () => {
    const service = new ProductService({
      source: source(products),
      cacheTtlMs: 60_000,
      featuredEntries: [{ id: 1 }, { id: 2 }],
    });
    expect((await service.featuredProducts(5)).map((p) => p.id)).toEqual([1, 2]);
  });

  it('skips ids that no longer exist upstream', async () => {
    const service = new ProductService({
      source: source(products),
      cacheTtlMs: 60_000,
      featuredEntries: [{ id: 999 }, { id: 2 }],
    });
    expect((await service.featuredProducts(5)).map((p) => p.id)).toEqual([2]);
  });

  it('applies an availability override from the list', async () => {
    const service = new ProductService({
      source: source(products),
      cacheTtlMs: 60_000,
      featuredEntries: [{ id: 1, available: false }, { id: 2 }],
    });
    const [first, second] = await service.featuredProducts(5);
    expect(first.available).toBe(false);
    expect(second.available).toBe(true);
  });

  it('falls back to top rated when no list is configured', async () => {
    const service = new ProductService({ source: source(products), cacheTtlMs: 60_000 });
    expect((await service.featuredProducts(2)).map((p) => p.id)).toEqual([1, 2]);
  });
});

describe('parseFeaturedEntries', () => {
  it('accepts a valid list', () => {
    expect(parseFeaturedEntries({ items: [{ id: 3 }, { id: 5, available: false }] })).toEqual([
      { id: 3, available: undefined },
      { id: 5, available: false },
    ]);
  });

  it('rejects a list without items', () => {
    expect(() => parseFeaturedEntries({})).toThrow('"items" array');
  });

  it('rejects a non-integer id', () => {
    expect(() => parseFeaturedEntries({ items: [{ id: 'x' }] })).toThrow('integer "id"');
  });

  it('rejects a non-boolean availability', () => {
    expect(() => parseFeaturedEntries({ items: [{ id: 1, available: 'no' }] })).toThrow('true or false');
  });
});
