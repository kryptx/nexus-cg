# Game Design Document: NEXUS: The Convergence

**Version:** 0.3 (Revision: Simplified 8-Slot Connections)

## 1. Introduction / Overview

NEXUS: The Convergence is a 2-5 player strategic card game centered around building and managing networks of interconnected "nodes." These nodes represent key societal facets: technology, culture, resources, and knowledge. Players utilize versatile cards that function simultaneously as resources, network nodes, executable actions, and potential scoring conditions.

The core theme revolves around shaping an evolving ecosystem where individual player networks inevitably intersect. This "convergence" mechanic is the game's unique selling point, creating complex interdependencies, strategic opportunities, and potential conflicts between players. Inspired by designers like Knizia, Meier, Miyamoto, Wright, and Chvátil, NEXUS challenges players to balance network optimization, resource management, and strategic interaction within a dynamic, interconnected system. Victory is achieved not just through expansion, but through mastering the delicate balance between independence and collaboration.

## 2. Design Goals / Pillars

*   **Strategic Interdependence:** The core experience revolves around the "convergence" mechanic. Player decisions must impact and be impacted by opponent networks, creating tension between cooperation and competition.
*   **Emergent Complexity:** Simple actions should lead to complex, evolving game states driven by player choices and network interactions.
*   **Meaningful Adaptability:** Players must adapt to opponent actions and dynamic "Paradigm Shifts." Flexible, responsive play is key.
*   **Tactical Depth via Multi-Use Cards:** Each card presents multiple choices (node, resource, action, scoring), demanding interesting tactical decisions.
*   **Satisfying Network Building:** Constructing and visually expanding one's network should be inherently rewarding, presenting spatial puzzles based on connection slots.
*   **Multiple Viable Paths:** Diverse strategies (e.g., expansion, convergence, resource focus, paradigm exploitation) should be viable routes to victory.

## 3. Target Audience

*   **Experienced Strategy Gamers:** Players comfortable with medium-to-heavyweight strategy games emphasizing network building, spatial control, resource management, and significant player interaction through shared systems. They appreciate tactical depth and adapting to evolving board states (e.g., fans of *Tigris & Euphrates*, *Steam* / *Brass*, *Galaxy Trucker*, other Knizia/Chvátil/Wallace titles).
*   **Players Enjoying Indirect Interaction:** Gamers preferring significant player interaction derived from influencing shared systems, opportunities, and limitations, rather than direct conflict.
*   **Systems Thinkers:** Individuals interested in building complex systems, observing emergent behaviors, and adapting to dynamic environments.
*   **Theme Appreciators:** Players drawn to themes of network building, societal/technological evolution, and the strategic interplay between different societal forces.
*   **Demographics:** Primarily adults (20s-50s) and experienced older teens, assuming familiarity with modern strategy game mechanics.

## 4. Gameplay Mechanics

*(Detailed breakdown of how the game plays. Referencing `NEXUS_rules_draft.md` for specifics is appropriate here.)*

### 4.1 Starting Conditions

*   **Player Setup:** Each player receives:
    *   A player board (Functionality TBD: resource tracking, VP tracking, etc.).
    *   One "Reactor" card placed in their starting play area. This serves as the **base**. The Reactor has **all 8 connection slots 'open'** according to the standard convention (See 4.3) and allows adjacent placement without requiring an initial Output->Input link.
    *   A starting hand of **X** defined "Seed Cards". Exact composition and quantity **X** TBD.
    *   Initial resources: **Y** Energy, **Z** Data, **W** Material. Quantities TBD.
    *   Four Convergence Link sets (each with 2 markers) - see 4.6.
*   **Central Setup:**
    *   The main deck (Node cards) is shuffled and placed centrally.
    *   The Paradigm Shift deck is shuffled (including Genesis Paradigms). One Genesis Paradigm is revealed. (See 4.7).
    *   Resource tokens (Energy, Data, Material) and Victory Point tokens are placed in a general supply.
    *   Optional: Central "Convergence Map" board placed centrally.

### 4.2 Core Loop

