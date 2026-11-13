# Test Design Techniques, UI/UX Standards & CI/CD Quality Gates

Use this reference when designing systematic test cases, auditing UI/UX & mobile compliance, or configuring CI/CD governance pipelines.

---

## 1. ISO/IEC 25010:2023 Quality Model & Shift-Left Alignment

Evaluate software against all **9 product quality characteristics** of ISO/IEC 25010:2023:
1. **Functional Suitability** (completeness, correctness, appropriateness)
2. **Performance Efficiency** (time behavior, resource utilization, capacity)
3. **Compatibility** (co-existence, interoperability)
4. **Interaction Capability** (formerly *Usability*: recognizability, learnability, operability, error protection, user engagement, inclusivity, user assistance)
5. **Reliability** (faultlessness, availability, fault tolerance, recoverability)
6. **Security** (confidentiality, integrity, non-repudiation, accountability, authenticity, resistance)
7. **Maintainability** (modularity, reusability, analyzability, modifiability, testability)
8. **Flexibility** (formerly *Portability*: adaptability, scalability, installability, replaceability)
9. **Safety** (operational/physical hazard identification, risk mitigation, fail-safe behavior, danger warnings, safe integration)

**Methodology Mapping:**
* **TDD (Unit/Domain):** *"Are we building the component right?"* $\rightarrow$ Red-Green-Refactor on pure algorithms, ViewModels, and DDD Aggregates.
* **ATDD (Acceptance/Contract):** *"Are we building the right system?"* $\rightarrow$ Executable acceptance rules agreed before coding.
* **BDD (Workflow/Ubiquitous Language):** *"Does the system behave as business expects?"* $\rightarrow$ `Given-When-Then` living documentation for multi-actor flows.

---

## 2. Systematic Test Case Design (ISTQB CTFL / CTAL-TA v4.0)

Apply these techniques to maximize defect detection without combinatorial explosion:

1. **Equivalence Partitioning (EP) & Boundary Value Analysis (BVA):**
   * Partition valid and invalid input classes; test one representative per partition.
   * For ordered ranges $[L, U]$ (e.g., age $18\text{--}65$):
     * **2-value BVA:** $\{L-1, L\}$ and $\{U, U+1\}$ $\rightarrow$ $\{17, 18, 65, 66\}$.
     * **3-value BVA (high-risk logic):** $\{L-1, L, L+1\}$ and $\{U-1, U, U+1\}$ $\rightarrow$ $\{17, 18, 19, 64, 65, 66\}$.
2. **Decision Table Testing (DTT):**
   * For $N$ interdependent boolean conditions, enumerate the $2^N$ combinations (e.g., $8$ rules for $3$ conditions), collapse don't-care (`-`) entries carefully, and assert exact resulting actions.
3. **State Transition Testing:**
   * Model stateful entities (orders, payments, subscriptions, auth sessions, mobile offline sync queues). Cover all **valid transitions** (0-switch/1-switch) AND explicitly test **invalid/forbidden transitions** (e.g., refunding a cancelled order, capturing an expired auth).
4. **Metamorphic Testing (Oracle-Free Systems):**
   * For search engines, recommenders, simulations, or AI models without a single exact expected output, assert **metamorphic relations** across transformed inputs:
     * *Monotonicity:* Adding a restrictive search filter must yield $|\text{Results}_{\text{filtered}}| \le |\text{Results}_{\text{base}}|$.
     * *Invariance:* Reordering independent filters or whitespace normalization must yield equivalent results.
     * *Symmetry / Round-Trip:* $\text{decode}(\text{encode}(x)) = x$.

---

## 3. Advanced Technical Verification Techniques

