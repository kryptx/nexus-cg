# NEXUS: The Convergence - LÖVE Implementation

**Version:** 0.1 (Initial Setup)

This README provides information for developers working on the LÖVE (Love2D) implementation of the strategic card game NEXUS: The Convergence.

**Note:** This README should be kept up-to-date with the current state of the project, including setup instructions, key architectural decisions, and build status.

## 1. Overview

NEXUS: The Convergence is a strategic card game focused on network building and player interaction via a "convergence" mechanic. This project aims to create a 2D digital version suitable for prototyping, playtesting, and potentially wider release.

For detailed gameplay rules, mechanics, theme, and design goals, please refer to the **[Game Design Document (GDD.md)](GDD.md)**.

## 2. Technology

*   **Engine:** LÖVE (Love2D) framework ([https://love2d.org/](https://love2d.org/))
*   **Language:** Lua
*   **Target Platforms:** Windows, macOS, Linux

## 3. Setup & Running

1.  **Install LÖVE:** Ensure you have the latest stable version of LÖVE installed for your operating system from the official website.
2.  **Clone Repository:** Clone this project repository to your local machine.
3.  **Run:**
    *   Navigate to the root directory (`nexus/`) of the cloned repository in your terminal.
    *   Run the command: `love .`
    *   Alternatively, on Windows/macOS, you can often drag the project folder onto the LÖVE application executable.

## 4. Directory Structure

The project follows this structure to maintain organization:

```
nexus/
├── main.lua           # Main LÖVE entry point (loads game state, handles core loop)
├── conf.lua           # LÖVE configuration file (window size, title, modules)
├── GDD.md             # Game Design Document (READ THIS FIRST)
├── NEXUS_rules_draft.md # Original rules concept draft
├── README.md          # This file
├── src/               # Source code directory
│   ├── core/          # Core engine systems (state management, event handling)
│   │   └── state_manager.lua # Example: Manages game states (menu, play, etc.)
│   ├── game/          # Gameplay logic and state representation
│   │   ├── card.lua     # Card definitions, data, logic
│   │   ├── player.lua   # Player state, hand, resources
│   │   ├── network.lua  # Network representation, placement logic
│   │   ├── rules.lua    # Core game rules validation, turn structure
│   │   └── reactor.lua # Reactor-specific logic (if any beyond a card)
│   ├── rendering/     # Graphics rendering logic
│   │   └── renderer.lua # Handles drawing game state, cards, UI
│   ├── audio/         # Sound and music management
│   │   └── audio_manager.lua # Handles loading/playing audio assets
│   ├── ui/            # User interface components
│   │   └── button.lua   # Example UI element
│   └── utils/         # General utility functions (math, tables, etc.)
│       └── vector.lua   # Example utility
├── assets/            # Game assets (art, sound, music)
│   ├── images/        # Sprites, icons, card art placeholders (PNG)
│   ├── sounds/        # Sound effects (WAV)
│   └── music/         # Music tracks (OGG)
├── tests/             # Unit and integration tests (using a Lua testing framework like Busted - TBD)
│   ├── core/
│   ├── game/
│   └── utils/
└── lib/               # External Lua libraries (if needed)
```

## 5. Development Philosophy

*   **Modularity:** Keep components (Lua files/modules) small, focused, and responsible for a specific piece of functionality.
*   **Testability:** Design components with testing in mind. Use pure functions where possible and minimize complex dependencies.
*   **Test Coverage:** **Write tests!** Aim for good test coverage, especially for core game logic (`src/core/`, `src/game/`, `src/utils/`). Use a suitable Lua testing framework (e.g., Busted, to be added to `lib/` or managed externally). Tests should verify component behavior in isolation and potentially integration between components.
*   **Clarity:** Write clear, readable code with appropriate comments for complex sections. Follow consistent naming conventions.
*   **GDD Alignment:** Ensure implementation aligns with the design specified in `GDD.md`. If changes are needed, update the GDD first or alongside the code changes.
*   **README Maintenance:** Keep this `README.md` updated with any significant changes to setup, architecture, or dependencies. 
