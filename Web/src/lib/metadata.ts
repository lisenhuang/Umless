import type { Metadata, Viewport } from 'next'

import { dict } from '@/content'

import {
  APP_STORE_ID,
  languageAlternates,
  type Locale,
  OG_LOCALE,
  type PageKey,
  pathFor,
  SITE_URL,
} from './site'

/** Shared by both root layouts. */
export const rootMetadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  applicationName: 'Umless',
  appleWebApp: { title: 'Umless' },
  // Safari on iPhone shows its own "Open in App Store" banner for this.
  itunes: { appId: APP_STORE_ID },
}

export const rootViewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#fbfbfd' },
    { media: '(prefers-color-scheme: dark)', color: '#0b0b0d' },
  ],
}

export function pageMetadata(locale: Locale, page: PageKey): Metadata {
  const t = dict(locale)
  const title = page === 'home' ? t.home.metaTitle : `${t[page].title} · Umless`
  const description = page === 'home' ? t.home.metaDescription : t[page].description
  const path = pathFor(locale, page)
  return {
    title: { absolute: title },
    description,
    alternates: { canonical: path, languages: languageAlternates(page) },
    openGraph: {
      title,
      description,
      url: path,
      siteName: 'Umless',
      locale: OG_LOCALE[locale],
      type: 'website',
      images: [{ url: '/app-icon.png', width: 384, height: 384, alt: 'Umless' }],
    },
    twitter: { card: 'summary', title, description, images: ['/app-icon.png'] },
  }
}
