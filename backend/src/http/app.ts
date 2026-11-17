import express, { type NextFunction, type Request, type Response } from 'express';
import { UpstreamError } from '../data/fakeStoreClient.js';
import type { ProductService } from '../services/productService.js';

export const ROUTES = {
  health: '/health',
  products: '/products',
  featured: '/products/featured',
} as const;

export const ERROR_CODES = {
  notFound: 'not_found',
  upstreamUnavailable: 'upstream_unavailable',
  internal: 'internal_error',
} as const;

export interface AppDeps {
  productService: ProductService;
  featuredCount: number;
}

export function createApp({ productService, featuredCount }: AppDeps) {
  const app = express();
  app.disable('x-powered-by');

  app.get(ROUTES.health, (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.get(ROUTES.featured, async (_req, res, next) => {
    try {
      res.json({ items: await productService.featuredProducts(featuredCount) });
    } catch (error) {
      next(error);
    }
  });

  app.get(ROUTES.products, async (_req, res, next) => {
    try {
      res.json({ items: await productService.listProducts() });
    } catch (error) {
      next(error);
    }
  });

  app.use((_req, res) => {
    res.status(404).json({ error: { code: ERROR_CODES.notFound, message: 'Route not found' } });
  });

  app.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (error instanceof UpstreamError) {
      res.status(502).json({
        error: { code: ERROR_CODES.upstreamUnavailable, message: 'Product data is temporarily unavailable' },
      });
      return;
    }
    console.error(error);
    res.status(500).json({ error: { code: ERROR_CODES.internal, message: 'Something went wrong' } });
  });

  return app;
}
