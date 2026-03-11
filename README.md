# AttentionBar

`AttentionBar` is a native macOS menu bar app for quickly logging what currently has your attention.

## Purpose

The app is meant to answer a simple question at the end of the day: where did your attention actually go?

Instead of tracking tasks, estimating time afterward, or filling out a journal, you keep a lightweight status running in your menu bar. When your focus changes, you click the new category. `AttentionBar` records those switches over time and turns them into a daily CSV report.

This makes the app useful for:

- spotting whether your day was mostly creation, admin, recovery, or distraction
- building a low-friction personal attention log
- exporting simple daily data you can review in Numbers, Excel, or scripts later

## What It Tracks

The app groups time into six categories:

- `Creation`: designing, writing, coding, or making something
- `Consumption`: reading, scrolling, watching, or taking in information
- `Logistics`: scheduling, email, admin, errands, and coordination
- `Connection`: calls, messages, meetings, and collaboration
- `Exploration`: research, curiosity, experiments, and rabbit holes
- `Recovery`: resting, walking, music, breaks, and downtime

## How It Works

1. The app lives in the macOS menu bar.
2. Clicking a category starts tracking it immediately.
3. Clicking a different category switches the active session.
4. Clicking the active category again stops tracking.
5. The app keeps a running total for the current reporting window.
6. At the daily cutoff, it exports a CSV report automatically.

The app saves its state in `~/Library/Application Support/AttentionBar/tracking-state.json` and writes CSV reports into `~/Documents/Attention Reports`.

## Reporting Window

The reporting day closes at local `20:00`.

- Each CSV is named for that cutoff date.
- Example: `attention-2026-03-10.csv` covers `2026-03-09 20:00` through `2026-03-10 20:00`.
- If your Mac is asleep or off at `20:00`, the missed export is written the next time the app wakes or launches.

## Run It

```bash
swift build
swift run AttentionBar
```

After launch, the app appears in the menu bar as an icon. Click it to open the tracker popover.

## CSV Output

Each CSV contains one row per category for the reporting window:

```csv
report_date,window_start,window_end,category,total_seconds,total_minutes,total_hhmmss
2026-03-10,2026-03-09T20:00:00.000+01:00,2026-03-10T20:00:00.000+01:00,Creation,5400,90.00,01:30:00
```

## Notes

- The app pauses tracking when the Mac goes to sleep.
- The current session is closed on quit, so time is not counted while the app is not running.
- This project is a Swift Package and can be built with `swift build` and run with `swift run`.
