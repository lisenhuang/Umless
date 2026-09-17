import type { MetadataRoute } from 'next'

import { LANG_TAG, LAST_UPDATED, LOCALES, type PageKey, pathFor, SITE_URL } from '@/lib/site'

const PAGES: PageKey[] = ['home', 'support', 'privacy', 'terms']

export default function sitemap(): MetadataRoute.Sitemap {
  return PAGES.flatMap(page =>
    LOCALES.map(locale => ({
      url: `${SITE_URL}${pathFor(locale, page)}`,
      lastModified: LAST_UPDATED,
      changeFrequency: 'monthly' as const,
      priority: page === 'home' ? 1 : 0.6,
      alternates: {
        languages: Object.fromEntries(LOCALES.map(l => [LANG_TAG[l], `${SITE_URL}${pathFor(l, page)}`])),
      },
    })),
  )
}
