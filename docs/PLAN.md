# Satisfactory Field Notes - Flutter App Plan

## Vision

A clean, ad-free mobile companion for Satisfactory. Two things in one app: **production planning** (tell me what I need to build X at Y/min) and **session notes** (track what I'm doing right now). The production planner is the killer feature. The notes are the glue that keeps you in the app while playing.

---

## Data Source

**greeny/SatisfactoryTools `data.json`** - pre-parsed from the game's Docs.json, publicly hosted on GitHub.

```
https://raw.githubusercontent.com/greeny/SatisfactoryTools/dev/data/data.json
```

Contains every item, recipe (default + alternates), machine, and rate in clean JSON. Ship a bundled copy in the app for offline use, check for updates on launch.

### Key data structures

**Recipe:**
```json
{
  "slug": "recipe-ironplate-c",
  "name": "Iron Plate",
  "className": "Recipe_IronPlate_C",
  "alternate": false,
  "time": 6.0,
  "ingredients": [{"item": "Desc_IronIngot_C", "amount": 3.0}],
  "products": [{"item": "Desc_IronPlate_C", "amount": 2.0}],
  "producedIn": ["Desc_ConstructorMk1_C"]
}
```

**Rate math:**
```
items_per_min = (60 / recipe.time) * product.amount
buildings_needed = desired_rate / items_per_min
input_rate = buildings_needed * (60 / recipe.time) * ingredient.amount
```

Walk the recipe tree recursively from desired output back to raw ore. That's the entire planner algorithm.

---

## Architecture

```
satisfactory-field-notes/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # MaterialApp, theme, navigation
│   ├── models/
│   │   ├── game_data.dart          # Item, Recipe, Building models
│   │   ├── production_node.dart    # Tree node for planner results
│   │   ├── note_data.dart          # Session, Need, Factory, Scratch models
│   │   └── wiki_result.dart        # Wiki lookup result model
│   ├── services/
│   │   ├── game_data_service.dart  # Load/parse/index data.json
│   │   ├── planner_engine.dart     # Recursive production calculator
│   │   ├── wiki_service.dart       # MediaWiki API (opensearch + parse)
│   │   ├── sync_service.dart       # Postgres API for notes sync
│   │   └── storage_service.dart    # Local fallback (SharedPreferences)
│   ├── screens/
│   │   ├── planner_screen.dart     # Production planner (main feature)
│   │   ├── wiki_screen.dart        # Wiki lookup
│   │   ├── session_screen.dart     # Session tasks
│   │   ├── needs_screen.dart       # Shopping list
│   │   ├── factories_screen.dart   # Factory registry
│   │   └── scratch_screen.dart     # Scratch pad
│   ├── widgets/
│   │   ├── production_tree.dart    # Indented tree list widget
│   │   ├── items_list.dart         # Flat rate summary
│   │   ├── buildings_list.dart     # Machine count summary
│   │   ├── recipe_card.dart        # Reusable recipe display
│   │   ├── item_search.dart        # Autocomplete item picker
│   │   └── status_pill.dart        # Factory status badge
│   └── theme/
│       └── app_theme.dart          # Colors, typography, FICSIT amber
├── assets/
│   └── data.json                   # Bundled game data (offline-first)
├── server/                         # Keep existing Express + Postgres
│   └── server.js
├── pubspec.yaml
└── docs/
```

### State Management

**Riverpod.** Lightweight, testable, no boilerplate. Three main providers:
- `gameDataProvider` - loaded once at startup, indexes items/recipes by className
- `plannerProvider` - holds current planner state (selected item, rate, computed tree)
- `notesProvider` - syncs with Postgres, falls back to local storage

### Offline-First

1. Game data ships bundled in `assets/data.json`. Works without internet.
2. Notes save locally first (SharedPreferences), then sync to Postgres when online.
3. Wiki lookup requires internet but degrades gracefully with a clear message.
4. On launch, check if a newer `data.json` exists on GitHub. If so, download and cache it. Don't block startup.

---

## Screens

### 1. Planner (Primary Tab)

The main draw. Three sub-views matching satisfactory-calculator.com:

**a) Tree View (default)**
- Select item via autocomplete search
- Enter target rate (items/min)
- Display indented tree: item name, machine type, machine count (xN), rate
- Each node expandable/collapsible
- Tap a node to wiki-lookup that item

**b) Items View**
- Flat list derived from the tree: "240 units/min of Iron Ore", etc.
- Sorted by rate descending
- Quick reference while building

