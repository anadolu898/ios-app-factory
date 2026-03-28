#!/bin/bash
# ============================================================
# MCP Server Setup — Run after filling in .env with your API keys
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env file not found. Copy .env.template to .env and fill in your keys."
    exit 1
fi

source "$ENV_FILE"

echo "Setting up MCP servers..."

# --- Appeeky (ASO Intelligence) ---
if [ -n "$APPEEKY_API_KEY" ]; then
    claude mcp add-json appeeky "{\"url\":\"https://mcp.appeeky.com/mcp\",\"headers\":{\"Authorization\":\"Bearer $APPEEKY_API_KEY\"}}" 2>&1
    echo "  Appeeky: configured"
else
    echo "  Appeeky: SKIPPED (no API key)"
fi

# --- App Store Connect ---
if [ -n "$ASC_KEY_ID" ] && [ -n "$ASC_ISSUER_ID" ] && [ -n "$ASC_P8_PATH" ]; then
    claude mcp add-json app-store-connect "{\"command\":\"npx\",\"args\":[\"-y\",\"@joshuarileydev/app-store-connect-mcp-server\"],\"env\":{\"APP_STORE_CONNECT_KEY_ID\":\"$ASC_KEY_ID\",\"APP_STORE_CONNECT_ISSUER_ID\":\"$ASC_ISSUER_ID\",\"APP_STORE_CONNECT_P8_PATH\":\"$ASC_P8_PATH\"}}" 2>&1
    echo "  App Store Connect: configured"
else
    echo "  App Store Connect: SKIPPED (missing key ID, issuer ID, or P8 path)"
fi

# --- RevenueCat ---
if [ -n "$REVENUECAT_API_KEY" ]; then
    claude mcp add --transport http revenuecat https://mcp.revenuecat.ai/mcp --header "Authorization: Bearer $REVENUECAT_API_KEY" 2>&1
    echo "  RevenueCat: configured"
else
    echo "  RevenueCat: SKIPPED (no API key)"
fi

# --- Twitter/X ---
if [ -n "$TWITTER_API_KEY" ] && [ -n "$TWITTER_API_SECRET" ]; then
    claude mcp add-json twitter "{\"command\":\"npx\",\"args\":[\"-y\",\"@enescinar/twitter-mcp\"],\"env\":{\"TWITTER_API_KEY\":\"$TWITTER_API_KEY\",\"TWITTER_API_SECRET\":\"$TWITTER_API_SECRET\",\"TWITTER_ACCESS_TOKEN\":\"$TWITTER_ACCESS_TOKEN\",\"TWITTER_ACCESS_SECRET\":\"$TWITTER_ACCESS_SECRET\"}}" 2>&1
    echo "  Twitter: configured"
else
    echo "  Twitter: SKIPPED (no API keys)"
fi

echo ""
echo "Done. Run 'claude mcp list' to verify."
