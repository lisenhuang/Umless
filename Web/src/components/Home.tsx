import Image from 'next/image'

import { dict } from '@/content'
import { APP_STORE_URL, type Locale } from '@/lib/site'

import { AppStoreButton } from './AppStoreButton'
import { QrCode } from './QrCode'
import { SiteChrome } from './SiteChrome'
import { TimelineArt } from './TimelineArt'

const FEATURE_ICONS = [
  // Private by design
  'M12 3 5 6v5c0 4.4 3 8.3 7 9.5 4-1.2 7-5.1 7-9.5V6l-7-3Zm-2.5 9 1.8 1.8L15 10',
  // Nothing lost
  'M4 7h16v10H4zM8 7V5m8 2V5M8 19v-2m8 2v-2',
  // Every cut is your call
  'M6 6a2 2 0 1 0 0 .01M6 18a2 2 0 1 0 0 .01M7.5 7.5 20 17M7.5 16.5 20 7',
  // Preview
  'M3 12s3.5-6 9-6 9 6 9 6-3.5 6-9 6-9-6-9-6Zm9 2.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z',
  // Devices
  'M3 6h13v9H3zM1 18h17M18 9h4v11h-4z',
  // Listens
  'M4 10v4m4-7v10m4-13v16m4-11v6m4-3v0',
]

export async function Home({ locale }: { locale: Locale }) {
  const t = dict(locale).home

  return (
    <SiteChrome locale={locale} page="home">
      {/* Hero */}
      <section className="mx-auto grid max-w-5xl items-center gap-12 px-5 pb-16 pt-14 sm:pt-20 md:grid-cols-[1.35fr_1fr]">
        <div>
          <div className="mb-6 flex items-center gap-3">
            <Image
              src="/app-icon.png"
              alt="Umless"
              width={72}
              height={72}
              className="rounded-[18px] shadow-md"
              priority
            />
            <p className="text-[14px] font-medium text-muted">{t.platforms}</p>
          </div>
          <h1 className="text-[44px] font-bold leading-[1.05] tracking-tight sm:text-[60px]">{t.title}</h1>
          <p className="mt-5 max-w-xl text-[18px] leading-relaxed text-muted sm:text-[20px]">{t.body}</p>
          <div className="mt-8 flex flex-wrap items-center gap-4">
            <AppStoreButton label={t.download} />
          </div>
          <p className="mt-5 flex items-center gap-2 text-[14px] text-muted">
            <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0" aria-hidden fill="none" stroke="currentColor" strokeWidth={1.8}>
              <rect x="5" y="10" width="14" height="10" rx="2.5" />
              <path d="M8 10V7.5a4 4 0 0 1 8 0V10" />
            </svg>
            {t.privacyNote}
          </p>
        </div>

        {/* A phone cannot scan its own screen, so the code is for larger screens only. */}
        <aside className="hidden justify-self-end md:block">
          <a
            href={APP_STORE_URL}
            className="block w-64 rounded-3xl border border-line bg-surface p-6 text-center shadow-sm transition-shadow hover:shadow-md"
          >
            <div className="rounded-2xl bg-white p-4">
              <QrCode value={APP_STORE_URL} label={t.qrTitle} />
            </div>
            <p className="mt-4 text-[16px] font-semibold">{t.qrTitle}</p>
            <p className="mt-1 text-[13px] leading-snug text-muted">{t.qrBody}</p>
          </a>
        </aside>
      </section>

      <section className="mx-auto max-w-5xl px-5">
        <TimelineArt caption={t.artCaption} />
      </section>

      {/* Steps */}
      <section className="mx-auto max-w-5xl px-5 pt-20">
        <h2 className="text-[30px] font-bold tracking-tight sm:text-[36px]">{t.stepsTitle}</h2>
        <ol className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {t.steps.map((step, i) => (
            <li key={step.title} className="rounded-2xl border border-line bg-surface p-5">
              <span className="grid h-8 w-8 place-items-center rounded-full bg-accent text-[15px] font-semibold text-white">
                {i + 1}
              </span>
              <h3 className="mt-4 text-[17px] font-semibold">{step.title}</h3>
              <p className="mt-1.5 text-[15px] leading-relaxed text-muted">{step.text}</p>
            </li>
          ))}
        </ol>
      </section>

      {/* Features */}
      <section className="mx-auto max-w-5xl px-5 pt-20">
        <h2 className="text-[30px] font-bold tracking-tight sm:text-[36px]">{t.featuresTitle}</h2>
        <div className="mt-8 grid gap-x-10 gap-y-8 sm:grid-cols-2 lg:grid-cols-3">
          {t.features.map((feature, i) => (
            <div key={feature.title}>
              <svg
                viewBox="0 0 24 24"
                className="h-7 w-7 text-accent"
                aria-hidden
                fill="none"
                stroke="currentColor"
                strokeWidth={1.7}
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d={FEATURE_ICONS[i]} />
              </svg>
              <h3 className="mt-3 text-[17px] font-semibold">{feature.title}</h3>
              <p className="mt-1.5 text-[15px] leading-relaxed text-muted">{feature.text}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Closing call to action */}
      <section className="mx-auto max-w-5xl px-5 py-24">
        <div className="flex flex-col items-center rounded-3xl border border-line bg-surface px-6 py-14 text-center">
          <Image src="/app-icon.png" alt="" width={64} height={64} className="rounded-2xl shadow-md" />
          <h2 className="mt-6 max-w-2xl text-[28px] font-bold tracking-tight sm:text-[34px]">{t.ctaTitle}</h2>
          <div className="mt-7">
            <AppStoreButton label={t.download} />
          </div>
          <p className="mt-4 text-[14px] text-muted">{t.platforms}</p>
        </div>
      </section>
    </SiteChrome>
  )
}
