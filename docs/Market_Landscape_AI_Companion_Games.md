# Market Landscape: AI + Companionship Games (August 2026)

Research compiled 2026-08-09 for Project Chill positioning. Sources listed at the bottom.

**Short version:** the genre that is *making money* right now (cozy focus/co-presence games) has almost
no AI in it. The genre that is *raising money* (AI-native companions) has weak retention and is now
under real regulatory pressure in both China and the US. Project Chill sits in the gap between them,
which is a good place to be — but the gap is narrow and one competitor (Chill with You) already owns
the pure non-AI version of our exact pitch.

---

## 1. The four clusters

| Cluster | What it is | Money? | AI? |
|---|---|---|---|
| **A. Cozy focus / co-presence games** | Pomodoro + ambience + a character who works alongside you | **Yes, proven** | Almost none |
| **B. AI-native narrative games** | LLM is the core mechanic; conversation *is* the game | Hype, mixed retention | Total |
| **C. AI companion apps** | Chat/relationship apps, not games | Huge but cooling | Total |
| **D. AI desktop pets / game buddies** | Live2D overlay that watches your screen | Small, cheap | Total |

Project Chill is Cluster A with a *bounded* slice of Cluster B. Nobody credible is standing exactly
there yet.

---

## 2. Cluster A — Cozy focus / co-presence games (our real competitors)

### Chill with You: Lo-Fi Story — **the direct competitor and the direct validation**
- **Dev:** Nestopi (Japan, indie). Character: **Satone**, a girl writing a novel.
- **Theme:** You sit at a virtual desk on a "work call" with Satone. Mix lo-fi music, ambient sound,
  scenery. Story unfolds as you accumulate focus time.
- **AI:** **None.** Fully hand-authored.
- **Stage:** Steam release 2025-11-16. Mobile (iOS/Android) 2026-04-08 with PC cross-progression.
- **Traction:** 100,000+ copies in the first two weeks, 10,000+ peak CCU, **98% Overwhelmingly
  Positive on 9,600+ reviews**.
- **Monetization:** Paid on Steam; mobile has a **free ad-supported tier with the first 10 story
  episodes** as the funnel.
- **Marketing:** "your study buddy" / second-monitor framing; cozy creators; Dexerto/press picked it
  up as "hang out with Lofi Girl."
- **Design decisions from their dev interview (important for us):**
  - They **restricted progression strictly to Pomodoro timer usage** — a late change, and they say it
    made the game better. *This is exactly the call we made in `AGENTS.md`.*
  - They deliberately **avoided strong romance** because it made players anxious during work.
  - Satone's personality is deliberately **understated** so she doesn't compete with your work.
  - Her idle actions (typing, reading) are **not player-controlled** — she has her own autonomy layer.

> **Read this as:** our core thesis is validated by a 98%-rated commercial hit. It also means "cozy
> girl works alongside you, focus unlocks story" is no longer a novel pitch on its own.

### Spirit City: Lofi Sessions
- Gamified focus tool: collect "Spirits", customize a room, journal + habit tracker + to-do list.
- **~$4.39M gross revenue** (~$1.3M net), **97% Overwhelmingly Positive on 8,853 reviews**.
- **No LLM AI.** Monetizes via **5 DLC packs and 19 bundles** — the strongest content-economy model
  in the genre.

### Chill Pulse
- Pomodoro + to-do + anime girl at a desk, swappable rooms (retro → cyberpunk).
- **Notable:** ~2,963 Simplified-Chinese reviews vs 517 English, 280 Japanese, 266 Trad-Chinese.
  **The Chinese-language audience for this genre is roughly 5x the English one.**

### On-Together: Virtual Co-Working
- Multiplayer body-doubling: your avatar sits in a shared lounge with strangers/friends doing real
  tasks. GigaPuff / Future Friends Games, released 2026-01-19. PC Gamer coverage.

### Virtual Cottage 2
- **58,000+ wishlists**, releasing 2026. Solo *or* online co-study in a customizable cottage.

### Focus With Luna: Cozy Magic Studies
- 3D magical dorm, weather/lighting control, timer + to-do + journal. Released 2026-05-27.
- Discloses **AI-assisted store art and some in-game alpha masks**. No reviews yet.

