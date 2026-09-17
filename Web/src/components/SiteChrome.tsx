import Image from 'next/image'
import Link from 'next/link'
import type { ReactNode } from 'react'

import { dict } from '@/content'
import { CONTACT_EMAIL, type Locale, MODEL_VENDOR, type PageKey, pathFor } from '@/lib/site'

/**
 * Header and footer around every page.
 *
 * Rendered by each page rather than by the layout, because the language link
 * has to point at *this* page in the other language, and a layout does not
 * know which page it is wrapping.
 */
export function SiteChrome({ locale, page, children }: { locale: Locale; page: PageKey; children: ReactNode }) {
  const t = dict(locale)
  const other: Locale = locale === 'en' ? 'zh' : 'en'
  const nav: { key: PageKey; label: string }[] = [
    { key: 'support', label: t.nav.support },
    { key: 'privacy', label: t.nav.privacy },
    { key: 'terms', label: t.nav.terms },
  ]

  return (
    <div className="flex min-h-dvh flex-col">
      <header className="sticky top-0 z-20 border-b border-line bg-bg/80 backdrop-blur-xl">
        <div className="mx-auto flex h-14 max-w-5xl items-center justify-between gap-4 px-5">
          <Link href={pathFor(locale, 'home')} className="flex items-center gap-2.5" aria-label={t.nav.home}>
            <Image src="/app-icon.png" alt="" width={28} height={28} className="rounded-[7px]" priority />
            <span className="text-[16px] font-semibold tracking-tight">Umless</span>
          </Link>
          <nav className="flex items-center gap-4 text-[14px] text-muted sm:gap-6">
            {nav.map(item => (
              <Link
                key={item.key}
                href={pathFor(locale, item.key)}
                aria-current={item.key === page ? 'page' : undefined}
                className={`transition-colors hover:text-text ${item.key === page ? 'text-text' : ''}`}
              >
                {item.label}
              </Link>
            ))}
            <Link
              href={pathFor(other, page)}
              hrefLang={other === 'zh' ? 'zh-Hans' : 'en'}
              aria-label={t.nav.otherLanguageAria}
              className="rounded-full border border-line px-2.5 py-1 text-[13px] transition-colors hover:text-text"
            >
              {t.nav.otherLanguage}
            </Link>
          </nav>
        </div>
      </header>

      <main className="flex-1">{children}</main>

      <footer className="border-t border-line">
        <div className="mx-auto flex max-w-5xl flex-col gap-4 px-5 py-8 text-[13px] text-muted sm:flex-row sm:items-center sm:justify-between">
          <div className="flex flex-col gap-1">
            <p>{t.footer.onDevice}</p>
            <p>
              <a href={MODEL_VENDOR.url} className="hover:text-text" target="_blank" rel="noopener noreferrer">
                {t.footer.modelCredit}
              </a>
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-x-5 gap-y-2">
            {nav.map(item => (
              <Link key={item.key} href={pathFor(locale, item.key)} className="hover:text-text">
                {item.label}
              </Link>
            ))}
            <a href={`mailto:${CONTACT_EMAIL}`} className="hover:text-text">
              {CONTACT_EMAIL}
            </a>
            <span>© {new Date().getFullYear()} Umless</span>
          </div>
        </div>
      </footer>
    </div>
  )
}
