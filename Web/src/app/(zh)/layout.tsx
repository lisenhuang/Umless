/**
 * Root layout for Simplified Chinese, served under `/zh`.
 *
 * The second of two root layouts — `(en)` is the other — so that
 * `<html lang>` is `zh-Hans` on these pages.
 */

import '../globals.css'

import type { Metadata, Viewport } from 'next'
import type { ReactNode } from 'react'

import { rootMetadata, rootViewport } from '@/lib/metadata'
import { LANG_TAG } from '@/lib/site'

export const metadata: Metadata = rootMetadata
export const viewport: Viewport = rootViewport

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang={LANG_TAG.zh}>
      <body>{children}</body>
    </html>
  )
}
