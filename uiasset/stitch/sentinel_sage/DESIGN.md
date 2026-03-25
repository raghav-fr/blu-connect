# Design System Document

## 1. Overview & Creative North Star: "The Resilient Sanctuary"

This design system is engineered to provide a sense of absolute reliability and calm in high-stakes environments. It moves beyond the clinical feel of traditional emergency tools by adopting a **"Resilient Sanctuary"** aesthetic—a creative direction that blends the organic stability of nature with the clarity of premium editorial design.

The system rejects the generic "utility app" look in favor of a sophisticated, high-end experience. We achieve this through:
*   **Intentional Asymmetry:** Breaking the rigid 12-column grid with overlapping elements and floating glass modules.
*   **Atmospheric Depth:** Using tonal shifts rather than harsh lines to define space.
*   **Safety-First Legibility:** Pairing an authoritative geometric sans-serif for headlines with a highly legible humanist sans-serif for data-dense body content.

The result is a UI that feels less like a piece of software and more like a dependable companion—structured, modern, and human-centric.

---

## 2. Colors: Tonal Nature & Emergency Precision

Our palette is grounded in the stability of `primary` forest greens and `background` sage tones, punctuated by high-urgency `tertiary` reds for SOS actions.

### The "No-Line" Rule
To maintain a premium, editorial feel, **1px solid borders for sectioning are strictly prohibited.** Structural boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a `surface-container-low` section should sit against a `surface` background to create a soft, intentional separation.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of materials. Use the surface-container tiers (`Lowest` to `Highest`) to define importance through nesting:
*   **Base Layer:** `surface` (#f6faf7)
*   **Sectioning:** `surface-container-low` (#f1f5f2)
*   **Interaction Cards:** `surface-container-highest` (#dfe3e1)
*   **Active Elements:** `primary-fixed` (#c8ebd5)

### The "Glass & Gradient" Rule
For status indicators and floating overlays (e.g., connectivity status or active alerts), utilize **Glassmorphism**. Use a semi-transparent `surface-container-lowest` (#ffffff at 60% opacity) with a `backdrop-blur` of 12px to 20px. 

Main CTAs or critical status banners should employ subtle gradients (e.g., `primary` transitioning to `primary-container`) to provide a "visual soul" that flat colors lack, ensuring the interface feels alive and professional.

---

## 3. Typography: Editorial Clarity

The typography system utilizes two distinct fonts to balance character with functionality.

*   **Display & Headlines (Manrope):** A modern, geometric sans-serif used for high-level status and hero statements. It conveys authority and modern professionalism.
*   **Body & Labels (Inter):** A workhorse typeface chosen for its exceptional legibility in low-light or high-stress scenarios.

| Level | Token | Font | Size | Case/Weight |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Manrope | 3.5rem | Semi-Bold |
| **Headline** | `headline-md` | Manrope | 1.75rem | Medium |
| **Title** | `title-md` | Inter | 1.125rem | Medium |
| **Body** | `body-md` | Inter | 0.875rem | Regular |
| **Label** | `label-md` | Inter | 0.75rem | Medium |

---

## 4. Elevation & Depth: The Layering Principle

Hierarchy is achieved through **Tonal Layering** rather than traditional structural lines.

*   **Stacking Tiers:** Instead of drop shadows, place a `surface-container-lowest` card on a `surface-container-low` background to create a soft, natural "lift."
*   **Ambient Shadows:** Where floating effects are required (e.g., SOS buttons), shadows must be extra-diffused. Use a blur of 32px with 6% opacity, tinted with the `on-surface` (#181d1b) color to mimic natural ambient light.
*   **The "Ghost Border" Fallback:** If a container requires further definition for accessibility, use a "Ghost Border"—the `outline-variant` token (#c2c8c2) at a maximum of 15% opacity.
*   **Glassmorphism Depth:** Status indicators (like Mesh active/inactive) should appear as "frosted glass" capsules. This allows the background imagery or maps to bleed through, softening the layout and making it feel integrated.

---

## 5. Components: Intentional Primitives

### Action Buttons
*   **Primary:** Solid `primary` (#163426) with `on-primary` text. Use `xl` (1.5rem) roundedness for a friendly yet firm feel.
*   **SOS/Emergency:** High-contrast `tertiary` (#650007). These should be the only elements using this deep red to ensure zero ambiguity.
*   **Secondary (Glass):** Semi-transparent `surface-container-lowest` with backdrop-blur.

### Cards & Lists
*   **Standard Card:** Use `xl` (1.5rem) corner radius. **Never use divider lines.** Separate list items using `spacing-4` (1rem) or `spacing-6` (1.5rem) and subtle background shifts between `surface-container-low` and `surface-container-high`.
*   **Floating Status Capsules:** Small, glassmorphic chips used for "Active Mesh" (using `secondary` text) or "No Devices" (using `error` text).

### Input Fields
*   **Text Inputs:** Use `surface-container-highest` as the fill. Forego the bottom line; instead, use a `label-md` for the title and the `outline-variant` at 20% opacity for a soft container.

### Signature Component: The "Environmental Hub"
A large, rounded card utilizing `surface-container-lowest` that overlaps a hero image or map. It should feature glassmorphic sub-modules for specific data points (e.g., Signal Strength, Local Temp), creating a "Control Center" feel.

---

## 6. Do's and Don'ts

### Do
*   **Do** use overlapping elements. Place a text module so it partially overlaps an image or a status card to create a high-end, editorial feel.
*   **Do** respect the breathing room. Use `spacing-12` (3rem) or `spacing-16` (4rem) for major section margins.
*   **Do** use `primary-fixed` for active states to keep the palette feeling "organic" rather than "synthetic."

### Don't
*   **Don't** use pure black for shadows. Use a tinted `on-surface` color.
*   **Don't** use 1px solid borders. It shatters the "Resilient Sanctuary" aesthetic and makes the UI feel dated.
*   **Don't** use the `tertiary` red for anything other than critical errors or SOS actions. It must remain a sacred "High-Contrast" signal.