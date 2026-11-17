import { FakeStoreClient } from './data/fakeStoreClient.js';
import { createApp } from './http/app.js';
import { loadConfig } from './config/config.js';
import { loadFeaturedEntries } from './config/featuredList.js';
import { ProductService } from './services/productService.js';

const config = loadConfig();

const productService = new ProductService({
  source: new FakeStoreClient({
    baseUrl: config.fakeStoreBaseUrl,
    timeoutMs: config.upstreamTimeoutMs,
  }),
  cacheTtlMs: config.cacheTtlMs,
  featuredEntries: loadFeaturedEntries(config.featuredListPath),
});

const app = createApp({ productService, featuredCount: config.featuredCount });

app.listen(config.port, () => {
  console.log(`catalogue-backend listening on http://localhost:${config.port}`);
});