A player's turn consists of the following phases, performed in order:

1.  **Build Phase:** Player may perform one or both of the following actions, in any order:
    *   Add one or more cards from their hand to their network, paying associated costs (e.g., Material) and following placement rules (See 4.3 Network Building), including the Uniqueness Rule.
    *   Discard one card from their hand to gain 1 Material resource. (This provides an outlet for duplicate cards).
2.  **Activate Phase:** Player may spend Energy to activate a path of connected nodes (See 4.5 Card Actions & Activation).
3.  **Converge Phase:** Player may initiate new connections to opponent networks using Convergence Link sets (See 4.6 Convergence Mechanic).
4.  **Cleanup Phase (End of Turn):**
    *   Check hand size. If the player has fewer than 3 cards in hand, they draw 1 card from the main deck.
    *   Pass the turn to the next player.

### 4.3 Network Building

*   **Placement:** Cards are played from hand into the player's network area, typically costing Material resources.
*   **Connectivity:** A new card must be placed adjacent (sharing a full edge) to at least one existing card in the player's network.
*   **Fixed Orientation:** Cards **must** be placed with a fixed "up" orientation and cannot be rotated.
*   **8-Slot Convention & Potential Connections:** Each edge has two potential connection slots with fixed type/direction:
    *   **Top Edge:** Slot 1 (Left Half) = Culture Output, Slot 2 (Right Half) = Technology Input
    *   **Bottom Edge:** Slot 3 (Left Half) = Culture Input, Slot 4 (Right Half) = Technology Output
    *   **Left Edge:** Slot 5 (Top Half) = Knowledge Output, Slot 6 (Bottom Half) = Resource Input
    *   **Right Edge:** Slot 7 (Top Half) = Knowledge Input, Slot 8 (Bottom Half) = Resource Output
    *   Node cards specify which of these 8 potential slots are **'open' (active)** (See 5.1).
*   **Connection Point Matching Rule (Simplified):** To place Card B adjacent to Card A:
    *   Align cards without rotation.
    *   Check all **open Input slots** on Card B's connecting edge.
    *   The placement is valid if **at least one** of these open Input slots aligns with a corresponding **open Output slot** on Card A's adjacent edge.
    *   Other slots (unmatched Inputs on Card B, any Outputs on Card B, any Inputs/Outputs on Card A) do not need to align or match for placement legality.
*   **Uniqueness Rule:** A player's network **cannot contain more than one copy of the exact same card**.

### 4.4 Resource Management

*   **Types:** Energy (E), Data (D), Material (M).
*   **Acquisition:** Gained primarily through Node Action/Convergence effects, potential Reactor base income, discarding cards (Material).
*   **Spending:**
    *   Energy: Used for path activation (cost = path length). Potentially other card effects.
    *   Data: Used primarily for card effects that involve drawing or manipulating cards.
    *   Material: Used primarily to pay the Build Cost of placing Node cards.

### 4.5 Card Actions & Activation

*   **Initiation (Targeted Activation):** Player selects a target node they wish to serve as the endpoint of the activation sequence.
    *   The player identifies a specific node (the **target node**) in their network or an opponent's network (reachable via Convergence Link).
