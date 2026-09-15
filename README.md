# Occupath

Paint the path. Hand the token.

Occupath is a pocket Marey desk for heritage-railway volunteers, model railroaders, and amateur working-timetable compilers. Home is the chart: time runs down, distance runs across, trains are polylines. A single-line block issues one token. A second consist on that interval is refused until the holder returns it. Tapping the conflict offers a meet that rewrites the later path. The desk is also a `loop_closure` calculator: tape, clino and bearing reduce to xyz, cycles are found by DFS, and misclosure is distributed −mis × (legLen / total). relativeError is |mis| / total. The board will not clear while a loop is shorter than the consist.

No account, no ads, no Game tab. The desk is the calculator.

## Architecture

DCI — Data, Context, Interaction.

Data is four value types: `Train`, `SingleLineBlock`, `Token`, and `Occupation`. A Context binds those objects to roles for one verb and dies when the verb finishes. The only Contexts are `OccupyBlock`, `HandToken`, `ApplyMeet`, and `LoopCheck`. Roles play for the life of that Context — Occupier already holds IssuedToken and Block; Surveyor already holds the board. Interaction is the role method (`occupier.take`, `holder.returnToken`, `laterPath.accept`, `traverse.close`, `surveyor.record`), not a ViewModel. SwiftUI starts a Context, adopts the board, and redraws published occupation. Views never mutate the graph.

This fits a working timetable: the legal move is an occupation of a block, not a row edit. A tab plus a list of trains would be a journal clone.

## Token-block occupation

This is why a compiler would pick the desk. Each single-line block issues exactly one token. Occupation is legal only for the holder. Painting two trains on the same interval is not a red wash on a valid chart — the second path is a refused occupation. Tapping the conflict opens a meet: the latest departure that returns the token before the later consist arrives. Accepting the meet hands the token and rewrites the later path on the same plate. `loopFeasible` is true iff loop length is at least the shorter train.

## Design

Working-timetable graph paper: green ruling, indian ink paths, signal-red conflicts. Palette lives in `Assets.xcassets` and is reached only through `PlateInk`: background `#F3EDE0`, surface `#FAF6EA`, ink `#1B1914`, accent `#C0172B`, muted `#5F6B58`. Type is DIN Condensed for every step of a six-step scale (system condensed width if the face is missing). Hard edges. Spacing unit 8 pt. Tap targets 44 pt. Navigation is the playhead and milepost dual scrubbers. Insights stay in the sidebar column, never a tab.

## Art

Style: lithographed working-timetable plate.

Base prompt reused for every asset:

```
lithographed working-timetable plate, cream rag paper, fine green engineer's ruling, indian ink polylines, dry litho grain, signal-red stamp, no lettering, no watermark, square-on plate photograph, light studio, Occupath desk
```

| Image set | Prompt |
| --- | --- |
| `ocp_AppIcon` | lithographed working-timetable plate filling the canvas, cream rag paper, green ruling, one indian-ink token disc on a single-line block, signal-red edge tick, no text, no letters, no rounded mask, subject inside the centre 80 percent, edge to edge, no drop shadow |
| `ocp_Splash` | Base prompt, a vertical hero composition with a calm, uncluttered centre band |
| `ocp_Onboarding1` | Base prompt, a person or object that is this product in one glance |
| `ocp_Onboarding2` | Base prompt, the primary action of this product, mid-gesture |
| `ocp_Onboarding3` | Base prompt, a later moment when the product has accumulated meaning |
| `ocp_EmptyHome` | empty Marey graph paper, time axis down, distance axis across, green ruling, cream plate, no trains, one faint unused token circle, lithograph grain, calm, no text |
| `ocp_EmptyList` | empty week ledger folio, lithographed cream plate, green ruling, no rows, one blank ISO-week stamp box, indian ink margin, no text |
| `ocp_CardBackdrop` | Base prompt, an abstract backdrop suitable for sitting behind a card |
| `ocp_ControlFace` | round staff-and-ticket token disc, lithographed brass and indian ink, green ruling fragment behind, no letters |
| `ocp_TwistHero` | one token changing hands on a single-line block, lithographed plate, indian ink paths, signal-red refused second path, cream paper, no text |
| `ocp_SuccessMark` | Base prompt, a confirmation mark or celebratory emblem |
| `ocp_HeaderDecor` | Base prompt, a wide decorative band or ornament |

## How this is not a repeat

Not a calorie tracker and not a station table. Home is the Marey plus the depth section and loop report. The verb is take or hand a block token; meet-apply rewrites the path on the same surface. Distinct from Clickface (group ellipse), Washfolio (year wash), LeafLedger (food carbon), and Restante (payday lock). No Game tab.

## Build

```bash
cd Occupath
xcodegen generate
xcodebuild -scheme Occupath -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.occupath.week`. Contact: https://occupath.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `ocp.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
