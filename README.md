# CatalogueKit

A product catalogue proof of concept. Customers browse featured products and categories, search the catalogue, open product pages, and send an enquiry about a product.

- **Client:** iOS app in Swift and SwiftUI.
- **Backend:** Node.js and TypeScript (Express 5). It is the only component that calls the product data source (Fake Store API).

Related documents: [DECISIONS.md](DECISIONS.md) (assumptions and trade-offs), [AI_USAGE.md](AI_USAGE.md) (how AI tools were used), [CLAUDE.md](CLAUDE.md) (engineering rules).

## Requirements

| Tool | Version |
| --- | --- |
| macOS with Xcode | Xcode with the iOS 26 SDK (the project targets iOS 26.5) |
| Node.js | 20 or later (tested on 22) |
| Simulator | Any iPhone simulator. Tested on iPhone 17 Pro |

No paid services or accounts are needed.

## 1. Run the backend

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

The backend listens on `http://localhost:3000`. Check it:

```bash
curl http://localhost:3000/health
# {"status":"ok"}
```

The `.env` file is optional. Every value has a default, so the app runs without it.

## 2. Run the iOS app

1. Keep the backend running.
2. Open `ios/CatalogueKit/CatalogueKit.xcodeproj` in Xcode.
3. Choose the **CatalogueKit** scheme and an iPhone simulator, then press **Run** (⌘R).

Debug builds call `http://localhost:3000` automatically. Nothing else needs to be configured.

## Configuration

### Backend (`backend/.env`)

| Variable | Default | What it does |
| --- | --- | --- |
| `PORT` | `3000` | Port the backend listens on |
| `FAKESTORE_BASE_URL` | `https://fakestoreapi.com` | Product data source |
| `FEATURED_COUNT` | `5` | Maximum number of featured products |
| `CACHE_TTL_SECONDS` | `300` | How long the backend caches the product list |
| `UPSTREAM_TIMEOUT_MS` | `5000` | Timeout for the product data source |
| `FEATURED_LIST_PATH` | `data/featured.json` | The admin's featured list, in order |
| `SALES_INBOX` | `sales@example.com` | Recipient of enquiry emails |
| `PRODUCT_LINK_BASE` | `http://localhost:3000/products` | Base of the product link in enquiry emails |

**Enquiry emails are written to the backend console**, not sent. Look for `[email]` lines in the terminal running `npm run dev`. No mail account is needed.

**Featured products** come from `backend/data/featured.json`. Edit the list of product IDs to change which products appear on Home. The order in the file is the order shown.

### iOS app

The app picks its backend from the build configuration:

- **Debug:** `http://localhost:3000` (the `develop` environment).
- **Release:** a placeholder production host.

To point a run at a different backend, add an environment variable in the scheme (Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables):

| Name | Value |
| --- | --- |
| `API_BASE_URL` | for example `http://localhost:3100` |

## Run the tests

Backend (typecheck and 61 tests):

```bash
cd backend
npm run typecheck
npm test
```

iOS unit tests (106 tests, on the simulator):

```bash
cd ios/CatalogueKit
xcodebuild test -project CatalogueKit.xcodeproj -scheme CatalogueKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CatalogueKitTests
```

## What to try

1. **Home:** the featured row, the categories grid, and pull to refresh.
2. **Search:** type two or more characters. Results update as you type. Return saves the search to recent searches.
3. **Category:** tap a category to see its top rated products, then the rest.
4. **Product:** tap any product. The gallery, description and specifications load.
5. **Enquiry:** tap **Enquire**. Fill in name and email, add a message, then submit. You see a thank-you screen, and the email appears in the backend console.
6. **Failures:** stop the backend (⌃C) and pull to refresh on Home. You see saved products with a notice. Restart the backend and tap **Try again**.

## Project layout

```
backend/
  src/domain/      product, search and enquiry rules
  src/services/    ProductService (cache, ranking, search), EnquiryService
  src/data/        FakeStoreClient, the only code that knows the Fake Store API
  src/http/        Express routes and error handling
  src/infra/       LogEmailSender (the email adapter)
  data/            featured.json (the admin's featured list)
  test/            Vitest and supertest tests
ios/CatalogueKit/CatalogueKit/
  Domain/          entities, use cases, repository protocols, validators
  Data/            HTTP client, DTOs, repositories, image and disk caches
  Presentation/    SwiftUI views and view models
  App/             AppContainer, the composition root
  Core/            constants, localized strings, environment
```

## API

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | Liveness check |
| GET | `/products/featured` | Featured products, in the admin's order |
| GET | `/products/categories` | All categories, in backend order |
| GET | `/products/categories/:name` | Top rated products in a category, then the rest |
| GET | `/products/search?q=&category=&offset=&limit=` | Search. Two to 100 characters. Pages of 20 |
| GET | `/products/:id` | One product, or 404 |
| POST | `/enquiries` | Submit an enquiry. 201 on success, 400 with field errors, 404 for an unknown product, 413 over 16 KB |

## Troubleshooting

- **Home shows "We couldn't load products":** the backend is not running, or not on port 3000. Start it with `npm run dev`.
- **Simulator says the app cannot connect:** check that `curl http://localhost:3000/health` returns `{"status":"ok"}`.
- **No scheme listed in Xcode:** open the project file, then choose the CatalogueKit scheme from the scheme menu.

## Known limits

- Enquiry emails are only logged. A real email provider is a new adapter behind `EmailSender`.
- The privacy policy link is a placeholder.
- Verified on the iPhone 17 Pro simulator in portrait, dark mode and large text. Landscape and VoiceOver still need a check on a device.
- The product page shows no discount, no "Low stock" status and no share button, because the product data has no such fields. See DECISIONS.md, section 4.
