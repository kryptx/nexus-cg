# NEXUS: The Convergence
## Player Rulebook (v0.3)

Welcome to **NEXUS: The Convergence**, a 2–5 player strategic card game of network building, resource management, and dynamic interdependence. Your goal is to grow your network, harness resources, and leverage "convergence" links to activate powerful effects—aiming to be the first to reach **25 Victory Points (VP)** or trigger the end game by depleting the Node card deck.

---

## 1. Components

*   **Player Boards (5):** Track your Energy, Data, Material resources, Victory Points, and available Convergence Link sets.
*   **Reactor Cards (5):** Your unique starting **base** node. It's always present in your network, features all 8 connection ports, and inherently provides 1 Energy during your Energy Gain Phase.
*   **Node Cards (~100):** The core building blocks, categorized into four types: **Technology**, **Culture**, **Resource**, and **Knowledge**. Each card details:
    *   Which of the 8 standard connection ports are **present**.
    *   Its **Build Cost** (paid in Material and/or Data).
    *   An **Action Effect** (triggered when activated by you).
    *   A **Convergence Effect** (triggered when activated by an opponent via a Convergence Link).
*   **Genesis Cards:** A special subset of Node Cards designed for easier initial placement and activation.
*   **Paradigm Shift Deck:** Contains cards that introduce global rule modifications during the game. Includes a few **Genesis Paradigms** (one of which starts revealed) and numerous standard **Paradigm Shifts**.
*   **Convergence Link Sets:** Each player receives 4 sets (one for each type: Tech, Culture, Resource, Knowledge). Each set consists of **two identical markers**.
*   **Resource Tokens:** Energy (cyan), Data (magenta), Material (silver/gray).
*   **Victory Point (VP) Tokens:** Various denominations.
*   **First-Player Marker.**

---

## 2. Setup

1.  **Player Setup:** Each player receives:
    *   1 Player Board.
    *   1 Reactor Card (placed face-up in their play area).
    *   4 Convergence Link sets (kept nearby, unused).
    *   Initial Resources: **0 Energy**, **1 Data**, **2 Material**.
2.  **Genesis Cards:** Create a separate pool of all Genesis Cards. Shuffle this pool, deal **one** Genesis Card face-down to each player (added to their hand). Shuffle any remaining Genesis Cards into the main Node deck.
3.  **Deal Starting Hand:** Shuffle the main Node deck thoroughly. Deal **two** additional Node cards face-down to each player. Players now have a starting hand of 3 cards (1 Genesis + 2 Node).
4.  **Central Setup:**
    *   Place the shuffled main Node deck centrally.
    *   Shuffle the Paradigm Shift deck (including Genesis Paradigms). Reveal the top card; this is the starting **Genesis Paradigm**. Place the deck nearby.
    *   Place Resource tokens and VP tokens in a general supply accessible to all players.
5.  **Choose First Player:** Determine the starting player randomly or by agreement. Give them the First Player marker.

---

## 3. Game Turn Overview

On your turn, you must perform the following phases in order:

1.  **Energy Gain Phase** (Start of Turn)
2.  **Build Phase** (Perform actions)
3.  **Activate Phase** (Optional action)
4.  **Converge Phase** (Optional action)
5.  **Cleanup Phase** (End of Turn)

---

## 4. Energy Gain Phase

At the start of your turn, gain Energy based on your network connections:

*   Gain a base of **1 Energy** for your own **Reactor**.
*   Gain additional Energy based on **Convergence Links** you have initiated *from* opponent networks *into* your network:
    *   **Initial Link Limitation:** *Until* you have established at least one Convergence Link originating from *each* opponent's network, you gain only **+1 Energy per opponent** you are linked *from* (regardless of the number of links from that specific opponent).
    *   **Full Link Bonus:** *Once* you have established at least one Convergence Link originating from *every* other player's network, you gain **+1 Energy for *each*** such Convergence Link you have initiated.
*   **Maximum Gain:** The total Energy gained during the Energy Gain Phase (base + bonus) cannot exceed **4 Energy**. Place gained Energy tokens on your Player Board.

---

## 5. Build Phase

