# /review-ready — Mark current work as ready for review

The current feature branch work is complete. Prepare it for review.

## Steps

1. **Detect the current branch and issue number**:
   ```bash
   BRANCH=$(git branch --show-current)
   ```
   Extract the issue number from the branch name (pattern: `issue-<NUMBER>-*`).

2. **Run tests and lint** to make sure everything passes:
   ```bash
   # Adjust these to the project's actual commands
   npm test 2>&1 || true
   npm run lint 2>&1 || true
   ```
   If tests fail, fix them before proceeding. If lint has auto-fixable issues, fix and commit.

3. **Commit any remaining changes** with a descriptive message referencing the issue:
   ```bash
   git add -A
   git commit -m "feat: <summary> (#<NUMBER>)"
   ```

4. **Push the branch**:
   ```bash
   git push -u origin $BRANCH
   ```

5. **Create a pull request**:
   ```bash
   gh pr create \
     --title "<Issue title>" \
     --body "Closes #<NUMBER>

   ## Changes
   <brief summary of what was implemented>

   ## Testing
   <what was tested and how>" \
     --base main \
     --head $BRANCH
   ```

6. **Move the issue to Review**:
   ```bash
   ./scripts/gh-project.sh move <NUMBER> "Review"
   ```

7. **Update the issue description** — change status to Review and add completion notes:
   ```bash
   # Append to the Implementation Progress section
   gh issue edit <NUMBER> --body "$(gh issue view <NUMBER> --json body -q .body | sed 's/Status: \*\*In Progress\*\*/Status: **Review**/')

   - ✅ Completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
   - PR: <PR_URL>
   "
   ```

8. **Inform me** with a summary: what was done, the PR link, and any notes for the reviewer.

## Rules
- Always create a PR — never push directly to main.
- The PR body must reference `Closes #<NUMBER>` so GitHub auto-links the issue.
- If tests are failing and you cannot fix them, tell me instead of creating the PR.
