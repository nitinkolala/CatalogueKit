import type { FeaturedEntry, Product, ProductSource } from '../domain/product.js';
import { rankTopRated } from '../domain/product.js';
import { TtlCache } from './ttlCache.js';

export interface ProductServiceOptions {
  source: ProductSource;
  cacheTtlMs: number;
  now?: () => number;
  /** Admin-curated featured list. When empty, featured products fall back to top rated. */
  featuredEntries?: FeaturedEntry[];
}

/** Application service: the only place the HTTP layer gets product data from. */
export class ProductService {
  private readonly source: ProductSource;
  private readonly cache: TtlCache<Product[]>;
  private readonly featuredEntries: FeaturedEntry[];

  constructor(options: ProductServiceOptions) {
    this.source = options.source;
    this.featuredEntries = options.featuredEntries ?? [];
    this.cache = new TtlCache<Product[]>(options.cacheTtlMs, options.now);
  }

  async listProducts(): Promise<Product[]> {
    const cached = this.cache.get();
    if (cached) return cached;
    const products = await this.source.fetchProducts();
    this.cache.set(products);
    return products;
  }

  /**
   * Admin-curated list in the admin's order, with availability overrides applied.
   * Falls back to the top `count` products by rating when no list is configured.
   */
  async featuredProducts(count: number): Promise<Product[]> {
    const products = await this.listProducts();
    if (this.featuredEntries.length === 0) {
      return rankTopRated(products, count);
    }
    const byId = new Map(products.map((product) => [product.id, product]));
    return this.featuredEntries.flatMap((entry) => {
      const product = byId.get(entry.id);
      if (!product) return [];
      return [{ ...product, available: entry.available ?? product.available }];
    });
  }
}