During this phase, you may perform one or both of the following actions, in any order you choose:

*   **(A) Play Node Cards:**
    *   Select one or more Node cards from your hand.
    *   Pay the **Build Cost** (typically Material, sometimes Data) shown on each card by returning tokens to the supply.
    *   Place each card into your network area adjacent (sharing a full edge) to at least one existing card (your Reactor or another Node card).
    *   **Placement Rules:**
        *   **Connectivity:** Must be adjacent to an existing card.
        *   **Fixed Orientation:** Cards **cannot** be rotated. Place them with the text upright.
        *   **Connection Point Matching:** To place Card B next to Card A, look at the edge where they touch. At least one **Input port present** on Card B's connecting edge must align with a corresponding **Output port present** on Card A's adjacent edge. Other ports don't need to match for placement legality. (See Section 11 for Port details).
        *   **Uniqueness Rule:** Your network **cannot contain more than one copy of the exact same card**. If you draw a duplicate of a card already in your network, you cannot play it (but you can discard it).
*   **(B) Discard for Resources:**
    *   Discard one card from your hand face-down to the discard pile.
    *   Gain either **1 Material** or **1 Data** token from the supply. (This is a way to get resources or cycle unwanted/duplicate cards).

---

## 6. Activate Phase

Optionally, during this phase, you may spend Energy to activate a path of connected nodes:

1.  **Select Target:** Choose one node to be the **target node**. This can be in your network or an opponent's network (if reachable via a Convergence Link you initiated).
2.  **Identify Path:** Trace a single, contiguous chain of connections from the target node back towards your **Reactor**. This path must follow valid **Output → Input** links between adjacent **present** ports on the cards. The path cannot branch. The final link must connect an Output port on the last node in the path to an Input port on your Reactor.
3.  **Pay Cost:** If a valid path exists, calculate the number of Node cards in the path (**M** nodes, excluding the Reactor). You must spend **M Energy** tokens to proceed with the activation. Return the Energy tokens to the supply.
4.  **Resolve Effects:** If you paid the cost, resolve the effects of the nodes along the activation path sequentially, starting with the **target node** and moving towards the Reactor:
    *   If the node being resolved belongs to **you**, trigger its "**Action**" effect.
    *   If the node being resolved belongs to an **opponent**, trigger its "**Convergence Effect**" for you (the activating player).
    *   Continue resolving effects node by node along the path.
    *   The **Reactor** is the necessary endpoint for a valid path but **does not** have its own effect resolved as part of the sequence.
5.  **Limitation:** You may initiate as many activation sequences as you like during your **Activate Phase**, but each specific node card can be part of at most **one** activation path per turn. Since each activation must include a node adjacent to your Reactor—and you can have at most **4** such adjacent nodes—this effectively limits you to **4 activations** per turn.

---

## 7. Converge Phase

Optionally, during this phase, a player may perform one of the following actions:

1.  **Create Convergence Link:**
    *   Spend **1 Data**.
    *   Select one of your available (unused) **Convergence Link sets** (Technology, Culture, Resource, or Knowledge).
    *   **Select Nodes & Ports:**
        *   Choose one of your Node cards (not your Reactor) that has a **present Output port** of the chosen type, located at the correct half-edge position (see Section 11).
        *   Choose a target Node card in an **opponent's** network (not their Reactor) that has a **present Input port** of the same type, located at the corresponding adjacent half-edge position.
        *   The chosen ports must form a valid **Output → Input** link across the potential connection *between* your networks.
        *   **Crucially:** The chosen port on your node **must not be directly facing an adjacent node card** in your network grid. Likewise, the chosen port on the target node **must not be directly facing an adjacent node card** in their network grid. Convergence links can only be placed across empty space or the boundaries between player networks.
    *   **Place Markers:**
        *   Place one marker from your chosen set onto the **Output port** of your node.
        *   Give the second, identical marker from the set to the target player.
        *   The target player places this marker onto the **Input port** of their targeted node.
    *   **Effect:** This establishes a permanent connection (unless broken by card effects). These specific half-edge ports are now **occupied** by this link. The link enables activation flow (Output → Input) between the networks for the **Activate Phase** and contributes to your **Energy Gain Phase**. Mark the used Link set on your Player Board (or set aside the used markers).

