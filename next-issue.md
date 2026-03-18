# /next-issue — Pick up the next issue from the project board

You are picking up the next prioritised issue from the GitHub Project board.

## Steps

1. **Get the next issue** by running:
   ```bash
   ./scripts/gh-project.sh next
   ```
   This returns the top item in the "Ready" column (highest priority).

2. **If no items are in Ready**, inform me and stop.

3. **Read the full issue** including all comments for additional context:
   ```bash
   gh issue view <NUMBER> --repo $GH_PROJECT_OWNER/$GH_PROJECT_REPO --comments
   ```

4. **Move the issue to In Progress**:
   ```bash
   ./scripts/gh-project.sh move <NUMBER> "In Progress"
   ```

5. **Create a working branch**:
   ```bash
   git checkout -b issue-<NUMBER>-<short-slug> main
   ```
   Use a short kebab-case slug derived from the issue title.

6. **Add a progress header to the issue description** so the team can see work has started:
   ```bash
   gh issue edit <NUMBER> --body "$(gh issue view <NUMBER> --json body -q .body)

   ---
   ## 🔧 Implementation Progress
   - ⏳ Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)
   - Branch: \`issue-<NUMBER>-<slug>\`
   - Status: **In Progress**
   "
   ```

7. **Start implementing.** Read any referenced files, specs, or docs mentioned in the issue. Follow the project's existing patterns and conventions. Refer to `/docs` and `CLAUDE.md` for project rules.

8. **Update the issue description** periodically as you complete meaningful steps — append bullet points under the Implementation Progress section describing what was done.

## Rules
- Never force-push to main.
- Always work on a feature branch.
- Run existing tests before considering the work complete.
- If the issue is unclear or blocked, add a comment to the issue asking for clarification and let me know.
