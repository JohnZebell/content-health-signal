# Content Health Signal
 
Score a nurture sequence by what each email actually does to your audience, and catch the pieces that look fine but are quietly costing you leads.
 
Built and tested on a Postgres sandbox. This is a method demonstrated on synthetic data, not a deployment against a live marketing platform. The value is the approach, not the dataset size.
 
## The idea
 
Most content dashboards rank emails by opens and clicks. That misses the pieces that are actively doing damage. An email can have a perfectly average open rate and still unsubscribe people at several times the normal rate. On an open-rate dashboard it looks healthy. In reality it's your biggest leak.
 
And an unsubscribe is the most expensive outcome a piece of content can cause. It isn't a lead going cold, which you can re-engage later. It's a permanent, irreversible loss of the channel. You can't nurture that lead back. So the piece that quietly drives unsubscribes is costing you leads you already paid to acquire, and normal analytics never flags it.
 
This scores every piece in the sequence on engagement and on damage, weights the permanent losses heaviest, and flags the pieces worth cutting or reviewing.
 
## What it catches
 
It separates three states that a normal dashboard blurs together:
 
- **Healthy** — good engagement, normal unsubscribe rate. Keep it.
- **Dead weight** — almost nobody engages, but it's not driving anyone away. Harmless but useless, taking up a slot. Review it.
- **Burning leads** — looks average on opens, but unsubscribes at a toxic rate. The hidden killer. Cut it.
That third one is the point. It's the piece you'd never catch by looking at opens.
 
## What's in here
 
- `sql/01_seed.sql` — builds three tables (leads, content, content_events, one row per open/click/unsubscribe) and seeds an 8-piece nurture sequence. Most pieces are healthy; one looks fine on opens but unsubscribes at a toxic rate; one is low-engagement dead weight. Which pieces are bad is discovered by the query, not hand-labeled.
- `sql/02_score_content.sql` — scores each piece on engagement and damage (unsubscribes weighted 10x as permanent losses) and flags the sequence.
- `sql/03_baseline_check.sql` — the honest layer. Measures each piece against the sequence's own baseline, so a flag reads as a grounded statement ("unsubscribes at 5.3x baseline") instead of an arbitrary cutoff.
Run the seed once, then either query.
 
## Why rates, not counts
 
A high-volume email racks up the most raw unsubscribes just by being sent more. Ranking on raw counts would blame your most-used email. So everything is a rate per lead who received the piece. What matters is not how many people left, but how often people leave *relative to how often they leave your other emails*. That's what `03_baseline_check.sql` measures, and it's what turns a made-up threshold into a data-grounded one.
 
## Example output (baseline check)
 
| position | name | open_rate | unsub_rate | unsub_vs_baseline | verdict |
|---|---|---|---|---|---|
| 4 | Industry report | 59.5 | 1.00 | 0.7 | Healthy |
| 5 | Hard-sell promo | 54.3 | 7.50 | 5.3 | CUT - unsubscribes at 5.3x baseline |
| 8 | Generic newsletter | 16.0 | 0.50 | 0.4 | Review - engagement far below sequence norm |
 
The Hard-sell promo has a normal open rate, so a standard dashboard would leave it alone. This flags it because it drives people out at 5.3x the rate of a typical email in the sequence. The Generic newsletter isn't toxic, just dead weight, flagged for a different reason.
 
## Honest scope
 
The synthetic data models a clean pattern on purpose, so the bad pieces stand out sharply. Real sequences are noisier and the lines are blurrier. The bucket multiples (3x, 1.8x) are chosen starting points a team would tune against their own norms; the baseline comparison underneath them is the data-driven part and the real engine. The method runs on standard marketing-engagement data (opens, clicks, unsubscribes) that most email and CRM platforms already capture, so the open question in practice is whether that data is clean enough to trust, which is its own audit before any of this runs.
