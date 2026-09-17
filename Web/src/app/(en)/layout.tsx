/**
 * Root layout for English, served from the site root.
 *
 * One of two root layouts — `(zh)` is the other — so that `<html lang>` is
 * right on every page. Route groups never appear in a URL, which keeps
 * `/support`, `/privacy` and `/terms` exactly where App Store Connect points.
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
    <html lang={LANG_TAG.en}>
      <body>{children}</body>
    </html>
  )
}