### Genre health (from a Feb 2026 Steam analysis of 34 productivity games)
- Only **9 of 34** cleared 500 reviews — quality is the differentiator, not category saturation.
- The author calls the subgenre **undersaturated** vs. e.g. roguelike deckbuilders.
- **What works in marketing:** selling *the fantasy of finally getting your tasks done* (not a feature
  list); **cozy content creators beat streamers**; Polygon/PC Gamer coverage; bundles; a Discord where
  people post their rooms and their wins; visible roadmap + consistent updates.
- **Four positioning archetypes identified:** solo focus companion / gamified habit tracker /
  social body-doubling / **parasocial companionship** (Chill with You is the only one in the last box).

---

## 3. Cluster B — AI-native narrative & companion games

### Whispers from the Star (星之低语) — Anuttacon (Cai Haoyu, ex-miHoYo founder)
- **Theme:** Stella, an astrophysics student, crash-lands on planet Gaia. You are her only contact via
  a communicator — real-time text/voice/video calls.
- **AI:** Dialogue, emotion, and body language generated in **real time**; fully voiced with actor
  collaboration; 100% real-time 3D rendering; **microphone effectively required**. AWS-scaled infra.
- **Stage:** Released 2025-08-14 on Steam + iOS. ~HK$47.
- **Reception:** 80% positive across 1,649 reviews **but "Mostly Negative" in the last 30 days
  (~34%)** — a sharp decay curve.
- **Criticisms that matter to us:** ~1.5s response latency breaking flow; **memory failures that are
  "immersion breaking"**; calls ending unexpectedly; pacing too slow; data-collection concerns.
- **Lesson:** the best-funded, best-looking AI-conversation game in the world still can't hold people
  past the novelty window, and the failure mode is *latency + memory*, not writing quality.

### 共鸣计划 (Resonance Plan) — 灵榫游戏 (LingEn Games, founded 2024)
- **Theme:** AI-native girl-band management. You're the manager; you build a band around a fixed
  protagonist "星音".
- **AI:** Prompt-driven character generation; **character art, expressions, story events, and songs are
  AI-generated at runtime**; characters remember conversations, autonomously schedule team activities,
  and "live autonomously" without the player.
- **Stage:** In development. **Drew long queues at ChinaJoy 2026** — this is likely one of the booths
  you saw.

### 猫仙札 — Tencent
- AI-Agent-driven female-oriented narrative RPG, shown at Tencent's ChinaJoy 2026 booth alongside a
  broader "AI 全家桶" of tools and an AI-native engine.

### AI2U: With You 'Til The End
- Yandere catgirl kidnaps you; you talk your way out. LLM + TTS NPCs in an escape-room structure.
- Early Access 2025-01-23. **89% positive on 1,677 reviews**, ~5 hours long.
- Critics: praised the AI behaviour, **criticised repetitiveness** — the classic AI-game problem of
  a great first hour and a thin second one.

### inZOI "Smart Zoi" — Krafton + NVIDIA ACE
- Life sim CPCs (co-playable characters) running a **Mistral NeMo Minitron 0.5B SLM fully on-device,
  no cloud**. They reason about actions and re-evaluate their behaviour "while sleeping."
- **Relevant because it solves the cost problem**: on-device small models make always-on AI companions
  economically viable in a way cloud API calls do not.

### ChinaJoy 2026 context
- Official theme was effectively "与AI同游" (play alongside AI). The **Next Play** area showed
  **70+ AIGC projects** — AI NPCs, interactive narrative, generative content.
- Reported **86% AI adoption among Chinese game companies**, mostly in production pipelines
  (art, animation, localization) rather than in runtime gameplay.
- Local commentary was openly skeptical — one widely-shared piece argued **~90% of AI games will die**
  because they're tech demos without a business model.

---

## 4. Cluster C — AI companion apps (not games, but they set user expectations)

### 星夜颂歌 (Celestial Reverie) — SingularDance / 奇点摄动 — *the one you asked about*
- **Company:** Founded April 2023, Beijing. Positions itself as a **foundational AI model company**,
  not a game studio — "超人格化" emotional modelling, with stated ambitions in embodied AI and
  "consciousness continuity."
- **Character:** **蕾伊 (Rei)**, a girl from the year 7000. Tsundere, a bit dopey, with an unexplained
  past. 3D.
- **Tech:** Self-developed **GEM model + deep memory system + personality representation engine**.
  They wrote **1M+ words of setting material first, then trained on it.**
