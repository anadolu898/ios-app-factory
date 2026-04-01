# Autonomous iOS App Factory — Master Playbook

**Version**: 1.0 | **Date**: March 28, 2026 | **Author**: Anadolu + Claude

---

## 0. Philosophy & Ground Rules

This playbook operates on three principles:

1. **Quality threshold before marketing spend.** We do not promote vibe-coded garbage. An app earns marketing budget by passing a quality gate: proper UI/UX following Apple HIG, smooth animations, no crashes on simulator testing across 3+ device sizes, proper error handling, and a clear value proposition. If it doesn't pass, we iterate or kill it — we don't throw money at it.

2. **Measure everything, cut fast.** Every dollar spent on marketing should be traceable to a result (impressions, taps, installs, trial starts, conversions). If a channel isn't producing signal within 14 days, we reallocate. The tooling exists to make this possible.

3. **Portfolio strategy, not single bets.** The economics work at 15-20 apps where 3-5 hit. Each app's marginal build cost is $50-200. Each app's marginal marketing cost is $0-350/month. We need a portfolio-level view, not app-level anxiety.

---

## 1. Hardware & Account Prerequisites

### Non-Negotiable

- **Mac running macOS** (Xcode only runs on macOS). Options: physical Mac, MacStadium cloud Mac (~$50/month), AWS EC2 Mac instance
- **Apple Developer Account** ($99/year) — already have this
- **Claude Max subscription** ($100-200/month) for Cowork, Dispatch, Computer Use, and high usage limits
- **Claude Code** installed on the Mac

### Accounts to Create (One-Time)

| Account | Purpose | Cost |
|---|---|---|
| GitHub | Code repos for all apps | Free |
| Appeeky | ASO intelligence + MCP | $8/month |
| RevenueCat | Subscription management | Free tier |
| Supabase | Backend (if needed) | Free tier |
| Apple Search Ads | Paid acquisition | Pay-per-click |
| ElevenLabs | AI voiceover for videos | $11/month (Starter) |
| Creatomate | Video generation API | $9/month |
| Postiz | Social media scheduling | $5-10/month self-hosted |
| Typefully | X/Twitter management | $19/month |
| Appfigures | Analytics + reviews | $9.99/month |
| F5Bot | Reddit/HN keyword alerts | Free |
| Carrd | App landing pages | $19/year |
| n8n | Workflow automation | Free self-hosted |
| Sentry | Crash monitoring | Free tier |

**Estimated fixed monthly cost (all tools): ~$175-250/month** — shared across entire app portfolio, not per-app.

---

## 2. The MCP & Plugin Stack

### Installation Commands (Run Once on Mac)

