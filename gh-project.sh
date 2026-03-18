#!/usr/bin/env bash
# gh-project.sh — Wrapper for GitHub Projects v2 GraphQL operations
# Usage: ./scripts/gh-project.sh <command> [args]
#
# Commands:
#   setup                         — Auto-detect project config and write .gh-project.env
#   list-ready                    — List items in the "Ready" column (top = highest priority)
#   list-in-progress              — List items in the "In Progress" column
#   list-review                   — List items in the "Review" column
#   list <status>                 — List items in any named status column
#   move <issue_number> <status>  — Move an issue to a status column
#   next                          — Show the top item in "Ready" (next to pick up)
#   assign <issue_number>         — Assign an issue to yourself
#
# Requires: gh CLI authenticated with project access

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.gh-project.env"

# ─── Config ───────────────────────────────────────────────────────────────────

load_config() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .gh-project.env not found. Run './scripts/gh-project.sh setup' first." >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$ENV_FILE"
}

# ─── Setup ────────────────────────────────────────────────────────────────────

cmd_setup() {
  echo "Setting up GitHub Project configuration..."

  # Detect owner/repo from git remote
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  local owner repo
  if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  else
    echo "Could not detect GitHub owner/repo from git remote."
    read -rp "Enter GitHub owner (org or user): " owner
    read -rp "Enter repository name: " repo
  fi

  echo "Detected: $owner/$repo"

  # List projects for this repo
  echo ""
  echo "Fetching projects..."

  local projects_json
  projects_json=$(gh api graphql -f query='
    query($owner: String!, $repo: String!) {
      repository(owner: $owner, name: $repo) {
        projectsV2(first: 10) {
          nodes {
            id
            number
            title
          }
        }
      }
    }
  ' -f owner="$owner" -f repo="$repo")

  local project_count
  project_count=$(echo "$projects_json" | jq '.data.repository.projectsV2.nodes | length')

  if [[ "$project_count" -eq 0 ]]; then
    echo "No projects found for $owner/$repo."
    echo "Create a project at: https://github.com/orgs/$owner/projects/new (org) or https://github.com/users/$owner/projects/new (user)"
    exit 1
  fi

  echo "Available projects:"
  echo "$projects_json" | jq -r '.data.repository.projectsV2.nodes[] | "  #\(.number) — \(.title) [\(.id)]"'

  local project_number
  if [[ "$project_count" -eq 1 ]]; then
    project_number=$(echo "$projects_json" | jq -r '.data.repository.projectsV2.nodes[0].number')
    echo ""
    echo "Auto-selected project #$project_number"
  else
    read -rp "Enter project number: " project_number
  fi

  local project_id
  project_id=$(echo "$projects_json" | jq -r --argjson num "$project_number" '.data.repository.projectsV2.nodes[] | select(.number == $num) | .id')

  if [[ -z "$project_id" || "$project_id" == "null" ]]; then
    echo "ERROR: Project #$project_number not found." >&2
    exit 1
  fi

  # Fetch the Status field and its options
  echo "Fetching project fields..."

  local fields_json
  fields_json=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 30) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
                options {
                  id
                  name
                }
              }
            }
          }
        }
      }
    }
  ' -f projectId="$project_id")

  local status_field
  status_field=$(echo "$fields_json" | jq '[.data.node.fields.nodes[] | select(.name == "Status")][0]')

  if [[ "$status_field" == "null" || -z "$status_field" ]]; then
    echo "ERROR: No 'Status' field found in the project. Make sure your project has a Status field." >&2
    exit 1
  fi

  local status_field_id
  status_field_id=$(echo "$status_field" | jq -r '.id')

  echo ""
  echo "Status field options:"
  echo "$status_field" | jq -r '.options[] | "  - \(.name) [\(.id)]"'

  # Map expected columns to option IDs
  local ready_id inprogress_id review_id done_id backlog_id

  ready_id=$(echo "$status_field" | jq -r '[.options[] | select(.name | test("ready"; "i"))][0].id // empty')
  inprogress_id=$(echo "$status_field" | jq -r '[.options[] | select(.name | test("in.?progress"; "i"))][0].id // empty')
  review_id=$(echo "$status_field" | jq -r '[.options[] | select(.name | test("review"; "i"))][0].id // empty')
  done_id=$(echo "$status_field" | jq -r '[.options[] | select(.name | test("done"; "i"))][0].id // empty')
  backlog_id=$(echo "$status_field" | jq -r '[.options[] | select(.name | test("backlog"; "i"))][0].id // empty')

  # Write config
  cat > "$ENV_FILE" <<EOF
