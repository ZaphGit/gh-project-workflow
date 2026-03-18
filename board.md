# /board — Show the current state of the project board

Display the current project board status across all columns.

## Steps

1. **List each column**:
   ```bash
   echo "=== 📋 READY ==="
   ./scripts/gh-project.sh list-ready

   echo ""
   echo "=== 🔧 IN PROGRESS ==="
   ./scripts/gh-project.sh list-in-progress

   echo ""
   echo "=== 👀 REVIEW ==="
   ./scripts/gh-project.sh list-review
   ```

2. **Present the results** as a clean summary to me, noting:
   - How many items are in each column
   - Which item is next up (top of Ready)
   - Any items that might be stale in In Progress

3. If I ask about a specific issue, fetch its details:
   ```bash
   gh issue view <NUMBER> --comments
   ```
