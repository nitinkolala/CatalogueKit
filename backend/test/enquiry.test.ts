import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { ERROR_CODES, ROUTES, createApp } from '../src/http/app.js';
import { EMAIL_PATTERN, validateEnquiry, normalizePhone } from '../src/domain/enquiry.js';
import type { Product, ProductSource } from '../src/domain/product.js';
import { EnquiryService, type EmailSender } from '../src/services/enquiryService.js';
import { ProductService } from '../src/services/productService.js';

const product: Product = {
  id: 7,
  title: 'Gaming Drive',
  price: 10,
  description: 'Fast drive',
  category: 'electronics',
  imageUrl: '',
  available: true,
  rating: { rate: 4, count: 3 },
};

const validBody = {
  productId: 7,
  name: '  Sam Lee  ',
  email: '  sam@example.com ',
  phone: '(04) 1234-5678',
  message: 'Is this in stock in Sydney?',
  marketingConsent: false,
};

function setup() {
  const sent: { to: string; subject: string; text: string }[] = [];
  const sender: EmailSender = {
    send: async (email) => {
      sent.push(email);
    },
  };
  const source: ProductSource = { fetchProducts: async () => [product] };
  const enquiries = new EnquiryService({
    sender,
    salesInbox: 'sales@shop.test',
    productLinkBase: 'https://shop.test/products/',
  });
  const app = createApp({
    productService: new ProductService({ source, cacheTtlMs: 60_000 }),
    featuredCount: 5,
    enquiries,
  });
  return { app, sent };
}

describe('validateEnquiry', () => {
  it('trims values and normalises the phone number', () => {
    const result = validateEnquiry(validBody);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.value.name).toBe('Sam Lee');
      expect(result.value.email).toBe('sam@example.com');
      expect(result.value.phone).toBe('0412345678');
    }
  });

  it('accepts a blank phone number', () => {
    const result = validateEnquiry({ ...validBody, phone: '' });
    expect(result.ok && result.value.phone).toBe(undefined);
  });

  it('rejects a phone number that is not exactly 10 digits', () => {
    expect(validateEnquiry({ ...validBody, phone: '04123' })).toMatchObject({ ok: false, errors: { phone: expect.any(String) } });
    expect(validateEnquiry({ ...validBody, phone: '04123456789' })).toMatchObject({ ok: false });
  });

  it('rejects an email without a proper domain', () => {
    expect(EMAIL_PATTERN.test('sam@example')).toBe(false);
    expect(EMAIL_PATTERN.test('sam example@x.com')).toBe(false);
    expect(validateEnquiry({ ...validBody, email: 'not-an-email' })).toMatchObject({ ok: false, errors: { email: expect.any(String) } });
  });

  it('requires name and message, and limits the message to 1000 characters', () => {
    expect(validateEnquiry({ ...validBody, name: '   ' })).toMatchObject({ ok: false, errors: { name: expect.any(String) } });
    expect(validateEnquiry({ ...validBody, message: '' })).toMatchObject({ ok: false, errors: { message: expect.any(String) } });
    expect(validateEnquiry({ ...validBody, message: 'a'.repeat(1001) })).toMatchObject({ ok: false });
    expect(validateEnquiry({ ...validBody, message: 'a'.repeat(1000) }).ok).toBe(true);
  });

  it('removes formatting characters from phone numbers', () => {
    expect(normalizePhone('+61 (4) 123-456 78')).toBe('+61412345678');
  });
});

describe('POST /enquiries', () => {
  it('sends the sales email with the product name and link, and returns 201', async () => {
    const { app, sent } = setup();
    const res = await request(app).post(ROUTES.enquiries).send(validBody);
    expect(res.status).toBe(201);
    expect(sent).toHaveLength(1);
    expect(sent[0].to).toBe('sales@shop.test');
    expect(sent[0].subject).toContain('Gaming Drive');
    expect(sent[0].text).toContain('https://shop.test/products/7');
    expect(sent[0].text).toContain('Name: Sam Lee');
  });

  it('returns 400 with a field error for each bad field and sends nothing', async () => {
    const { app, sent } = setup();
    const res = await request(app).post(ROUTES.enquiries).send({ ...validBody, email: 'bad', phone: '12' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ERROR_CODES.invalidEnquiry);
    expect(res.body.error.fields).toHaveProperty('email');
    expect(res.body.error.fields).toHaveProperty('phone');
    expect(sent).toHaveLength(0);
  });

  it('returns 404 when the product does not exist', async () => {
    const { app, sent } = setup();
    const res = await request(app).post(ROUTES.enquiries).send({ ...validBody, productId: 99 });
    expect(res.status).toBe(404);
    expect(sent).toHaveLength(0);
  });

  it('returns 413 when the body is larger than the 16 KB limit', async () => {
    const { app, sent } = setup();
    const res = await request(app)
      .post(ROUTES.enquiries)
      .send({ ...validBody, message: 'a'.repeat(20_000) });
    expect(res.status).toBe(413);
    expect(res.body.error.code).toBe(ERROR_CODES.payloadTooLarge);
    expect(sent).toHaveLength(0);
  });

  it('returns 400 for malformed JSON', async () => {
    const { app } = setup();
    const res = await request(app)
      .post(ROUTES.enquiries)
      .set('Content-Type', 'application/json')
      .send('{"name": ');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe(ERROR_CODES.invalidJson);
  });
});
