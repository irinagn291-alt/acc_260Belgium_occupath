# Occupath — Build Specification

> Portfolio app 50, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Paint the path. Hand the token.

| Field | Value |
| --- | --- |
| Product name | Occupath |
| Bundle identifier | `com.occupath.week` |
| Domain | https://occupath.pro |
| Contact URL | https://occupath.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `ocp_` |
| User-Agent | `Occupath/1.0 (iOS; +https://occupath.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Occupath -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

The chart is the occupation.

### 2.1 User flow

1. Open the empty Marey desk for this ISO week — time runs down, distance runs across, no train list.
2. Place a train path on the chart by setting its passing times at mileposts; the desk immediately paints occupation intervals on every single-line block the path uses.
3. A block issues one token. The holder is marked on the occupation; a second train that enters that block lights as a conflict instead of stacking on the same ink.
4. Tap the conflict. The desk offers a meet: the latest departure that returns the token before the second train arrives. Accepting it rewrites the later path on the same chart.
5. A terminal loop is ready only when loop length is at least the shorter train; otherwise the desk stays in exception and will not clear the board.
6. Open Insights from the sidebar for conflict count, token hops, and loop feasibility of the saved working board.
7. Commit the board to the local ledger and start the next ISO week as a new document.

### 2.2 Essential behaviour

- Pinch-zoom Marey surface as the only home: trains are polylines, not rows.
- Occupation intervals computed per single-line block from path + passing times.
- One visible token per block; non-holders cannot occupy.
- Conflict-to-meet apply that rewrites the later path in place.
- loopFeasible iff loopLen >= shorter train, unit-tested.
- Local ledger of working boards keyed by ISO week date.
- Sidebar inspector for the selected train or block; Insights and Settings stay off the chart.

---

## 3. Uniqueness assignment for Occupath

| Axis | Assigned value |
| --- | --- |
| Architecture | **DCI (Data Context Interaction)** |
| UI approach | **SwiftUI hosting a UIView with a CATiledLayer Marey surface** |
| Naming convention | **Railway / working-timetable lexicon** |
| File organization | **By occupation graph (Train, Block, Token, Occupation)** |
| Dependency strategy | **None (zero external dependencies)** |
| Design direction | **Working-timetable graph paper (green ruling, indian ink paths, signal red conflicts)** |
| Typography | **DIN Condensed** |
| Navigation pattern | **Playhead and milepost dual scrubbers** |
| AI art style | **Lithographed working-timetable plate** |
| Functional twist | **Token-block occupation (one token per single-line block)** |
| Persistence | **JSON documents (one file per working timetable)** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — instrument_desk

**Core** — The chart is the occupation.

**Audience** — Heritage-railway volunteers, model railroaders, and amateur working-timetable compilers who already think in Marey graphs and need a pocket desk that refuses an illegal occupation, not a spreadsheet of train names.

**User flow**

1. Open the empty Marey desk for this ISO week — time runs down, distance runs across, no train list.
2. Place a train path on the chart by setting its passing times at mileposts; the desk immediately paints occupation intervals on every single-line block the path uses.
3. A block issues one token. The holder is marked on the occupation; a second train that enters that block lights as a conflict instead of stacking on the same ink.
4. Tap the conflict. The desk offers a meet: the latest departure that returns the token before the second train arrives. Accepting it rewrites the later path on the same chart.
5. A terminal loop is ready only when loop length is at least the shorter train; otherwise the desk stays in exception and will not clear the board.
6. Open Insights from the sidebar for conflict count, token hops, and loop feasibility of the saved working board.
7. Commit the board to the local ledger and start the next ISO week as a new document.

**Essential features**

- Pinch-zoom Marey surface as the only home: trains are polylines, not rows.
- Occupation intervals computed per single-line block from path + passing times.
- One visible token per block; non-holders cannot occupy.
- Conflict-to-meet apply that rewrites the later path in place.
- loopFeasible iff loopLen >= shorter train, unit-tested.
- Local ledger of working boards keyed by ISO week date.
- Sidebar inspector for the selected train or block; Insights and Settings stay off the chart.

**Twist** — Token-block occupation. A single-line block issues exactly one token. Painting two trains on the same interval is not a red overlay on a valid chart — the second train is refused until the holder returns the token. Tapping the conflict offers a meet that transfers the token and rewrites the later path, so the verb on home is take-or-hand-the-token, not edit-a-row.

**Why this is not a repeat** — Clickface is a tap-on-face group ellipse that yields clicks. Washfolio paints a 365-cell year. LeafLedger is a food-tracker carbon budget. Restante locks a want to payday. This desk is a time-distance chart whose unit of work is occupation of a single-line block. Home is the Marey, not a timetable table (the catalog fake). The new verb is take or hand a block token; meet-apply rewrites the path on the same surface. Screens, daykey, typography and search_api are leftover catalog values; the exhausted unique axes are new labels that do not fold onto PAC, Functional Core, Document-View, Clockmaker, payday calendar, or locked-canvas chrome.

### 3.0a Craft from the shipped portfolio

These rules come from apps that already shipped. Follow them. Do not copy their type names or layouts.

**Ship these. They are what made the real apps feel finished.**

- Home **is** the mechanic (canvas, rings, tower, wheel, matrix, dial, board, console). A tab plus a list of records is a clone.
- One persisted verb on home. Unit-test that verb. A decorative Game / Aura / Circuit / Nest / Sweep tab is filler — do not ship one.
- Every primary list has an empty state: generated art, one headline, one line, one CTA. Blank `List` fails.
- Simulator seed only, once, behind a versioned key. Never seed on a device.
- Contact URL on Settings (or Goals). App Review looks for it.
- Offline: if the product needs a catalog, a local shelf must catch empty/fail search. A spinner forever fails.
- Denied camera (when used) explains the state and routes to Settings. Silent no-op fails.
- Numbers go through `NumberFormatter`. Day edges use `Calendar.current.startOfDay`.
- One haptic on a successful commit, none on navigation.
- VoiceOver labels on every icon-only control. Colour is never the only signal.

**Review screenshots (21AUG App02–09)**

The running app, not `ImageRenderer`. One launch argument, three keys:

- `-ReviewScreen today` — home after onboarding (often a no-op)
- `-ReviewScreen log` — log / statement / planner
- `-ReviewScreen goals` — goals / targets / profile

Read `ProcessInfo.processInfo.arguments` **once**, **after** onboarding is done.
If onboarding is still showing, the hook never fires.

Companion (Simulator only):

- Seed one demo day behind a versioned key (`{prefix}.demo.v1`).
- Mark onboarding complete in the same seed so the hook is reachable.
- `#if targetEnvironment(simulator)`. Never seed on a device.
- Seed fills the primary surface (four slot posts from the local shelf).

