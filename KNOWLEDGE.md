# Craft

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
