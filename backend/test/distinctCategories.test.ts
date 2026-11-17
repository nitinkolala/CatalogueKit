import { describe, expect, it } from 'vitest';
import { distinctCategories, type Product } from '../src/domain/product.js';

const product = (id: number, category: string): Product => ({
  id,
  title: `P${id}`,
  price: 1,
  description: '',
  category,
  imageUrl: '',
  available: true,
  rating: { rate: 1, count: 1 },
});

describe('distinctCategories', () => {
  it('returns unique categories sorted A to Z', () => {
    const products = [product(1, 'men\'s clothing'), product(2, 'electronics'), product(3, 'electronics')];
    expect(distinctCategories(products)).toEqual(['electronics', 'men\'s clothing']);
  });

  it('skips blank categories and trims whitespace', () => {
    expect(distinctCategories([product(1, ' bags '), product(2, '   ')])).toEqual(['bags']);
  });

  it('returns an empty list for no products', () => {
    expect(distinctCategories([])).toEqual([]);
  });
});