2.  **Destroy Convergence Link:**
    *   Spend **2 Data**.
    *   Choose an existing Convergence Link on an opponent's node that was created by that opponent.
    *   Remove both paired markers from the involved ports, freeing those ports for other actions.

---

## 8. Paradigm Shifts

These are global rule modifications that change the strategic landscape:

*   **Starting Paradigm:** The game begins with one **Genesis Paradigm** revealed during setup, establishing an initial global rule variant.
*   **Triggering Shifts:** Paradigm Shifts are triggered *immediately* when specific game milestones related to Convergence Links are reached. Each trigger condition occurs only **once per game**. When triggered:
    1.  **First Convergence:** Triggered when the *first* Convergence Link is successfully established between *any* two players in the game.
    2.  **Universal Convergence:** Triggered when *every* player in the game has established *at least one* Convergence Link originating from their network.
    3.  **Individual Completion:** Triggered the *first* time *any* player successfully establishes their final (e.g., 4th) Convergence Link.
*   **New Paradigm:** When a shift is triggered, draw the top card from the shuffled standard Paradigm Shift deck and reveal it. This new Paradigm immediately **replaces** the currently active one. Place the old Paradigm card aside or under the deck.
*   **Scope of Effects:** The revealed Paradigm Shift card dictates new global rules, often focused on:
    *   Costs (Energy for activation, Material for building).
    *   Resource generation or conversion rates.
    *   Scoring conditions (immediate VP gains or end-game bonuses).
    *   Activation effects or bonuses for specific node types.

---

## 9. Cleanup Phase

Perform these steps at the end of your turn:

*   **Check Hand Size:** If you have fewer than 3 cards in your hand, draw cards from the main Node deck until you have 3. If the deck runs out while drawing, draw as many as possible and trigger the game end (see Section 10).
*   **Pass Turn:** Pass the First Player marker (if applicable, or simply indicate) to the next player clockwise.

---

## 10. End Game & Scoring

The game end is triggered when either of the following occurs *at the end of any player's turn*:

*   A player reaches or exceeds **25 Victory Points (VP)**.
*   The main Node draw deck is depleted for the first time (even if during the Cleanup Phase draw).

Once triggered, finish the current round of play so that every player has had an equal number of turns. Then, proceed to Final Scoring:

1.  **Network Size:** Gain **1 VP** for each Node card currently active in your network (do *not* count your Reactor).
2.  **Endgame Objectives/Paradigm Bonuses:** Add any VP awarded from specific card effects or the final active Paradigm card that grant end-game points. (Check card text).
3.  **(Optional Rule - Check if Used) Resource Conversion:** Convert remaining resources (Energy, Data, Material) into VP at a pre-agreed ratio (e.g., 5 total resources = 1 VP).

**Winner:** The player with the highest total Victory Point score wins!

**Tiebreakers:** If tied for the highest score, the tied player with the most **Node cards** in their network wins. If still tied, the player with the most **Energy** wins. If still tied, the most **Data**. If still tied, the most **Material**. If still tied, tied players share the victory.

---

## 11. Port & Connection Reference

Understanding the 8 potential ports on each card edge is crucial for placement and activation. Remember, cards are **never rotated**.

| Edge     | Left Half Port (Position 1/3/5/7) | Right Half Port (Position 2/4/6/8) |
| :------- | :-------------------------------- | :--------------------------------- |
| **Top**  | Culture **Output** (1)            | Technology **Input** (2)           |
| **Bottom**| Culture **Input** (3)             | Technology **Output** (4)          |
| **Left** | Knowledge **Output** (5)          | Resource **Input** (6)             |
| **Right**| Knowledge **Input** (7)           | Resource **Output** (8)            |

*   A **Node Card** indicates which of these 8 ports are **present**. Absent ports cannot be used for connections.
*   A valid connection (for network building or activation) **always** requires linking a **present Output port** on one card to a **present Input port** on an adjacent card at the corresponding half-edge position.

---

### Ready to converge? Build your network, forge your links, and may your strategies shape the future of NEXUS!
