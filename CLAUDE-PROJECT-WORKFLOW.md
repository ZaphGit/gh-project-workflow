# GitHub Project Workflow

This section documents how issues are managed through the GitHub Project board and how Claude Code interacts with it.

## Project Board Columns

| Column | Meaning |
|---|---|
| **Backlog** | Ideas and future work, unprioritised |
| **Ready** | Prioritised and fully specified — ready to be picked up. Top item = highest priority. |
| **In Progress** | Actively being worked on |
| **Review** | PR created, awaiting code review |
| **Done** | Merged to main (auto-moved by GitHub Action) |

## Slash Commands

| Command | What it does |
|---|---|
| `/next-issue` | Pick up the top issue from Ready, move to In Progress, create branch, start working |
| `/review-ready` | Run tests, push, create PR, move issue to Review |
| `/update-progress` | Append progress notes to the current issue |
| `/board` | Show the current state of all columns |

## Workflow Rules

1. **Never push directly to main.** Always work on a feature branch (`issue-<NUMBER>-<slug>`).
2. **PRs must reference the issue** with `Closes #<NUMBER>` in the body.
3. **Update the issue description** with progress as you work — the team watches these for status.
4. **When a PR merges to main**, a GitHub Action automatically moves the issue to Done.
5. **If blocked**, add a comment to the issue (not just the description) so notifications fire.

## Helper Script

`./scripts/gh-project.sh` wraps GitHub Projects v2 GraphQL into simple commands:

```bash
./scripts/gh-project.sh setup          # First-time: auto-detect project config
./scripts/gh-project.sh next           # Show the top Ready item
./scripts/gh-project.sh list-ready     # List all Ready items
./scripts/gh-project.sh move 42 "In Progress"   # Move issue #42
./scripts/gh-project.sh assign 42      # Assign to yourself
```

Config is stored in `.gh-project.env` (gitignored).