*   **Path Requirement for Activation:** For activation to be valid, there must exist a single, contiguous chain of connections originating from the target node and terminating at the player's Reactor. This chain must adhere to the following:
    *   It starts by using an **'open' Output slot** on the **target node**.
    *   Each subsequent step in the chain uses an **'open' Output slot** on the current node...
    *   ...to connect to a corresponding **'open' Input slot** on the **next node** in the sequence leading towards the Reactor (following the established `Output -> Input` links).
    *   The **final node** in the chain (the one whose Output connects directly to the Reactor's Input) must use an **'open' Output slot**...
    *   ...to connect to a corresponding **'open' Input slot** on the **Reactor**.
    *   The chain cannot branch.
*   **Activation Path & Cost:** The sequence of nodes starting with the Target and ending with the node directly connected to the Reactor constitutes the **activation path**. Let the number of nodes in this path be **M**. The player must spend **M Energy** to activate this path.
*   **Activation Sequence (Target to Reactor):**
    *   Activation effects are resolved sequentially along the identified activation path, starting with the **target node**.
        *   If the target node belongs to the **current player**, resolve its "Action" effect.
        *   If the target node belongs to an **opponent** *and* was targeted via a Convergence Link (respecting the Output->Input chain), resolve its "Convergence Effect" for the current player.
    *   The activation then proceeds node by node along the path towards the Reactor, resolving each node's appropriate effect (Action or Convergence) in turn.
    *   The **Reactor** itself is the necessary endpoint for a valid path but **does not** have its own effect resolved as part of this sequence.
*   **Limitations:** A specific node can only be activated **once** as part of a single activation sequence per turn, even if it has multiple open slots involved in the path.
*   **Harvest Effects:** Some card Actions or Convergence Effects may be designated as "Harvest" effects, involving the conversion of network elements into VP or resources.

### 4.6 Convergence Mechanic

*   **Link Components (Paired Markers):** Each player starts with a limited supply of **four Convergence Link sets**. Each set corresponds to a connection type (Technology, Culture, Resource, Knowledge) and consists of **two identical markers**. Using a set consumes this finite resource for the initiating player.
*   **Initiation:** During their Converge Phase, a player may use **one** available (unused) `[Type] Convergence Link set` to connect their network to an opponent's.
*   **Placement Requirements:** To use a `[Type] Convergence Link set`:
    *   The initiator must possess the corresponding unused `[Type] Link set`.
    *   The player chooses one of their nodes with an **'open' `[Type]` Output slot** at the appropriate half-edge position (per convention 4.3).
    *   The player targets an opponent's node with an **'open' `[Type]` Input slot** at the corresponding adjacent half-edge position.
    *   The chosen slots must form a valid **Output -> Input** link across the potential connection.
*   **Physical Placement & Occupation:**
    *   The initiating player places one marker from the chosen `[Type]` set onto the **'open' Output slot** of their node.
    *   The initiating player gives the second, identical marker from the set to the target player.
    *   The target player places this marker onto the **'open' Input slot** of their targeted node.
    *   These paired markers visually signify the link and that **these specific half-edge slots are now occupied** by this convergence link, unavailable for standard network building or other convergences.
*   **Effect:** Establishes a permanent (unless broken by card effects) connection enabling activation flow between the marked slots. An activation path (See 4.5) can cross this link (between the paired markers) if it follows the established Output -> Input direction. Activating across the link triggers the target node's "Convergence Effect" for the active player.
*   **Limitations:** Typically only one convergence initiation per turn. Nodes/slots may have limits on how many convergence links can attach. Some cards might block convergence or allow breaking existing links (requiring removal of both markers).

### 4.7 Paradigm Shifts

*   **Concept:** Global rule modifications that periodically change throughout the game, forcing players to adapt their strategies.
*   **Starting Paradigm:** The game begins with one randomly drawn "Genesis Paradigm" card revealed during setup, establishing an initial global rule variant.
*   **Paradigm Deck:** A separate deck of Paradigm Shift cards exists.
*   **Triggering Shifts:** Paradigm Shifts are triggered when specific conditions are met. Proposal: Shuffle a predetermined number of Paradigm Shift cards into the lower portion (e.g., bottom third) of the main draw deck. When a Paradigm Shift card is drawn, it immediately replaces the currently active Paradigm.
*   **Scope of Effects:** The revealed Paradigm Shift card dictates new global rules primarily focused on:
    *   Costs (e.g., Energy for activation, Material for building specific types).
    *   Resource generation or conversion rates.
    *   Scoring conditions (immediate or end-game VP).
    *   Activation effects or bonuses for specific node types.
    *   **Note:** Paradigms **do not** alter the fundamental connection type matching, fixed orientation, or implied directional flow rules established in section 4.3.
*   **Transition Principle:** Paradigm Shifts primarily alter the **value, cost, or potential** of existing game elements and future actions. They generally **do not invalidate physically placed cards or connections**. Previously legal placements remain, but their strategic value or operational cost may change significantly under the new paradigm.
*   **Duration:** A Paradigm remains in effect until the next one is triggered and replaces it.
*   **Example Paradigms:**
    *   *Cultural Boom:* Activating Culture nodes costs 1 less Energy. Gain 1 VP immediately each time you activate a Culture node.
    *   *Resource Scarcity:* Resource node actions produce 1 less Material/Energy. Gain 1 VP for each Resource node in your network at game end.

### 4.8 Victory Conditions & Scoring

*   **Game End Triggers:** The game end is triggered when either of the following occurs at the end of any player's turn:
    *   A player reaches or exceeds **25 Victory Points (VP)**.
    *   The main draw deck is depleted for the first time.
    *   Once triggered, the current round is completed (so every player has an equal number of turns), and then Final Scoring occurs.
*   **Earning Victory Points (In-Game):** VP are earned throughout the game primarily through:
    *   **Node Activation:** Resolving the "Action" or "Convergence Effect" of specific nodes during the Activate Phase frequently grants VP.
    *   **Paradigm Shift Bonuses:** Capitalizing on scoring opportunities presented by the currently active Paradigm card.
    *   **Convergence Achievements:**
        *   Potential VP bonus for establishing a Convergence Link (TBD).
        *   Specific card effects may grant VP based on active Convergence Links.
        *   Potential high-value VP bonuses for complex convergences (e.g., linking to multiple opponents) (TBD).
    *   **Network Structures:** Potential one-time VP bonus for completing "circuits" (closed loops) in the network, possibly scaling with size (TBD).
    *   **Card Effects:** Specific card "Actions" may allow conversion of resources or other game elements directly into VP.
*   **Final Scoring (End of Game):** After the final round, players add VP from:
    *   **Network Size:** Gain 1 VP for each card currently active in their network (excluding the Reactor).
    *   **Endgame Objectives:** VP awarded from completing specific public or private objective cards (Mechanism TBD).
    *   **Paradigm Effects:** Some Paradigm cards might provide end-game scoring bonuses.
    *   **(Optional) Resource Conversion:** Convert remaining resources (Energy, Data, Material) into VP at a specified ratio (e.g., 5:1) (TBD).
*   **Winner:** The player with the highest total Victory Point score wins. Ties are broken by [Tiebreaker Rule TBD - e.g., most remaining resources, most cards in network].

## 5. Game Assets

### 5.1. Cards

This section details the different types of cards used in NEXUS.

**A. Node Cards (Technology, Culture, Resource, Knowledge)**

These form the main draw deck and are the building blocks of player networks.

*   **Layout Elements:**
    *   **Card Title:** Unique name.
    *   **Node Type:** Icon/color-coding.
    *   **Connection Slots (8 Potential):** Visual indication of which of the 8 standard slots (defined in 4.3) are **'open'**. Clear graphic design needed.
    *   **Art:** Space for illustration reflecting the node's theme.
    *   **Build Cost:** Resources required to play the card into the network (e.g., X Material, Y Data). Clearly displayed.
    *   **Action Effect:** Text describing the effect triggered when activated by its owner via path activation (originating from one of its 'open' Input slots).
    *   **Convergence Effect:** Text describing the effect triggered when activated by an opponent via a Convergence Link targeting one of its 'open' Input slots.
    *   **(Optional) VP Value:** Some cards might grant VP at game end (indicated by a VP icon/number).
    *   **(Optional) Flavor Text:** Thematic text.

*   **Seed Cards:** A specific subset of Node Cards used for the starting player hands. Functionally identical layout, likely with simpler/fewer open slots.

**B. Reactor Card**

Each player starts with one unique Reactor card.

*   **Layout Elements:**
    *   **Card Title:** "Reactor".
    *   **Node Type:** Special/Unique.
    *   **Connection Slots:** All 8 potential slots are **'open'** according to the convention in 4.3. Allows adjacent placement without requiring link formation.
    *   **Art:** Unique art representing the player's core base.
    *   **No Build Cost.**
    *   **No Action/Convergence Effect:** Serves only as the destination for activation path traces.
    *   **(Potential) Base Income:** May generate a small amount of a resource (e.g., 1 Energy) automatically each turn (TBD).

**C. Paradigm Shift Cards**

These cards modify global rules.

*   **Layout Elements:**
    *   **Card Title:** Name of the Paradigm.
    *   **Type:** Indication if "Genesis Paradigm" (start only) or standard shift.
    *   **Rule Text:** Clear description of the rule modifications (affecting costs, scoring, resource rates, activation effects - see 4.7).
    *   **Art/Iconography:** Thematic visual.

### 5.2. Other Components

*   **Convergence Link Sets:** 4 sets per player (Tech, Cult, Res, Know), each containing 2 identical markers (total 8 markers per player). Markers should ideally indicate type and perhaps fit visually onto half-edge slots.
*   **Resource Tokens:** Energy, Data, Material.
*   **Victory Point Tokens:** Various denominations.
*   **Player Boards (Optional):** For resource/VP tracking, storing unused Link markers.
*   **First Player Marker.**
*   **(Optional) Central Convergence Map.**

## 6. Art Style & Visuals

*   **Overall Style:** A clean, functional, and minimalist aesthetic drawing inspiration from electronic schematics, network diagrams, and modern user interfaces. The primary goal is **clarity of information**, especially regarding connection slots and network flow, while maintaining a cohesive, tech-focused theme. Think vector graphics, clear iconography, and avoiding photorealism or complex textures.
*   **Color Palette:** A reserved base palette (e.g., dark blues, grays, off-whites for backgrounds and base card elements) punctuated by distinct, vibrant accent colors for key game elements:
    *   **Node Types:** Technology (e.g., Electric Green), Culture (e.g., Warm Yellow/Orange), Resource (e.g., Earthy Brown/Bronze), Knowledge (e.g., Deep Purple/Indigo).
    *   **Resources:** Energy (e.g., Bright Cyan), Data (e.g., Magenta), Material (e.g., Gray/Silver).
    *   **Highlights/Activation:** A bright, contrasting color (e.g., White or light Gold).
*   **Cards (Nodes & Reactor):**
    *   Rendered as clean rectangular tiles or panels.
    *   **Connection Slots:** The critical element. Each of the 8 potential slots should be clearly visualized on the edges (e.g., as small circles, squares, or notches).
        *   **State:** 'Open' slots are visually distinct (e.g., filled with the corresponding Type color, potentially with a subtle border). 'Closed' slots are empty, grayed out, or absent.
        *   **Input/Output:** Primarily defined by position (per convention 4.3). Subtle visual cues like a tiny dot inside inputs vs. a tiny line inside outputs, or a slightly different shape, could be added *if* extensive playtesting deems it necessary for clarity, but the aim is to rely on position.
    *   **Information:** Node type represented by a large, clear icon. Text (Title, Cost, Effects) uses a clean, readable sans-serif font.
*   **Network Visualization:**
    *   **Connections:** When a valid Output->Input link is formed between adjacent open slots, draw a clean line (perhaps matching the Type color, or a neutral connection color) directly connecting the centers of the two linked slots. Unlinked but adjacent open slots remain visually unconnected.
    *   **Convergence Links:** The paired markers placed on linked slots should be visually distinct sprites (perhaps matching the Type color but with a unique shape) that clearly indicate the slot is occupied by a convergence. A different line style (e.g., dashed, glowing) could connect the paired markers across the player areas.
*   **Activation Effect:**
    *   Highlight the nodes involved in the activation path (e.g., brighten their border or background).
    *   Visualize the path trace with a temporary effect: animate a pulse or particle effect traveling along the connecting lines between the activated slots, moving from the target node back towards the Reactor. Use the highlight color (e.g., White/Gold) or Energy color (Cyan).
*   **UI Elements:** Resource displays, VP trackers, Player Boards (if implemented) should use the same clean, minimalist style with clear iconography and typography.
*   **LÖVE Engine Feasibility:** This style is well-suited for LÖVE. It primarily relies on drawing primitives (`love.graphics.rectangle`, `love.graphics.line`, `love.graphics.circle`), loading images/sprites for icons and markers (`love.graphics.newImage`), rendering text (`love.graphics.print`), and potentially simple particle effects or color manipulation for activation highlights. No complex 3D or heavy shader work is required.

## 7. Sound & Music

*   **Overall Direction:** The audio design should complement the clean, schematic visual style. It should be functional, providing clear feedback without being intrusive or overly complex. An electronic, synthesized, and slightly abstract feel is appropriate.
*   **Music:**
    *   **Style:** Atmospheric, minimalist electronic music. Think ambient synth pads, subtle rhythmic pulses, perhaps generative or evolving soundscapes that aren't overly melodic or demanding of attention (e.g., ambient techno, synthwave backgrounds, "data stream" type sounds).
    *   **Function:** To create a focused, tech-infused atmosphere that supports concentration. It should loop seamlessly and potentially have subtle variations based on game state (e.g., slightly increasing tempo or adding layers as the game progresses or nears its end).
    *   **Implementation:** Use looped Ogg Vorbis files via `love.audio`. Volume should be relatively low by default.
*   **Sound Effects (SFX):**
    *   **Style:** Crisp, distinct, synthesized sounds. Focus on short, clear feedback rather than realistic noises. Think clicks, beeps, pulses, subtle digital glitches, and soft hums.
    *   **Function:** Provide immediate confirmation for player actions and important game events.
    *   **Specific Examples:**
        *   *Card Placement:* Soft electronic "snap" or "click".
        *   *Resource Gain/Spend:* Distinct short digital tones/blips for Energy, Data, Material (perhaps higher pitch for gain, lower for spend).
        *   *Path Activation Start:* Subtle "power up" hum or chime.
        *   *Node Activation (along path):* Short, crisp "ping" or "pulse" sound for each node, maybe subtly varying by type. A confirmation sound when the path completes.
        *   *Convergence Link:* A slightly more resonant "connection established" synth sound.
        *   *Card Draw/Discard:* Soft digital "swish" or "data transfer" sound.
        *   *UI Interaction:* Consistent, minimal digital click/beep for buttons.
        *   *Paradigm Shift:* A noticeable but not jarring sound – perhaps a short filter sweep, a low resonant tone, or a brief "system alert" type sound.
    *   **Implementation:** Use short WAV files via `love.audio`, played as non-looping sources. Ensure sounds don't excessively overlap or become cacophonous. Manage concurrency if many things happen at once.
*   **LÖVE Engine Feasibility:** This audio approach is very feasible in LÖVE using standard `love.audio` functions for loading sources (`love.audio.newSource`), playing (`Source:play`), setting volume (`Source:setVolume`), and looping (`Source:setLooping`).

## 8. Technology

*   **Primary Target Platform:** Tabletop board game. The rules and components are designed primarily for physical play.
*   **Digital Implementation Platform:** A 2D digital version/prototype is planned.
*   **Game Engine:** **LÖVE (Love2D)** framework. Chosen for its simplicity, cross-platform capabilities (Windows, macOS, Linux), and suitability for 2D graphics and straightforward audio handling.
*   **Programming Language:** **Lua**. Required by the LÖVE framework.
*   **Key LÖVE Modules:** Development will leverage core LÖVE modules including:
    *   `love.graphics` (for drawing shapes, lines, images, text)
    *   `love.audio` (for music loops and sound effects)
    *   `love.keyboard` and `love.mouse` (for player input)
    *   `love.event` (for handling events)
    *   `love.filesystem` (for loading assets)
    *   `love.timer` (for timing and animations)
*   **Design Considerations:** The chosen art style (minimalist schematic) and audio design (synthesized effects, ambient music) have been explicitly selected for their feasibility and ease of implementation within the LÖVE framework, prioritizing clarity and function over complex rendering techniques.

## 9. Future Considerations / Potential Expansions

*(Ideas for expansions, variants, or further development.)* 
