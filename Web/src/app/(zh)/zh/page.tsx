import type { Metadata } from 'next'

import { Home } from '@/components/Home'
import { pageMetadata } from '@/lib/metadata'

export const metadata: Metadata = pageMetadata('zh', 'home')

export default function Page() {
  return <Home locale="zh" />
}
