import type { EmailSender } from '../services/enquiryService.js';

/**
 * Development sender: prints each email to the console instead of delivering it.
 * No email account is needed to run the app. Swap in a real provider for production.
 */
export class LogEmailSender implements EmailSender {
  async send(email: { to: string; subject: string; text: string }): Promise<void> {
    console.log(`[email] to=${email.to} subject="${email.subject}"\n${email.text}`);
  }
}
