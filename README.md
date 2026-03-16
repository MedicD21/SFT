# SFT

SFT is a native iPhone food tracking app built in SwiftUI with one job: track food simply and beautifully.

Minimum supported OS: iOS 26.0.

It does not include weight tracking, coaching, exercise, water, or habit clutter. The app focuses on:

- Manual food lookup and entry
- Barcode scanning
- Food photo analysis
- HealthKit nutrition sync

## Product Direction

SFT uses a dark, modern, luxe visual system with a moody black, jade, ember, and gold palette.

Core product choices:

- Native iOS app: SwiftUI + SwiftData
- Health sync: HealthKit nutrition samples
- Food database: USDA FoodData Central
- Barcode source: USDA branded food records via GTIN/UPC lookup
- Photo AI provider: OpenRouter
- Photo AI model default: `anthropic/claude-sonnet-4.6`

As of March 15, 2026, `anthropic/claude-sonnet-4.6` is the default photo-analysis model in the project config.

## What’s Included

- Today dashboard with calories and macro totals
- Quick add flows for search, scan, and photo
- USDA search results with nutrition previews
- Live barcode scanning using `DataScannerViewController`
- Photo capture or photo-library import for AI analysis
- Review-and-edit composer before saving
- Local log persistence in SwiftData
- HealthKit sync for:
  - Calories
  - Protein
  - Carbohydrates
  - Total fat
  - Fiber
  - Sugar
  - Sodium

## Project Structure

- `project.yml`: XcodeGen source of truth
- `SFT/`: app source
- `SFTTests/`: basic unit tests
- `Config/`: build config and secrets template

## Setup

1. Generate the Xcode project:

```bash
xcodegen generate
```

2. Add local API keys:

```bash
cp Config/LocalSecrets.example.xcconfig Config/LocalSecrets.xcconfig
```

3. Fill in these values in `Config/LocalSecrets.xcconfig`:

- `OPENROUTER_API_KEY`
- `OPENROUTER_HTTP_REFERER`
- `OPENROUTER_APP_NAME`
- `USDA_API_KEY`

Notes:

- `USDA_API_KEY` defaults to `DEMO_KEY` for lightweight testing.
- Photo analysis stays disabled until `OPENROUTER_API_KEY` is set.

4. Open the project:

```bash
open SFT.xcodeproj
```

## Build And Test

Build:

```bash
xcodebuild -project SFT.xcodeproj -scheme SFT -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build
```

Test:

```bash
xcodebuild -project SFT.xcodeproj -scheme SFT -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
```

## HealthKit Notes

SFT requests read/write access for nutrition quantity types only. Logged foods are written to HealthKit with a sync identifier so the app remains food-focused and nutrition-specific.

## Why USDA

The app reads food records from USDA FoodData Central, which is a US government food database and keeps the lookup layer US-based as requested.

## Current Status

The repo now contains:

- A generated Xcode project
- A working SwiftUI app shell
- USDA search and barcode lookup
- OpenRouter + Anthropic photo analysis integration
- HealthKit nutrition sync
- A dark themed dashboard and add-food flows
- Passing unit tests
