import type { Locale } from '@/lib/site'

import { en } from './en'
import type { Dict } from './types'
import { zh } from './zh'

const dictionaries: Record<Locale, Dict> = { en, zh }

export function dict(locale: Locale): Dict {
  return dictionaries[locale]
}

export type { Block, Dict, Doc } from './types'
