import { describe, expect, it } from 'vitest';
import { matchProducts, normalizeQuery, paginate, SEARCH_LIMITS } from '../src/domain/search.js';
import type { Product } from '../src/domain/product.js';

const product = (id: number, title: string, description = ''): Product => ({
  id,
  title,
  price: 1,
  description,
  category: 'c',
  imageUrl: '',
  available: true,
  rating: { rate: 1, count: 1 },
});

describe('normalizeQuery', () => {
  it('trims and lowercases', () => {
    expect(normalizeQuery('  Gaming DRIVE  ')).toBe('gaming drive');
  });

  it('rejects queries shorter than the minimum after trimming', () => {
    expect(normalizeQuery('a')).toBeUndefined();
    expect(normalizeQuery('  a  ')).toBeUndefined();
  });

  it('accepts the minimum length exactly and rejects one character over the maximum', () => {
    expect(normalizeQuery('ab')).toBe('ab');
    expect(normalizeQuery('a'.repeat(SEARCH_LIMITS.maxLength))).toBe('a'.repeat(SEARCH_LIMITS.maxLength));
    expect(normalizeQuery('a'.repeat(SEARCH_LIMITS.maxLength + 1))).toBeUndefined();
  });

  it('rejects non-string input', () => {
    expect(normalizeQuery(['ab'])).toBeUndefined();
    expect(normalizeQuery(undefined)).toBeUndefined();
  });
});

describe('matchProducts', () => {
  const products = [product(1, 'WD Gaming Drive'), product(2, 'Desk lamp', 'Warm gaming light'), product(3, 'Kettle')];

  it('matches title or description, ignoring case', () => {
    expect(matchProducts(products, 'gaming').map((p) => p.id)).toEqual([1, 2]);
  });

  it('returns nothing when no text matches', () => {
    expect(matchProducts(products, 'toaster')).toEqual([]);
  });
});

describe('paginate', () => {
  const items = [1, 2, 3, 4, 5].map((id) => product(id, `P${id}`));

  it('returns one page and reports more pages', () => {
    const page = paginate(items, 0, 2);
    expect(page.items.map((p) => p.id)).toEqual([1, 2]);
    expect(page.total).toBe(5);
    expect(page.hasMore).toBe(true);
  });

  it('reports no more pages on the last page', () => {
    const page = paginate(items, 4, 2);
    expect(page.items.map((p) => p.id)).toEqual([5]);
    expect(page.hasMore).toBe(false);
  });

  it('returns an empty page past the end', () => {
    const page = paginate(items, 10, 2);
    expect(page.items).toEqual([]);
    expect(page.hasMore).toBe(false);
  });
});
