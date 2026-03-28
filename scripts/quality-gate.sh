#!/bin/bash
# ============================================================
# Quality Gate — Must pass before any marketing spend
# Usage: ./scripts/quality-gate.sh <app-directory>
# Example: ./scripts/quality-gate.sh apps/AquaLog
# ============================================================

set -e

APP_DIR="${1:?Usage: $0 <app-directory>}"
APP_NAME=$(basename "$APP_DIR")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local description="$1"
    local result="$2"
    if [ "$result" -eq 0 ]; then
        echo -e "  ${GREEN}PASS${NC} $description"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC} $description"
        ((FAIL++))
    fi
}

warn() {
    local description="$1"
    echo -e "  ${YELLOW}WARN${NC} $description"
    ((WARN++))
}

manual_check() {
    local description="$1"
    echo -e "  ${YELLOW}TODO${NC} $description (manual verification required)"
}

echo "============================================"
echo "Quality Gate: $APP_NAME"
echo "============================================"
echo ""

# --- Find Xcode project ---
XCODEPROJ=$(find "$APP_DIR" -maxdepth 2 -name "*.xcodeproj" -type d | head -1)
XCWORKSPACE=$(find "$APP_DIR" -maxdepth 2 -name "*.xcworkspace" -type d | head -1)

if [ -z "$XCODEPROJ" ] && [ -z "$XCWORKSPACE" ]; then
    echo -e "${RED}ERROR: No Xcode project found in $APP_DIR${NC}"
    exit 1
fi

BUILD_TARGET="${XCWORKSPACE:-$XCODEPROJ}"
echo "Project: $BUILD_TARGET"
echo ""

# --- AUTOMATED CHECKS ---
echo "=== Automated Checks ==="

# 1. Build without warnings
echo "Building for iPhone 16 Pro..."
BUILD_OUTPUT=$(xcodebuild -project "$XCODEPROJ" \
    -scheme "$APP_NAME" \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
    -configuration Debug \
    clean build 2>&1)
BUILD_RESULT=$?
check "Builds successfully" $BUILD_RESULT

if [ $BUILD_RESULT -eq 0 ]; then
    WARNING_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "warning:" || true)
    if [ "$WARNING_COUNT" -gt 0 ]; then
        warn "Build has $WARNING_COUNT warnings (target: 0)"
    else
        check "Zero build warnings" 0
    fi
fi

# 2. Run tests
echo "Running tests..."
xcodebuild test -project "$XCODEPROJ" \
    -scheme "$APP_NAME" \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
    -configuration Debug 2>&1 | tail -5
TEST_RESULT=${PIPESTATUS[0]}
check "All tests pass (iPhone 16 Pro)" $TEST_RESULT

# 3. Build for iPhone SE
echo "Building for iPhone SE..."
xcodebuild build -project "$XCODEPROJ" \
    -scheme "$APP_NAME" \
    -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)" \
    -configuration Debug 2>&1 > /dev/null
check "Builds for iPhone SE" $?

# 4. Build for iPad
echo "Building for iPad..."
xcodebuild build -project "$XCODEPROJ" \
    -scheme "$APP_NAME" \
    -destination "platform=iOS Simulator,name=iPad Pro 13-inch (M4)" \
    -configuration Debug 2>&1 > /dev/null
check "Builds for iPad" $?

# 5. App size check
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" -path "*/Debug-iphonesimulator/*" -type d 2>/dev/null | head -1)
if [ -n "$APP_PATH" ]; then
    APP_SIZE_MB=$(du -sm "$APP_PATH" | awk '{print $1}')
    if [ "$APP_SIZE_MB" -lt 50 ]; then
        check "App size < 50MB (actual: ${APP_SIZE_MB}MB)" 0
    else
        check "App size < 50MB (actual: ${APP_SIZE_MB}MB)" 1
    fi
    if [ "$APP_SIZE_MB" -lt 30 ]; then
        echo -e "  ${GREEN}BONUS${NC} App size < 30MB (ideal)"
    fi
else
    warn "Could not find .app bundle to check size"
fi

echo ""

# --- MANUAL CHECKS ---
echo "=== Manual Verification Required ==="
manual_check "Every screen renders correctly on 3+ device sizes"
manual_check "Dark Mode works throughout"
manual_check "Landscape orientation handled (or properly locked)"
manual_check "Paywall displays correctly, purchase flow works"
manual_check "Restore purchases works"
manual_check "Onboarding flow is smooth and concise (< 4 screens)"
manual_check "Empty states are designed (not blank screens)"
manual_check "Error states show helpful messages"
manual_check "Accessibility: VoiceOver labels on all interactive elements"
manual_check "Privacy nutrition labels accurate"
manual_check "App feels native (not a web view, not generic AI aesthetic)"
manual_check "Clear 'aha moment' within 30 seconds"
manual_check "Would you pay for this?"

echo ""
echo "============================================"
echo "RESULTS: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}, ${YELLOW}${WARN} warnings${NC}"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}QUALITY GATE: FAILED${NC}"
    echo "Fix failures before proceeding to marketing."
    exit 1
else
    echo -e "${GREEN}AUTOMATED CHECKS: PASSED${NC}"
    echo "Complete manual checks above before authorizing marketing spend."
    exit 0
fi
