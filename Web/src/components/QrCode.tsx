import QRCode from 'qrcode'

/**
 * The App Store link as a QR code, generated at build time into plain SVG —
 * no image request, no client code.
 *
 * Always dark on white, even in dark mode: phone cameras read inverted codes
 * unreliably, and a code that fails to scan is worse than one that clashes.
 */
export async function QrCode({ value, label }: { value: string; label: string }) {
  const svg = await QRCode.toString(value, {
    type: 'svg',
    margin: 0,
    errorCorrectionLevel: 'M',
    color: { dark: '#000000', light: '#ffffff' },
  })
  return (
    <div
      role="img"
      aria-label={label}
      className="aspect-square w-full [&>svg]:block [&>svg]:h-full [&>svg]:w-full"
      // Generated here from a constant URL, never from user input.
      dangerouslySetInnerHTML={{ __html: svg }}
    />
  )
}
