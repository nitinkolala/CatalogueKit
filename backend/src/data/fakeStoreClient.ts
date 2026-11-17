import type { Product, ProductSource } from '../domain/product.js';

/** Shape returned by https://fakestoreapi.com/products (only the fields we use). */
interface FakeStoreProduct {
  id: number;
  title: string;
  price: number;
  description: string;
  category: string;
  image: string;
  rating: { rate: number; count: number };
}

export class UpstreamError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
    this.name = 'UpstreamError';
  }
}

export interface FakeStoreClientOptions {
  baseUrl: string;
  timeoutMs: number;
  fetchImpl?: typeof fetch;
}

export class FakeStoreClient implements ProductSource {
  private readonly baseUrl: string;
  private readonly timeoutMs: number;
  private readonly fetchImpl: typeof fetch;

  constructor(options: FakeStoreClientOptions) {
    this.baseUrl = options.baseUrl.replace(/\/+$/, '');
    this.timeoutMs = options.timeoutMs;
    this.fetchImpl = options.fetchImpl ?? fetch;
  }

  async fetchProducts(): Promise<Product[]> {
    const response = await this.fetchImpl(`${this.baseUrl}/products`, {
      signal: AbortSignal.timeout(this.timeoutMs),
      headers: { Accept: 'application/json' },
    }).catch((error: unknown) => {
      throw new UpstreamError(`Product source unreachable: ${String(error)}`);
    });

    if (!response.ok) {
      throw new UpstreamError(`Product source responded with ${response.status}`, response.status);
    }

    const body: unknown = await response.json().catch(() => {
      throw new UpstreamError('Product source returned invalid JSON');
    });
    if (!Array.isArray(body)) {
      throw new UpstreamError('Product source returned an unexpected payload');
    }
    return body.map(toProduct);
  }
}

export function toProduct(raw: FakeStoreProduct): Product {
  return {
    id: raw.id,
    title: raw.title,
    price: raw.price,
    description: raw.description,
    category: raw.category,
    imageUrl: raw.image,
    // Fake Store has no stock data, so every product is available unless the featured list says otherwise.
    available: true,
    rating: { rate: raw.rating.rate, count: raw.rating.count },
  };
}
