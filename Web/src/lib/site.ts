/**
 * Facts about Umless that more than one page states.
 *
 * Kept in one place because each of them is also stated somewhere Apple
 * checks — the App Store listing, App Store Connect's URL fields, the app's own
 * Settings — and a copy that drifts from those is worse than no copy at all.
 */

/** The App Store listing. One app record covers iPhone, iPad and Mac. */
export const APP_STORE_ID = '6810557305'
export const APP_STORE_URL = `https://apps.apple.com/app/umless-cut-filler-words/id${APP_STORE_ID}`

/** Where support and privacy mail goes — the address the app already lists. */
export const CONTACT_EMAIL = 'lisen8018+umless@gmail.com'

/** The model's maker, credited as its licence requires. */
export const MODEL_VENDOR = { name: 'Desert Ant Labs', url: 'https://desertant.com' }

/** Apple's standard licence, which the Terms of Use build on. */
export const APPLE_EULA_URL = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'

/**
 * The day the *text* of the privacy policy and terms last changed. Hardcoded:
 * a policy's date is when its wording changed, not when someone loaded it.
 */
export const LAST_UPDATED = new Date('2026-09-18T00:00:00Z')

/**
 * The public origin, for canonical URLs, the sitemap and Open Graph. Vercel
 * provides its production hostname at build time; a custom domain can be set
 * explicitly with NEXT_PUBLIC_SITE_URL.
 */
export const SITE_URL =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : 'http://localhost:3000')

export type Locale = 'en' | 'zh'

export const LOCALES: Locale[] = ['en', 'zh']

/** `<html lang>` and Open Graph locale for each language. */
export const LANG_TAG: Record<Locale, string> = { en: 'en', zh: 'zh-Hans' }
export const OG_LOCALE: Record<Locale, string> = { en: 'en_US', zh: 'zh_CN' }

export type PageKey = 'home' | 'support' | 'privacy' | 'terms'

/**
 * English lives at the root and Chinese under `/zh`. The English paths are the
 * ones entered in App Store Connect, so they must never move.
 */
export function pathFor(locale: Locale, page: PageKey): string {
  const leaf = page === 'home' ? '' : `/${page}`
  if (locale === 'en') return leaf || '/'
  return `/zh${leaf}`
}

/** hreflang alternates for one page, for metadata. */
export function languageAlternates(page: PageKey) {
  return {
    en: pathFor('en', page),
    'zh-Hans': pathFor('zh', page),
    'x-default': pathFor('en', page),
  }
}

export function formatDate(date: Date, locale: Locale): string {
  return new Intl.DateTimeFormat(locale === 'zh' ? 'zh-CN' : 'en-GB', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    timeZone: 'UTC',
  }).format(date)
}
