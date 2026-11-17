import { readFileSync } from 'node:fs';
import { parseFeaturedEntries, type FeaturedEntry } from '../domain/product.js';

/** Reads the admin-curated featured list. A missing file means "no curated list". */
export function loadFeaturedEntries(path: string): FeaturedEntry[] {
  let text: string;
  try {
    text = readFileSync(path, 'utf8');
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
    throw error;
  }
  return parseFeaturedEntries(JSON.parse(text));
}
