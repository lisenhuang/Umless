import { APP_STORE_URL } from '@/lib/site'

/**
 * A plain button rather than a copy of Apple's badge: the official badge has
 * to be Apple's own artwork, so this does not imitate it.
 */
export function AppStoreButton({ label, size = 'lg' }: { label: string; size?: 'md' | 'lg' }) {
  return (
    <a
      href={APP_STORE_URL}
      className={`inline-flex items-center gap-2.5 rounded-full bg-accent font-semibold text-white shadow-sm transition-colors hover:bg-accent-hover ${
        size === 'lg' ? 'px-6 py-3.5 text-[17px]' : 'px-5 py-2.5 text-[15px]'
      }`}
    >
      <svg viewBox="0 0 20 20" className="h-5 w-5" aria-hidden fill="none" stroke="currentColor" strokeWidth={1.8}>
        <path d="M10 3v10m0 0 4-4m-4 4-4-4" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M4 15.5h12" strokeLinecap="round" />
      </svg>
      {label}
    </a>
  )
}
