# App Pipeline — Automated Checklist for Each New App

This is the step-by-step process Claude follows for every new app. Each step should be executed and documented in the app's `Metadata/APP_SPEC.md`.

---

## Phase 0: Market Research (30-60 min)

### Step 0.1: Keyword Discovery
```
Tools: Appeeky MCP
Commands:
  - get_keyword_suggestions(term="[primary term]", expand=true, metrics=true)
  - get_keyword_suggestions(term="[secondary term]", expand=true, metrics=true)
  - get_keyword_metrics(keyword="[each candidate]")

Output: Keyword table with volume, difficulty, priority ranking
Target: 15-20 keywords, prioritize difficulty < 70 with volume > 60
```

### Step 0.2: Competitor Analysis
```
Tools: Appeeky MCP
Commands:
  - search_apps(query="[niche]", limit=20)
  - get_app_intelligence(app_id="[top 3 competitors]")
  - get_app_reviews(app_id="[top competitor]", sort_by="mostRecent")
  - aso_competitor_report(app_id="[our app]", competitor_id="[their app]") (post-launch)

Output: Competitor table with ratings, revenue estimates, weaknesses
Key questions:
  - What do 1-star reviews complain about?
  - What do 5-star reviews love (table stakes)?
  - When was the last update? (>6 months = opportunity)
  - What's missing that users ask for?
```

### Step 0.3: Go/No-Go Decision
```
Criteria:
  - ✅ Keyword opportunity exists (volume > 60, difficulty < 80)
  - ✅ Competitors have identifiable weaknesses
  - ✅ Clear monetization path (subscription or one-time)
  - ✅ Buildable in < 6 hours autonomous
  - ❌ Market saturated with strong, recently-updated apps
  - ❌ No search volume
  - ❌ Requires capabilities beyond Tier 1
```

---

## Phase 1: Design (30-60 min)

### Step 1.1: App Spec Document
```
Create apps/[AppName]/Metadata/APP_SPEC.md with:
  - Market research results from Phase 0
  - Feature list (MVP — max 5 core features)
  - Screen list (max 5-7 for MVP)
  - Monetization model
  - ASO metadata (title, subtitle, keywords)
  - Competitive positioning statement
```

### Step 1.2: Architecture
```
Define:
  - SwiftData models
  - View hierarchy
  - Navigation flow
  - Which templates to reuse (PaywallView, OnboardingView, ReviewPrompt)
```

### Step 1.3: Color & Design
```
Set in Assets.xcassets:
  - AccentColor (light + dark variants)
  - SF Pro typography (system default)
  - Max 2-3 accent colors
```

---

## Phase 2: Development (2-6 hours)

### Step 2.1: Project Scaffold
```
Run: ./scripts/new-app.sh [AppName] [BundleID] [Category]
Create Xcode project with xcodegen
Set up: SwiftData models, App entry point, ContentView, MainTabView
Build and verify on simulator
```

### Step 2.2: Core Features
```
Build iteratively — each feature should compile:
  1. Data models + persistence
  2. Main dashboard/home screen
  3. Core value action (the thing users came for)
  4. Onboarding flow (reuse template)
  5. Settings screen
```

### Step 2.3: Monetization
```
  1. Create StoreKit configuration (.storekit file)
  2. Implement StoreManager service
  3. Implement PaywallView (reuse template)
  4. Gate premium features behind StoreManager.shared.isPremium
  5. Add premium section to Settings
```

### Step 2.4: RevenueCat Setup
```
Tools: RevenueCat MCP
Commands:
  - create-entitlement(project_id, lookup_key="premium", display_name="...")
  - create-product(project_id, store_identifier="...", app_id, type="subscription")
  - attach-products-to-entitlement(...)
  - Verify offering has monthly + yearly packages
```

---

## Phase 3: Quality Gate (1-2 hours)

### Step 3.1: Automated
```
Run: ./scripts/quality-gate.sh apps/[AppName]
Must pass:
  - Zero build warnings
  - Tests pass on iPhone 17 Pro, iPhone SE, iPad
  - App size < 50MB
  - Launch time < 2s
```

### Step 3.2: Code Audit
```
Check:
  - No force unwraps outside previews
  - All strings use String(localized:)
  - Accessibility labels on all interactive elements
  - Dark Mode works on every screen
  - No stale type references
  - Swift 6 concurrency compliance
```

### Step 3.3: Manual Verification
```
  - Onboarding flow smooth
  - Paywall displays and purchase works (sandbox)
  - Restore purchases works
  - Empty states designed
  - Error states handled
```

---

## Phase 4: Submission (1-2 hours)

### Step 4.1: App Store Metadata
```
Tools: Appeeky MCP
Commands:
  - aso_validate_metadata(platform="apple", title="...", subtitle="...", keywords="...")
  - aso_suggest_metadata(app_id="...", keywords=[...])

Files to prepare:
  - Metadata/aso.json (all fields)
  - Metadata/APP_SPEC.md (updated with final metadata)
```

### Step 4.2: Screenshots
```
Capture via XcodeBuildMCP:
  - screenshot() on iPhone 17 Pro Max (6.9")
  - screenshot() on iPhone 17 Pro (6.3")
  - screenshot() on iPhone 16e (6.1")
  - screenshot() on iPad Pro 13" (12.9")

Add text overlays via Creatomate or manual design
```

### Step 4.3: Submit
```
  - Set Development Team
  - Archive build
  - Upload via fastlane or Xcode
  - Fill metadata via App Store Connect MCP
  - Submit for review
```

---

## Phase 5: Launch Marketing (Week 1-2, $150-300)

### Step 5.1: Apple Search Ads
```
Day 1:
  - Discovery Campaign: $10/day, Search Match ON
  - Exact Match: Top 5 keywords from research, $5/day, max CPT $1.00
Track: CPI, TTR, conversion rate
Kill: CPI > $5.00 after 100 impressions
```

### Step 5.2: Organic Launch
```
Day 1:
  - Reddit: r/iOSApps (Thursdays), relevant subreddits
  - Product Hunt submission
  - Hacker News Show HN (if technically interesting)

Format: "I built X because Y wasn't solving Z" + screenshots + link
```

### Step 5.3: Social Content
```
Day 3-7:
  - TikTok: 1 video/day (problem→solution, screen recording)
  - X/Twitter: 2-3 posts/day via Typefully
  - Script → ElevenLabs voiceover → Creatomate video
```

---

## Phase 6: Ongoing Operations (Automated)

### Daily
```
  - Keyword rank tracking (Appeeky)
  - Review monitoring (Appfigures)
  - Crash monitoring (Sentry)
  - Revenue tracking (RevenueCat)
```

### Weekly
```
  - Competitor monitoring (Appeeky)
  - ASA keyword optimization
  - Social content creation (3x/week)
```

### Monthly
```
  - Portfolio review: MRR, downloads, marketing spend
  - Kill/scale decision per MASTER_PLAYBOOK.md thresholds
  - Feature update prioritization from reviews
```

---

## File Structure Per App

```
apps/[AppName]/
├── [AppName]/                 # Source code
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   ├── Services/
│   ├── Extensions/
│   ├── Resources/
│   └── Preview Content/
├── [AppName]Tests/
├── [AppName]Widgets/          # If applicable
├── Metadata/
│   ├── APP_SPEC.md            # Research + spec + launch plan
│   └── aso.json               # ASO metadata (machine-readable)
├── Screenshots/               # App Store screenshots
└── project.yml                # xcodegen spec
```