- **The differentiating behaviour:** she is *not* always agreeable. She can be sharp-tongued
  ("who told you to slack off"), abruptly change subject ("I dreamt the ship hit a nebula"), **sulk,
  and give you the cold shoulder if you leave without saying goodbye.**
- **Philosophy:** "We want to create an AI life that can accompany you, not provide AI-companionship
  as a service." Their thesis: companionship only works if you believe the other side is real.
- **Stage:** Still in **test-signup / closed testing**. ~2 years of development.
- **Funding:** tens-of-millions RMB angel+ round led by **九合创投 (Unity Ventures)**.
- **Marketing:** founder-led narrative in Chinese tech media (36Kr, Sina Finance), Bilibili content
  showing 蕾伊's daily life, "the company everyone thought had died" underdog framing.

### The Chinese AI-companion app market
- Leaders: **星野 (MiniMax)**, **猫箱 (ByteDance)**, **筑梦岛** (~80% young female users, ~5M
  registered as of Jan 2025). 300+ apps in the category.
- **The market is cooling hard.** Downloads and ad spend both roughly halved / dropped ~80% from the
  2024 peak. Widely-cited forecasts of ¥38.7B (2025) → ¥595B (2028) should be treated as promotional.
- Persistent problem in press coverage: **"擦边" (edging toward suggestive content) is the only reliably
  monetizing behaviour**, which is precisely what the new regulation targets.

### Tolan — Portola (US)
- An **alien** companion, deliberately non-human to sidestep parasocial-romance criticism.
- **3M+ downloads, 100k+ paying users, >$1M/month revenue.** $20M Series A (Khosla / Keith Rabois)
  on top of a $10M seed. $4.99/wk, ~$10/mo, ~$70/yr.
- **The most successful Western AI companion product, and it won by being cute and non-romantic.**

### Grok "Ani" — xAI
- 3D anime companion launched July 2025. Downloads spiked **+40%** on launch day; **revenue only +9%**.
- **Retired 2026-07-24.** Textbook case: AI companions are an install magnet that doesn't convert.

### Character.AI / Replika — the regulatory reckoning
- Character.AI **permanently removed open-ended chat for under-18s** (effective 2025-11-25), added
  age verification via Persona, and **settled multiple wrongful-death lawsuits in early 2026**.
- FTC is probing seven companies. **California and New York have active AI-companion laws.**

### Other funded plays
- **Status** (Fai Nur) — $17M, a social sim where AI companions are your followers.
- **Born / Pengu** — $15M Series A, $25M total, backed by Accel and **Tencent**. AI pet framed as a
  shared project between real friends.

---

## 5. Cluster D — AI desktop pets & game buddies

- **逗逗游戏伙伴 (Doudou)** — Beijing 心影随形. **10M+ users.** Self-built vision-language model
  **LynkSoul V1** reads your game screen and gives tactical advice + emotional reaction. Free +
  paid tiers. *But* its Steam version sits at **58% positive on only 51 reviews with no update in
  16 months* — the mobile/PC-client product is the real business, not the Steam SKU.
- A whole cluster of small Steam SKUs shipped in 2025–2026: **AI Desk Pet** (bring your own
  Gemini/Claude key, can run Python in a sandbox), **AI Desktop Pet** (fully local Live2D, no API key,
  no internet), **Molili AI Friends** (Live2D "Kotonoha"), **Ai Vpet**, **AIKO** (pay-once 3D AI
  girlfriend, 45 personality traits, persistent memory).
- **Two monetization patterns worth noting:** (1) **pay-once + bring-your-own-API-key**, and
  (2) **fully local model, no server cost**. Both are direct answers to the inference-cost problem.

---

## 6. Regulation — this is now a first-class design constraint

### China — 《人工智能拟人化互动服务管理暂行办法》
Issued 2026-04-10 by CAC + 4 ministries; **in force since 2026-07-15**. First regulation in the world
aimed specifically at AI emotional companionship / virtual partners. Scope: any service using AI to
provide **continuous emotional interaction simulating a natural person's personality, thinking, and
communication style** to the public in the PRC. A game with a persistent AI character is in scope.

Key obligations:
- **Providers must not offer virtual-kin or virtual-partner (虚拟亲属、虚拟伴侣) relationships to
  minors at all.**
