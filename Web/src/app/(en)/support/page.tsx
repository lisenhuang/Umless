import type { Metadata } from 'next'

import { DocPage } from '@/components/DocPage'
import { pageMetadata } from '@/lib/metadata'

export const metadata: Metadata = pageMetadata('en', 'support')

export default function Page() {
  return <DocPage locale="en" page="support" />
}
