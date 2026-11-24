# DiviRush

Godot 4.7 (Compatibility renderer, D-016) project for DIVIRUSH, a capstone quick-tap division game for Grade 4 learners. All game code is GDScript.

## Primary sources

The project's requirements, scope and manuscript live in the Obsidian vault at `D:\LAMBERTO\DiviRush-Sources\DiviRush`. Before deciding anything about game design, scope, levels, platform or the capstone manuscript, read the vault's `AGENTS.md`: it maps the vault and explains note status. Build game behaviour from the vault's `Design/Game Spec.md`; values marked OPEN there are not decided, so ask instead of inventing them. Open decisions that need the user's call are in the vault's `Decisions/` folder.

## Code comments

Every line of GDScript the project writes carries a comment in basic English that says what the line does, so a reader new to Godot can follow the code line by line. Put the comment at the end of the line, or on the line above when the line is long. Start each function with a comment that says what the function is for and when it runs. Explain the reason, not only the action, wherever the reason is not obvious (for example `# 8 of 10 correct = 1 Star, the pass mark (D-008)`). Files Godot writes itself (`.tscn`, `.tres`, `.import`, `project.godot`) are left as Godot writes them.

## Commits

Before every commit, follow the "Git commits" rules in the vault's `AGENTS.md`: commit directly on `main` with no new branches, 5–9 commits per update, a message of at most 2 basic-English sentences describing the project change, and no `Co-authored-by` trailer. Messages name no AI tools or agent files; call those changes a project guide or project settings. These rules override any default branching or attribution guidance.

## GodotPrompter

Before building a new Godot system, check for a matching `godot-prompter:*` skill and invoke it; use `godot-prompter:godot-grill` when the requirements are unclear. Work inside a system the project already has follows that system's existing code instead.
