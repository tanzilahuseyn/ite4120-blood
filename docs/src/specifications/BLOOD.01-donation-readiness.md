# BLOOD.01 · Blood donation information and readiness

> **BLOOD.01** · state **Confirmed** · traces from [BLOOD-US-001](../user-stories/BLOOD-US-001.md)
> · source `backend/src/main/java/ee/taltech/ite4120/blood/`, `backend/src/main/resources/blood/db/changelog/`, `frontend/src/pages/`

## Description

Two things for a prospective blood donor. A **directory of donation centres**:
create, search, view, update, retire (soft delete). A **readiness
questionnaire**: the questions and their advice are content held in the
database and served by the API; the person's answers are evaluated in the
browser. The centre's operator is held as a business registry code only; its
legal name and address are resolved live from the business register through
the operator-registry adapter (imitated by the application in this course,
X-Road-shaped in production — see *The business register* under API).

**Privacy constraint — part of the specification, not an aspiration.** No
table, endpoint, request, log line or browser storage key holds a
questionnaire answer or any other personal data about a donor. The API has no
endpoint that accepts answers. Evaluation is a pure function in the frontend.

Excluded: donor accounts, donation history, appointments, blood stock, medical
screening, editing questions through the UI (they arrive by changeset),
authentication management (mock auth only — the template signs every visitor
in as a mock user, so the public/staff split is stated here but not enforced).

**The questions** come from the Estonian donor criteria, checked 17.10.2026:
Sotsiaalministri määrus nr 65, *Isiku doonoriks sobivuse kriteeriumid,
hindamise tingimused ja kord* (RT I, 22.11.2023, 3; in force 25.11.2023), and
the Estonian Blood Centre's guidance at verekeskus.ee. Twenty yes/no questions:
five about preparation (`ADVISORY`) and fifteen about eligibility today
(`BLOCKING`). Two choices are deliberate:

- **Not asked:** sexual behaviour, HIV, hepatitis and drug use. They exclude
  donors too, but the centre covers them in its confidential interview with
  the doctor (§ 12), and asking here would collect more than necessary.
- **Simplified:** for a tattoo, piercing or procedure the regulation says
  6 months, or 4 with a negative NAT test; the questionnaire uses the Blood
  Centre's public figure of 4 months.

The questionnaire stays guidance: it covers the common reasons people are
turned away, not every rule, and the centre's doctor decides.

**Still open:** the legal and privacy analysis.

## Data model

| Table | Field | Type | Rules |
| --- | --- | --- | --- |
| `blood.region` | `code` PK | text | reference list of regions (counties) |
| | `name` | text | display name |
| `blood.donation_centre` | `id` PK | bigint | from `core.seq_id` |
| | `centre_code` | text | required, ≤50; **unique among active rows** |
| | `name` | text | required, ≤255 |
| | `region_code` | text | required; FK → region |
| | `address` | text | required, ≤255 |
| | `latitude` | numeric(9,6) | optional; −90 … 90 |
| | `longitude` | numeric(9,6) | optional; −180 … 180; given together with latitude or not at all |
| | `opening_hours` | text | optional, ≤255 — free text, e.g. `Mon–Fri 8–16` |
| | `phone` | text | optional, ≤30 |
| | `operator_registry_code` | text | optional; exactly 8 digits — a string, never a number |
| | `sys_*` | — | platform columns, trigger-managed |
| `blood.readiness_question` | `id` PK | bigint | from `core.seq_id` |
| | `question_code` | text | required, ≤50; **unique among active rows** |
| | `category` | text | required; `PREPARATION` or `ELIGIBILITY` |
| | `question_text` | text | required, ≤500 — phrased so it is answered yes or no |
| | `concern_answer` | text | required; `YES` or `NO` — the answer that raises a concern |
| | `severity` | text | required; `ADVISORY` (fixable before going) or `BLOCKING` (do not go today) |
| | `advice` | text | required, ≤1000 — what to do when the concern is raised |
| | `display_order` | int | required; ≥ 0 |
| | `sys_*` | — | platform columns, trigger-managed |

Three tables, one foreign key (`donation_centre → region`). Indexes on the
business tables carry `where (sys_status = 'A')`. Regions are seeded with the
reference table; demo centres arrive under `context:demo`. The readiness
questions are real content and arrive in changeset 04, without a context; it
also retires the placeholder questions the first demo data seeded. There is
deliberately **no** answers table.

## API

| Method + path | Does | Failure answers |
| --- | --- | --- |
| `GET /api/centres` | paged search: `textContains` (name or address), `regionCode`, `limit`, `offset`, `sort` (`name`, `centreCode`) | 400 unknown sort key |
| `GET /api/centres/{id}` | one active centre | 404 |
| `POST /api/centres` | add a centre; answers **201 + Location** | 400 validation · 409 duplicate centre code |
| `PUT /api/centres/{id}` | update; centre code immutable | 400 · 404 |
| `DELETE /api/centres/{id}` | retire (soft) — **204** | 404 |
| `GET /api/centres/{id}/operator` | operator's legal name and address via the registry adapter; **200 with an empty body** when the centre has no operator code or the register does not know it | 404 no such active centre · 502 register down |
| `GET /api/centres/regions` | the reference list | — |
| `GET /api/readiness-questions` | the active questions, by `display_order` | — |

Every error is `application/problem+json`. All endpoints require
`Authorization: Bearer <user>` (mock auth); the contract is live at
`/swagger-ui.html`. No endpoint accepts questionnaire answers.

