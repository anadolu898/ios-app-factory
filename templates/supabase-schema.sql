-- ============================================================
-- iOS App Factory — Supabase Database Schema
-- Run this in your Supabase SQL Editor to set up portfolio tracking
-- ============================================================

-- Apps table: core registry of all apps in the portfolio
CREATE TABLE apps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    bundle_id TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'development' CHECK (status IN ('development', 'review', 'active', 'scaling', 'maintenance', 'killed')),
    app_store_id TEXT,
    launch_date DATE,
    subscription_monthly_price DECIMAL(6,2),
    subscription_yearly_price DECIMAL(6,2),
    github_repo TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Monthly metrics: revenue, downloads, marketing spend per app
CREATE TABLE monthly_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    app_id UUID REFERENCES apps(id) ON DELETE CASCADE,
    month DATE NOT NULL, -- first of month, e.g. 2026-03-01
    mrr DECIMAL(10,2) DEFAULT 0,
    downloads INTEGER DEFAULT 0,
    marketing_spend DECIMAL(10,2) DEFAULT 0,
    trial_starts INTEGER DEFAULT 0,
    trial_conversions INTEGER DEFAULT 0,
    churned_subscribers INTEGER DEFAULT 0,
    active_subscribers INTEGER DEFAULT 0,
    app_store_rating DECIMAL(2,1),
    avg_cpi DECIMAL(6,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(app_id, month)
);

-- Keyword rankings: daily position tracking
CREATE TABLE keyword_rankings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    app_id UUID REFERENCES apps(id) ON DELETE CASCADE,
    keyword TEXT NOT NULL,
    country TEXT DEFAULT 'US',
    rank INTEGER, -- NULL if not ranked
    difficulty DECIMAL(4,1),
    popularity DECIMAL(4,1),
    tracked_at DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- App reviews: aggregated from Appfigures
CREATE TABLE reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    app_id UUID REFERENCES apps(id) ON DELETE CASCADE,
    external_id TEXT UNIQUE, -- Appfigures review ID
    stars INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
    title TEXT,
    body TEXT,
    author TEXT,
    country TEXT,
    version TEXT,
    sentiment TEXT CHECK (sentiment IN ('positive', 'neutral', 'negative')),
    response TEXT, -- our drafted response
    responded BOOLEAN DEFAULT FALSE,
    review_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Marketing campaigns: Apple Search Ads + social
CREATE TABLE campaigns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    app_id UUID REFERENCES apps(id) ON DELETE CASCADE,
    channel TEXT NOT NULL CHECK (channel IN ('apple_search_ads', 'tiktok', 'twitter', 'reddit', 'product_hunt', 'other')),
    campaign_name TEXT NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed')),
    daily_budget DECIMAL(8,2),
    total_spend DECIMAL(10,2) DEFAULT 0,
    impressions INTEGER DEFAULT 0,
    taps INTEGER DEFAULT 0,
    installs INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    start_date DATE,
    end_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Competitor tracking
CREATE TABLE competitors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    app_id UUID REFERENCES apps(id) ON DELETE CASCADE, -- our app they compete with
    competitor_app_store_id TEXT NOT NULL,
    competitor_name TEXT NOT NULL,
    competitor_bundle_id TEXT,
    last_checked TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Views for quick portfolio overview
CREATE VIEW portfolio_overview AS
SELECT
    a.name,
    a.category,
    a.status,
    a.launch_date,
    m.mrr,
    m.downloads,
    m.marketing_spend,
    m.app_store_rating,
    m.active_subscribers,
    CASE
        WHEN m.marketing_spend > 0 THEN ROUND(m.mrr / m.marketing_spend, 2)
        ELSE NULL
    END as roas,
    CASE
        WHEN m.trial_starts > 0 THEN ROUND(m.trial_conversions::DECIMAL / m.trial_starts * 100, 1)
        ELSE NULL
    END as trial_conversion_pct
FROM apps a
LEFT JOIN monthly_metrics m ON a.id = m.app_id
    AND m.month = DATE_TRUNC('month', CURRENT_DATE)
ORDER BY m.mrr DESC NULLS LAST;

-- Indexes for performance
CREATE INDEX idx_monthly_metrics_app_month ON monthly_metrics(app_id, month);
CREATE INDEX idx_keyword_rankings_app_date ON keyword_rankings(app_id, tracked_at);
CREATE INDEX idx_reviews_app_date ON reviews(app_id, review_date);
CREATE INDEX idx_campaigns_app_status ON campaigns(app_id, status);

-- Row Level Security (enable when ready)
-- ALTER TABLE apps ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE monthly_metrics ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE keyword_rankings ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE competitors ENABLE ROW LEVEL SECURITY;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_apps_updated_at BEFORE UPDATE ON apps
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
