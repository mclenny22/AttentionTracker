# AttentionBar

`AttentionBar` is a native macOS menu bar app for tracking what currently has your attention.

It gives you six categories:

- Creation
- Consumption
- Logistics
- Connection
- Exploration
- Recovery

The app saves its running state in `~/Library/Application Support/AttentionBar/tracking-state.json` and writes one CSV per reporting window into `~/Documents/Attention Reports`.

## Reporting Window

The reporting day closes at local `20:00`.

- Each CSV is named by the date of that 20:00 cutoff.
- Example: `attention-2026-03-10.csv` covers the window from `2026-03-09 20:00` to `2026-03-10 20:00`.
- If your Mac is asleep or off at `20:00`, the app exports the missed CSV the next time it wakes or launches after `20:00`.

## Run It

1. In Terminal, go to the project folder.
2. Build the app:

```bash
swift build
```

3. Launch it:

```bash
swift run AttentionBar
```

The app will appear in your menu bar as an icon. Click it to open the tracker popover.

## Use It

1. Click one of the category chips to start tracking that category.
2. Click another chip to switch categories.
3. Click the active chip again to stop tracking.
4. Click `Open CSV Folder` to jump straight to the exported files in Finder.
5. Leave the app running in your menu bar if you want automatic end-of-day exports.

## CSV Format

Each CSV has one row per category:

```csv
report_date,window_start,window_end,category,total_seconds,total_minutes,total_hhmmss
2026-03-10,2026-03-09T20:00:00.000+01:00,2026-03-10T20:00:00.000+01:00,Creation,5400,90.00,01:30:00
```

## Notes

- The app pauses tracking when your Mac goes to sleep.
- The app closes any active timer when it quits, so it does not count time while the app is not running.
- This repo is a Swift Package so it works with `swift build` / `swift run`, and you can also open the package in Xcode later if you want to turn it into a bundled `.app`.
