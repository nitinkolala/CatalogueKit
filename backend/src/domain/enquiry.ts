/** Limits and patterns for enquiries. Keep these in one place so the app and backend agree. */
export const ENQUIRY_LIMITS = {
  nameMaxLength: 100,
  messageMaxLength: 1000,
  phoneDigits: 10,
} as const;

/** Strict pattern: one local part, one @, and a dotted domain with a 2+ letter top level. */
export const EMAIL_PATTERN = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$/;

export interface EnquiryInput {
  productId: number;
  name: string;
  email: string;
  phone?: string;
  message: string;
  marketingConsent: boolean;
}

export type EnquiryFieldErrors = Partial<Record<'name' | 'email' | 'phone' | 'message' | 'productId', string>>;

export type EnquiryValidation =
  | { ok: true; value: EnquiryInput }
  | { ok: false; errors: EnquiryFieldErrors };

const text = (raw: unknown): string => (typeof raw === 'string' ? raw.trim() : '');

/** Removes the formatting characters a customer might type in a phone number. */
export function normalizePhone(raw: string): string {
  return raw.replace(/[\s\-().]/g, '');
}

/** Checks a raw request body. Returns the cleaned values, or an error for each bad field. */
export function validateEnquiry(raw: unknown): EnquiryValidation {
  const body = (raw ?? {}) as Record<string, unknown>;
  const errors: EnquiryFieldErrors = {};

  const productId = typeof body.productId === 'number' && Number.isInteger(body.productId) ? body.productId : undefined;
  if (productId === undefined) errors.productId = 'Product is missing';

  const name = text(body.name);
  if (name === '' || name.length > ENQUIRY_LIMITS.nameMaxLength) {
    errors.name = `Enter your name (up to ${ENQUIRY_LIMITS.nameMaxLength} characters)`;
  }

  const email = text(body.email);
  if (!EMAIL_PATTERN.test(email)) errors.email = 'Enter a valid email address';

  const phoneRaw = text(body.phone);
  const phone = normalizePhone(phoneRaw);
  if (phoneRaw !== '' && !new RegExp(`^\\d{${ENQUIRY_LIMITS.phoneDigits}}$`).test(phone)) {
    errors.phone = `Enter a ${ENQUIRY_LIMITS.phoneDigits}-digit phone number, or leave it blank`;
  }

  const message = text(body.message);
  if (message === '' || message.length > ENQUIRY_LIMITS.messageMaxLength) {
    errors.message = `Enter a message (up to ${ENQUIRY_LIMITS.messageMaxLength} characters)`;
  }

  if (Object.keys(errors).length > 0 || productId === undefined) {
    return { ok: false, errors };
  }
  return {
    ok: true,
    value: {
      productId,
      name,
      email,
      phone: phone === '' ? undefined : phone,
      message,
      marketingConsent: body.marketingConsent === true,
    },
  };
}