- Guardian consent required for under-14s for *any* anthropomorphic service.
- Mandatory **minors mode**: mode switching, **periodic "this is not real" reminders**, usage time
  limits, guardian controls to block specific characters and cap spending.
- Must take effective measures to **identify minor users** and switch them, with an appeals channel.
- AI is explicitly positioned as **"assisting humans."** Making **substituting for real social life,
  psychologically controlling users, or inducing addiction** a product goal is prohibited.
- Must build **over-dependency warnings and emotional-boundary guidance**.

Separately, 2026 minors anti-addiction rules tightened to 3-hour limits with AI-based detection and
face verification, with Tencent/NetEase/miHoYo participating in a shared 智瞳守护 scheme.

> **Good news for us:** `AGENTS.md` already says Yua is a *peer, never a supervisor*, that focus is
> optional and never nagged, and that the game should be genuinely useful. A **co-worker** framing is
> materially safer under this rule than a **girlfriend** framing. Keep it that way and write it down.

### US / EU
FTC probe of seven companies; active AI-companion statutes in California and New York; a proposed
federal under-18 ban (Hawley); EU chatbot investigations; Meta age-gating AI personas.

### Steam
- Valve **rewrote its AI disclosure rules on 2026-01-16**: two-tier system, explicit exemptions for
  behind-the-scenes dev-efficiency tools, and **new requirements for games that use live AI generation
  at runtime** — which is us.
- ~**20% of 2025 Steam releases** disclosed AI; **7,300+ games** carry the label as of March 2026.
- Epic, PlayStation, Xbox, and Nintendo still have **no comparable rule**.

---

## 7. Why AI companions keep failing (and what it means for Yua)

Synthesis of the Frisson Labs analysis plus the review data above:

1. **The economics are inverted.** More engagement = higher inference cost. In a game people leave
   running for hours, unbounded chat is a per-user liability. Dialogue trees are cheaper *and* more
   controllable.
2. **Novelty decays fast.** Whispers from the Star: 80% lifetime → 34% recent. Grok Ani: +40%
   installs, +9% revenue, dead in 12 months. AI2U: praised, then "repetitive."
3. **"Helpfulness is not the same thing as personhood."** Unbounded AI characters collapse into
   know-it-all mode or therapist mode. They lack their own goals, refusals, and interruptions.
4. **Memory failure is the #1 immersion killer**, ahead of writing quality.
5. **Latency above ~1s breaks the illusion.**
6. Inworld and Convai had huge GDC buzz in 2023 and **still have no breakout game**.

**Project Chill's existing design already answers 1, 3, and partly 2 and 5:**
- AI is bounded because **Yua is busy with her own work** — that's a *fictional* justification for a
  *technical* limit, which is the single smartest thing in our design doc.
- Progression is deterministic and game-side, so AI can never be the retention mechanic.
- Memory is game-side and persistent, so we don't inherit the LLM's amnesia problem.

That's not a small thing. It's arguably a talk-worthy design thesis, and it should be *foregrounded*
rather than treated as a technical footnote.

---

## 8. Where Project Chill actually sits

```
                     AI is the mechanic
                            ▲
        Whispers from       │       共鸣计划
        the Star            │       AI2U
        星夜颂歌 / 猫箱      │       AI desk pets
                            │
   relationship ◄───────────┼───────────► productivity
   is the point             │             is the point
                            │
        Chill with You      │  ★ PROJECT CHILL (target)
        (parasocial,        │
         no AI)             │  Spirit City / Chill Pulse
                            │  On-Together / Virtual Cottage 2
                            ▼
                     AI is absent
```

The upper-right quadrant — **AI in service of a productivity ritual** — is empty. Everyone with AI is
chasing relationship intensity; everyone chasing productivity has no AI.

---

## 9. Differentiation options, ranked

### 1. Mandarin-first, Chinese-context co-presence (strongest wedge, lowest risk)
Chill Pulse has ~3,000 Simplified-Chinese reviews vs 517 English. Chill with You is Japanese, with a
Japanese character and Japanese study culture. **There is no flagship Chinese-language cozy focus
companion game.** Yua speaking natural Mandarin about 考研 / 论文 / 加班 / 打工人 rhythms is a real,
defensible market position that a Japanese or Western studio cannot easily copy. This also plays well
with the ChinaJoy-adjacent audience you just saw in person.

