# 🌐 Umless website

The public site for Umless: a landing page with the App Store link and QR code,
plus the pages App Store Connect links to. English and Simplified Chinese.

| Path | Page | Used in App Store Connect as |
| --- | --- | --- |
| `/` · `/zh` | Home | Marketing URL |
| `/support` · `/zh/support` | Support | Support URL |
| `/privacy` · `/zh/privacy` | Privacy Policy | Privacy Policy URL |
| `/terms` · `/zh/terms` | Terms of Use | Licence / Terms of Use link |

All pages are static — prerendered at build time, readable with JavaScript off.

## Develop

```sh
pnpm install
pnpm dev                                     # http://localhost:3000
pnpm typecheck && pnpm lint && pnpm build    # before every commit
```

## Deploy (Vercel, from GitHub)

1. **vercel.com/new** → import the `Umless` repository.
2. **Root Directory → Edit → `Web`**. Next.js and pnpm are detected from here.
3. **Deploy.** Every push to `main` redeploys.

The site finds its own address from Vercel. With a custom domain, set
`NEXT_PUBLIC_SITE_URL` (for example `https://umless.app`) so canonical links and
the sitemap use it.

## Where things live

| | |
| --- | --- |
| `src/content/en.ts`, `zh.ts` | Every word on the site, one file per language |
| `src/lib/site.ts` | App Store link, contact address, the policy date |
| `src/components/` | Page chrome, home page, document pages, QR code |
| `src/app/(en)`, `src/app/(zh)` | One root layout per language, so `<html lang>` is right |
