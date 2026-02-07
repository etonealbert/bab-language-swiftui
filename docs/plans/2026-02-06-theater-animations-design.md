# Design: iOS 18+ Animations for BringABrainLanguage

## Overview
This design implements premium iOS 18 animations including Zoom Transitions, KeyframeAnimators, and SF Symbol Effects.

## Architecture

### Navigation & Transitions
The `LobbyView` will serve as the root coordinator.
- **Namespace**: A shared `@Namespace` in `LobbyView` will coordinate the zoom transition.
- **NavigationStack**: Wraps the `TabView`.
- **Deep Linking**: `ScenarioGrid` will use `NavigationLink(value: ScenarioDisplayData)` instead of buttons.
- **Transition**: `TheaterView` will apply `.navigationTransition(.zoom(sourceID: id, in: namespace))`.

### Components

1.  **LobbyView**
    - `NavigationStack`
    - `TabView` with `.sidebarAdaptable` style.
    - Routes `ScenarioDisplayData` to `TheaterView`.

2.  **ScenarioGrid**
    - Accepts `namespace: Namespace.ID`.
    - Renders `ScenarioCard` with `.matchedTransitionSource`.

3.  **TheaterView**
    - Destination for the zoom transition.
    - Manages the role-play session.
    - Contains `ScrollView` of `DialogBubble`s.
    - Contains `DirectorToolbar` at the bottom.

4.  **DialogBubble**
    - Displays chat messages.
    - **Animation**: `KeyframeAnimator` on appearance.
        - Scale: 0.8 -> 1.05 -> 1.0
        - OffsetY: 20 -> -5 -> 0
        - Opacity: 0 -> 1

5.  **DirectorToolbar**
    - **SF Symbols**:
        - Hint: `lightbulb.max` with `.wiggle`
        - Replay: `arrow.counterclockwise` with `.rotate`
        - End: `stop.circle` with `.breathe`
    - **Interactions**: Tap triggers `.symbolEffect(.bounce)`.

## Data Flow
- User taps `ScenarioCard` -> `NavigationLink` pushes `ScenarioDisplayData`.
- `LobbyView` intercepts, builds `TheaterView` with zoom transition.
- `TheaterView` loads data based on `scenarioId`.

## Implementation Steps
1. Create `Features/Theater` directory.
2. Create `DialogBubble.swift` with `KeyframeAnimator`.
3. Create `DirectorToolbar.swift` with Symbol Effects.
4. Create `TheaterView.swift` assembling the pieces.
5. Modify `ScenarioGrid.swift` to accept namespace and use NavigationLink.
6. Modify `LobbyView.swift` to implement TabView and NavigationStack.
