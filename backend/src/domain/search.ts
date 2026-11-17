import type { Product } from './product.js';

export const SEARCH_LIMITS = {
  minLength: 2,
  maxLength: 100,
  defaultLimit: 20,
  maxLimit: 50,
} as const;

/** One page of search results, plus enough to ask for the next page. */
export interface ProductPage {
  items: Product[];
  total: number;
  offset: number;
  limit: number;
  hasMore: boolean;
}

/**
 * Trims and lowercases a raw query. Returns `undefined` when it is not a string,
 * or when the trimmed length is outside the allowed range.
 */
export function normalizeQuery(raw: unknown): string | undefined {
  if (typeof raw !== 'string') return undefined;
  const term = raw.trim().toLowerCase();
  if (term.length < SEARCH_LIMITS.minLength || term.length > SEARCH_LIMITS.maxLength) return undefined;
  return term;
}

/** Products whose title or description contains the term. `term` must already be lowercase. */
export function matchProducts(products: readonly Product[], term: string): Product[] {
  return products.filter(
    (product) =>
      product.title.toLowerCase().includes(term) || product.description.toLowerCase().includes(term),
  );
}

/** Slices one page out of an ordered list and says whether more pages exist. */
export function paginate(items: readonly Product[], offset: number, limit: number): ProductPage {
  const page = items.slice(offset, offset + limit);
  return {
    items: page,
    total: items.length,
    offset,
    limit,
    hasMore: offset + page.length < items.length,
  };
}
