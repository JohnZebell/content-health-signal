-- ============================================================
-- Content Health Signal - Score the nurture sequence
-- ============================================================
-- Scores every piece of content in the sequence on engagement and
-- damage, then flags the ones worth reviewing or cutting.
--
-- The key idea: normal content dashboards rank by opens/clicks and
-- miss the pieces that quietly cost you leads. A piece can have an
-- average open rate and still unsubscribe people at several times
-- the normal rate. An unsubscribe is a PERMANENT loss -- you can't
-- nurture that lead back -- so it's weighted heaviest.
--
-- Rates, not raw counts: a high-volume email would rack up the most
-- raw unsubscribes just by volume. What matters is the RATE.
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
scored AS (
    SELECT
        position,
        name,
        ROUND(100.0 * opens  / sent, 1) AS open_rate,
        ROUND(100.0 * clicks / sent, 1) AS click_rate,
        ROUND(100.0 * unsubs / sent, 2) AS unsub_rate,
        -- health score: clicks worth most (real intent), opens some,
        -- unsubscribes penalized 10x (permanent loss)
        ROUND(
            (100.0 * clicks / sent) * 1.5
          + (100.0 * opens  / sent) * 0.5
          - (100.0 * unsubs / sent) * 10.0
        , 1) AS health_score
    FROM piece_stats
)
SELECT
    position,
    name,
    open_rate,
    click_rate,
    unsub_rate,
    health_score,
    CASE
        WHEN unsub_rate  >= 3.0  THEN 'CUT - burning leads'
        WHEN health_score < 15   THEN 'Review - dead weight'
        WHEN health_score < 30   THEN 'Watch'
        ELSE 'Healthy'
    END AS verdict
FROM scored
ORDER BY position;
