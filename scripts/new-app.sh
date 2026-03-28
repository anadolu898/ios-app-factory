#!/bin/bash
# ============================================================
# New App Scaffold — Creates a new iOS app project from template
# Usage: ./scripts/new-app.sh <AppName> <BundleID> <Category>
# Example: ./scripts/new-app.sh AquaLog com.anadolu898.aqualog "Health & Fitness"
# ============================================================

set -e

APP_NAME="${1:?Usage: $0 <AppName> <BundleID> <Category>}"
BUNDLE_ID="${2:?Usage: $0 <AppName> <BundleID> <Category>}"
CATEGORY="${3:?Usage: $0 <AppName> <BundleID> <Category>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$PROJECT_ROOT/apps/$APP_NAME"

if [ -d "$APP_DIR" ]; then
    echo "ERROR: App directory already exists: $APP_DIR"
    exit 1
fi

echo "Creating new app: $APP_NAME"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Category: $CATEGORY"
echo "  Directory: $APP_DIR"
echo ""

# Create directory structure
mkdir -p "$APP_DIR/Sources/Views"
mkdir -p "$APP_DIR/Sources/Models"
mkdir -p "$APP_DIR/Sources/ViewModels"
mkdir -p "$APP_DIR/Sources/Services"
mkdir -p "$APP_DIR/Sources/Extensions"
mkdir -p "$APP_DIR/Sources/Resources"
mkdir -p "$APP_DIR/Tests"
mkdir -p "$APP_DIR/Widgets"
mkdir -p "$APP_DIR/Screenshots"
mkdir -p "$APP_DIR/Metadata"

# Create app spec document
cat > "$APP_DIR/Metadata/APP_SPEC.md" << EOF
# $APP_NAME — App Specification

**Category**: $CATEGORY
**Bundle ID**: $BUNDLE_ID
**Status**: Development
**Created**: $(date +%Y-%m-%d)

## Market Research
- Target keywords: (to be filled)
- Competitor weaknesses: (to be filled)
- Revenue model: Subscription

## Feature List (MVP)
1. (to be filled)
2. (to be filled)
3. (to be filled)
4. (to be filled)
5. (to be filled)

## Monetization
- Free tier: (to be filled)
- Premium (\$X.XX/month or \$XX.XX/year): (to be filled)
- Trial: 7 days

## ASO
- App Name: (to be filled, 30 chars max)
- Subtitle: (to be filled, 30 chars max)
- Keywords: (to be filled, 100 chars max)

## Quality Gate
- [ ] Automated checks passed
- [ ] Manual checks passed
- [ ] Marketing authorized
EOF

# Create ASO metadata template
cat > "$APP_DIR/Metadata/aso.json" << EOF
{
  "app_name": "$APP_NAME",
  "bundle_id": "$BUNDLE_ID",
  "category": "$CATEGORY",
  "title": "",
  "subtitle": "",
  "keywords": "",
  "description": "",
  "whats_new": "Initial release",
  "promotional_text": "",
  "support_url": "",
  "privacy_url": "",
  "price_tier": "0",
  "subscription_groups": [],
  "localizations": {
    "en-US": {
      "title": "",
      "subtitle": "",
      "keywords": "",
      "description": ""
    }
  }
}
EOF

echo ""
echo "App scaffold created at: $APP_DIR"
echo ""
echo "Next steps:"
echo "  1. Fill in APP_SPEC.md with market research results"
echo "  2. Create Xcode project: open Xcode -> New Project -> save in $APP_DIR"
echo "     OR use 'claude' to generate the project programmatically"
echo "  3. Follow Phase 1 (Design) from MASTER_PLAYBOOK.md"
echo ""
echo "Directory structure:"
find "$APP_DIR" -type d | sed "s|$PROJECT_ROOT/||" | sort