### 2. AI as *continuity*, never as *conversation*
The one thing nobody has shipped well: an AI layer whose only job is to make the character remember
**your actual life** — the task you named on Tuesday, that you always fade at 3pm, that you came back
after a five-day gap. Cheap (one short call per session boundary, not per message), immune to the
latency problem, and it directly attacks the failure mode (memory) that sank the best-funded competitor.
**Sell "she remembers," not "she chats."**

### 3. Reciprocal stakes — Yua has her own avoidance
Nestopi deliberately made Satone's personality *understated* so she wouldn't compete with your work.
That's a real gap: their character is a pleasant presence with no arc of her own. **Yua half-hiding
from her own creative project, and being pulled back into it by your focus, is a genuinely different
emotional proposition** — a parallel struggle rather than a support NPC. This is already in
`AGENTS.md` and it's the most under-exploited asset we have.

### 4. Don't lead with "AI" in marketing
The money in this genre is in hand-authored warmth; AI labels attract suspicion from exactly the cozy
audience that buys these games (see the Focus With Luna disclosure, and the general Steam AI backlash).
Disclose honestly per Valve's runtime-AI rules, but **position as "a focus companion with a story,"
not "an AI girlfriend."**

### 5. Deliberately *not* pursued
- **Multiplayer body-doubling** (On-Together, Virtual Cottage 2) is the other growth vector, but it
  breaks the intimate 1:1 call framing. Skip.
- **Romance** — Nestopi found it makes players anxious during work, and it is the exact thing Chinese
  regulation now polices. Peer framing is both better design and better compliance.

---

## 10. Concrete risks to plan around

| Risk | Severity | Mitigation already in our design |
|---|---|---|
| Chill with You's head start (mobile, 9.6k reviews, cross-progression) | High | Language/market wedge + Yua's own arc |
| Inference cost on a game left running for hours | High | Bounded AI; session-boundary calls only; consider local SLM later |
| Chinese AI-companion regulation (in force since 2026-07-15) | High if shipping in CN | Peer framing, no romance, no dependency mechanics — but we still need a minors mode and dependency guardrails written into the spec |
| Steam runtime-AI disclosure (rewritten 2026-01-16) | Medium | Straightforward; just needs doing correctly at store-page time |
| Novelty decay (the Whispers/Ani curve) | Medium | Deterministic authored story is the retention engine, not the AI |
| "AI" as a marketing liability with cozy audiences | Medium | Lead with story + focus, disclose plainly |
| Placeholder assets (see `Vertical_Slice_01_Spec.md` §11) | Blocking for Steam | Already tracked |

---

## Sources

