/**
 * A drawing of what the app shows: a waveform on a timeline, with each filler
 * marked in amber. Deterministic, so the server render and every rebuild
 * produce the same picture.
 */

const BARS = 96
const FILLERS = [
  { at: 0.14, label: 'um' },
  { at: 0.39, label: 'uh' },
  { at: 0.63, label: 'hmm' },
  { at: 0.86, label: 'um' },
]

function barHeight(i: number) {
  const x = i / BARS
  const speech = 0.55 + 0.45 * Math.sin(x * 23.7) * Math.sin(x * 7.1 + 1.3)
  const texture = 0.25 * Math.sin(i * 1.91) + 0.15 * Math.cos(i * 3.37)
  return Math.max(0.12, Math.min(1, Math.abs(speech + texture)))
}

export function TimelineArt({ caption }: { caption: string }) {
  const width = 960
  const height = 220
  const mid = 118
  const barWidth = width / BARS

  return (
    <figure className="overflow-hidden rounded-3xl border border-line bg-surface p-5 shadow-sm sm:p-8">
      <svg viewBox={`0 0 ${width} ${height}`} className="h-auto w-full" role="img" aria-label={caption}>
        {FILLERS.map(f => {
          const x = f.at * width
          return (
            <g key={f.at}>
              <rect x={x - 26} y={30} width={52} height={176} rx={10} className="fill-filler" opacity={0.14} />
              <rect x={x - 2} y={30} width={4} height={176} rx={2} className="fill-filler" />
              <rect x={x - 26} y={2} width={52} height={24} rx={12} className="fill-filler" />
              <text x={x} y={19} textAnchor="middle" className="fill-white text-[13px] font-semibold">
                {f.label}
              </text>
            </g>
          )
        })}
        {Array.from({ length: BARS }, (_, i) => {
          const h = barHeight(i) * 76
          const near = FILLERS.some(f => Math.abs(i / BARS - f.at) < 0.022)
          return (
            <rect
              key={i}
              x={i * barWidth + barWidth * 0.2}
              y={mid - h}
              width={barWidth * 0.6}
              height={h * 2}
              rx={barWidth * 0.3}
              className={near ? 'fill-filler' : 'fill-muted'}
              opacity={near ? 0.95 : 0.45}
            />
          )
        })}
        {/* Playhead */}
        <rect x={width * 0.5 - 1} y={34} width={2} height={170} className="fill-accent" />
        <circle cx={width * 0.5} cy={34} r={6} className="fill-accent" />
      </svg>
      <figcaption className="mt-4 text-center text-[14px] text-muted">{caption}</figcaption>
    </figure>
  )
}
