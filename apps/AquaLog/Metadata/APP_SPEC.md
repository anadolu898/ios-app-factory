# AquaLog — App Specification & Research

**Category**: Health & Fitness
**Bundle ID**: com.anadolu898.aqualog
**Status**: Development (awaiting Apple Developer account recovery)
**Created**: 2026-03-28
**Phase**: 2 complete, awaiting Phase 4 (submission)

---

## 1. Market Research

### Keyword Analysis

| Keyword | Volume | Difficulty | Opportunity | Priority |
|---------|--------|------------|-------------|----------|
| water tracker | 82 | 72 | Medium | **Primary — in title** |
| hydration | 82 | 76 | Medium | **Primary — in keywords** |
| drink reminder | 82 | 72 | Medium | **Primary — in subtitle** |
| daily water | 82 | 69 | **Good** | **High — lowest difficulty** |
| water log | 81 | 76 | Medium | In keywords |
| drink water | 82 | 76 | Medium | In keywords |
| water intake | 82 | 90 | Low | In keywords (high diff) |
| water goal | 82 | 87 | Low | In keywords (high diff) |
| hydration app | 57 | 83 | Low | Skip (low volume) |
| water widget | 47 | 73 | Low | Skip (low volume) |

**Key insight**: All top keywords have volume 81-82 and difficulty 69-90. "daily water" (difficulty 69) is the easiest to rank for. Branded competitor terms (waterllama, waterminder) have high volume but we can't target them.

### Long-tail opportunities (lower difficulty)
| Keyword | Volume | Difficulty |
|---------|--------|------------|
| drink ai - hydration tracker | 77 | 60 |
| waterfall: water tracker | 79 | 61 |
| hydratrack: water tracker | 77 | 62 |
| hydra - water drink reminder | 81 | 65 |
| water tracker: hydrio tracker | 77 | 66 |

### Competitor Analysis

#### Top Competitor: Waterllama (id: 1454778585)
- **Rating**: 4.88 (148K reviews) — 2022 App Store Award Winner
- **Est. Revenue**: $183K/day (est. range $55K-$551K)
- **Est. Downloads**: 14.8M lifetime
- **Pricing**: Monthly $3.99, Yearly $9.99, Lifetime $24.99
- **Strengths**: Gamification (100+ characters, challenges, streaks), Apple Design Award, 22 languages, massive review count
- **Weaknesses**: Complex (too many features for simple users), 298MB app size, premium feels expensive for what it offers
- **What we can exploit**: Simplicity — many users want "just track water, no llamas"

#### Top Competitor: WaterMinder (id: 653031147)
- **Rating**: 4.75 (32K reviews) — Featured by Apple
- **Est. Revenue**: $40K/day (est. range $12K-$120K)
- **Est. Downloads**: 3.3M lifetime
- **Pricing**: Monthly $2.99, Yearly $14.99-$29.99
- **Strengths**: Cross-platform, Apple Watch, 50+ characters, Siri Shortcuts
- **Weaknesses**: 302MB app size, confusing pricing (multiple yearly tiers), cluttered UI
- **What we can exploit**: Clean minimal design, smaller app, transparent pricing

#### Market Gap Identified
Both top competitors are **feature-heavy and gamified**. There's a segment of users who want:
- Simple, clean water tracking (not a game)
- Fast logging (one-tap)
- Widgets that actually work
- Small app size
- Straightforward pricing

**AquaLog positioning: "The clean, simple water tracker that just works."**

---

## 2. App Store Metadata

### Title (30 chars max)
**AquaLog - Water Tracker** (25 chars)

### Subtitle (30 chars max)
**Hydration & Drink Reminder** (26 chars)

### Keyword Field (100 chars max, comma-separated, no spaces after commas)
```
water,tracker,hydration,drink,reminder,daily,intake,goal,health,log,widget,habit,counter,record,fit
```
(97 chars — uses all high-volume terms, adds "habit", "counter", "record", "fit" to capture adjacent searches)

### Description (4000 chars max)
```
Track your daily water intake with AquaLog — the simple, beautiful hydration tracker designed to help you drink more water and build a healthy habit.

SIMPLE ONE-TAP LOGGING
Log water instantly with quick-add buttons. No complicated setup, no distractions — just tap and track. AquaLog shows your progress with a beautiful animated ring that fills as you hydrate throughout the day.

SMART REMINDERS
Set customizable drink reminders that fit your schedule. Choose your preferred interval and active hours. AquaLog gently nudges you to stay hydrated without being annoying.

BEAUTIFUL WIDGETS
Add hydration progress to your Home Screen and Lock Screen. See your daily progress at a glance without opening the app. Available in small, medium, and circular Lock Screen sizes.

DETAILED HISTORY & CHARTS
Track your hydration over time with weekly bar charts. See daily totals, trends, and which days you hit your goal. Understand your hydration patterns and improve over time.

APPLE HEALTH SYNC
AquaLog reads and writes water intake data to Apple Health, keeping all your health data in one place.

TRACK MORE THAN WATER
Log tea, coffee, juice, and other beverages. Each drink type has its own hydration factor so you get accurate tracking no matter what you drink.

CUSTOMIZABLE GOALS
Set your daily hydration goal based on your needs. Support for both metric (mL/L) and imperial (oz) units.

AQUALOG PRO
Unlock the full experience with AquaLog Pro:
- Detailed analytics and weekly charts
- All widget sizes
- Custom beverages
- Data export
- Smart reminders

Start with a 7-day free trial. Monthly ($3.99/month) or yearly ($29.99/year — save 37%).

Built with privacy in mind. Your data stays on your device and in Apple Health. No accounts required. No ads. Ever.
```

