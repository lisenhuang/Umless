@AGENTS.md

# Working agreements

## Every change

1. **Bump `version` in `package.json`** — patch for a fix, minor for a feature.
   It is the only thing that tells one deploy from the next.
2. **Verify, all three, every time:**

   ```sh
   pnpm typecheck && pnpm lint && pnpm build
   ```

   After deleting a route, clear `.next/` first — its generated types still
   reference the old files and `tsc` fails on them.

## Rules the site depends on

- **The address is fixed.** The site is `https://umless-app.vercel.app`, and
  `/support`, `/privacy` and `/terms` are entered in App Store Connect. The apps
  link to `/privacy` and `/terms` from their purchase screen (`Store.swift` in
  `Mac/` and `iOS/`). Moving a page or the host breaks a link Apple checks.
- **Both languages change together.** `src/content/en.ts` and `zh.ts` share one
  type, so a missing field fails the build — but a changed *meaning* does not.
  Update the other file in the same change.
- **Chinese UI labels quote the app exactly** (选择视频, 灵敏度, 预览剪辑结果, …).
  Check `iOS/Umless/Localizable.xcstrings` rather than translating afresh.
- **The privacy policy describes real behaviour.** It lists every network
  connection the app makes. When the app gains one, this page changes in the
  same round of work, and `LAST_UPDATED` in `src/lib/site.ts` moves.
- **No imitation of Apple's badge.** The download button is a plain button; the
  official badge may only be Apple's own artwork.