```bash
# === LAYER 1: Core Development ===
claude mcp add github                           # Official plugin
claude mcp add context7                         # Live library docs
claude mcp add memory                           # Persistent project memory

# === LAYER 2: iOS Build & Test ===
claude mcp add-json XcodeBuildMCP '{"command":"npx","args":["-y","xcodebuildmcp@latest","mcp"]}'
claude mcp add --transport stdio xcode -- xcrun mcpbridge   # Apple native (Xcode 26.3+)
claude mcp add-json mobile-mcp '{"command":"npx","args":["-y","@mobilenext/mobile-mcp@latest"]}'

# === LAYER 3: App Store & ASO ===
claude mcp add-json appeeky '{"url":"https://mcp.appeeky.com/mcp","headers":{"Authorization":"Bearer YOUR_KEY"}}'
claude mcp add-json app-store-connect '{"command":"npx","args":["-y","@joshuarileydev/app-store-connect-mcp-server"],"env":{"APP_STORE_CONNECT_KEY_ID":"YOUR_KEY_ID","APP_STORE_CONNECT_ISSUER_ID":"YOUR_ISSUER_ID","APP_STORE_CONNECT_P8_PATH":"/path/to/auth-key.p8"}}'

# === LAYER 4: Monetization ===
claude mcp add --transport http revenuecat https://mcp.revenuecat.ai/mcp --header "Authorization: Bearer YOUR_RC_KEY"

# === LAYER 5: Social Media & Marketing ===
# Postiz (after self-hosting setup)
claude mcp add-json postiz '{"url":"https://your-postiz-instance.com/mcp"}'
# Twitter (community server)
claude mcp add-json twitter '{"command":"npx","args":["-y","@enescinar/twitter-mcp"],"env":{"TWITTER_API_KEY":"...","TWITTER_API_SECRET":"...","TWITTER_ACCESS_TOKEN":"...","TWITTER_ACCESS_SECRET":"..."}}'
# Reddit (read-only monitoring)
claude mcp add-json reddit '{"command":"npx","args":["-y","reddit-mcp-buddy"]}'

# === LAYER 6: Backend (as needed per app) ===
# Supabase — use official MCP, configure per project
# Firebase — /plugin install firebase
# Sentry — /plugin install sentry

# === LAYER 7: Skills (Installed in .agents/skills/) ===
# SwiftUI Skills (auto-invoked during development):
#   swiftui-pro       — Core rules: state, nav, data, perf, a11y (Paul Hudson methodology)
#   swiftui-expert    — Advanced: animations, Charts, Widgets, Intents, SwiftData (AvdLee methodology)
#   swiftui-patterns  — Architecture: MVVM, composition, refactoring (Dimillian methodology)
#   design-check      — Visual & accessibility audit via screenshots + UI snapshots
# ASO Skills (30 marketing/optimization skills in .agents/skills/):
#   aso-audit, keyword-research, metadata-optimization, competitor-analysis, etc.
#
# Design Infrastructure (in .claude/):
#   rules/design-system.md       — Color, typography, spacing, component standards
#   rules/swiftui-conventions.md — File organization, naming, import order
#   commands/design-check.md     — /project:design-check slash command
#   commands/quality-gate.md     — /project:quality-gate slash command
#   agents/ui-reviewer.md        — Visual quality review subagent
#   agents/accessibility-auditor.md — WCAG 2.1 AA compliance subagent
```

### Context Budget Management

Each active MCP server consumes context tokens. With Anthropic's Tool Search (lazy loading), this is manageable, but be deliberate:

- **Always active**: GitHub, Context7, XcodeBuildMCP, Appeeky
- **Activate per-phase**: Xcode MCP (build phase), RevenueCat (monetization phase), Postiz/Twitter (marketing phase)
- **Use McPick** (`npx mcpick`) to toggle servers on/off between phases

---

## 2b. Design & Quality Toolkit

### Autonomous Visual Feedback Loop

The key to production-grade UI without human review is a **screenshot → evaluate → iterate** cycle. Claude builds the view, screenshots it via XcodeBuildMCP, evaluates against the design system rules, fixes issues, and re-screenshots — all autonomously.

**Tools in the loop:**
- `build_run_sim` — compile and launch
- `screenshot` — capture current screen state
- `snapshot_ui` — get accessibility tree with element coordinates
- `.claude/rules/design-system.md` — evaluation criteria
- `swiftui-pro` / `swiftui-expert` skills — code fix guidance

### Skills Architecture

Skills are stored in `.agents/skills/` and symlinked to `.claude/skills/`. They auto-invoke based on task context.

| Skill | Triggers On | Purpose |
|-------|-------------|---------|
| `swiftui-pro` | Any SwiftUI code writing | Prevents deprecated APIs, enforces @Observable, accessibility |
| `swiftui-expert` | Animations, Charts, Widgets, SwiftData | Advanced framework integration patterns |
| `swiftui-patterns` | Refactoring, architecture decisions | MVVM, view composition, performance audit |
| `design-check` | "design check", Phase 3 QG, after major UI changes | Structured visual + accessibility audit |
| 30 ASO/marketing skills | Various marketing tasks | ASO, keywords, reviews, campaigns, etc. |

### Slash Commands

- `/project:design-check` — Screenshot every screen, audit visual quality + accessibility, output structured report
- `/project:quality-gate` — Full pre-submission checklist (build + test + design + performance + paywall + dark mode + a11y)

### Specialized Agents

- **UI Reviewer** (`.claude/agents/ui-reviewer.md`) — Scores visual quality, usability, and polish on a 1-5 scale per screen
- **Accessibility Auditor** (`.claude/agents/accessibility-auditor.md`) — WCAG 2.1 AA compliance check with per-screen results

### Active MCP Stack for Design & Quality

