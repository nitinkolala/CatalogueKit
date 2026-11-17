export interface AppConfig {
  port: number;
  fakeStoreBaseUrl: string;
  featuredCount: number;
  cacheTtlMs: number;
  upstreamTimeoutMs: number;
  featuredListPath: string;
}

export const DEFAULTS = {
  PORT: 3000,
  FAKESTORE_BASE_URL: 'https://fakestoreapi.com',
  FEATURED_COUNT: 5,
  CACHE_TTL_SECONDS: 300,
  UPSTREAM_TIMEOUT_MS: 5000,
  FEATURED_LIST_PATH: 'data/featured.json',
} as const;

const MS_PER_SECOND = 1000;

function readInt(env: NodeJS.ProcessEnv, key: string, fallback: number): number {
  const raw = env[key];
  if (raw === undefined || raw.trim() === '') return fallback;
  const parsed = Number(raw);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`Environment variable ${key} must be a non-negative integer, got "${raw}"`);
  }
  return parsed;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const fakeStoreBaseUrl = env.FAKESTORE_BASE_URL?.trim() || DEFAULTS.FAKESTORE_BASE_URL;
  return {
    port: readInt(env, 'PORT', DEFAULTS.PORT),
    fakeStoreBaseUrl,
    featuredCount: readInt(env, 'FEATURED_COUNT', DEFAULTS.FEATURED_COUNT),
    cacheTtlMs: readInt(env, 'CACHE_TTL_SECONDS', DEFAULTS.CACHE_TTL_SECONDS) * MS_PER_SECOND,
    upstreamTimeoutMs: readInt(env, 'UPSTREAM_TIMEOUT_MS', DEFAULTS.UPSTREAM_TIMEOUT_MS),
    featuredListPath: env.FEATURED_LIST_PATH?.trim() || DEFAULTS.FEATURED_LIST_PATH,
  };
}
