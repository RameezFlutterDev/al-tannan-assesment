# Al Tannan Attendance System

Location-based employee attendance system built for Al Tannan Holding's technical
assessment: an Android mobile app for employees and a web admin panel for HR,
sharing one Firebase project as their only backend.

## Deliverables

| Item | Link |
|---|---|
| Admin panel (live) | https://employee-attendance-altannan.web.app/ |
| Admin panel demo video | https://drive.google.com/file/d/1OPMvjNCpp2GML8ABHnPimojGU72da6oS/view?usp=sharing |
| Mobile app demo video | https://drive.google.com/file/d/1Xl68nvOUqENfT1KUAcm1aKMkuYAy2Bl7/view?usp=drive_link |
| Android APK | https://drive.google.com/file/d/10ZJgSkhgoSAQzYZUbqrqfuT-SemE6V-F/view?usp=sharing |
| Test credentials | Provided separately in the submission email — not committed to this repository |

## Table of contents

- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Data model / database schema](#data-model--database-schema)
- [APIs](#apis)
- [Geofence configuration](#geofence-configuration)
- [Security controls](#security-controls)
- [Location integrity & anti-spoofing](#location-integrity--anti-spoofing)
- [Attendance calculations](#attendance-calculations)
- [Setup instructions](#setup-instructions)
- [Required validation scenarios](#required-validation-scenarios)
- [Known limitations](#known-limitations)
- [Production improvements](#production-improvements)

## Architecture

```
                     ┌───────────────────┐
                     │   Firebase Auth   │  (email/password, both apps)
                     └─────────┬─────────┘
                               │
   ┌───────────────┐   ┌───────▼────────┐   ┌───────────────┐
   │  employee_app  │──▶│ Cloud Firestore│◀──│  admin_panel   │
   │ (Flutter,      │   │  + Security    │   │ (Flutter Web,  │
   │  Android)      │   │  Rules         │   │  hosted)       │
   └───────────────┘   └────────────────┘   └───────────────┘
```

**Firestore Security Rules are the
backend** for this project: every write that matters (attendance check-in/break/
check-out, employee/shift/location management) is gated by rules that run on
Google's servers, not on the client.


- `shared/` — a pure-Dart package (no Flutter/Firebase dependency) holding domain
  models, enums, constants, and the attendance calculation + sequencing logic used
  identically by both apps. Being plain Dart means it has a fast, dependency-free
  unit test suite (17 tests, see `shared/test/`).
- `employee_app/` — Flutter mobile app (Android), GetX for state management and
  routing, feature-first folder structure.
- `admin_panel/` — Flutter Web app, same GetX + feature-first conventions, hosted
  on Firebase Hosting.
- `firestore.rules` / `firestore.indexes.json` — the security/authorization layer
  and query indexes, deployed via the Firebase CLI (`firebase deploy`).




## Tech stack

| Layer | Choice |
|---|---|
| Mobile app | Flutter (Dart), Android target |
| Admin panel | Flutter Web |
| State management / DI / routing | GetX (`update()` + `GetBuilder`, not `.obs`/`Obx`) |
| Auth | Firebase Authentication (email/password) |
| Database | Cloud Firestore |
| Hosting | Firebase Hosting (admin panel) |
| Location | `geolocator` |
| Biometric confirmation | `local_auth` (Check In / Check Out only) |
| Connectivity check | `connectivity_plus` |
| Shared logic | Plain-Dart package (`shared/`), no Firebase dependency |

## Project structure

Both apps follow the same feature-first layout:

```
employee_app/lib/
├─ app/
│  ├─ core/            # services (location, connectivity, biometric), Firestore↔DateTime converters
│  └─ routes/           # GetPage list, auth middleware
├─ data/repositories/    # thin Firestore read/write wrappers
├─ features/
│  ├─ auth/              # login
│  ├─ home/               # today's status dashboard
│  │  └─ widgets/          # AssignmentCard, StatusCard, ActionSection
│  ├─ attendance/          # AttendanceController — the check-in/break/checkout flow
│  └─ history/              # past attendance days
└─ main.dart

admin_panel/lib/            # same app/ + data/ + features/{auth,dashboard,employees,
                             # shifts,locations,attendance_reports}/{controllers,views,widgets}
                             # pattern
```

`shared/lib/src/` holds `models/`, `enums/`, `constants/`, and `utils/`
(calculations, geofence math, the attendance-day state machine) — the single
source of truth both apps and `firestore.rules` are kept in sync with by hand.

## Data model / database schema

Firestore is schemaless, so `firestore.rules` (validation) and this section
(field reference) together serve as the schema documentation the assessment
asks for. Deploying `firestore.rules` + `firestore.indexes.json` via the
Firebase CLI is the closest equivalent to a migration file — it's
declarative, versioned in this repo, and re-applied with one command.

| Collection | Doc ID | Purpose |
|---|---|---|
| `employees` | Firebase Auth UID | Profile, role, active flag, current shift/location assignment |
| `shifts` | auto | Name, start/end (minutes since midnight), grace period, active flag |
| `locations` | auto | Name, lat/lng, geofence radius, `cosLatitude` (see below), active flag |
| `assignments` | auto | Shift+location assignment history per employee (date-ranged; audit trail / optional scheduling bonus) |
| `attendanceEvents` | auto | Immutable log of **every** attendance attempt, accepted or rejected — the required audit trail |
| `attendanceDays` | `{employeeId}_{yyyy-MM-dd}` | One aggregated record per employee per day — what the home screen and admin reports read |

**`employees/{uid}`**: `authUid`, `name`, `email`, `employeeCode`, `isActive`,
`role` (`employee`\|`admin`), `currentShiftId` (nullable), `currentLocationId`
(nullable). `currentShiftId`/`currentLocationId` are nullable so a brand-new
employee (or an admin, who doesn't clock in) can exist before HR assigns them —
attendance actions are blocked until both are set.

**`shifts/{id}`**: `name`, `startMinutes`, `endMinutes`, `graceMinutes`,
`isActive`. Stored as raw minutes-since-midnight integers, not "HH:mm" strings,
so late-minute arithmetic never involves string parsing.

**`locations/{id}`**: `name`, `latitude`, `longitude`, `radiusMeters`,
`isActive`, `cosLatitude`. `cosLatitude` (`cos(latitude in radians)`) is
computed automatically by the admin panel whenever a location's latitude is
set — it's the input `firestore.rules`' geofence check needs, since the rules
language has no trig functions. See [Geofence configuration](#geofence-configuration).

**`attendanceEvents/{id}`**: `employeeId`, `actionType`, `clientTimestamp`,
`serverTimestamp` (`FieldValue.serverTimestamp()`), `latitude`, `longitude`,
`accuracyMeters`, `isMockedClientFlag`, `integrityResult`, `distanceMeters`,
`withinGeofence`, `assignedShiftId`, `assignedLocationId`, `accepted`,
`rejectionReason`. Create-only — rules forbid update/delete, making this an
append-only audit log.

**`attendanceDays/{employeeId_date}`**: `employeeId`, `date`,
`assignedShiftId`, `assignedLocationId`, `state`
(`not_started`\|`checked_in`\|`on_break`\|`completed`), `status`
(`not_started`\|`on_time`\|`late`\|`incomplete`\|`absent`), `checkIn`,
`breaks[]`, `checkOut`, `lateMinutes`, `breakDurationMinutes`,
`grossPresenceMinutes`, `netWorkMinutes`, plus `lastActionLatitude` /
`lastActionLongitude` / `lastActionIsMockedClientFlag` — the most recent
action's coordinates/mock-flag, denormalized here purely so
`firestore.rules` can validate every update (whichever action it is) against
the same three field names.

## APIs

There's no literal REST API — the "endpoints" are Firestore operations, each
authorized by a specific rule:

| Operation | Firestore call | Authorized by |
|---|---|---|
| Employee login | Firebase Auth `signInWithEmailAndPassword` | Firebase Auth itself |
| Check In / Break Out / Break In / Check Out | Batched write to `attendanceEvents` (create) + `attendanceDays` (create/update) | `firestore.rules`: ownership, sequence state machine, geofence, mock-flag, active shift/location |
| Read today's status / history | `attendanceDays` query, `where employeeId ==` | Owner-only read rule |
| Admin: create/edit employee, shift, location | Direct Firestore write | `role == 'admin'` check in rules |
| Admin: daily report / rejected-attempts log | `attendanceDays` / `attendanceEvents` query with filters | Admin-only read rule |

Input validation happens in two places: the Flutter `TextFormField`
validators (immediate UX feedback) and `firestore.rules` (the actual
enforcement — a malicious client bypassing the app entirely and writing to
Firestore directly is still bound by the same rules).

## Geofence configuration

Admins set a location's latitude, longitude, and allowed radius (meters) in
the admin panel. Two distance checks exist, for two different purposes:

1. **Client-side (Haversine, exact)** — `GeoUtils.distanceMeters()` in
   `shared/`. Used for live "you're ~40m from the geofence" UX feedback and to
   decide whether the app should even attempt the write.
2. **Server-side (equirectangular approximation, the actual gate)** —
   `firestore.rules`' `withinGeofence()`. Rules have no trigonometric
   functions, so an exact Haversine isn't possible there. Instead:
   `dx = Δlongitude × cosLatitude × 111320`, `dy = Δlatitude × 110540`,
   compare `dx² + dy²` against `radiusMeters²` — accurate at the tens-to-hundreds-of-meters
   scale a geofence operates at, and avoids needing `sqrt` too. `cosLatitude`
   is precomputed and stored on the location document (see above) since it's
   the one piece of trig this approximation needs.

The client's Haversine check and the rules' approximation will occasionally
disagree by a meter or two right at the radius boundary — the rules' result
is always the one that actually decides acceptance.

## Security controls

- **Authentication**: Firebase Auth (email/password), session tokens managed
  entirely by the Firebase SDK — no custom token handling, no secrets stored
  in app code.
- **Authorization / ownership**: every attendance write requires
  `request.auth.uid == employeeId` on the record being written — an
  authenticated employee can only ever write their own records (assessment
  scenario #12: tampered request for another employee is rejected).
- **Assignment integrity**: the shift/location an action is validated against
  always comes from the caller's own `employees/{uid}.currentShiftId` /
  `currentLocationId` document, read server-side — never from the request
  payload (scenario #4: an employee assigned to another office can't check in
  as if assigned elsewhere).
- **Sequence enforcement**: `firestore.rules`' `isValidStateChange()` only
  allows `not_started → checked_in → (on_break ⇄ checked_in) → completed`
  transitions, rejecting out-of-order or duplicate actions outright
  (scenarios #6, #7, #8) — a retried request that already succeeded fails
  safely rather than double-recording.
- **Active-assignment enforcement**: an admin deactivating a shift or
  location immediately blocks check-ins against it for any employee still
  assigned to it, not just new assignments.
- **Admin authorization**: admin-only collections (`employees` writes,
  `shifts`, `locations`, `assignments`) require
  `employees/{callerUid}.role == 'admin'`, checked server-side.
- **Biometric confirmation**: Check In and Check Out (not the breaks) require
  the device's fingerprint/Face ID/PIN confirmation via `local_auth` before
  the location is even captured — an anti-proxy-checkin layer. No biometric
  data is ever captured, stored, or transmitted by this app; the OS handles
  matching in secure hardware and returns only yes/no.

## Location integrity & anti-spoofing

Computed client-side on every action (`AttendanceController._computeIntegrity`),
stored as `integrityResult` on every `attendanceEvents` record, and
independently re-checked for the fields rules are able to verify (mock flag,
geofence, active assignment):

| Result | Detection | Policy |
|---|---|---|
| `mock_location_detected` | `Position.isMocked` (Android) | **Hard block** |
| `outside_geofence` | Distance > location radius | **Hard block** |
| `impossible_movement` | Implied speed since last accepted action > 200 km/h | **Hard block** |
| `stale_location` | GPS fix's own timestamp is >2 min older than submission time | Flagged, not blocked |
| `low_accuracy` | Reported GPS accuracy worse than 50m | Flagged, not blocked |
| `ok` | None of the above | Accepted |

Flag-not-block for staleness/accuracy is deliberate: weak GPS signal
(elevators, basements, bad weather) is a common, innocent occurrence, and
hard-blocking on it would lock out real employees. Admins can see every
flagged (and every rejected) event in the **Rejected Attempts Log** and each
day's **detail view** in the admin panel — nothing is silently dropped.

**Explicitly not implemented** (documented per the assessment's own
allowance to explain platform limitations):

- **Play Integrity API / App Attest** device attestation — would add genuine
  cryptographic device-trust verification; out of scope for this timeline,
  noted under [Production improvements](#production-improvements).
- **Fake-GPS-app enumeration** — deliberately not attempted, per the
  assessment's own guidance to respect Android/iOS privacy restrictions
  around querying installed apps.

## Attendance calculations

All in `shared/lib/src/utils/attendance_calculations.dart`, unit-tested in
`shared/test/`:

| Metric | Logic |
|---|---|
| Late minutes | `max(0, checkInMinutes − (shiftStartMinutes + graceMinutes))` |
| Break duration | Sum of each closed `breakOut → breakIn` cycle's minutes |
| Gross presence | `checkOut.time − checkIn.time` in minutes |
| Net work | `grossPresence − totalBreakDuration` |
| Status | `completed` → `late` or `on_time` by `lateMinutes`; `not_started` → `not_started`; otherwise `incomplete` |

**Timezone strategy**: shift start/end times are raw minutes-since-midnight,
exactly as typed into the admin panel's time picker — no timezone conversion
is applied anywhere in this comparison. Check-in times use the device's own
local clock. This assumes the admin and employees operate in the same
practical timezone, which holds for a single-location/single-country
deployment like this one. 

## Setup instructions

### Quick start — nothing to install

Everything is already deployed, so the fastest way to review this is:

1. **Admin panel**: open https://employee-attendance-altannan.web.app/ and
   sign in with the admin credentials from the submission email.
2. **Mobile app**: install the [APK](https://drive.google.com/file/d/10ZJgSkhgoSAQzYZUbqrqfuT-SemE6V-F/view?usp=sharing)
   on an Android device, sign in with either test employee's credentials.

No Firebase project, build tools, or local setup required for either of those.

### Running from source (optional)

To run the code locally instead of using the deployed versions:

```bash
# 1. Create a Firebase project → enable Firestore (Native mode) → enable
#    Email/Password sign-in — all on the free Spark plan, no billing needed.

# 2. Register both apps with your project
cd employee_app && flutterfire configure --project=<your-project-id> --platforms=android,web
cd ../admin_panel && flutterfire configure --project=<your-project-id> --platforms=web

# 3. Deploy the security rules + indexes (from the repo root)
cd .. && firebase deploy --only firestore:rules,firestore:indexes --project <your-project-id>

# 4. Run the apps
cd employee_app && flutter run                    # Android device/emulator
cd ../admin_panel && flutter run -d chrome          # local web dev

# 5. Unit tests
cd ../shared && flutter test
```

One manual step is unavoidable: rules require an *existing* admin to create
anything else, so the very first admin account can't be self-service —
create one user in **Authentication → Add user**, then add a matching
`employees/{that user's UID}` document in Firestore with `role: "admin"`
and `isActive: true`. Every other account (employees, shifts, locations) is
created through the admin panel UI from that point on.

### 5. Run the apps

```bash
# Employee app (Android device/emulator)
cd employee_app && flutter run

# Admin panel (local dev)
cd admin_panel && flutter run -d chrome

# Admin panel (production build + deploy)
cd admin_panel && flutter build web --release
cd .. && firebase deploy --only hosting --project <your-project-id>

# Android release APK
cd employee_app && flutter build apk --release
```

### 6. Run the test suite

```bash
cd shared && flutter test
```

## Required validation scenarios

| # | Scenario | How it's satisfied |
|---|---|---|
| 1 | Correct location + before/on shift start | Geofence check passes; `lateMinutes = 0` → status `on_time` |
| 2 | Correct location + after shift start/grace | Geofence passes; `lateMinutes > 0` → status `late`, minutes shown |
| 3 | Outside assigned geofence | `withinGeofence` fails client-side and server-side → hard-blocked, "You are outside your assigned office location." |
| 4 | Employee assigned to another office | Validation always reads the caller's own `currentLocationId` server-side, never trusts the client |
| 5 | Fake/mock location signal | `Position.isMocked` → `mock_location_detected`, hard-blocked, logged with reason |
| 6 | Break Out before Check In | State machine: `breakOut` only valid from `checked_in`; rejected from `not_started` |
| 7 | Break In without active Break Out | State machine: `breakIn` only valid from `on_break` |
| 8 | Duplicate Check In/Check Out | Client pre-checks current state before attempting; rules independently reject any invalid state transition regardless |
| 9 | Permission denied / GPS unavailable | `LocationService` maps every failure mode to a specific actionable message; no write is attempted |
| 10 | Network/API failure | Connectivity checked before any write attempt; batched Firestore write is atomic (all-or-nothing), so no partial/duplicate records |
| 11 | Checkout after one or more breaks | `AttendanceCalculations` sums closed break cycles and subtracts from gross presence — unit-tested |
| 12 | Tampered request for another employee | `employeeId == request.auth.uid` enforced in rules on every write; a forged `employeeId` is rejected regardless of what the client sends |

## Known limitations


- **Calculations are trusted, not re-derived server-side.** `late minutes`,
  `break duration`, `gross`/`net` hours are computed once, consistently, by
  `shared/`'s calculation module and written by the client. 
- **Biometric confirmation is client-side only.** It proves the device's
  unlock credential was used at that moment (anti-proxy-checkin), not
  cryptographically which employee is present — there's no server-side
  attestation of the biometric result.
- **No device/app integrity attestation** (Play Integrity API / App Attest)
  — see [Production improvements](#production-improvements).
- **Date-based scheduling is partially modeled.** The `assignments`
  collection can hold dated shift/location history, but the admin panel only
  edits an employee's *current* assignment; there's no UI yet for scheduling
  a future-dated reassignment.
- **`absent` status isn't automatically computed.** It exists in the status
  enum, but deriving it requires knowing an employee had zero activity on a
  day they should have worked — that needs a scheduled daily job. The admin dashboard computes an
  equivalent count live (`active employees − employees with any activity
  today`) instead of storing it per-record.
- **Offline actions are not queued.** The app detects connectivity before
  attempting a write and shows an explicit "requires network" state rather
  than queuing for later sync.
- **Export is not implemented** (optional per the assessment).

## Production improvements

- Play Integrity API (Android) / App Attest (iOS) for real device attestation.
- Full IANA timezone support (the `timezone` package) if the company ever
  operates across multiple timezones.
- Offline-safe write queue with idempotent later sync.
- Supervisor approval / attendance-correction workflow with its own audit
  trail, and finer-grained admin roles beyond a single `admin` flag.
- CSV/Excel export for reports.
- Automated widget/integration tests beyond `shared/`'s current unit tests.
- Production Android signing config (the release build currently signs with
  the debug key, per the default Flutter scaffold, so `flutter build apk
  --release` runs without extra setup for this assessment).
