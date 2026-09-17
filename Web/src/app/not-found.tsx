/**
 * The 404 page.
 *
 * It renders its own `<html>` and imports the stylesheet, which a page
 * normally never does: with two root layouts there is no single root above a
 * top-level `not-found`, and without this it falls back to Next's unstyled
 * default. English, since a path that does not exist has no language of its
 * own; the link home is one click from either.
 */

import './globals.css'

import type { Metadata } from 'next'
import Link from 'next/link'

import { rootMetadata } from '@/lib/metadata'

export const metadata: Metadata = {
  ...rootMetadata,
  title: 'Page not found · Umless',
  robots: { index: false, follow: true },
}

export default function NotFound() {
  return (
    <html lang="en">
      <body>
        <main className="mx-auto flex min-h-dvh max-w-2xl flex-col justify-center px-6 py-24">
          <p className="text-[13px] font-medium uppercase tracking-wide text-muted">404</p>
          <h1 className="mt-3 text-[34px] font-bold tracking-tight">There is nothing at this address</h1>
          <p className="mt-3 text-[16px] leading-relaxed text-muted">
            The page may have moved, or the link may have been typed slightly wrong.
          </p>
          <p className="mt-8 flex gap-5 text-[15px]">
            <Link href="/" className="link font-medium">Umless home</Link>
            <Link href="/zh" className="link font-medium">中文首页</Link>
          </p>
        </main>
      </body>
    </html>
  )
}