# Auto-generated by gh-project.sh setup — $(date -Iseconds)
# Re-run './scripts/gh-project.sh setup' if your project columns change.

GH_PROJECT_OWNER="$owner"
GH_PROJECT_REPO="$repo"
GH_PROJECT_NUMBER="$project_number"
GH_PROJECT_ID="$project_id"
GH_STATUS_FIELD_ID="$status_field_id"

# Status column option IDs (edit if names differ)
GH_STATUS_BACKLOG="${backlog_id}"
GH_STATUS_READY="${ready_id}"
GH_STATUS_IN_PROGRESS="${inprogress_id}"
GH_STATUS_REVIEW="${review_id}"
GH_STATUS_DONE="${done_id}"

# All status options as JSON (for dynamic lookup)
GH_STATUS_OPTIONS='$(echo "$status_field" | jq -c '.options')'
EOF

  echo ""
  echo "Config written to .gh-project.env"
  echo ""

  # Warn about missing mappings
  [[ -z "$ready_id" ]] && echo "⚠️  No 'Ready' column detected — edit .gh-project.env manually"
  [[ -z "$inprogress_id" ]] && echo "⚠️  No 'In Progress' column detected — edit .gh-project.env manually"
  [[ -z "$review_id" ]] && echo "⚠️  No 'Review' column detected — edit .gh-project.env manually"
  [[ -z "$done_id" ]] && echo "⚠️  No 'Done' column detected — edit .gh-project.env manually"

  echo ""
  echo "✅ Setup complete. Add .gh-project.env to .gitignore (it contains project IDs)."
}

# ─── Resolve status name → option ID ─────────────────────────────────────────

resolve_status_id() {
  local status_name="$1"
  local normalized
  normalized=$(echo "$status_name" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

  case "$normalized" in
    backlog)     echo "$GH_STATUS_BACKLOG" ;;
    ready)       echo "$GH_STATUS_READY" ;;
    inprogress)  echo "$GH_STATUS_IN_PROGRESS" ;;
    review)      echo "$GH_STATUS_REVIEW" ;;
    done)        echo "$GH_STATUS_DONE" ;;
    *)
      # Dynamic lookup from options JSON
      echo "$GH_STATUS_OPTIONS" | jq -r --arg name "$status_name" \
        '[.[] | select(.name | test($name; "i"))][0].id // empty'
      ;;
  esac
}

# ─── Get project item ID for an issue number ─────────────────────────────────

get_item_id() {
  local issue_number="$1"

  local items_json
  items_json=$(gh api graphql -f query='
    query($projectId: ID!, $cursor: String) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100, after: $cursor) {
            nodes {
              id
              content {
                ... on Issue {
                  number
                }
                ... on PullRequest {
                  number
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      }
    }
  ' -f projectId="$GH_PROJECT_ID")

  echo "$items_json" | jq -r --argjson num "$issue_number" \
    '.data.node.items.nodes[] | select(.content.number == $num) | .id'
}

# ─── List items by status ─────────────────────────────────────────────────────

cmd_list() {
  local status_name="${1:-Ready}"
  load_config

  local items_json
  items_json=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
              fieldValueByName(name: "Status") {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                }
              }
              content {
                ... on Issue {
                  number
                  title
                  url
                  labels(first: 10) {
                    nodes { name }
                  }
                  assignees(first: 5) {
                    nodes { login }
                  }
                }
              }
            }
          }
        }
      }
    }
  ' -f projectId="$GH_PROJECT_ID")

  echo "$items_json" | jq -r --arg status "$status_name" '
    [.data.node.items.nodes[]
      | select(.fieldValueByName.name != null)
      | select(.fieldValueByName.name | test($status; "i"))
      | select(.content.number != null)
    ] | to_entries[]
    | "\(.key + 1). #\(.value.content.number) — \(.value.content.title)"
  '
}

