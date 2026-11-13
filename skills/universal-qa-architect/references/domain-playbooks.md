# Domain-Specific QA Playbooks & Oracles

Load the relevant section below whenever auditing, architecting, or writing tests for one of these specialized domains.

---

## 1. Financial, Banking & Fintech Systems

* **Recommended Topology:** Risk-Based + Classic Pyramid in core ledger domain.
* **Mandatory Monetary Invariants:**
  * **Zero IEEE 754 Floating-Point Math:** Strictly forbid `float`/`double` for currency (e.g., $0.1 + 0.2 = 0.30000000000000004$). Enforce `Money` value objects using integer minor units per **ISO 4217** (test 0-decimal currencies like `JPY`, 3-decimal like `KWD`/`BHD`, and special increments like `CHF` 5 Rappen) or exact `Decimal`/`BigDecimal` with `HALF_EVEN` (Banker's rounding) applied *only* at the end of calculation chains.
  * **Immutable Double-Entry Ledger:** Property-Based Tests (PBT) must verify that $\sum \text{Debits} + \sum \text{Credits} = 0$ per transaction, ledger entries are strictly append-only, and split/allocation logic distributes remainder cents without creating or destroying money.
* **Concurrency, Idempotency & Distributed Sagas:**
  * **Timeout After Capture:** Simulate gateway timeout after successful charge. Verify atomic `Idempotency-Key` uniqueness in DB, payload hash validation (reject key reuse with different amount via HTTP 409/422), transition to `UNKNOWN` (never `FAILED`) without premature ledger posting, and asynchronous reconciliation via derived processor key (`pay_123:charge`) + webhook deduplication.
  * **Double-Spend Prevention:** Run parallel concurrent load tests (e.g., k6) against the same account verifying `SERIALIZABLE` isolation (including transaction retry loops on serialization failure), optimistic locking (`version`), Saga compensation steps for every failure point, and **Transactional Outbox** consistency between DB and message broker.
* **Temporal & Regulatory Oracles:**
  * **Billing & Clocks:** Use virtual test clocks (e.g., Stripe Test Clocks) to fast-forward leap years, trial expirations, renewals, and dunning retries. For high-throughput consensus engines, use Deterministic Simulation Testing (e.g., TigerBeetle VOPR).
  * **ISO 20022 (CBPR+):** Validate MT-to-MX translations (`MT103`/`MT940` $\rightarrow$ `pacs.008`, `pain.001v9`, `camt.053`), enforcing structured address fields (`townName`, `country`) and verifying that field truncation triggers compliance alerts rather than silent reconciliation breaks.
  * **PCI DSS v4.0.1:** Verify zero plaintext PANs in DB/logs (format-preserving tokenization, Req. 3), MFA on CDE access, automated browser payment page script/header tamper detection (Req. 11.6.1), authenticated internal scans, and authenticated business-logic penetration testing (PTaaS) with verified retesting.

---

## 2. Chatbots, Voice Assistants & AI/Agentic Systems

* **Recommended Topology:** Hybrid Testing Trophy + Continuous Statistical Evaluation.
* **Non-Deterministic Evaluation (Oracles as Distributions):**
  * Replace exact string equality with multi-run statistical distributions over curated **Golden Datasets** and production traces (using `DeepEval`, `Ragas`, `Promptfoo`, or `TruLens`).
  * **RAG Triad Separation:** Evaluate *Retriever* independently (`ContextualPrecision`, `ContextualRecall`, `ContextualRelevancy`) from *Generator* (`Faithfulness`, `AnswerRelevancy`, calibrated LLM-as-a-Judge `G-Eval`). Cross-check high faithfulness against human ground truth to catch accurate citations of obsolete documents.
  * **Multi-Turn & Tool Execution:** Measure sliding-window `TurnFaithfulness` and `RoleAdherence`. Assert database/API side effects of tool calls directly rather than trusting conversational confirmations.
* **Voice, WebRTC & Omnichannel E2E:**
  * Use synthetic caller simulators across accents, background noise, and emotional tones.
  * **Latency Budgets:** Measure Time to First Token/Audio ($\text{TTFT} < 1\text{ s}$ typical, $< 2\text{ s}$ p95) and End-of-Turn detection accuracy.
  * **Telephony & Messaging Edge Cases:** Test mid-sentence interruptions (`barge-in`) without context loss, STT transcription error propagation, **DTMF** tone routing over SIP/RTP (RFC 4733), WebRTC/LiveKit room reconnection, strict SMS character/encoding segmentation (smart apostrophes triggering UCS-2 split), and **Human Handoff** with explicit consent and full slot transfer.
* **Generative & Agentic Security Red Teaming:**
  * Run automated adversarial suites (`Garak`, `PyRIT`, `DeepTeam`, `Promptfoo`) on every prompt, tool, or model change covering **OWASP Top 10 for LLMs 2025** (`LLM01` direct/indirect/multimodal prompt injection, `LLM02` sensitive info disclosure, `LLM06` excessive agency, `LLM07` system prompt leakage, `LLM08` vector/embedding weaknesses, `LLM09` misinformation, `LLM10` unbounded consumption) and **OWASP Agentic Applications 2026 (`ASI01`–`ASI10`)** enforcing *Least Agency*.

---

## 3. Audiovisual Production, DAM & Render Pipelines

* **Recommended Topology:** Pipeline Honeycomb + Format/Metadata Contracts.
* **DAM & Production Tracking (Perforce P4 DAM, Autodesk ShotGrid):**
  * Verify exclusive binary file locking against concurrent overwrites, immutable version history rollbacks, territory/window rights-expiration enforcement, and closed-taxonomy metadata schemas (rejecting free-text drift that breaks search).
  * Test DCC Python hooks (`Maya`, `Houdini`, `Nuke`) end-to-end across **Publish** (Alembic/scene export) and **Load** (downstream version resolution) cycles.
* **Deterministic FFmpeg CI/CD:**
  * Pin exact Docker base images shared with production workers and assert `ffmpeg -version` and `ffmpeg -buildconf` at test startup.
  * Generate $0.5\text{ s}$ synthetic video/audio fixtures on the fly via FFmpeg `lavfi` sources for fast unit/filter-graph tests. Inspect container outputs with `ffprobe` (codecs, frame rate, duration, audio tracks) against golden baselines, keeping heavy queue orchestration (`Celery`, `Airflow`) isolated via mocks.
* **SMPTE Timecode & Frame-Rate Math Invariants:**
  * **Drop-Frame (`29.97` / `59.94` fps, semicolon `;`):** Verify that video frames are *never* dropped—only timecode labels `00` and `01` at the start of each minute except every 10th minute:
    $$\text{Actual Frames} = \text{Nominal Frames} - N_{\text{drops}} \times \left(\text{Total Minutes} - \left\lfloor \frac{\text{Total Minutes}}{10} \right\rfloor\right)$$
    where $N_{\text{drops}} = 2$ for $29.97\text{ fps}$ and $4$ for $59.94\text{ fps}$.
  * **Non-Drop & `23.976` fps Caption Drift:** At $29.97\text{ fps}$ Non-Drop (`SMPTE 30`) or cinema $23.976\text{ fps}$ ($24 / 1.001$, which has no SMPTE Drop-Frame standard), $1\text{ hour}$ of wall-clock time ($3600.0\text{ s}$) drifts by **$3.6\text{ seconds/hour}$** ($\approx 43\text{ s}$ in $12\text{ h}$). Unit-test `.scc`/subtitle exporters for explicit time-base compensation to prevent progressive caption drift.

---

## 4. Multimedia, OTT Streaming & Smart TVs

* **Recommended Topology:** Trophy/Honeycomb + Physical Device Matrix.
* **Transport, ABR & Multi-DRM:**
  * Validate unified **CMAF** segments across **HLS** (`.m3u8`) and **MPEG-DASH** (.mpd) under simulated packet loss, bandwidth throttling, and Wi-Fi $\leftrightarrow$ cellular handoffs.
  * For **LL-HLS** ($2\text{--}4\text{ s}$ target latency), audit partial segments, `Preload Hints`, and blocking playlist reloads (`EXT-X-SERVER-CONTROL`) across Safari, `hls.js`, and `ExoPlayer`.
  * Verify **Multi-DRM** license negotiation (`CPIX` / `AWS SPEKE`), **HDCP** enforcement, incognito playback, and encrypted-content $\leftrightarrow$ ad-stitching (**VAST/SSAI**) transitions across **Google Widevine** (`L1` hardware vs `L3` software resolution caps), **Apple FairPlay** (`cbcs`), and **Microsoft PlayReady**.
* **Perceptual Video Quality (VMAF):**
  * Run `libvmaf` / `libvmaf_cuda` (v0.6.1 and banding/color-aware **v1** models) matched to viewing geometry (default 1080p at $3H$, `--phone-model`, or 4K at $1.5H$) after bicubic upscaling to source resolution.
  * Target $93\text{--}100$ for transparent 1080p streaming ($80\text{--}93$ good, $< 60$ encoding failure; Just Noticeable Difference $\text{JND} \approx 6\text{ points}$).
  * **Never gate CI on arithmetic mean alone** (which hides macroblocking spikes on scene cuts): gate on **harmonic mean, 5th percentile ($p_5$), minimum frame score**, and non-overlapping **$95\%$ bootstrap confidence intervals**.
* **Audio Loudness, Lip-Sync & Smart TV Constraints:**
  * Enforce **ITU-R BS.1770** loudness: **EBU R128** ($-23\text{ LUFS}$, max $-1\text{ dBTP}$), **Netflix** ($-27\text{ LKFS} \pm 2\text{ LU}$ dialog-gated, max $-2\text{ dBFS}$ True Peak, verified $5.1 \rightarrow 2.0$ Lo/Ro downmix), or **Spotify/YouTube** ($-14\text{ LUFS}$).
  * Validate A/V **Lip-Sync** within **ITU-R BT.1359-1** ($+90\text{ ms}$ audio lead to $-185\text{ ms}$ audio lag) or broadcast **ATSC IS-191** ($+15\text{ ms} / -45\text{ ms}$) using $240\text{ fps}$ flash-beep capture or optical-acoustic probes across built-in speakers, soundbars, and Bluetooth.
  * Stress-test **Smart TV** runtimes (**Tizen, webOS, Roku, tvOS, Fire TV**) under strict shared RAM quotas and lifecycle suspend/resume transitions.

---

## 5. Distributed, Event-Driven & Serverless Systems

* **Recommended Topology:** Testing Honeycomb + Remocal.
* **Asynchronous & Contract Oracles:**
  * Enforce **contract-first** validation with **AsyncAPI** (`Specmatic` or `Pact` message contracts) in PRs, plus Schema Registry backward/forward compatibility checks (`Avro`/`Protobuf`).
  * Execute integration tests with **Testcontainers** (real Kafka/RabbitMQ/Redis/Postgres) or **Remocal** (local function execution against ephemeral cloud IAM/managed resources).
  * **Silent Failure Prevention:** Replace static waits with bounded polling or WebSocket event sinks asserting eventual convergence within SLA (e.g., $< 5\text{ s}$), monitor **Dead-Letter Queues (DLQs)** for unexpected messages, inject duplicate deliveries (rebalance idempotency) and out-of-order partition events, and assert internal async spans via **OpenTelemetry Trace-Based Testing** (`Tracetest`).

---

## 6. Native Mobile Applications (iOS & Android)

* **Recommended Topology:** Mobile Testing Trophy / Pyramid Hybrid (Fast ViewModel/UseCase unit tests + JVM/Simulator UI & Snapshot tests + Real Device Farm E2E golden paths).
* **Platform Testing Stack & Anti-Flakiness Oracles:**
  * **iOS (Swift / SwiftUI / UIKit):** Use `Swift Testing` (`@Test`, `#expect`) or `XCTest` for pure domain UseCases, ViewModels, and Combine/AsyncSequence streams. Use `XCUITest` (or `Maestro`) for E2E journeys locating elements exclusively via `accessibilityIdentifier` and synchronized via `waitForExistence(timeout:)` (zero `sleep()`). Run `swift-snapshot-testing` across Light/Dark modes, RTL layouts, and Dynamic Type sizes.
  * **Android (Kotlin / Jetpack Compose / Views):** Use `JUnit5`/`Kotest` + `Turbine` (to assert Kotlin `StateFlow`/`SharedFlow` emissions) on ViewModels and repositories. Use `Jetpack Compose UI Testing` (`onNodeWithTag`, `onNodeWithContentDescription`, `waitUntil`) or `Espresso` with custom `IdlingResource` (zero `Thread.sleep()`). Run JVM screenshot tests (`Paparazzi` or `Roborazzi`) in PRs without booting slow emulators.
  * **Real Device Cloud Matrix:** Execute golden E2E suites (`Maestro`, `XCUITest`, `Espresso`, or `Appium 2.x`) on real device farms (`BrowserStack`, `Sauce Labs`, `Firebase Test Lab`) covering OS version fragmentation, low-RAM devices, notches/Dynamic Island insets, and foldable screen posture changes.
* **Offline-First, Sync & OS Lifecycle Chaos:**
  * **Network Chaos:** Test airplane mode toggles, Wi-Fi $\leftrightarrow$ 5G/3G handoffs, high latency/packet loss, and captive portals. Verify local persistence (`SwiftData`/`CoreData`, `Room`/`SQLDelight`), optimistic UI rollback upon HTTP 4xx/5xx rejection, conflict resolution, and idempotent background sync queues (`BGTaskScheduler` / `WorkManager`) preventing duplicate transactions on retry.
  * **Interruptions & Process Death:** Simulate incoming calls/SMS, push notification & Universal Link / App Link routing across **cold start**, **warm start**, and **background** states, OS low-memory process termination (`SavedStateHandle` / `NSUserActivity` state restoration), and biometric/passkey re-authentication prompts (`FaceID`/`TouchID`/`BiometricPrompt`).
  * **Runtime Permissions & Hardware:** Test first-time grant, single denial, permanent denial ("Don't ask again" $\rightarrow$ deep link to OS Settings), and **revoking permissions while the app is backgrounded** (Location precise vs. approximate, Camera, Photos limited picker, Bluetooth, Notifications).
* **Mobile Vitals, Performance & Battery Budgets:**
  * **Android Vitals (Google Play Bad Behavior Thresholds):** Gate releases against user-perceived crash rate $< 1.09\%$, user-perceived **ANR** (Application Not Responding) rate $< 0.47\%$, excessive wakeups, and slow/frozen UI frames ($> 16\text{ ms}$ at $60\text{ Hz}$ or $> 8.3\text{ ms}$ at $120\text{ Hz}$ LTPO displays).
  * **iOS Performance (`Xcode MetricKit` & `XCTMetric`):** Track cold app launch latency ($< 400\text{ ms}$ to first frame / $< 1.5\text{ s}$ interactive), main-thread hang rate ($> 250\text{ ms}$), peak memory footprint (preventing Jetsam OOM terminations), and background CPU/battery drain.
* **Mobile Accessibility & Security (OWASP MASVS / MASTG):**
  * **Native Accessibility:** Audit full screen-reader navigation with **VoiceOver** (iOS) and **TalkBack** (Android), Dynamic Type / font scaling up to $200\%\text{--}300\%$ without text clipping or overlapping controls, minimum touch target geometry of **$44 \times 44\text{ pt}$** (Apple HIG) and **$48 \times 48\text{ dp}$** (Material Design), and `Reduce Motion` compliance.
  * **Mobile Security (`OWASP MASVS`):** Assert zero plaintext secrets, tokens, or PII in `UserDefaults`, `SharedPreferences`, local SQLite DBs, crash dumps, or system logs (`os_log` / `Logcat`); enforce hardware-backed **iOS Keychain** / **Android Keystore**; verify TLS Certificate Pinning (with safe key-rotation fallback), deep-link URI parameter validation (preventing open redirects/intent injection), and binary hardening (`R8`/`ProGuard`, Apple App Attest / Google Play Integrity).
