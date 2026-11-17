import { describe, expect, it } from 'vitest';
import { rankTopRated, type Product } from '../src/domain/product.js';

const product = (id: number, rate: number, count: number): Product => ({
  id,
  title: `P${id}`,
  price: 1,
  description: '',
  category: 'c',
  imageUrl: '',
  rating: { rate, count },
});

describe('rankTopRated', () => {
  it('orders by rating, then rating count, then id', () => {
    const ranked = rankTopRated(
      [product(1, 4.1, 10), product(2, 4.9, 3), product(3, 4.9, 50), product(4, 4.9, 50)],
      4,
    );
    expect(ranked.map((p) => p.id)).toEqual([3, 4, 2, 1]);
  });

  it('returns at most the requested count', () => {
    const ranked = rankTopRated([1, 2, 3, 4, 5, 6].map((id) => product(id, id, 1)), 5);
    expect(ranked).toHaveLength(5);
    expect(ranked[0].id).toBe(6);
  });

  it('does not mutate the input array', () => {
    const input = [product(1, 1, 1), product(2, 5, 1)];
    rankTopRated(input, 2);
    expect(input.map((p) => p.id)).toEqual([1, 2]);
  });
});
