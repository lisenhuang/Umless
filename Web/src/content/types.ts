/**
 * The shape both languages fill in.
 *
 * Text is plain data with three pieces of inline markup, rendered by
 * `RichText`: `**bold**`, `[label](url)` — where a url of `@support`,
 * `@privacy` or `@terms` means "that page, in this language" — and `{email}`
 * for the contact address. Keeping copy as data means the English and Chinese
 * pages cannot drift in structure, only in wording, and TypeScript refuses a
 * dictionary that is missing a field.
 */

export type Rich = string

export type Block =
  | { kind: 'p'; text: Rich }
  | { kind: 'list'; items: Rich[] }
  | { kind: 'steps'; items: { title: string; text: Rich }[] }
  | { kind: 'qa'; items: { q: string; a: Rich[] }[] }

export type DocSection = { title: string; blocks: Block[] }

export type Doc = {
  /** `<title>` and the page heading. */
  title: string
  /** Search and link-preview description. */
  description: string
  intro: string
  sections: DocSection[]
}

export type Dict = {
  nav: {
    home: string
    support: string
    privacy: string
    terms: string
    /** Label of the link to the *other* language. */
    otherLanguage: string
    otherLanguageAria: string
  }
  footer: {
    onDevice: string
    modelCredit: string
    lastUpdated: string
  }
  home: {
    metaTitle: string
    metaDescription: string
    platforms: string
    title: string
    body: string
    download: string
    privacyNote: string
    qrTitle: string
    qrBody: string
    artCaption: string
    stepsTitle: string
    steps: { title: string; text: string }[]
    featuresTitle: string
    features: { title: string; text: string }[]
    ctaTitle: string
  }
  support: Doc
  privacy: Doc
  terms: Doc
}