# ─── Next item in Ready ──────────────────────────────────────────────────────

cmd_next() {
  load_config

  local items_json
  items_json=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
              fieldValueByName(name: "Status") {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                }
              }
              content {
                ... on Issue {
                  number
                  title
                  url
                  body
                  labels(first: 10) {
                    nodes { name }
                  }
                }
              }
            }
          }
        }
      }
    }
  ' -f projectId="$GH_PROJECT_ID")

  local next_item
  next_item=$(echo "$items_json" | jq '
    [.data.node.items.nodes[]
      | select(.fieldValueByName.name != null)
      | select(.fieldValueByName.name | test("ready"; "i"))
      | select(.content.number != null)
    ] | first
  ')

  if [[ "$next_item" == "null" || -z "$next_item" ]]; then
    echo "No items in Ready column."
    return 0
  fi

  local number title url body
  number=$(echo "$next_item" | jq -r '.content.number')
  title=$(echo "$next_item" | jq -r '.content.title')
  url=$(echo "$next_item" | jq -r '.content.url')
  body=$(echo "$next_item" | jq -r '.content.body // "(no description)"')

  echo "NEXT ISSUE: #$number"
  echo "TITLE: $title"
  echo "URL: $url"
  echo ""
  echo "DESCRIPTION:"
  echo "$body"
}

# ─── Move issue to status ────────────────────────────────────────────────────

cmd_move() {
  local issue_number="$1"
  local target_status="$2"
  load_config

  local option_id
  option_id=$(resolve_status_id "$target_status")

  if [[ -z "$option_id" ]]; then
    echo "ERROR: Could not resolve status '$target_status'. Available statuses:" >&2
    echo "$GH_STATUS_OPTIONS" | jq -r '.[].name' >&2
    exit 1
  fi

  local item_id
  item_id=$(get_item_id "$issue_number")

  if [[ -z "$item_id" ]]; then
    echo "ERROR: Issue #$issue_number not found in project." >&2
    exit 1
  fi

  gh api graphql -f query='
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { singleSelectOptionId: $optionId }
      }) {
        projectV2Item {
          id
        }
      }
    }
  ' -f projectId="$GH_PROJECT_ID" \
    -f itemId="$item_id" \
    -f fieldId="$GH_STATUS_FIELD_ID" \
    -f optionId="$option_id" > /dev/null

  echo "✅ Moved #$issue_number → $target_status"
}

# ─── Assign issue ─────────────────────────────────────────────────────────────

cmd_assign() {
  local issue_number="$1"
  load_config

  local current_user
  current_user=$(gh api user --jq '.login')

  gh issue edit "$issue_number" --add-assignee "$current_user" \
    -R "$GH_PROJECT_OWNER/$GH_PROJECT_REPO"

  echo "✅ Assigned #$issue_number to $current_user"
}

# ─── Dispatcher ───────────────────────────────────────────────────────────────

case "${1:-help}" in
  setup)
    cmd_setup
    ;;
  list-ready)
    cmd_list "Ready"
    ;;
  list-in-progress)
    cmd_list "In Progress"
    ;;
  list-review)
    cmd_list "Review"
    ;;
  list)
    cmd_list "${2:?Usage: gh-project.sh list <status>}"
    ;;
  next)
    cmd_next
    ;;
  move)
    cmd_move "${2:?Usage: gh-project.sh move <issue_number> <status>}" "${3:?Missing status}"
    ;;
  assign)
    cmd_assign "${2:?Usage: gh-project.sh assign <issue_number>}"
    ;;
  help|*)
    echo "Usage: ./scripts/gh-project.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  setup                          Auto-detect project config"
    echo "  next                           Show top item in Ready column"
    echo "  list-ready                     List all Ready items"
    echo "  list-in-progress               List In Progress items"
    echo "  list-review                    List Review items"
    echo "  list <status>                  List items by any status name"
    echo "  move <issue_number> <status>   Move issue to a status column"
    echo "  assign <issue_number>          Assign issue to yourself"
    ;;
esac
