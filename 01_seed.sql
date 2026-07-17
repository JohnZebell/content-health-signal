-- ============================================================
-- Content Health Signal - Sandbox Seed
-- ============================================================
-- Synthetic marketing-nurture data for demonstrating content health
-- scoring. NOT real data. It exists to prove the method on Postgres.
--
-- Structure mirrors how a real marketing system logs engagement:
--   leads           - the audience
--   content         - the pieces in a nurture sequence, in order
--   content_events  - one row per lead-touches-piece (open/click/unsubscribe)
--
-- The data is shaped so a real pattern exists to find:
--   most pieces are healthy (good opens, low unsubscribes)
--   ONE piece looks fine on opens but unsubscribes at a toxic rate
--     (the hidden killer that normal open-rate dashboards miss)
--   ONE piece is dead weight (almost no engagement, harmless but useless)
--
-- Which pieces are bad is DISCOVERED by the query, not hand-labeled.
-- ============================================================

DROP TABLE IF EXISTS content_events;
DROP TABLE IF EXISTS content;
DROP TABLE IF EXISTS leads;

CREATE TABLE leads (
    id      SERIAL PRIMARY KEY,
    outcome TEXT
);

CREATE TABLE content (
    id       SERIAL PRIMARY KEY,
    position INT,
    name     TEXT
);

CREATE TABLE content_events (
    id          SERIAL PRIMARY KEY,
    lead_id     INT,
    content_id  INT,
    event_type  TEXT,        -- 'open', 'click', 'unsubscribe'
    occurred_at TIMESTAMP
);

INSERT INTO leads (outcome)
SELECT 'engaged' FROM generate_series(1, 400);

INSERT INTO content (position, name) VALUES
(1, 'Welcome email'),
(2, 'Case study roundup'),
(3, 'Product deep-dive'),
(4, 'Industry report'),
(5, 'Hard-sell promo'),        -- hidden killer: fine opens, toxic unsubscribes
(6, 'Customer story'),
(7, 'Webinar invite'),
(8, 'Generic newsletter');     -- dead weight: almost no engagement

-- Healthy pieces: good opens/clicks, normal (~0.8%) unsubscribes
INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'open', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position IN (1,2,3,4,6,7)
WHERE random() < 0.62;

INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'click', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position IN (1,2,3,4,6,7)
WHERE random() < 0.28;

INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'unsubscribe', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position IN (1,2,3,4,6,7)
WHERE random() < 0.008;

-- Piece 5: decent opens, TOXIC unsubscribe rate (the hidden killer)
INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'open', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position = 5
WHERE random() < 0.55;

INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'click', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position = 5
WHERE random() < 0.15;

INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'unsubscribe', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position = 5
WHERE random() < 0.06;

-- Piece 8: low-engagement dead weight, low unsubscribe but does nothing
INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'open', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position = 8
WHERE random() < 0.18;

INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'click', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position = 8
WHERE random() < 0.03;

INSERT INTO content_events (lead_id, content_id, event_type, occurred_at)
SELECT l.id, c.id, 'unsubscribe', NOW() - ((random()*30) || ' days')::interval
FROM leads l JOIN content c ON c.position = 8
WHERE random() < 0.006;