**Failure policy** for the operator lookup: **fail open** — an unreachable
register answers 502 on the `/operator` endpoint only; the directory and the
questionnaire stay fully usable. Rationale: the operator's legal name is
supporting information; a person looking for where and when to give blood must
never be blocked by it. An organisation the register does not know is a miss
(empty answer), not a failure.

**The business register.** The adapter lives in `blood/operatorregistry/` and
follows `animals/ownerregistry/` file for file: an `OperatorRegistryAdapter`
interface, an HTTP adapter, an X-Road skeleton, and one mapper that turns the
register's wire record into our `OperatorInfo` (`registryCode`, `legalName`,
`address`). In local mode the register is imitated by the application itself:

| Imitated endpoint | Answers |
| --- | --- |
| `GET /mock-registry/companies/{registrikood}` | 200 + wire record `ArCompanyResponse(registrikood, nimi, aadress)` — Estonian field names, not translated · 404 for an unknown code |

It serves three fictional organisations, enough to demonstrate a hit, a miss
and the demo centres. Real organisations' data is not copied into the mock.

## UI

| Screen | Element | Component | Rules |
| --- | --- | --- | --- |
| Centre list `/centres` | table | `ResourceList` | columns: centre code (locked, **a link to the centre's page**), name, region tag (`AppTag`), address, opening hours, phone (hidden by default); search field; row detail panel |
| | add button | `AppButtonPrimary` | navigates to the form |
| | readiness button | `AppButtonSecondary` | navigates to the questionnaire |
| | detail panel | `ResourceList.detailView` | name, address, opening hours, operator name via `/operator`; silently omits it when the register is down |
| Centre page `/centres/{id}` | view / edit | `ResourceForm` + `useDataController` | sections Identity (centre code read-only, name, region) and Location and contact (address, latitude, longitude, opening hours, phone, operator code); Edit → Save is `PUT`, Cancel restores; Retire is the soft `DELETE` with confirmation; Back to the list |
| | operator | `ResourceForm` field, view mode | the registry code plus legal name and address via `/operator`; omitted when the register fails |
| | metadata | `ResourceForm.sidebar` — `AppCard` of `FieldItem`s | created at / by, modified at / by, version |
| Add form `/centres/new` | centre code | `Input` | required, ≤50 |
| | name | `Input` | required, ≤255 |
| | region | `Select` | required, options from `/regions` |
| | address | `Input` | required, ≤255 |
| | latitude, longitude | `InputNumber` | optional; ranges as in the data model; both or neither |
| | opening hours | `Input` | ≤255 |
| | phone | `Input` | ≤30 |
| | operator code | `Input` | pattern `\d{8}` |
| | submit | `AppButtonPrimary` | 400/409 problem text shown verbatim in a notification |
| Questionnaire `/readiness` | notice | `Alert` (antd) | states that this is guidance only, that centre staff make the final decision, and that answers are not sent or stored |
| | questions | `AppCard` per category, `Radio.Group` (Yes / No) per question | questions from `/api/readiness-questions`, in `display_order` |
| | check button | `AppButtonPrimary` | enabled once every question is answered; evaluates in the browser, makes no request |
| | outcome | `Result` (antd) + list of advice | **Ready** — no concern raised; **Prepare first** — only `ADVISORY` concerns; **Not today** — at least one `BLOCKING` concern; the advice of every raised concern is listed |
| | start over | `AppButtonSecondary` | clears the answers; leaving or reloading the page clears them too |

A concern is raised when the answer equals the question's `concern_answer`.
Answers live only in component state — never in `localStorage`,
`sessionStorage`, the URL or a request. The outcome is computed by one pure
function, `evaluateReadiness(questions, answers)` in
`frontend/src/pages/readiness/evaluate.ts`, which the page calls and the
business tests exercise directly.

## Business tests

1. **A centre code is unique among active centres.**
   Given an active centre with code X, when a second centre claims X, then the
   request conflicts (409). And when the first is retired, code X may be used
   again — retirement is a soft delete.
2. **A centre's location is a real coordinate, given whole.**
   Given a request for a centre with latitude 91, when it is added, then it is
   refused with "latitude must be between -90 and 90". And given a latitude
   without a longitude, then it is refused with "latitude and longitude must
   be given together".
3. **The questionnaire serves only active questions, in order.**
   Given three active questions with display orders 2, 1 and 3 and one retired
   question, when the questions are requested, then exactly the three active
   ones are returned, ordered 1, 2, 3.
4. **A centre's region must be a known one.**
   Given a request for a centre with region code `ATLANTIS`, when it is added,
   then it is refused (400) with "unknown region code ATLANTIS".
5. **An operator code is exactly eight digits.**
   Given a request for a centre with operator code `1234567` (seven digits) or
   `1234567A`, when it is added, then it is refused (400) with
   "operatorRegistryCode must be exactly 8 digits".
6. **The outcome follows the most serious concern raised.**
   Given an `ADVISORY` and a `BLOCKING` question: when neither concern is
   raised, then the outcome is *Ready* with no advice; when only the
   `ADVISORY` concern is raised, then it is *Prepare first* with that
   question's advice; when the `BLOCKING` concern is raised, with or without
   the other, then it is *Not today* with the advice of every raised concern.

Tests 1–5 are backend tests next to `AnimalBusinessRulesIT`. Test 6 tests
`evaluateReadiness` directly with **Vitest**, added to the frontend as a dev
dependency for this, since the template has no frontend test runner. It runs
with `npx vitest run`, and CI's frontend job gains that step.

The privacy constraint is verified by inspection rather than by a service
test: the changelog has no table for answers, the API has no endpoint that
accepts them, and the questionnaire page makes no request after loading the
questions (browser network tab, during the manual check before each PR).
