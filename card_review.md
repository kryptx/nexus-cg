# NEXUS Card Definition Review (v0.3)

This document provides feedback on the card definitions found in `card_definitions.csv` based on the goals outlined in `GDD.md` v0.3.

## General Observations

*   **Solid Foundation:** The current card set establishes the core mechanics and thematic types well. The basic resource generation and VP nodes provide a necessary baseline.
*   **Interaction Focus:** Convergence effects are present, but their impact and appeal vary significantly. Some offer strong interaction (stealing, destruction), while others are simple resource gains that might not strongly incentivize convergence.
*   **Cost vs. Benefit:** Costs (Material/Data) seem somewhat inconsistent relative to the effects and VP provided. A systematic review pass is recommended.
*   **Port Consistency:** Ports generally align thematically with card types (e.g., Culture nodes having Culture ports).
*   **Genesis Card Discrepancy:** The current Genesis cards (`GENESIS_*`) do not strictly meet the GDD criteria (Section 5.1.A, point 2) of having a paired Input/Output on the *same edge*. While they likely *function* (having *some* Output to connect to the Reactor and *some* Input to be activated *from*), the GDD description should be aligned with the card data, or the cards adjusted to match the description if that specific port configuration is deemed crucial for early game flow.

## Suggestions for Revision

Here are suggestions grouped by key areas:

### 1. Variety and Fun Factor

*   **Beyond Basic Resources:** Reduce the number of cards whose primary effect (Activation or Convergence) is just gaining 1-2 Data/Material. While necessary, over-reliance makes cards feel similar.
*   **Introduce More Mechanics:**
    *   **Manipulation:** Effects that allow rearranging own/opponent nodes (within rules), swapping nodes, or temporarily disabling nodes/ports.
    *   **Hand/Deck Interaction:** Effects allowing targeted discard (opponent), searching own deck for specific types, viewing opponent's hand, or manipulating the draw deck.
    *   **Energy Economy:** More ways to gain/spend/steal Energy beyond activation costs. Make Energy a more dynamic resource.
    *   **Paradigm Interaction:** Cards whose effects change based on the current Paradigm, or cards that allow influencing the Paradigm deck (e.g., peek, reorder).
    *   **Link Manipulation:** More ways to interact with Convergence Links beyond NODE_TECH_007 (e.g., strengthening own links, taxing opponent links, converting link types).
    *   **Conditional Complexity:** Expand on conditional effects ("If adjacent...", "If X cards activated...") with more diverse triggers and payoffs. Consider conditions based on opponent network states.
*   **Unique Card Roles:** Design cards that clearly excel in specific strategies (e.g., a card amazing for initiating early convergence, a card focused on defense, a card that synergizes heavily with a specific type).

### 2. Balance

*   **Cost/Benefit Analysis:** Perform a pass comparing Build Cost (Material + Data, perhaps weighting Data higher?) against the combined value of VP + Activation Effect + Convergence Potential. Standardize costs for similar effect magnitudes or ensure cost differences are justified by significant effect power differences.
    *   *Example:* Compare NODE_TECH_002 (7M, 1VP, 2 Data) vs. NODE_KNOW_004 (4M+3D, 1VP, 2 Data). Is 3 Material equivalent to 3 Data in value?
    *   *Example:* Compare NODE_CULT_001 (3M+1D, 0VP, Draw/Gain E vs Draw) vs NODE_CULT_002 (2M, 1VP, Gain Data vs Gain 2 Data). 002 seems more cost-effective upfront.
*   **Genesis Cards:** Standardize their cost slightly (e.g., all 3M or 4M) and ensure their activation effect provides a small, reliable early-game boost (like 1 specific resource) without being powerful late-game. Revisit the port configuration based on the GDD clarification.
*   **High-Cost Cards:** Ensure cards costing 6+ Material or significant Data have appropriately impactful effects or VP to justify the investment. NODE_RES_001 (6M, 0VP, 2 Material + conditional E) feels potentially weak for its cost.

### 3. Network Building Challenge

*   **Port Diversity:** While thematic consistency is good, ensure enough variety in port configurations *within* each type. Avoid too many cards sharing the most common Input/Output pattern (e.g., Type IN on one side, Type OUT on the opposite).
*   **"Awkward" Nodes:** Introduce some nodes with less intuitive port layouts (e.g., Inputs on multiple sides but only one Output, specific non-opposing Input/Output pairs) that offer strong rewards but require careful planning to integrate effectively.
*   **Bridging Nodes:** Ensure sufficient nodes exist with multiple *different* port types to facilitate connecting diverse network branches. Mixed-type nodes (NODE_CULT_KNOW_001, etc.) help here, but consider single-type nodes with off-type ports.

### 4. Player Interaction (Convergence)

*   **Distinct Convergence Effects:** Make a stronger design rule that Convergence effects should generally be *different* from the Owner Activation effect to make convergence more unique and strategically interesting.
*   **Impactful Convergence:** Increase the general appeal or impact of Convergence effects. Consider:
    *   More resource denial/stealing (like NODE_KNOW_006, NODE_TECH_007).
    *   Effects that grant the activator unique information or choices.
    *   Effects that scale based on the state of the *owner's* network.
    *   Effects that benefit the activator *and* potentially hinder the owner slightly (beyond simple resource gain for the activator).
*   **Symbiotic vs. Parasitic:** The mix of effects where the activator gains (NODE_CULT_002), both gain (NODE_TECH_002), or the activator takes (NODE_KNOW_006) is good. Ensure a deliberate balance across card types.
*   **Convergence Costs/Requirements:** Introduce more Convergence effects that require a small payment (Data/Material/Energy) from the *activator* for a stronger effect (like NODE_KNOW_006).

### 5. Thematic Consistency

*   **Generally Strong:** The current theme is well-represented.
*   **Minor Refinements:**
    *   Ensure effects align strongly with the *type*. Culture could focus more on VP, influence, drawing. Knowledge on data manipulation, drawing, information. Technology on energy, efficiency, complex actions, building. Resource on material, energy, conversion.
    *   Clarify ambiguous effects: NODE_TECH_007's activation effect description seems misplaced or needs rewording ("If Activator pays 1 Energy: Destroy..." should likely be under Convergence, or specify *Owner* pays).

## Specific Card Notes (Examples for Consideration)

*   **GENESIS_*:** Reconcile GDD port description or revise ports.

By incorporating more varied mechanics, refining the cost-benefit balance, enhancing the incentives and impact of convergence, and ensuring clear thematic ties, the card set can become even more engaging and strategically deep. 
