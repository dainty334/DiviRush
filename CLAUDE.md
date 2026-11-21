# DiviRush

Godot 4.7 (Mobile renderer) project for DIVIRUSH, a capstone quick-tap division game for Grade 4 learners. All game code is GDScript.

## Primary sources

The project's requirements, scope and manuscript live in the Obsidian vault at `D:\LAMBERTO\DiviRush-Sources\DiviRush`. Before deciding anything about game design, scope, levels, platform or the capstone manuscript, read the vault's `AGENTS.md`: it maps the vault, explains note status (`final`, `unrevised`, `revised`, `reference`), and lists known conflicts between sources that need the user's call.

## Commits

Before every commit, follow the "Git commits" rules in the vault's `AGENTS.md`: commit directly on `main` with no new branches, at most 5–6 commits per update, a message of at most 2 basic-English sentences describing the project change, and no `Co-authored-by` trailer. Messages name no AI tools or agent files; call those changes a project guide or project settings. These rules override any default branching or attribution guidance.

## GodotPrompter

Before building a new Godot system, check for a matching `godot-prompter:*` skill and invoke it; use `godot-prompter:godot-grill` when the requirements are unclear. Work inside a system the project already has follows that system's existing code instead.
