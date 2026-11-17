/** Product as exposed by this backend. Independent of the upstream (Fake Store) shape. */
export interface Product {
  id: number;
  title: string;
  price: number;
  description: string;
  category: string;
  imageUrl: string;
  /** False when the product is out of stock or unavailable. Customers can still view it. */
  available: boolean;
  rating: {
    rate: number;
    count: number;
  };
}

/** Source of product data. Implement this to swap the upstream provider. */
export interface ProductSource {
  fetchProducts(): Promise<Product[]>;
}

/**
 * Top-rated first: highest rating, then most ratings, then lowest id for a stable order.
 * Returns a new array; does not mutate the input.
 */
export function rankTopRated(products: readonly Product[], limit: number): Product[] {
  return [...products]
    .sort(
      (a, b) =>
        b.rating.rate - a.rating.rate ||
        b.rating.count - a.rating.count ||
        a.id - b.id,
    )
    .slice(0, limit);
}

/** One entry in the admin-curated featured list. `available` overrides the product's own flag when set. */
export interface FeaturedEntry {
  id: number;
  available?: boolean;
}

/** Validates the raw featured list file. Throws with a clear message when the shape is wrong. */
export function parseFeaturedEntries(raw: unknown): FeaturedEntry[] {
  if (typeof raw !== 'object' || raw === null || !Array.isArray((raw as { items?: unknown }).items)) {
    throw new Error('Featured list must be an object with an "items" array');
  }
  return (raw as { items: unknown[] }).items.map((entry, index) => {
    const item = entry as Partial<FeaturedEntry>;
    if (!Number.isInteger(item?.id)) {
      throw new Error(`Featured entry ${index} needs an integer "id"`);
    }
    if (item.available !== undefined && typeof item.available !== 'boolean') {
      throw new Error(`Featured entry ${index} "available" must be true or false`);
    }
    return { id: item.id as number, available: item.available };
  });
}