- [星夜颂歌 / SingularDance — 老二次元耗时2年，造出会闹脾气的3D AI女友 (知乎)](https://zhuanlan.zhihu.com/p/1942161230363080395)
- [星夜颂歌 融资 — 新浪财经](https://finance.sina.cn/stock/jdts/2025-12-24/detail-inhcwhpr4540375.d.html)
- [SingularDance official site](https://www.singulardance.com.cn/)
- [Whispers from the Star — Steam](https://store.steampowered.com/app/3730100/Whispers_from_the_Star/)
- [Whispers from the Star — Steambase reviews](https://steambase.io/games/whispers-from-the-star/reviews)
- [How Anuttacon scaled AI workloads — AWS](https://aws.amazon.com/blogs/storage/how-anuttacon-scaled-ai-enhanced-gaming-workloads-for-whispers-from-the-star/)
- [共鸣计划 at ChinaJoy 2026 — 新浪财经](https://finance.sina.com.cn/roll/2026-08-03/doc-inikzeat6110942.shtml)
- [ChinaJoy 2026 观察：“与AI同游” — 证券时报](https://www.stcn.com/article/detail/4054067.html)
- [直击ChinaJoy：AI突进、老外涌入、乙女热钱不退 — 36氪](https://www.36kr.com/p/3927937407383943)
- [腾讯游戏 ChinaJoy 2026 AI 展台 — 17173](https://news.17173.com/content/07272026/170152606.shtml)
- [The Rise of Productivity Games on Steam — OP Game Marketing](https://opgamemarketing.substack.com/p/the-rise-of-productivity-games-on)
- [Chill with You: Lo-Fi Story — Steam](https://store.steampowered.com/app/3548580/Chill_with_You__LoFi_Story/)
- [Nestopi interview on building Satone — MonsterVine](https://monstervine.com/2026/04/chill-with-you-lo-fi-story-interview/)
- [Chill with You mobile release — Inven Global](https://www.invenglobal.com/articles/20719/chill-with-you-lo-fi-story-mobile-version-officially-released)
- [Spirit City: Lofi Sessions — Steam](https://store.steampowered.com/app/2113850/Spirit_City_Lofi_Sessions/)
- [Spirit City revenue stats — games-stats.com](https://games-stats.com/steam/game/spirit-city-lofi-sessions/)
- [Chill Pulse — Steam](https://store.steampowered.com/app/2826180/Chill_Pulse/)
- [On-Together: Virtual Co-Working — PC Gamer](https://www.pcgamer.com/games/life-sim/like-going-to-the-office-in-animal-crossing-my-most-productive-work-from-home-experience-this-year-was-spending-all-day-online-in-this-virtual-co-working-game/)
- [Virtual Cottage 2 — Steam](https://store.steampowered.com/app/2943180/Virtual_Cottage_2/)
- [Focus/Chill With Luna — Steam](https://store.steampowered.com/app/4443720/Chill_With_Luna__your_companion/)
- [AI2U: With You 'Til The End — Steam](https://store.steampowered.com/app/2880730/AI2U_With_You_Til_The_End/)
- [AI Desk Pet — Steam](https://store.steampowered.com/app/4417720/AI_Desk_Pet/)
- [AI Desktop Pet — Steam](https://store.steampowered.com/app/4227700/AI_Desktop_Pet/)
- [Molili AI Friends — Steam](https://store.steampowered.com/app/4141770/Molili_AI_Friends_Your_AI_Desk_Pal/)
- [逗逗游戏伙伴 — Steam](https://store.steampowered.com/app/2715220/Doudou_Companion/)
- [逗逗AI 千万用户 — 东方财富](https://caifuhao.eastmoney.com/news/20250822100416931232230)
- [inZOI Smart Zoi / NVIDIA ACE — VentureBeat](https://venturebeat.com/gaming-business/krafton-and-nvidia-team-up-to-create-smarter-ai-characters-for-pubg-and-inzoi/)
- [inZOI first game with NVIDIA ACE — DSOGaming](https://www.dsogaming.com/news/inzoi-is-the-first-game-with-ai-powered-npcs-using-nvidia-ace/)
- [AI社交下载量暴跌八成 — 虎嗅](https://m.huxiu.com/article/4532115.html)
- [星野、猫箱 AI社交热 — 每日经济新闻](https://www.nbd.com.cn/articles/2025-07-04/3933446.html)
- [Tolan raises $20M — GeekWire](https://www.geekwire.com/2025/ai-companionship-app-tolan-raises-20m-to-help-more-people-grow-with-a-virtual-alien-friend/)
- [Grok companions retired — Robo Rhythms](https://www.roborhythms.com/grok-companions-discontinued/)
- [Character.AI bans teens amid lawsuits — AOL/CNN](https://www.aol.com/articles/character-ai-bans-teens-talking-182337508.html)
- [人工智能拟人化互动服务管理暂行办法 (全文) — 中央网信办](https://www.cac.gov.cn/2026-04/10/c_1777558395078289.htm)
- [答记者问 — 中央网信办](https://www.cac.gov.cn/2026-04/10/c_1777558395284407.htm)
- [不得向未成年人提供虚拟伴侣 — 上海教育新闻网](https://www.shedunews.sh.cn/guonei/con/2026-04/14/content_30589.html)
- [中国AI拟人化互动服务新规解读 — Lexology](https://www.lexology.com/library/detail.aspx?g=0a96db1d-c25b-473e-b997-23e1255244b7)
- [2026防沉迷新规 — 新浪](https://k.sina.com.cn/article_7879777286_1d5abdc0601901fm48.html)
- [Steam AI disclosure rules 2026 — StraySpark](https://www.strayspark.studio/blog/steam-ai-disclosure-rules-2026-indie-developer-guide)
- [Three years of AI on Steam — Sulka Haro](https://fragwyz.substack.com/p/three-years-of-ai-on-steam)
- [It's 2026… where are all the AI NPCs? — Frisson Labs](https://www.frisson-labs.com/ai-npcs-2026)
- [Status raises $17M / AI-native gaming funding — Fundraise Insider](https://fundraiseinsider.com/blog/recently-funded-gaming-startups/)
