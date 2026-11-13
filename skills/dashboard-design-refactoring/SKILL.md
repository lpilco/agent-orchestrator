---
name: dashboard-design-refactoring
description: "Principles and review criteria to design, audit or refactor professional data dashboards and visualizations: insight count, time to insight, chart choice by data type, removing chartjunk. Use when creating or reviewing a chart, dashboard or data report."
---

# Skill: Professional Dashboard Creation and Refactoring

## Purpose
Provide agents and human developers with rigorous principles, evaluation frameworks, and actionable criteria to design, review, or refactor professional data dashboards and visualizations. This skill ensures clarity, efficiency, accurate data representation, and freedom from chartjunk.

---

## Core Principles of Data Visualization

1. **Prioritize Insights & Speed**
   - **Measure 1 (Insight Count):** A good visualization maximizes the number of valid insights a reader can extract. Avoid plots with zero insights.
   - **Measure 2 (Time to Insight):** Viewers should grasp the core message within ~20 seconds. Keep designs clean and focused.

2. **Data-Type Alignment (Variables)**
   - **Continuous Variables (Numbers):** Use arithmetic-compatible plots (e.g., histograms, scatter plots, box plots, line plots).
   - **Categorical Variables (Classifications):** Use appropriate groupings (e.g., bar plots, box plots, panels).
   - **Handling Grey Areas:** Treat variables dynamically based on the analytical question (e.g., treating continuous time/age as categorical groupings when necessary).

3. **Multi-Dimensional Encoding Strategy**
   - For higher dimensions ($>2$ variables), leverage visual aesthetics carefully:
     - **Color:** Best for qualitative categories (hue) or sequential scales (luminance/chroma). Ensure perceptual distance is constant.
     - **Size & Transparency:** Use cautiously; larger elements can falsely imply greater importance or cause overlap/clutter.
     - **Shape:** Avoid for ordered data (shapes lack intrinsic hierarchy). Use discrete categories sparingly.
     - **Small Multiples / Panels:** Highly effective for breaking down multi-variable relationships without cluttering a single coordinate space. Avoid 3D scatter plots entirely (loss of perspective).

---

## Color Theory & Palettes (HCL Model)

- **Colorspaces:** Prefer **Hue-Chroma-Luminance (HCL)** over RGB or CMYK for data encoding because it aligns with human perception.
- **Three Scale Types:**
  1. **Qualitative (Unordered Categories):** Vary **hue** while keeping chroma and luminance constant (e.g., differentiating product lines or political parties).
  2. **Sequential (Ordered Data / Magnitudes):** Vary **chroma or luminance** while holding hue fixed (or use scientifically designed scales like *Viridis* for accessibility and monochrome printing).
  3. **Diverging (Midpoint/Deviation):** Use two contrasting hues meeting at a neutral midpoint luminance/chroma (e.g., Likert scale surveys: Strongly Disagree to Strongly Agree).

---

## Anti-Patterns & Chartjunk Elimination

1. **Combatting Chartjunk & Skeuomorphism:**
   - Eliminate unnecessary real-world decorations (shadows, 3D bar depth, fake textures, ostentatious lines/hatching). 
   - 3D perspective on 2D charts (like bar charts or scatter plots) adds zero value and severely distorts value judgment.

2. **Axis Integrity (The "Axes of Evil"):**
   - **Bar Length Proportionality:** Bar lengths and stacked bar heights *must* always be strictly proportional to their underlying numeric values. Never truncate bar chart axes to exaggerate differences.
   - **Y-Axis Baseline:** Bar charts must start at zero. Stacked bar charts must reflect true 0-100% scales.
   - **Avoid Dual Y-Axes:** Dual axes distort relationships and make correlations look strong or weak arbitrarily based on axis scaling. Use separate panels/subplots instead.

3. **Comparison Rigor:**
   - Use **Box Plots** instead of summary bar charts when comparing distributions across groups (capturing spread, median, and outliers rather than hiding variation behind a single mean).

---

## Dashboard Refactoring Workflow (Step-by-Step)

When asked to refactor or audit a dashboard or chart, execute the following steps:

1. **Audit Purpose & Audience:** What is the primary question the viewer needs to answer in under 20 seconds?
2. **Data & Scale Check:** 
   - Are axes starting at zero where required? 
   - Are bar lengths mathematically truthful?
   - Are dual axes eliminated in favor of panels?
3. **Visual Clarity & Aesthetics Check:**
   - Remove all skeuomorphic elements, 3D effects, and heavy background grids/hatching.
   - Verify color scales match data types (Qualitative vs. Sequential vs. Diverging using HCL/Viridis principles).
4. **Information Density & Layout:**
   - Use small multiples/panels to show multi-variable interactions instead of cramming variables into a single unreadable plot.
   - Ensure typography and labels are legible and direct.
