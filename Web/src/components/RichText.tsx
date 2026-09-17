import Link from 'next/link'

import { CONTACT_EMAIL, type Locale, type PageKey, pathFor } from '@/lib/site'

/** `**bold**`, `[label](url)` and `{email}` — see `content/types.ts`. */
const TOKEN = /(\*\*[^*]+\*\*|\[[^\]]+\]\([^)]+\)|\{email\})/g
const LINK = /^\[([^\]]+)\]\(([^)]+)\)$/

export function RichText({ text, locale }: { text: string; locale: Locale }) {
  const parts = text.split(TOKEN).filter(Boolean)
  return <>{parts.map((part, i) => renderPart(part, i, locale))}</>
}

function renderPart(part: string, key: number, locale: Locale) {
  if (part === '{email}') {
    return (
      <a key={key} href={`mailto:${CONTACT_EMAIL}`} className="link font-medium">
        {CONTACT_EMAIL}
      </a>
    )
  }
  if (part.startsWith('**') && part.endsWith('**')) {
    return (
      <strong key={key} className="font-semibold text-text">
        {part.slice(2, -2)}
      </strong>
    )
  }
  const link = part.match(LINK)
  if (link) {
    const [, label, href] = link
    // `@privacy` and friends point at that page in the reader's language.
    if (href.startsWith('@')) {
      return (
        <Link key={key} href={pathFor(locale, href.slice(1) as PageKey)} className="link">
          {label}
        </Link>
      )
    }
    return (
      <a key={key} href={href} className="link" target="_blank" rel="noopener noreferrer">
        {label}
      </a>
    )
  }
  return part
}
