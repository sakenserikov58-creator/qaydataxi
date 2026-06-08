# Design System Document: The Obsidian Ether

## 1. Overview & Creative North Star
**Creative North Star: "The Midnight Navigator"**

This design system is engineered to feel like a high-end concierge service—silent, sophisticated, and impeccably organized. Moving away from the cluttered "utility" look of standard taxi apps, this system treats the map of Almaty as a living canvas. We break the "template" look through **Tonal Depth** and **Organic Layering**. 

By utilizing intentional asymmetry—such as off-center typography in hero headers and overlapping glass cards—we create a sense of movement. The interface isn't just a tool; it’s a premium experience that reflects the nocturnal energy of a modern metropolis.

## 2. Colors: The Depth of Night
The palette is built on a foundation of `background (#0e0e0f)`, using a scale of charcoal and obsidian to create a sense of infinite space.

### The "No-Line" Rule
Traditional 1px solid borders are strictly prohibited for sectioning. Boundaries between content blocks must be defined through:
- **Tonal Shifts:** Placing a `surface-container-low` card against a `background` base.
- **Negative Space:** Using generous padding to allow the eye to perceive groupings naturally.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers.
*   **Base:** `surface` (#0e0e0f) – The map or main background.
*   **Level 1:** `surface-container-low` – Subtle layout divisions.
*   **Level 2:** `surface-container-highest` – Active interactive cards (e.g., "Where to?" input).

### The Glass & Gradient Rule
To achieve the signature Almaty "High-End" look, floating elements must use **Glassmorphism**:
*   **Fill:** `surface_variant` at 40-60% opacity.
*   **Backdrop Blur:** 20px - 40px.
*   **Signature Gradients:** For primary CTAs (e.g., "Заказать"), use a linear gradient from `primary` (#a3a6ff) to `secondary` (#c180ff) at a 135° angle. This provides a "visual soul" that feels alive under the city lights.

## 3. Typography: Editorial Authority
We utilize **Inter** for its exceptional Cyrillic legibility and geometric precision. The hierarchy is designed to feel like a premium editorial magazine.

*   **Display (Large/Medium):** Used for "Welcome back" or destination arrivals. These should have tight letter-spacing (-0.02em) to feel authoritative.
*   **Title (Large/Medium):** Used for driver names and vehicle classes. Bold weights here emphasize trust.
*   **Body (Large/Medium):** Used for addresses and trip details.
*   **Label (Medium/Small):** Reserved for metadata like "Estimated Time" or "License Plate."

**Editorial Balance:** Contrast a `display-md` greeting ("Куда поедем?") with a `label-md` subtext in `on_surface_variant` to create a sophisticated, non-uniform layout.

## 4. Elevation & Depth
We eschew traditional drop shadows for **Tonal Layering**.

*   **The Layering Principle:** Depth is achieved by stacking. A `surface-container-lowest` card placed on a `surface-container-low` section creates a natural "sunken" or "lifted" effect without artificial lines.
*   **Ambient Shadows:** For floating action buttons or modal sheets, use extra-diffused shadows: `box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4)`. The shadow should feel like a soft glow of darkness rather than a hard edge.
*   **The "Ghost Border":** If containment is required for accessibility, use the `outline_variant` token at **15% opacity**. This creates a "breathable" boundary that catches the light like the edge of a glass pane.

## 5. Components

### Buttons
*   **Primary:** A gradient of `primary` to `secondary`. Text: `on_primary_fixed` (Black). High-roundedness (`full` scale).
*   **Secondary:** Glassmorphic base (`surface_variant` @ 20%) with a Ghost Border.
*   **States:** On hover, increase the `surface_tint` intensity; on press, scale the component down slightly (0.98x).

### Floating Trip Cards
*   **Style:** No dividers. Use `surface_container_high` with a 24px backdrop blur. 
*   **Layout:** Use vertical white space from the `xl` scale to separate the "Pickup" and "Destination" points. Use a soft glow (using `tertiary_dim`) for the active route line.

### Input Fields
*   **Style:** Minimalist. No background fill—only a bottom "Ghost Border" that illuminates into a `primary` glow when focused. 
*   **Typography:** Placeholder text uses `on_surface_variant`.

### Map Markers
*   **Style:** A pulsing `primary` dot with a wide, soft `primary_container` outer glow (30% opacity) to mimic the look of neon in the Almaty mist.

### Destination Chips
*   **Style:** `surface_container_lowest` with `md` roundedness. No border. Use `body-sm` for the location name (e.g., "Медеу" or "Шымбулак").

## 6. Do's and Don'ts

### Do:
*   **DO** use varying opacities of `on_surface` to create hierarchy in text instead of changing font sizes constantly.
*   **DO** allow the map to "bleed" behind glassmorphic headers for a sense of immersion.
*   **DO** use `xl` (1.5rem) corner radius for main cards to maintain a friendly, premium feel.

### Don't:
*   **DON'T** use 100% white (#ffffff) for borders; it breaks the illusion of glass.
*   **DON'T** use standard grey shadows. If a shadow is needed, tint it with a hint of `primary` to keep the dark theme "expensive."
*   **DON'T** use divid ers. If two pieces of information feel too close, increase the spacing token rather than adding a line.