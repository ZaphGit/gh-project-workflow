# /update-progress — Update the current issue with progress notes

Append a progress update to the GitHub issue you're currently working on.

## Steps

1. **Detect the current branch and issue number**:
   ```bash
   BRANCH=$(git branch --show-current)
   ```
   Extract the issue number from the branch name (pattern: `issue-<NUMBER>-*`).

2. **Summarise what you've done** since the last update — list the files changed, features implemented, or problems encountered. Be specific and concise.

3. **Append to the issue description** under the Implementation Progress section:
   ```bash
   gh issue edit <NUMBER> --body "$(gh issue view <NUMBER> --json body -q .body)
   - 🔄 $(date -u +%Y-%m-%dT%H:%M:%SZ): <concise summary of progress>
   "
   ```

4. **If blocked or need input**, also add a comment to the issue so it shows up in notifications:
   ```bash
   gh issue comment <NUMBER> --body "🚧 **Blocked**: <description of what's needed>"
   ```

## Rules
- Keep updates brief — one or two bullet points per update.
- Don't rewrite the existing description — only append.
- If the issue body is getting long, keep only the most recent 5-6 progress entries and summarise older ones.
