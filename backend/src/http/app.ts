import express, { type NextFunction, type Request, type Response } from 'express';
import { UpstreamError } from '../data/fakeStoreClient.js';
import type { ProductService } from '../services/productService.js';
import { SEARCH_LIMITS, normalizeQuery } from '../domain/search.js';

export const ROUTES = {
  health: '/health',
  products: '/products',
  featured: '/products/featured',
  categories: '/products/categories',
  search: '/products/search',
} as const;

export const ERROR_CODES = {
  notFound: 'not_found',
  invalidQuery: 'invalid_query',
  upstreamUnavailable: 'upstream_unavailable',
  internal: 'internal_error',
} as const;

/** Reads a non-negative integer query parameter, clamped to `max`. Falls back when missing or invalid. */
function readIntParam(value: unknown, fallback: number, max = Number.MAX_SAFE_INTEGER): number {
  if (typeof value !== 'string' || !/^\d+$/.test(value)) return fallback;
  return Math.min(Number(value), max);
}

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

  app.get(ROUTES.categories, async (_req, res, next) => {
    try {
      res.json({ items: await productService.categories() });
    } catch (error) {
      next(error);
    }
  });

  app.get(`${ROUTES.categories}/:name`, async (req, res, next) => {
    try {
      const page = await productService.productsInCategory(req.params.name, featuredCount);
      if (!page) {
        res.status(404).json({ error: { code: ERROR_CODES.notFound, message: 'Category not found' } });
        return;
      }
      res.json(page);
    } catch (error) {
      next(error);
    }
  });

  app.get(ROUTES.search, async (req, res, next) => {
    const term = normalizeQuery(req.query.q);
    if (term === undefined) {
      res.status(400).json({
        error: {
          code: ERROR_CODES.invalidQuery,
          message: `Search needs ${SEARCH_LIMITS.minLength} to ${SEARCH_LIMITS.maxLength} characters`,
        },
      });
      return;
    }
    const category = typeof req.query.category === 'string' ? req.query.category.trim() : '';
    try {
      const page = await productService.search(term, {
        category: category === '' ? undefined : category,
        offset: readIntParam(req.query.offset, 0),
        limit: readIntParam(req.query.limit, SEARCH_LIMITS.defaultLimit, SEARCH_LIMITS.maxLimit) || SEARCH_LIMITS.defaultLimit,
      });
      res.json(page);
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