### What's New (for v1.0)
```
Welcome to AquaLog! Start tracking your hydration today.

- Beautiful progress ring dashboard
- Quick-add buttons for instant logging
- Home Screen and Lock Screen widgets
- Weekly hydration charts
- Apple Health integration
- Smart drink reminders
- Dark Mode support
```

### Promotional Text (170 chars, updatable anytime)
```
Stay hydrated with the simplest water tracker. One-tap logging, beautiful widgets, and smart reminders. Start your free trial today.
```

---

## 3. Monetization

| Tier | Price | Trial |
|------|-------|-------|
| Free | $0 | — |
| Monthly | $3.99/mo | 7-day free trial |
| Yearly | $29.99/yr | 7-day free trial |

**Free tier includes**: Basic water tracking, 1 widget (small), daily goal

**Premium includes**: All widgets (small, medium, lock screen), weekly charts, custom beverages, data export, smart reminders, analytics

### RevenueCat Setup
- **Project**: RightBehind (proje6d6c9b3)
- **Entitlement**: `premium` (entla7bdce6b82)
- **Products**: Monthly (prod0ced7dea21), Yearly (prod88e7ecc3da)
- **Offering**: `default` (ofrng9217191b69) with monthly, yearly, lifetime packages
- **Note**: When Apple Developer account is connected, swap generic store identifiers to `com.anadolu898.aqualog.premium.monthly` / `.yearly`

---

## 4. Technical Spec

| Aspect | Value |
|--------|-------|
| **Platform** | iOS 18.0+ |
| **Framework** | SwiftUI + SwiftData |
| **Architecture** | MVVM, @Observable |
| **Concurrency** | Swift 6 strict |
| **App Size** | 2.8 MB (target <50 MB) |
| **Swift Files** | 21 |
| **Lines of Code** | ~2,300 |

### Screens
1. Onboarding (3 pages + goal picker)
2. Dashboard (progress ring, quick-add, drink log)
3. History (weekly chart, daily breakdown)
4. Settings (goal, units, reminders, premium)
5. Paywall (monthly/yearly, feature list, free trial)
6. Add Drink Sheet (custom amount, beverage type)

### Widgets
- Small: Progress ring with percentage
- Medium: Progress ring + amount details
- Lock Screen: Circular gauge

### Integrations
- HealthKit (read/write dietary water)
- StoreKit 2 (subscriptions)
- WidgetKit (3 widget sizes)
- UserNotifications (reminders)

---

## 5. Competitive Positioning

**Tagline**: "The clean, simple water tracker that just works."

**Differentiators vs. Waterllama/WaterMinder**:
1. **10x smaller** (2.8 MB vs 300 MB)
2. **No gamification** — designed for adults who want utility, not characters
3. **Transparent pricing** — two options, clearly stated
4. **Privacy-first** — no accounts, no ads, no tracking
5. **Modern tech** — SwiftUI, SwiftData, iOS 18 features

---

## 6. Launch Plan

### Apple Search Ads (Day 1-3)
- **Discovery Campaign**: $10/day, Search Match ON
- **Exact Match**: Top 5 keywords, $5/day
- Target keywords: "daily water", "drink reminder", "water tracker", "hydration", "water log"
- Kill threshold: CPI > $5.00 after 100 impressions

### Organic (Day 1)
- Reddit post in r/iOSApps (Thursday)
- Product Hunt listing
- Share in r/hydrohomies, r/fitness, r/loseit

### Content (Day 3-7)
- TikTok: "I built a water tracker app" story format
- X/Twitter: Health tips + app mentions via Typefully

### Metrics to Track
| Metric | Target | Kill If |
|--------|--------|---------|
| CPI | < $2.00 | > $5.00 sustained |
| Trial Start Rate | > 40% | < 20% |
| Trial Conversion | > 15% | < 8% |
| Day 7 Retention | > 20% | < 10% |
| Rating | > 4.3 | < 3.5 |
| MRR after 90 days | > $50 | < $50 → kill marketing |

---

## 7. Remaining Tasks

- [ ] Recover Apple Developer account (tomorrow)
- [ ] Set Development Team in Xcode
- [ ] Test widget + StoreKit on simulator
- [ ] Generate app icon (1024x1024)
- [ ] Create App Store screenshots (4 sizes)
- [ ] Connect RevenueCat to App Store Connect
- [ ] Submit to App Review
- [ ] Set up Apple Search Ads campaigns
- [ ] Post to Reddit + Product Hunt