Driver (outside the app): build → install on iPhone and iPad → launch with the
argument → wait until the UI settles → `xcrun simctl io <udid> screenshot`.
Name files `{App}-{today|log|goals}.png`. Pick any available simulator UDID.

**Family `instrument_desk`**
- Home: The desk IS the calculator. If home is a list, you shipped a journal clone.
- Invariant (unit-test this): Pick ONE domain calculator from the desk catalog and unit-test that formula. Theme nouns are not the invariant.
- Empty: The desk is empty. Enter the first measurement.
- Fake that fails: Dashboard / Editor / Charts / Insights with swapped nouns, or a countdown in place of the real math.
- Never: One domain. No generic habit skin.

**Desk `loop_closure` — Cave survey close**
- Home: Depth section + loop report.
- Invariant (unit-test this): Reduce tape/clino/brg → xyz; DFS cycles; distribute −mis*(legLen/total). relativeError=|mis|/total.
- Fake that fails: Station table.

### 3.1 Architecture contract

Data is four value types: Train, Block, Token, and Occupation. A Context binds those objects to roles for one verb and dies when the verb finishes. OccupyBlock, HandToken, ApplyMeet, and LoopCheck are the only Contexts. Interactions run on the roles; views never mutate the graph. SwiftUI starts a Context and redraws the published occupation; there is no ViewModel and no coordinator.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI owns chrome only: the dual scrubbers, the Sidebar detail column, sheets, and empty states. The home surface is a UIView hosted through UIViewRepresentable whose backing layer is a CATiledLayer Marey; time runs down, distance runs across, trains are polylines painted in tiles. Pinch-zoom and occupation ink live in the tiled layer, not in a SwiftUI Path. Meet offers, token marks, and the inspector sit in SwiftUI overlays so VoiceOver can name them without flattening the chart.

### 3.3 Naming contract

Convention: Railway / working-timetable lexicon.

Examples to follow: `PassingTime`, `SingleLineBlock`, `TokenHolder`, `WorkingTimetable`

### 3.4 Dependency contract

Zero SPM packages and no Alamofire. Persistence is local JSON. The leftover search_api value is unused; do not call /cgi/search.pl. Bundle a DIN Condensed face in Resources and list it in UIAppFonts. AVFoundation is not linked for capture.

### 3.5 Navigation contract

Navigation is the playhead (time, vertical) and milepost (distance, horizontal) dual scrubbers on MareyDesk. There is no tab bar of trains and no timetable table. iPad keeps the assigned Sidebar detail column beside the chart; iPhone presents that inspector as a trailing split or sheet while the Marey stays home. WeekLedger and Settings open from the sidebar, never as a list that replaces the chart. Scrubbing is not a haptic; only a successful board commit fires one.

### 3.6 Screen composition contract

Physical screens: MareyDesk, WeekLedger, Settings. Home is MareyDesk, the pinch-zoom CATiledLayer chart; trains are polylines, never a table. The assigned Sidebar detail column inspects the selected train or block and shows conflict count, token hops, and loop feasibility; it is a column, not a tab. WeekLedger is the local list of working boards keyed by ISO week date, each row opening a MareyDesk document. Settings holds the contact-us URL, reset, and re-run onboarding. Do not ship an editor tab, an insights tab, a dashboard, or a charts page; path edits and meet-apply happen on the chart. ReviewScreen today opens MareyDesk after onboarding, log opens WeekLedger, goals opens Settings.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By occupation graph (Train, Block, Token, Occupation)**

