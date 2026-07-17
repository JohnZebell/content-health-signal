-- ============================================================
-- Content Health Signal - Baseline-relative check (the honest layer)
-- ============================================================
-- A hardcoded "unsubscribe rate over 3%" is a made-up line. This
-- version measures each piece against the sequence's OWN baseline,
-- so a flag becomes a grounded statement instead of an arbitrary cutoff:
-- "this piece unsubscribes at 5.3x your normal rate", not "over 3%".
--
-- Same discipline as deriving weights from the data rather than
-- guessing them. The multiples (3x / 1.8x) that set the buckets are
-- still chosen starting points a team would tune -- but the baseline
-- comparison itself is data-driven, and it's the real engine.
-- ============================================================

WITH piece_stats AS (
    SELECT
        c.position,
        c.name,
        400.0 AS sent,
        COUNT(*) FILTER (WHERE e.event_type = 'open')        AS opens,
        COUNT(*) FILTER (WHERE e.event_type = 'click')       AS clicks,
        COUNT(*) FILTER (WHERE e.event_type = 'unsubscribe') AS unsubs
    FROM content c
    LEFT JOIN content_events e ON e.content_id = c.id
    GROUP BY c.position, c.name
),
baseline AS (
    SELECT
        SUM(unsubs) / SUM(sent) AS baseline_unsub_rate,
        AVG(opens / sent)       AS baseline_open_rate
    FROM piece_stats
),
scored AS (
    SELECT
        p.position,
        p.name,
        ROUND(100.0 * p.opens  / p.sent, 1) AS open_rate,
        ROUND(100.0 * p.unsubs / p.sent, 2) AS unsub_rate,
        ROUND( (p.unsubs / p.sent) / NULLIF(b.baseline_unsub_rate, 0), 1) AS unsub_vs_baseline,
        ROUND( (p.opens  / p.sent) / NULLIF(b.baseline_open_rate, 0), 2) AS open_vs_baseline
    FROM piece_stats p CROSS JOIN baseline b
)
SELECT
    position,
    name,
    open_rate,
    unsub_rate,
    unsub_vs_baseline,
    open_vs_baseline,
    CASE
        WHEN unsub_vs_baseline >= 3.0 THEN 'CUT - unsubscribes at ' || unsub_vs_baseline || 'x baseline'
        WHEN open_vs_baseline  <  0.5 THEN 'Review - engagement far below sequence norm'
        WHEN unsub_vs_baseline >= 1.8 THEN 'Watch - elevated unsubscribes'
        ELSE 'Healthy'
    END AS verdict
FROM scored
ORDER BY position;