| Technique | Defect Class Caught | Representative Tools | Adoption & Cadence |
| :--- | :--- | :--- | :--- |
| **Mutation Testing** | High line coverage with missing or weak assertions ($\text{Score} = \frac{\text{Killed}}{\text{Total} - \text{Equivalent}}$) | **Stryker** (JS/TS/C#/Scala), **PITest** (Java/Kotlin), **mutmut** (Python), **Muter** (Swift) | Critical domain/billing logic; target $\ge 80\%$ (flag $< 60\%$). Run incrementally on PR changed files. |
| **Property-Based Testing (PBT)** | Edge-case crashes, Unicode/empty lists, overflow, broken algebraic invariants | **Hypothesis** (Python), **fast-check** (TS/JS), **Kotest Property** (Kotlin), **SwiftCheck**, **Antithesis** | Pricing engines, financial ledgers, parsers, encoders, state machines. |
| **Deterministic Simulation (DST)** | Distributed consensus races, split-brain, storage corruption under crashes | **TigerBeetle VOPR**, **Antithesis**, **Jepsen** | Storage engines, transactional cores, distributed locks/queues (nightly/release). |
| **Contract Testing (CDC / BDCT)** | Microservice/mobile-BFF API schema drift without deploying full staging clusters | **Pact**, **PactFlow (BDCT)**, **Specmatic** (OpenAPI/GraphQL/AsyncAPI) | Mandatory on every PR for APIs, BFFs, mobile clients, and event producers/consumers. |
| **Trace-Based Testing** | Silent async failures, missing DB/broker side effects, span latency bottlenecks | **OpenTelemetry + Tracetest** | Ephemeral integration environments and production synthetic monitors. |

---

## 4. UI/UX, Accessibility (Web & Mobile) & Performance Standards

### Visual & Snapshot Regression Hierarchy
* **Web Containerized Pixel/SSIM (`Playwright toHaveScreenshot()`, `pixelmatch`, `BackstopJS`):** Deterministic and zero-license-cost; requires pinned Docker browser/font rendering to avoid anti-aliasing noise.
* **Native Mobile Snapshots (`swift-snapshot-testing` on iOS, `Paparazzi` / `Roborazzi` on Android):** Fast, deterministic component rendering across Light/Dark themes, RTL languages, and scaled font sizes.
* **Visual AI / VLM (`Applitools Eyes`, `Percy`, `OverlayQA`, `Wopee.io`):** Semantic DOM/view-tree + vision comparison; essential for AI-generated UIs and ignoring dynamic timestamps/ads.

### Web Accessibility: WCAG 2.2 Level AA (ISO/IEC 40500:2025)
Automated DOM checks (`@axe-core/playwright`) catch only $\approx 30\%\text{--}50\%$ of WCAG criteria (contrast $\ge 4.5:1$ normal text / $\ge 3:1$ large text & UI components, labels, ARIA roles). Explicitly test the **6 new WCAG 2.2 A/AA criteria**:
* **2.4.11 Focus Not Obscured (Minimum, AA):** Tab through all interactive elements verifying sticky headers, cookie banners, or floating chat widgets never completely hide the focused element.
* **2.5.7 Dragging Movements (AA):** Every drag-and-drop interaction (Kanban boards, sliders, map pins) must have a single-pointer click/tap alternative.
* **2.5.8 Target Size (Minimum, AA):** Interactive targets must measure at least $24 \times 24\text{ CSS pixels}$ or maintain compliant spacing.
* **3.2.6 Consistent Help (A):** Support/contact mechanisms remain in the same relative order across pages.
* **3.3.7 Redundant Entry (A):** Multi-step workflows auto-populate or avoid re-asking data already entered in the same session.
* **3.3.8 Accessible Authentication (Minimum, AA):** Login flows must not rely solely on cognitive function tests (puzzles/CAPTCHAs without accessible alternatives or password-manager support).
* **Manual Audits:** Keyboard-only navigation, screen reader pass, $200\% / 400\%$ zoom without horizontal scrolling, and high-contrast modes.

### Native Mobile Accessibility & Vitals (iOS & Android)
* **Touch Target Geometry:** Minimum **$44 \times 44\text{ pt}$** on iOS (Apple HIG) and **$48 \times 48\text{ dp}$** on Android (Material Design), verified via Accessibility Inspector / Accessibility Scanner.
* **Screen Readers & Dynamic Scaling:** Full gesture traversal with **VoiceOver** (iOS) and **TalkBack** (Android), Dynamic Type / font scaling up to $200\%\text{--}300\%$ without text clipping, and `Reduce Motion` compliance.
* **Mobile Performance Budgets:**
  * *Android Vitals:* User-perceived crash rate $< 1.09\%$, user-perceived **ANR** rate $< 0.47\%$, frozen frames ($> 700\text{ ms}$) near $0\%$.
  * *iOS MetricKit:* Cold start $< 400\text{ ms}$ to first frame ($< 1.5\text{ s}$ interactive), main-thread hangs $< 250\text{ ms}$, zero Jetsam OOM kills.

### Web Ergonomics & Core Web Vitals
* **Nielsen's 10 Usability Heuristics:** Visibility of system status, match with real world, user control & freedom, consistency & standards, error prevention, recognition rather than recall, flexibility & efficiency, aesthetic & minimalist design, clear error recovery, contextual help.
* **Core Web Vitals (Field p75 CrUX Thresholds for "Good"):**
  * **LCP** (Largest Contentful Paint) $\le 2.5\text{ s}$
  * **INP** (Interaction to Next Paint) $\le 200\text{ ms}$
  * **CLS** (Cumulative Layout Shift) $\le 0.1$
  * *(Use Lighthouse/WebPageTest in CI as a reproducible lab microscope, never confusing lab scores with 28-day field CrUX data).*

---

## 5. Progressive CI/CD Quality Gates & Executive Governance

| Quality Gate | Trigger & Cadence | Checks & Suites Executed | Automatic Blocking Criteria |
| :--- | :--- | :--- | :--- |
| **Gate 1: Local / IDE** | Pre-commit / local dev | Linters (`SwiftLint`, `Detekt`, `ESLint`), strict typecheck, OpenAPI/AsyncAPI schema lint, pure DDD/ViewModel unit tests, $0.5\text{ s}$ `lavfi` checks | Syntax/type errors, Hexagonal/Clean Architecture boundary violations |
| **Gate 2: Pull Request** | Every push / PR (cached & incremental) | Sociable unit tests, Testcontainers/MSW integration, Pact/Specmatic contracts, incremental Mutation Testing, `@axe-core/playwright`, Web Visual AI & Mobile Snapshots (`Paparazzi` / `swift-snapshot-testing`) | Contract break, mutation score $< 80\%$ on critical modules, automated accessibility or snapshot regressions |
| **Gate 3: Ephemeral / Device Integration** | Pre-merge / PR preview & build artifact (sharded if $> 10\text{ min}$) | Playwright E2E golden paths, Mobile E2E (`Maestro`/`XCUITest`/`Espresso`) on real device cloud, concurrency/idempotency tests, RAG/LLM evals, `ffprobe`/VMAF gates, APK/IPA binary size check | Golden path regression, duplicate payment/charge, binary size budget exceeded, RAG faithfulness or VMAF $p_5$/JND drop |
| **Gate 4: Nightly / Pre-Release** | Scheduled daily / Release Candidate | Full PBT (`Hypothesis`/`Kotest`), DST (`VOPR`), `k6`/`Artillery` load with PII-masked synthetic data, mobile offline/throttling sync chaos, OWASP LLM/Agentic/MASVS security scans & PTaaS | Safety invariant violation, p95/TTFT/cold-start latency regression, unmitigated exploitable vulnerability |
| **Gate 5: Shift-Right / Prod** | Continuous real-time | OpenTelemetry trace synthetic monitors, weighted canary / phased store rollouts ($1\% \rightarrow 5\% \rightarrow 20\% \rightarrow 100\%$), CrUX RUM, Crashlytics / Xcode MetricKit / Android Vitals | Automated canary rollback on Change Fail Rate, ANR ($> 0.47\%$), or crash ($> 1.09\%$) spike + quarterly escaped-defect RCA |

### Governance Metrics (Guard Against Goodhart's Law)
* **DORA 5 Metrics (Never optimize one in isolation):**
  1. *Deployment Frequency*
  2. *Change Lead Time*
  3. *Failed Deployment Recovery Time*
  4. *Change Fail Rate (CFR)* (Elite benchmark $\approx 5\%$)
  5. *Deployment Rework Rate* (unplanned deployments fixing production issues)
* **Defect Escape Rate (DER) & Defect Removal Efficiency (DRE):**
  $$\text{DRE} = \frac{\text{Defects Found Pre-Release}}{\text{Defects Found Pre-Release} + \text{Defects Escaped to Production}} \times 100\%, \quad \text{DER} = 100\% - \text{DRE}$$
  Track DER **segmented by severity (P0–P3)** and environment (`dev`, `staging`, `production`). Target $< 5\%$ DER overall ($\text{DRE} > 95\%$) and $\approx 0\%$ DER on P0 critical business/security invariants.
