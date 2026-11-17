import type { EnquiryInput } from '../domain/enquiry.js';
import type { Product } from '../domain/product.js';

/** Sends one email. The implementation decides the provider (log only, SMTP, SES, ...). */
export interface EmailSender {
  send(email: { to: string; subject: string; text: string }): Promise<void>;
}

export interface EnquiryServiceOptions {
  sender: EmailSender;
  salesInbox: string;
  productLinkBase: string;
}

/** Builds and sends the sales email for a validated enquiry. */
export class EnquiryService {
  constructor(private readonly options: EnquiryServiceOptions) {}

  productLink(productId: number): string {
    return `${this.options.productLinkBase.replace(/\/+$/, '')}/${productId}`;
  }

  async submit(enquiry: EnquiryInput, product: Product): Promise<void> {
    const lines = [
      `Product: ${product.title}`,
      `Link: ${this.productLink(product.id)}`,
      `Product ID: ${product.id}`,
      '',
      `Name: ${enquiry.name}`,
      `Email: ${enquiry.email}`,
      `Phone: ${enquiry.phone ?? 'not given'}`,
      `Marketing consent: ${enquiry.marketingConsent ? 'yes' : 'no'}`,
      '',
      enquiry.message,
    ];
    await this.options.sender.send({
      to: this.options.salesInbox,
      subject: `Enquiry about ${product.title}`,
      text: lines.join('\n'),
    });
  }
}