```
Occupath/
  Data/Train/
  Data/Block/
  Data/Token/
  Data/Occupation/
  Contexts/OccupyBlock/
  Contexts/HandToken/
  Contexts/ApplyMeet/
  Contexts/LoopCheck/
  Interactions/
  UI/MareySurface/
  UI/Inspector/
  Persistence/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Desk
A first-class screen for **Desk**. Must render empty, populated and error states.

### 5.3 Editor
A first-class screen for **Editor**. Must render empty, populated and error states.

### 5.4 Ledger
A first-class screen for **Ledger**. Must render empty, populated and error states.

### 5.5 Insights
A first-class screen for **Insights**. Must render empty, populated and error states.

### 5.6 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.7 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.8 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Subject** — named per this app's convention.
- **Measurement** — named per this app's convention.
- **Session** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Working-timetable graph paper (green ruling, indian ink paths, signal red conflicts)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#F3EDE0` | Screen background |
| `surface` | `#FAF6EA` | Cards, rows, sheets |
| `ink` | `#1B1914` | Primary text and icons |
| `accent` | `#C0172B` | Primary action, key figure, progress fill |
| `muted` | `#5F6B58` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **DIN Condensed**

DIN Condensed is the only display face: titles, milepost figures, playhead times, and token labels. Body copy and inspector prose use the same family at Regular; never jump above 34pt. If the bundled face is missing, fall back to the system font with condensed width so the plate still reads as a working timetable. All numbers go through NumberFormatter; ISO week edges use Calendar with iso8601, not a handwritten week formula.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **JSON documents (one file per working timetable)**

One Codable JSON document per working timetable, stored in Application Support, keyed by ISO week date (daykey), filename like 2026-W35.json. Each document carries schemaVersion from 1, an in-memory WorkingTimetable as source of truth, and atomic writes off the main thread. Debounce path edits; flush on scenePhase inactive and after commit. Simulator seed once behind ocp.demo.v1, mark onboarding complete in that seed, and paint a legal occupation graph on MareyDesk; never seed on a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Occupath/1.0 (iOS; +https://occupath.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.utilities`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.utilities
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Token-block occupation (one token per single-line block)

Each single-line block issues exactly one Token; occupation is legal only for the holder. A second Train that enters the same interval is a refused Occupation, not a red wash on a valid chart. Tapping the conflict opens a meet: the latest departure that returns the Token before the later Train arrives. Accepting the meet rewrites the later path in place on the Marey surface. loopFeasible is true iff loopLen is at least the shorter Train; the board will not clear while a loop is in exception. Unit-test occupancy overlap and loopFeasible; the home verb is take or hand the token.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Lithographed working-timetable plate**

Base prompt, reused and extended for every asset:

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `ocp_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `ocp_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `ocp_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `ocp_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `ocp_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `ocp_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `ocp_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `ocp_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `ocp_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `ocp_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `ocp_TwistHero` | 1024x1024 | allowed | Hero art for the 'Token-block occupation (one token per single-line block)' feature screen. |
| 11 | `ocp_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `ocp_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`ocp_AppIcon`** — 1024x1024

```
lithographed working-timetable plate filling the canvas, cream rag paper, green ruling, one indian-ink token disc on a single-line block, signal-red edge tick, no text, no letters, no rounded mask, subject inside the centre 80 percent, edge to edge, no drop shadow
```

**`ocp_Splash`** — 1290x2796

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk, a vertical hero composition with a calm, uncluttered centre band
```

**`ocp_Onboarding1`** — 1024x1536

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk, a person or object that is this product in one glance
```

**`ocp_Onboarding2`** — 1024x1536

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk, the primary action of this product, mid-gesture
```

**`ocp_Onboarding3`** — 1024x1536

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk, a later moment when the product has accumulated meaning
```

**`ocp_EmptyHome`** — 1024x1024

```
empty Marey graph paper, time axis down, distance axis across, green ruling, cream plate, no trains, one faint unused token circle, lithograph grain, calm, no text
```

**`ocp_EmptyList`** — 1024x1024

```
empty week ledger folio, lithographed cream plate, green ruling, no rows, one blank ISO-week stamp box, indian ink margin, no text
```

**`ocp_CardBackdrop`** — 1200x800

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk, an abstract backdrop suitable for sitting behind a card
```

**`ocp_ControlFace`** — 512x512

```
round staff-and-ticket token disc, lithographed brass and indian ink, green ruling fragment behind, no letters
```

**`ocp_TwistHero`** — 1024x1024

```
one token changing hands on a single-line block, lithographed plate, indian ink paths, signal-red refused second path, cream paper, no text
```

**`ocp_SuccessMark`** — 512x512

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk, a confirmation mark or celebratory emblem
```

**`ocp_HeaderDecor`** — 1200x600

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk, a wide decorative band or ornament
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `ocp.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `OccupathTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Occupath -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **DCI (Data Context Interaction)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI hosting a UIView with a CATiledLayer Marey surface**.
- [ ] Navigation matches **Playhead and milepost dual scrubbers**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **DIN Condensed** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Occupath
xcodegen generate
xcodebuild -scheme Occupath -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Occupath -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
