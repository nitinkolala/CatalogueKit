import type { CategoryPage, FeaturedEntry, Product, ProductSource } from '../domain/product.js';
import { distinctCategories, rankTopRated } from '../domain/product.js';
import { matchProducts, paginate, type ProductPage } from '../domain/search.js';
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

  /** Every category in the catalogue, sorted. Derived from the cached product list. */
  async categories(): Promise<string[]> {
    return distinctCategories(await this.listProducts());
  }

  /**
   * Products in one category: the top `topCount` by rating, then every other product in that category.
   * Returns `undefined` when no product has that category.
   */
  async productsInCategory(category: string, topCount: number): Promise<CategoryPage | undefined> {
    const inCategory = (await this.listProducts()).filter((product) => product.category.trim() === category);
    if (inCategory.length === 0) return undefined;
    const ranked = rankTopRated(inCategory, inCategory.length);
    return { topRated: ranked.slice(0, topCount), more: ranked.slice(topCount) };
  }

  /**
   * Products whose title or description contains `term` (already normalised), best rated first.
   * Optionally limited to one category. Returns one page of results.
   */
  async search(
    term: string,
    options: { category?: string; offset: number; limit: number },
  ): Promise<ProductPage> {
    let products = await this.listProducts();
    if (options.category !== undefined) {
      products = products.filter((product) => product.category.trim() === options.category);
    }
    const ranked = rankTopRated(matchProducts(products, term), products.length);
    return paginate(ranked, options.offset, options.limit);
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
