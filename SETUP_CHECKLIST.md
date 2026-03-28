# Infrastructure Setup Checklist

Status: **In Progress** | Last updated: 2026-03-28

---

## Automated (Done by Claude)

- [x] GitHub repo created (`anadolu898/ios-app-factory`, private)
- [x] Project structure (`apps/`, `templates/`, `scripts/`, `portfolio/`)
- [x] CLAUDE.md with conventions and standards
- [x] .gitignore for iOS/Xcode
- [x] MCP: GitHub, Context7, XcodeBuildMCP, Reddit, mobile-mcp
- [x] MCP: Apple Xcode bridge (installed, connects when Xcode is open)
- [x] ASO Skills: 30 skills installed from eronred/aso-skills
- [x] XcodeBuildMCP defaults: iPhone 17 Pro, Debug config
- [x] SwiftUI templates: PaywallView, OnboardingView, ReviewPrompt
- [x] Quality gate script (`scripts/quality-gate.sh`)
- [x] New app scaffold script (`scripts/new-app.sh`)
- [x] MCP setup script (`scripts/setup-mcps.sh`)
- [x] Fastlane template (`templates/Fastfile`)
- [x] n8n workflow templates (review monitor, portfolio report, keyword tracker)
- [x] Supabase schema template (`templates/supabase-schema.sql`)
- [x] Portfolio tracker CSV
- [x] .env.template with all credential placeholders

---

## Needs Your Action (One-Time Setup)

### Priority 1: Required Before First App Build

- [ ] **Fix Homebrew + Install Fastlane**
  ```bash
  sudo chown -R $(whoami) /opt/homebrew
  brew install fastlane
  ```

### Priority 2: Required Before First App Submission

- [ ] **App Store Connect API Key**
  1. Go to https://appstoreconnect.apple.com/access/integrations/api
  2. Click "Generate API Key" (role: Admin or App Manager)
  3. Save the `.p8` file somewhere safe (e.g., `~/.appstoreconnect/AuthKey_XXXXX.p8`)
  4. Note the Key ID and Issuer ID
  5. Add to `.env`:
     ```
     ASC_KEY_ID=your_key_id
     ASC_ISSUER_ID=your_issuer_id
     ASC_P8_PATH=/path/to/AuthKey.p8
     ```
  6. Run `./scripts/setup-mcps.sh`

- [ ] **RevenueCat Account + API Key**
  1. Sign up at https://app.revenuecat.com
  2. Create a project
  3. Go to Settings > API Keys > Generate new secret key
  4. Add to `.env`:
     ```
     REVENUECAT_API_KEY=sk_xxxxxxxxxxxxx
     ```
  5. Run `./scripts/setup-mcps.sh`

### Priority 3: Required Before Marketing Phase

- [ ] **Appeeky API Key** (already purchased, waiting on key to appear)
  - Contact @appeeky on X if key doesn't show up
  - Once received, add to `.env` and run `./scripts/setup-mcps.sh`

- [ ] **Apple Search Ads Account**
  1. Go to https://searchads.apple.com
  2. Sign in with Apple Developer account
  3. Set up billing (credit card)
  4. No MCP needed — managed via web dashboard

- [ ] **Supabase Project**
  1. Sign up at https://supabase.com
  2. Create new project
  3. Run `templates/supabase-schema.sql` in SQL Editor
  4. Authenticate Supabase MCP in Claude Code (it's already installed as a plugin)

### Priority 4: For Content & Social Pipeline

- [ ] **ElevenLabs** — Sign up, get API key, add to `.env`
  - https://elevenlabs.io — $11/month Starter plan
  - Used for: video voiceovers for TikTok/YouTube content

- [ ] **Creatomate** — Sign up, get API key, add to `.env`
  - https://creatomate.com — $9/month
  - Used for: automated video generation from templates

- [ ] **Typefully** — Sign up, connect X/Twitter
  - https://typefully.com — $19/month
  - Used for: scheduled tweets, auto-plug feature

- [ ] **Postiz** (self-hosted) — Optional, can skip initially
  - Requires VPS ($15/month on Railway/DigitalOcean)
  - Used for: TikTok + multi-platform scheduling
  - Alternative: post manually from each platform until volume justifies it

- [ ] **Twitter/X API Keys** (if using MCP for automated monitoring)
  1. Apply at https://developer.twitter.com
  2. Create app, get API keys
  3. Add to `.env` and run `./scripts/setup-mcps.sh`

### Priority 5: Monitoring (Set Up After First App Launch)

- [ ] **Appfigures** — https://appfigures.com — $9.99/month
  - Connect App Store Connect account
  - Used for: review monitoring, ranking data, analytics

- [ ] **Sentry** — https://sentry.io — Free tier
  - Create project per app
  - Add DSN to each app's config

- [ ] **F5Bot** — https://f5bot.com — Free
  - Set up keyword alerts for Reddit + Hacker News
  - Keywords: your app names, competitor names, problem-space terms

- [ ] **Carrd** — https://carrd.co — $19/year
  - Used for: simple landing pages per app

### Priority 6: Automation (Set Up When Running 3+ Apps)

- [ ] **n8n** (self-hosted)
  - Deploy on same VPS as Postiz
  - Import workflow templates from `templates/n8n-workflows/`
  - Connect: Appfigures, RevenueCat, Appeeky, Slack/Discord

---

## Recommended Order of Operations

1. Fix Homebrew + Fastlane (5 min)
2. App Store Connect API key (10 min)
3. RevenueCat account + key (10 min)
4. Get Appeeky API key resolved (pending)
5. **Build first app** (AquaLog) <-- don't wait for everything
6. Set up Supabase + run schema (15 min)
7. Apple Search Ads account (10 min)
8. Set up remaining marketing tools as you approach Phase 5

**You don't need everything to start building.** Items 1-3 cover development + submission. Everything else is for marketing and operations phases.
