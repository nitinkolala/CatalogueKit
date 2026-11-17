import { FakeStoreClient } from './data/fakeStoreClient.js';
import { createApp } from './http/app.js';
import { loadConfig } from './config/config.js';
import { loadFeaturedEntries } from './config/featuredList.js';
import { ProductService } from './services/productService.js';
import { EnquiryService } from './services/enquiryService.js';
import { LogEmailSender } from './infra/logEmailSender.js';

const config = loadConfig();

const productService = new ProductService({
  source: new FakeStoreClient({
    baseUrl: config.fakeStoreBaseUrl,
    timeoutMs: config.upstreamTimeoutMs,
  }),
  cacheTtlMs: config.cacheTtlMs,
  featuredEntries: loadFeaturedEntries(config.featuredListPath),
});

const enquiries = new EnquiryService({
  sender: new LogEmailSender(),
  salesInbox: config.salesInbox,
  productLinkBase: config.productLinkBase,
});

const app = createApp({ productService, featuredCount: config.featuredCount, enquiries });

app.listen(config.port, () => {
  console.log(`catalogue-backend listening on http://localhost:${config.port}`);
});
