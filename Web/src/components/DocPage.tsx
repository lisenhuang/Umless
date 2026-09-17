import { type Block, dict } from '@/content'
import { formatDate, LAST_UPDATED, type Locale } from '@/lib/site'

import { RichText } from './RichText'
import { SiteChrome } from './SiteChrome'

type DocKey = 'support' | 'privacy' | 'terms'

/**
 * The three pages App Store Connect links to. Pure server-rendered text, so
 * they read correctly with JavaScript off — which is how App Review, and
 * plenty of in-app browsers, will first open them.
 */
export function DocPage({ locale, page }: { locale: Locale; page: DocKey }) {
  const t = dict(locale)
  const doc = t[page]
  // Support is a guide, not an agreement; only the legal pages carry a date.
  const dated = page !== 'support'

  return (
    <SiteChrome locale={locale} page={page}>
      <article className="mx-auto max-w-3xl px-5 pb-24 pt-14 sm:pt-20">
        <header className="border-b border-line pb-8">
          <h1 className="text-[36px] font-bold tracking-tight sm:text-[44px]">{doc.title}</h1>
          <p className="mt-3 text-[18px] leading-relaxed text-muted">{doc.intro}</p>
          {dated && (
            <p className="mt-4 text-[13px] text-muted">
              {t.footer.lastUpdated}: <time dateTime={LAST_UPDATED.toISOString().slice(0, 10)}>{formatDate(LAST_UPDATED, locale)}</time>
            </p>
          )}
        </header>

        {doc.sections.map(section => (
          <section key={section.title} className="mt-12">
            <h2 className="text-[24px] font-semibold tracking-tight">{section.title}</h2>
            <div className="mt-4 space-y-4">
              {section.blocks.map((block, i) => (
                <BlockView key={i} block={block} locale={locale} />
              ))}
            </div>
          </section>
        ))}
      </article>
    </SiteChrome>
  )
}

function BlockView({ block, locale }: { block: Block; locale: Locale }) {
  const body = 'text-[16px] leading-relaxed text-muted'
  switch (block.kind) {
    case 'p':
      return (
        <p className={body}>
          <RichText text={block.text} locale={locale} />
        </p>
      )
    case 'list':
      return (
        <ul className={`${body} list-disc space-y-2.5 pl-5 marker:text-line`}>
          {block.items.map(item => (
            <li key={item}>
              <RichText text={item} locale={locale} />
            </li>
          ))}
        </ul>
      )
    case 'steps':
      return (
        <ol className="space-y-3">
          {block.items.map((step, i) => (
            <li key={step.title} className="flex gap-4 rounded-2xl border border-line bg-surface p-4">
              <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-accent text-[14px] font-semibold text-white">
                {i + 1}
              </span>
              <div>
                <h3 className="text-[16px] font-semibold">{step.title}</h3>
                <p className={`mt-1 ${body}`}>
                  <RichText text={step.text} locale={locale} />
                </p>
              </div>
            </li>
          ))}
        </ol>
      )
    case 'qa':
      return (
        <div className="divide-y divide-line rounded-2xl border border-line bg-surface">
          {block.items.map(item => (
            <div key={item.q} className="p-5">
              <h3 className="text-[16px] font-semibold">{item.q}</h3>
              <div className="mt-2 space-y-2">
                {item.a.map(para => (
                  <p key={para} className={body}>
                    <RichText text={para} locale={locale} />
                  </p>
                ))}
              </div>
            </div>
          ))}
        </div>
      )
  }
}
