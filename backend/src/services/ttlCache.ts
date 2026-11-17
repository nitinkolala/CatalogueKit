/** Minimal in-memory cache with a fixed time-to-live. */
export class TtlCache<T> {
  private entry: { value: T; expiresAt: number } | undefined;

  constructor(
    private readonly ttlMs: number,
    private readonly now: () => number = Date.now,
  ) {}

  get(): T | undefined {
    if (!this.entry) return undefined;
    if (this.now() >= this.entry.expiresAt) {
      this.entry = undefined;
      return undefined;
    }
    return this.entry.value;
  }

  set(value: T): void {
    this.entry = { value, expiresAt: this.now() + this.ttlMs };
  }
}
