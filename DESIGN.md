# Design: Abadgar

The locked system. Every Hallmark run reads this first and screens share it. Change it on purpose; the file is the rule.

## System
- Genre: modern-minimal
- Scope: app (6 screens + shell + entry sheets)
- Theme: Console (`console: paper` light + `console: graphite` dark, dual-mode parity)
- Axes: warm-paper & matte-graphite / system-sans + tabular numerals / warm-amber + slate-blue · posture: restrained

## Tokens
Implemented in `lib/core/theme/app_theme.dart` (`AppTokens`, `AppSpace`, `AppRadius`) and `lib/core/constants/app_colors.dart`.

### Light (`console: paper`)
- `canvas`: `#F6F4EE` (warm alabaster paper, zero glare)
- `surface`: `#FDFCF9` (elevated plate)
- `well`: `#EDEAE1` (recessed input/control track)
- `surfaceDeep`: `#E4E0D5` (active pill / pressed state)
- `hairline`: `#DEDAD0` (1px structural seam)
- `hairlineStrong`: `#C9C3B5` (focused/selected seam)
- `ink`: `#1B1A17` (primary charcoal-umber ink)
- `inkMuted`: `#656158` (secondary label ink)
- `primary`: `#B45F16` (warm harvest amber — human actions, primary CTA, active tab)
- `onPrimary`: `#FDFCF9`
- `instrument`: `#2F638D` (calm slate-blue — readings, sync instrument, rice crop)

### Dark (`console: graphite`)
- `canvas`: `#15171A` (matte graphite ground)
- `surface`: `#1C1F24` (raised panel, +3% lightness)
- `well`: `#101214` (recessed input/track well)
- `surfaceDeep`: `#252930` (active pill / pressed state)
- `hairline`: `#2B3038` (1px structural seam)
- `hairlineStrong`: `#3D4450` (focused/selected seam)
- `ink`: `#ECEEF2` (soft chalk ink, never pure white)
- `inkMuted`: `#949CA8` (muted pewter ink)
- `primary`: `#E09846` (soft warm amber, chroma-tuned for dark ground)
- `onPrimary`: `#17130E`
- `instrument`: `#6CA5D4` (calm cool steel-blue — readings, sync instrument, rice crop)

### Semantic Ledger Signals
- `revenue`: `#26734D` (light) / `#5CB88A` (dark)
- `expense`: `#B5443A` (light) / `#E0786E` (dark)
- `wheat`: `#B45F16` (light) / `#E09846` (dark)
- `rice`: `#2F638D` (light) / `#6CA5D4` (dark)

## Controls
- Compact height: `36dp`–`40dp` visual controls inside `44dp+` hit targets; `48dp` primary form submit buttons.
- Hairline containment: `1px` rules (`hairline`), zero drop shadows, zero gradients, single containment layer (`AppPanel`).
- Granular controls: inline segmented tracks (`AppSegmentedControl`), 1-tap filter chips, compact stepper nudges, and `FontFeature.tabularFigures()` on all numbers.
- Radii: `6dp` (inner pills/chips), `10dp` (controls/inputs), `14dp` (panels/cards), `20dp` (bottom sheets).

## Motion
- Character: brisk, silent, state-driven (`120ms`–`180ms` ease-out); zero decorative bounce or scroll reveals.