**c) Buildings View**
- Grouped by machine type: "4x Assembler, 6x Constructor, 8x Smelter, 1x Miner Mk.3"
- Shows total power consumption
- Nice-to-have: construction cost per machine

**Planner Options:**
- Toggle alternate recipes per node (tap to cycle through available recipes)
- Overclock slider (50-250%) per machine type
- "I already have X/min of [ingredient]" input constraints (satisfactory-calculator supports this)

### 2. Wiki Lookup

Port the existing wiki tab. Same two-step API:
1. `action=opensearch` for fuzzy search
2. `action=parse&prop=text` for rendered HTML

Parse the HTML server-side or in a webview. Display: summary, default recipe, alternates, power stats, link to full wiki page.

### 3. Session Tasks

Port existing. Checkbox list of small steps for the current play session. Syncs to Postgres.

### 4. Needs

Port existing. Shopping list of things you still need to build/find. Syncs to Postgres.

### 5. Factories

Port existing. Registry of your factories with name, produces, and status (wip/minimal/optimized). Syncs to Postgres.

### 6. Scratch Pad

Port existing. Freeform text for ratios, counts, half-formed plans. Syncs to Postgres.

---

## Phases

### Phase 1: Foundation
- Flutter project scaffolding
- Theme setup (FICSIT amber, Share Tech Mono, light theme matching current web app)
- Bottom navigation with 6 tabs
- Load and index `data.json` at startup
- Item search autocomplete

### Phase 2: Production Planner
- `PlannerEngine` - recursive production chain calculator
- Tree view widget with indented nodes
- Items flat list view
- Buildings summary view
- Tab bar within Planner screen to switch between tree/items/buildings

### Phase 3: Wiki Lookup
- Port MediaWiki API integration
- HTML parsing for recipes, stats, summary
- Recipe card widget (reusable between planner and wiki)

### Phase 4: Notes Sync
- Port session tasks, needs, factories, scratch pad
- Local storage (SharedPreferences) for offline-first
- Postgres sync service (reuse existing Express server at Railway URL)
- Conflict resolution: last-write-wins (single user, good enough)

### Phase 5: Planner Enhancements
- Alternate recipe selection per node
- Overclock slider
- Input constraints ("I already have X/min of Y")
- Save/load planner configurations
- Share production plan (deep link or export)

### Phase 6: Polish
- Game data update check on launch
- Smooth animations on tree expand/collapse
- Haptic feedback on status pill tap
- Dark mode toggle
- App icon and splash screen (FICSIT branding)

---

## Tech Stack

| Component | Choice | Why |
|-----------|--------|-----|
| Framework | Flutter | Cross-platform (iOS, Android, web, desktop) from one codebase |
| State | Riverpod | Lightweight, no codegen, good for async data |
| HTTP | `http` package | Simple, no need for dio's extras |
| Local storage | `shared_preferences` | Key-value, perfect for JSON blob |
| HTML parsing | `html` package | Parse wiki HTML into DOM, extract recipe data |
| Navigation | Bottom nav + nested tabs | 6 main tabs, planner has 3 sub-tabs |
| Backend | Existing Express + Postgres on Railway | Already deployed, just add Flutter as a client |
| Fonts | Share Tech Mono (bundled) | Matches existing FICSIT aesthetic |

### Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  http: ^1.3.0
  shared_preferences: ^2.5.3
  html: ^0.15.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## Design Tokens

Carried over from the web app:

```dart
// Colors
const ficsitAmber = Color(0xFFBA7517);
const bgPrimary = Color(0xFFFFFFFF);
const bgSecondary = Color(0xFFF5F5F4);
const textPrimary = Color(0xFF1A1A1A);
const textSecondary = Color(0xFF6B7280);
const textTertiary = Color(0xFF9CA3AF);
const borderSecondary = Color(0xFFD6D3D1);
const borderTertiary = Color(0xFFE7E5E4);

// Status pills
const wipBg = Color(0xFFE6F1FB);
const wipText = Color(0xFF185FA5);
const minimalBg = Color(0xFFFAEEDA);
const minimalText = Color(0xFF633806);
const optimizedBg = Color(0xFFEAF3DE);
const optimizedText = Color(0xFF27500A);

// Typography
const fontFamily = 'ShareTechMono';
```

---

## What This Is NOT

- Not an interactive map
- Not a blueprint editor
- Not a save file reader
- Not multiplayer

It's a personal companion tool. Production planning + session notes. Two things, done well, on your phone.
