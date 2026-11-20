---
name: harness-presentation
description: Use when you create or change a presentation, slide deck, report page, or data chart for people to read (.pptx, Keynote, Google Slides, PDF, HTML slides). Applies Edward Tufte's rules for showing data and a defined brand or design system.
---

# Presentations

A presentation shows evidence clearly and follows one defined brand.
The brand decides color, type, logo, and layout. Tufte's rules decide what the content and the data graphics look like.
Never distort data to satisfy a brand rule.

## 1. Find the brand. Stop if there is none.
Look in this order:
1. The brand file or template that the user names.
2. In the project: `brand.md`, `DESIGN.md`, `design-system/`, design tokens (`tokens.json`, CSS variables), a `.potx` or branded `.pptx` template.
3. Customer mode: the brand that `ENGAGEMENT.md` names.

If there is no brand, stop and ask. Offer two choices:
- The user gives the brand facts. Write them into `brand.md` in the project with `brand-template.md` from this skill folder.
- The user picks a theme (use the `theme-factory` skill if it is installed). Save it as `brand.md`. The user confirms it before you continue.

Do not invent a brand. Use the `brand-guidelines` skill only for Anthropic material. It contains only the Anthropic brand.
Read the whole brand file before the first slide. If a field that the deck needs is missing, ask.

## 2. Write the argument first
- Write one sentence each: the audience, the claim or decision, and the evidence.
- Write each slide title as a full sentence that states the finding ("Churn fell 18% after the new onboarding"), not a topic ("Churn").
- Read the titles in order. They must tell the whole story without the slides.
- One slide, one point.
- If the audience must study the data, write a document or a one-page handout with dense tables and graphics.
  Use the slides only to guide the talk. Tufte: for technical analysis, a written report is better than slides.

## 3. Text
- Use sentences. Do not use nested bullet outlines. They hide causes and relationships.
  If you use bullets: one level, few items, each a full statement.
- Give each number its unit, period, and comparison ("€1.2M in Q3, +8% vs Q2").
- Do not replace numbers with traffic-light colors or icons. Show the number, then the judgment.
- Each slide with data has a source line: source, date, and filter.
- Put the detail in the handout or appendix. Do not shrink it into small type.

## 4. Data graphics
Apply each item of `tufte-checklist.md` in this skill folder to each graphic. In short:
- Show the data. Each graphic answers "compared to what?".
- Graphical integrity: the visual size of an effect equals the size in the data (lie factor 1.0).
  Bars and areas start at zero. No 3D, no perspective, no area for one-dimensional values.
- Remove non-data ink: borders, backgrounds, heavy gridlines, shadows, gradients, decorative icons.
- Label series directly. Use a legend only when direct labels do not fit.
- Compare groups with small multiples on the same scale.
- Use a table for exact values or for few numbers. Do not chart four numbers.
- Use sparklines for trends next to numbers or text.
- Write the finding on the graphic, where it occurs.
- Color: use the data palette of the brand. Gray for context, one accent for the finding. Color carries meaning, not decoration.
  Check colorblind safety and contrast.

## 5. Brand without chartjunk
- Use the brand colors, fonts, logo rules, and template layouts exactly.
- Keep repeated brand elements small: one logo position, a thin footer. Tufte measured about 20% of slide area lost to branding and repeated titles.
- If a brand rule conflicts with graphical integrity (for example, a template chart with a cut axis, or 3D), keep the integrity. Write the conflict in the report.
- If a brand rule conflicts only with style (for example, a mandatory title bar), follow the brand. Write the conflict in the report.

## 6. Build
Use the format that the user asks for. Defaults:
- `.pptx`: the `pptx` skill (from `anthropics/skills`). If there is a brand template, use its template workflow.
  Prefer native, editable charts so that the numbers can be checked. Remove their default gridlines, borders, and legends.
- Chart color and marks: the `dataviz` skill if it is installed. The brand palette replaces its default palette.
- HTML slides or a web page: use the brand tokens and the web stack of the project.

If a skill is not installed, apply these rules directly. Write "<skill> not installed" in the report.
Customer mode: do not upload customer data to design services (Canva, Gamma, and others) unless `ENGAGEMENT.md` allows them.

## 7. Check
- Render each slide to an image and look at each one. For `.pptx`, follow the visual QA of the `pptx` skill
  (LibreOffice to PDF, then `pdftoppm`).
- Check text overflow, overlaps, margins, and minimum font sizes from the brand.
- Check each graphic against `tufte-checklist.md`. Compute the lie factor of each graphic that shows a change.
- Check each number against its source.
- Check that only brand colors, fonts, and logo rules are used.
- Read the slide titles in order. They tell the story.
- If you cannot render the slides, write "slides not visually checked" in the report.

## Report
Write: the brand file used, the output file, each data source, the checks run, and each conflict between the brand and these rules with your decision.