- **Xcode MCP** (`xcrun mcpbridge`) — SwiftUI preview rendering, Apple docs search, code snippets (Xcode 26.3)
- **iOS Simulator MCP** — Granular UI interaction: tap coordinates, swipe gestures, text input, video recording
- **XcodeBuildMCP** — Build, test, screenshot, UI snapshot, LLDB debug

### Future Additions (When Needed)

- **Motion AI Kit** — Animation performance auditing (if we add complex animations)

---

## 3. Target Categories & App Types

### Tier 1: Build These First (Fully Autonomous, Proven Revenue)

| Category | Example App Ideas | Monetization | Monthly Revenue Range (if ranked) |
|---|---|---|---|
| Health & Fitness | Water tracker, workout timer, sleep logger, blood pressure diary, stretching guide | Subscription $3.99-9.99/mo | $2,000-50,000 |
| Lifestyle | Habit tracker, gratitude journal, mood diary, daily affirmations, vision board | Subscription $2.99-6.99/mo | $1,000-20,000 |
| Productivity | Pomodoro timer, expense tracker, goal planner, meeting notes, bookmark manager | Subscription $2.99-5.99/mo | $1,000-15,000 |
| Food & Drink | Meal planner, recipe organizer, cocktail guide, grocery list, fasting tracker | Subscription $3.99-7.99/mo | $2,000-25,000 |
| Utilities | Unit converter, QR scanner, calculator variants, battery monitor, WiFi analyzer | One-time $1.99-4.99 or sub | $500-5,000 |
| Widgets | Custom clock widgets, photo widgets, countdown widgets, quote widgets | Subscription $1.99-4.99/mo | $1,000-30,000 |

### Tier 2: Build After Portfolio Established (Mostly Autonomous)

| Category | Why Wait | Additional Complexity |
|---|---|---|
| Finance (no real money) | Needs accuracy testing | Tax disclaimers, calculation verification |
| AI Wrappers | API cost management | Rate limiting, prompt quality, margins |
| Simple Games | Balancing required | Game design iteration, engagement tuning |
| HealthKit/Watch Apps | Physical device testing | Apple Watch complications, health data |

### Do Not Build (Autonomous Not Viable)

Social networks, fintech, healthcare (regulated), messaging, marketplaces, complex games, enterprise tools.

---

## 4. The Pipeline — Phase by Phase

### Phase 0: Market Research & Niche Selection

**Time**: 30-60 minutes per app concept | **Cost**: $0 (uses Appeeky free credits + Claude reasoning)

**Steps**:
1. **Keyword opportunity scan** via Appeeky MCP: `/keyword-research [category]`
   - Look for: difficulty < 40, popularity > 30, low competitor count
   - Extract: top 20 keyword opportunities with traffic estimates

2. **Competitor analysis** via App Store Scraper MCP + Appeeky:
   - Identify top 10 apps in target niche
   - Read 1-star reviews (pain points = your features)
   - Read 5-star reviews (table stakes features you must match)
   - Check last update dates (abandoned apps = opportunity)

3. **Reddit demand validation** via Reddit MCP:
   - Search r/iOSApps, r/AppHookup, r/productivity, r/fitness (etc.) for relevant threads
   - Look for "looking for an app that..." posts
   - Check if recommendations are outdated or have gaps

4. **Go/No-Go Decision**:
   - GO if: keyword opportunity exists, competitors have weaknesses, clear monetization path, buildable in < 4 hours
   - KILL if: market saturated with strong competitors, no search volume, requires capabilities beyond Tier 1

**Output**: App Spec Document including:
- App name (optimized for ASO — primary keyword in name)
- Subtitle (secondary keywords)
- Feature list (MVP — max 5 core features)
- Monetization model (free trial length, price points, what's behind paywall)
- Target keywords (20-30, ranked by priority)
- Competitor weaknesses to exploit

---

### Phase 1: Design

**Time**: 30-60 minutes | **Cost**: $0

**Steps**:
1. **UI Architecture**: Claude Code generates screen flow document
   - Follow Apple HIG (Human Interface Guidelines)
   - iOS 26+ Liquid Glass design language where appropriate
   - Max 5-7 screens for MVP
   - SwiftUI-native, no UIKit unless required

2. **App Icon**: Generate via DALL-E/Midjourney API or Recraft
   - Simple, distinctive, category-appropriate
   - Test at small sizes (29pt, 40pt, 60pt) — must be legible
   - Export at 1024x1024 for App Store

3. **Color Palette & Typography**: Define in code
   - Use SF Pro (system font) unless strong reason not to
   - 2-3 accent colors max
   - Support Dark Mode from day one

**Output**: Complete SwiftUI component library + app icon + design tokens

---

### Phase 2: Development

**Time**: 2-6 hours autonomous | **Cost**: ~$5-20 in Claude API usage

**Steps**:
1. **Project scaffolding**: Claude Code creates Xcode project
   ```
   - SwiftUI App lifecycle
   - Core Data or SwiftData for persistence
   - StoreKit 2 for subscriptions
   - RevenueCat SDK integration
   - WidgetKit if applicable
   - HealthKit if applicable
   ```

2. **Feature implementation**: Iterative build
   - Claude Code writes feature -> builds -> tests -> fixes -> repeats
   - Context7 MCP provides current API docs
   - Each feature committed to GitHub via GitHub MCP

3. **Monetization integration**:
   - RevenueCat MCP: create products, entitlements, offerings
   - Implement paywall screen (use RevenueCat paywall templates or custom)
   - Free trial configuration (7 days recommended — 19% higher conversion)
   - Restore purchases flow

4. **Review prompt integration**:
   - Implement SKStoreReviewController
   - Trigger after 3rd positive interaction (e.g., completing a workout, logging 7 days in a row)
   - Max 3 prompts per user per year (Apple enforced)

5. **Analytics integration**:
   - Sentry for crash reporting
   - RevenueCat for revenue metrics
   - Basic event tracking (screen views, key actions)

**Output**: Complete Xcode project, compiling, committed to GitHub

---

### Phase 3: Quality Gate (MUST PASS BEFORE MARKETING)

**Time**: 1-2 hours | **Cost**: $0

This is the checkpoint. No marketing spend is authorized until an app passes every item.

**Automated Checks (via XcodeBuildMCP)**:
- [ ] Builds without warnings on latest Xcode
- [ ] All unit tests pass
- [ ] UI tests pass on iPhone 16 Pro, iPhone SE, iPad
- [ ] No memory leaks (Instruments check)
- [ ] Launch time < 2 seconds
- [ ] App size < 50MB (ideally < 30MB)

**Manual/Semi-Automated Checks (via Cowork Computer Use)**:
- [ ] Every screen renders correctly on 3+ device sizes
- [ ] Dark Mode works throughout
- [ ] Landscape orientation handled (or properly locked)
- [ ] Paywall displays correctly, purchase flow works
- [ ] Restore purchases works
- [ ] Onboarding flow is smooth and concise (< 4 screens)
- [ ] Empty states are designed (not blank screens)
- [ ] Error states show helpful messages
- [ ] Accessibility: VoiceOver labels on all interactive elements
- [ ] Privacy nutrition labels accurate

**Subjective Quality Check**:
- [ ] Does the app feel native? (Not a web view, not generic AI aesthetic)
- [ ] Is there a clear "aha moment" within 30 seconds?
- [ ] Would I pay for this?

**Decision**:
- All checks pass -> Proceed to Phase 4
- Fixable issues -> Loop back to Phase 2
- Fundamental problems -> Kill the app, learn, move on

---

### Phase 4: App Store Preparation & Submission

**Time**: 1-2 hours | **Cost**: $0

**Steps**:
1. **Screenshot generation** via App Store Screenshots skill:
   - 4 required sizes: 6.9", 6.5", 6.3", 6.1"
   - 5-8 screenshots per size (first 3 most important — visible without scrolling)
   - Include device frames, compelling headlines, feature callouts
   - Consider localization for high-value markets (Japan, UK, Germany)

2. **ASO metadata** via Appeeky MCP + ASO Skills:
   ```
   /aso-audit          — baseline analysis
   /keyword-research   — final keyword selection
   /metadata-optimization — generate optimized title, subtitle, description
   ```
   - App Name: 30 chars max, primary keyword included
   - Subtitle: 30 chars max, secondary keywords
   - Keyword field: 100 chars, comma-separated, no spaces after commas
   - Description: Feature-benefit oriented, keywords in first paragraph
   - What's New: Specific, user-facing changes

3. **App Preview Video** (optional but recommended):
   - 15-30 second screen recording with motion
   - Capture via XcodeBuildMCP simulator recording
   - Add text overlays via Creatomate or Rotato

4. **Submission** via Fastlane MCP + App Store Connect MCP:
   - Code signing via Fastlane match
   - Build upload via Fastlane deliver
   - Metadata + screenshots via App Store Connect MCP
   - Submit for review
   - Privacy questionnaire completion

5. **Landing page** via Carrd or Claude-generated Next.js:
   - One-page site: hero + 3 features + screenshots + App Store badge
   - Smart App Banner meta tag for Safari users
   - SEO-optimized for primary keywords
   - Email capture form (MailerLite free tier)

**Output**: App submitted to App Review, landing page live

---

### Phase 5: Launch Marketing (Week 1-2)

**Budget**: $150-300 for initial push | **Channels**: ASO + Apple Search Ads + 1 organic launch

This is where money starts flowing. Only for apps that passed the Quality Gate.

**Day 1-3: Apple Search Ads**
- Create Discovery Campaign (Search Match ON)
  - Daily budget: $10-20
  - Let Apple's algorithm find converting keywords
  - Monitor: cost per install (CPI), tap-through rate (TTR), conversion rate (CR)
- Create Exact Match Campaign with top 10 ASO keywords
  - Max CPT bid: start at $1.00, adjust based on competition
  - Daily budget: $5-10
- **Track**: CPI target < $2.00 for most categories. Kill keywords with CPI > $5.00 after 100 impressions.

**Day 1: Organic Launch Posts**
- Reddit: genuine post in relevant subreddit (manual, from personal account)
  - r/iOSApps (Thursdays), r/AppHookup, r/SideProject, category-specific subs
  - Format: "I built X because Y wasn't solving Z. Here's what I learned."
  - Include screenshots, link to App Store, ask for feedback
- Product Hunt: submit listing (manual)
- Hacker News: Show HN post if technically interesting (manual)

**Day 3-7: Social Content Pipeline Activation**
- TikTok (via Postiz):
  - 1 video/day for first 2 weeks
  - Content types: problem->solution demo, "This app changed my X", screen recording with voiceover
  - Video creation: Claude writes script -> ElevenLabs voiceover -> Creatomate assembly
  - Schedule via Postiz MCP
- X/Twitter (via Typefully):
  - 2-3 posts/day
  - Mix: tips related to app's domain, behind-the-scenes, feature highlights
  - Use Typefully's Auto-Plug: when a tweet hits engagement threshold, auto-reply with app link
  - Schedule via Typefully API/MCP

**Day 7-14: Evaluate & Adjust**
- Check Apple Search Ads dashboard: which keywords convert?
- Feed converting keywords back into ASO metadata
- Check TikTok analytics: which video formats get views?
- Double down on what works, cut what doesn't

---

### Phase 6: Ongoing Operations (Week 3+)

**Budget**: $100-250/month steady state | **Time**: ~2 hours/week human oversight

**Weekly Automated Tasks (via Cowork Scheduled Tasks / n8n)**:

| Task | Frequency | Tool | Action |
|---|---|---|---|
| Keyword ranking check | Daily | Appeeky MCP | Track position changes for top 20 keywords |
| Review monitoring | Daily | Appfigures API | Fetch new reviews, sentiment analysis, draft responses |
| Crash monitoring | Continuous | Sentry | Alert on new crash patterns |
| Revenue tracking | Daily | RevenueCat MCP | MRR, trial conversions, churn |
| Competitor monitoring | Weekly | Appeeky MCP | Track competitor keyword changes, new apps |
| Social content creation | 3x/week | Creatomate + ElevenLabs | Generate and queue TikTok/X content |
| Social posting | Daily | Postiz MCP + Typefully | Publish queued content |
| Reddit monitoring | Daily | F5Bot + Reddit MCP | Alert on relevant discussions |
| ASO keyword refresh | Bi-weekly | Appeeky MCP | Update keywords based on ranking data |
| Apple Search Ads optimization | Weekly | ASA API | Pause low-CPI keywords, increase budget on winners |

**Monthly Human Review (The One Thing That Can't Be Automated)**:
1. Portfolio dashboard review: which apps are growing vs. declining?
2. Kill decision: any app with < $50/month revenue after 90 days gets its marketing budget reallocated
3. Double-down decision: any app showing upward trajectory gets increased ASA budget
4. New app decision: based on learnings, what should the next app be?
5. Feature update prioritization: based on reviews and competitor moves

---

## 5. Measurement & Decision Framework

### Key Metrics Per App

| Metric | Source | Target (Tier 1 App) | Action if Below |
|---|---|---|---|
| Daily Downloads | App Store Connect | > 10/day after week 2 | Increase ASA spend or improve ASO |
| Conversion Rate (page view -> install) | App Store Connect | > 30% | Improve screenshots, description |
| Trial Start Rate | RevenueCat | > 40% of installs | Improve onboarding, paywall timing |
| Trial -> Paid Conversion | RevenueCat | > 15% | Improve trial experience, adjust trial length |
| Day 7 Retention | App Store Connect | > 20% | Improve core value loop, add notifications |
| App Store Rating | Appfigures | > 4.3 stars | Fix bugs, improve UX based on reviews |
| Apple Search Ads CPI | ASA Dashboard | < $2.00 | Optimize keywords, improve conversion |
| Monthly Recurring Revenue | RevenueCat | Growth > 5% MoM | Scale marketing if positive, investigate if flat |
| Churn Rate (monthly) | RevenueCat | < 12% | Improve retention features, engagement |

### Portfolio-Level Tracking

Maintain a simple spreadsheet (or Supabase table) with:
- App name, category, launch date
- Monthly: downloads, MRR, marketing spend, profit/loss
- Status: Active / Scaling / Maintenance / Killed
- Running total: portfolio MRR, portfolio marketing spend, portfolio profit

### Kill Criteria

An app should be killed (marketing stopped, moved to maintenance) if:
- After 90 days: MRR < $50 AND no growth trend
- After 180 days: MRR < $200
- Apple Search Ads CPI consistently > $5 with no conversion improvement
- App Store rating drops below 3.5 with no clear fix

"Killed" doesn't mean deleted — leave it on the App Store (it costs nothing). Just stop active marketing spend. Occasionally, killed apps get discovered organically months later.

### Scale Criteria

An app should get increased investment if:
- MRR > $500 AND growing > 10% MoM
- Trial conversion > 20%
- App Store rating > 4.5
- Apple Search Ads showing positive ROAS

Investment means: increase ASA budget, add more content channels, consider localization, add features based on review feedback.

---

## 6. Cost Model

### Fixed Monthly Costs (Shared Across Portfolio)

| Item | Monthly Cost | Notes |
|---|---|---|
| Claude Max | $100-200 | Core AI infrastructure |
| Apple Developer | $8.25 | $99/year amortized |
| Appeeky | $8 | ASO intelligence |
| ElevenLabs | $11 | Video voiceover |
| Creatomate | $9 | Video generation |
| Postiz (self-hosted) | $10 | Social scheduling |
| Typefully | $19 | X/Twitter management |
| Appfigures | $9.99 | Analytics + reviews |
| Carrd | $1.58 | $19/year, landing pages |
| Mac (if cloud) | $0-50 | MacStadium or own Mac |
| VPS for n8n/Postiz | $15 | Railway or DigitalOcean |
| **Total Fixed** | **$192-343** | |

### Variable Costs Per App (Marketing Phase)

| Item | Monthly Cost | Notes |
|---|---|---|
| Apple Search Ads | $100-300 | $5-10/day, scale with performance |
| Additional video credits | $0-20 | If exceeding Creatomate free renders |
| **Total Variable** | **$100-320/app** | Only for apps that pass Quality Gate |

### Break-Even Analysis

With $250/month fixed + $200/month marketing on 3 apps:
- Total monthly spend: $850
- Need: ~$850/month MRR across portfolio to break even
- At median indie app revenue ($500-2,000/month per successful app): **2-3 successful apps cover the entire operation**

---

## 7. The First App — Recommended Starting Point

**App**: Hydration Tracker with Apple Watch Complication + Home Screen Widget

**Why this specifically**:
- Health & Fitness = highest revenue-to-competition ratio (0.80x)
- Water tracking = evergreen need, not trend-dependent
- Widget + Watch complication = perceived premium value
- SwiftUI + HealthKit + WidgetKit = well-documented, within autonomous capability
- Subscription-worthy: people pay $3-5/month for health tracking
- Simple enough to complete in one Claude Code session
- Complex enough to not look vibe-coded

**Spec**:
- Screens: Onboarding (3 steps) -> Main (daily intake + progress ring) -> History -> Settings -> Paywall
- Widget: Small (progress ring), Medium (progress + recent logs), Lock Screen (progress ring)
- Watch: Complication (progress ring), Watch app (log + progress)
- Features: Custom daily goal, reminders, HealthKit sync, weekly summary
- Free tier: Basic tracking, 1 widget
- Premium ($3.99/month or $29.99/year): All widgets, Watch app, analytics, export, custom beverages

**ASO Target**:
- Name: "AquaLog - Water Tracker" (25 chars, keyword-rich)
- Subtitle: "Hydration & Drink Reminder" (26 chars)
- Keywords: water,tracker,hydration,drink,reminder,health,intake,daily,goal,widget

---

## 8. Operational Playbook Reference

### When Adding a New App to the Portfolio

```
1. Phase 0: Market Research          -> 30-60 min
2. Phase 1: Design                   -> 30-60 min
3. Phase 2: Development              -> 2-6 hours (autonomous)
4. Phase 3: Quality Gate             -> 1-2 hours
5. Phase 4: Submission               -> 1-2 hours
6. [Wait for App Review]             -> 1-3 days
7. Phase 5: Launch Marketing         -> First 2 weeks, $150-300
8. Phase 6: Ongoing Operations       -> Automated + monthly review
```

Total human time per app: **~6-12 hours** over 3 weeks
Total AI autonomous time: **~4-10 hours**
Total cost to launch + first month marketing: **~$200-500**

### When an App Gets Rejected by App Review

Common rejections and autonomous fixes:
1. **Metadata rejection** (keywords, screenshots): Fix via ASC MCP, resubmit
2. **Crashes during review**: Check Sentry, fix, rebuild, resubmit
3. **Missing privacy details**: Update privacy questionnaire via ASC MCP
4. **Guideline 4.2 (minimum functionality)**: Add features, resubmit — may indicate app concept is too thin
5. **Guideline 3.1.1 (IAP required)**: Ensure all digital content uses IAP, not external payment

**If rejected for fundamental design/concept reasons**: Reassess whether the app concept is viable. Don't fight App Review on subjective calls — iterate or kill.

### When Scaling a Successful App

1. **Localization** (highest ROI expansion): Japanese, German, French, Korean, Portuguese (Brazil)
   - Use Claude to translate all metadata + UI strings
   - Localize screenshots via App Store Screenshots skill
   - Add localized keywords via Appeeky
   - Apple Search Ads: create campaigns per country

2. **Feature expansion** based on review mining:
   - Appfigures: extract feature requests from positive reviews
   - Reddit MCP: monitor what competitors lack
   - Prioritize features that increase retention (Day 7, Day 30)

3. **Content multiplication**:
   - Increase TikTok to 2x/day
   - Add YouTube Shorts (same content, slightly re-edited via Creatomate)
   - Start a simple blog on the Carrd site (SEO for long-tail keywords)

---

## 9. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| App Review rejection | Medium | Low | Follow guidelines strictly, iterate quickly |
| Apple changes App Store rules | Low | High | Diversify app types, stay current with WWDC |
| MCP server breaks/disappears | Medium | Medium | Have fallback tools, don't depend on one community server |
| Appeeky shuts down | Low | High | Appfigures as backup ASO tool, manual keyword research |
| TikTok bans account | Medium | Medium | Don't violate ToS, use compliant posting tools, diversify channels |
| Reddit bans for promotion | Medium | Low | Never automate Reddit posting, only monitor |
| Apple Search Ads CPI spikes | Medium | Medium | Set daily budget caps, pause and reassess |
| AI-generated content detected/penalized | Medium | Medium | Add human touches, vary content, don't use obvious AI patterns |
| Market saturated by other AI-built apps | High | Medium | Quality gate enforced, niche down further, speed advantage |

---

## 10. Version History & Notes

- **v1.0** (March 28, 2026): Initial playbook consolidating market research, toolchain analysis, and marketing automation research.
- Next: After first app launch, update with actual performance data and adjust assumptions.

---

*This document is a living reference. Update after each app launch with learnings. The best playbook is the one that reflects reality, not theory.*
