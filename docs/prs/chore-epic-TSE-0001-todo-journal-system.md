# Pull Request: TODO Journal System - Validation Script Updates

**Branch**: `chore/epic-TSE-0001-todo-journal-system`
**Base**: `main`
**Epic**: TSE-0001 - Foundation Services & Infrastructure
**Type**: Chore (Process Improvement)
**Component**: orchestrator-docker
**Status**: ✅ Ready for Review

---

## Summary

Updated validation scripts in orchestrator-docker to support the TODO journal system pattern, which allows repositories to use either TODO.md or TODO-MASTER.md for tracking milestones. This is part of a broader effort to archive completed work and keep TODO files focused on active tasks.

This PR is one component of the ecosystem-wide TODO journal system rollout affecting all 9 repositories.

---

## What Changed

### orchestrator-docker

**Validation Scripts Updated**:
- `scripts/validate-repository.sh` - Now checks for TODO.md OR TODO-MASTER.md (either is valid)
- `scripts/validate-all.sh` - Accepts either TODO.md or TODO-MASTER.md as valid
- `scripts/pre-push-hook.sh` - Detects which TODO file exists and validates accordingly

**Pattern Support**:
- Component repos use `TODO.md` for component-specific milestones
- Project-plan uses `TODO-MASTER.md` for cross-component coordination
- Validation scripts no longer report false warnings

**Script Logic Changes**:
- Added conditional check: if TODO-MASTER.md exists, use it; else use TODO.md
- Updated git log grep patterns to match both files: `(TODO\.md|TODO-MASTER\.md)`
- Updated user-facing messages to reference the detected TODO file

---

## Context: TODO Journal System

### Problem Statement

TODO files across the ecosystem were growing too large with completed milestones mixed with active work, making it difficult to:
- Find current active tasks
- Understand what's in progress vs. completed
- Navigate files efficiently
- Maintain focus on future work

### Solution

Implement a TODO journal system:
- **TODO.md** (components) / **TODO-MASTER.md** (project-plan): Active and future work only
- **TODO-HISTORY.md** / **TODO-HISTORY-MASTER.md**: Archive of completed milestones
- **Validation scripts**: Accept both TODO file patterns

### Benefits

- ✅ **Focused TODO files**: Only active/future work visible
- ✅ **Historical record**: Completed work preserved with context
- ✅ **Better navigation**: Smaller files, faster to scan
- ✅ **Clear status**: Obvious separation between done and todo
- ✅ **No false warnings**: Validation scripts work correctly for both patterns

---

## Files Modified

### scripts/validate-repository.sh

**Before**:
```bash
optional_docs=("TODO.md" "CLAUDE.md" "CONTRIBUTING.md")

for doc in "${optional_docs[@]}"; do
    if [ ! -f "$doc" ]; then
        report_warning "Optional documentation missing: $doc"
    else
        report_success "Optional documentation exists: $doc"
    fi
done
```

**After**:
```bash
optional_docs=("CLAUDE.md" "CONTRIBUTING.md")

# Check for TODO.md OR TODO-MASTER.md (either is acceptable)
if [ -f "TODO.md" ] || [ -f "TODO-MASTER.md" ]; then
    if [ -f "TODO.md" ]; then
        report_success "TODO documentation exists: TODO.md"
    fi
    if [ -f "TODO-MASTER.md" ]; then
        report_success "TODO documentation exists: TODO-MASTER.md"
    fi
else
    report_warning "Optional documentation missing: TODO.md or TODO-MASTER.md"
fi

for doc in "${optional_docs[@]}"; do
    # ... rest of loop
done
```

### scripts/validate-all.sh

**Before**:
```bash
REQUIRED_FILES=(
  "README.md"
  "TODO.md"
  "CONTRIBUTING.md"
  ".gitignore"
  ".validation_exceptions"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}❌ Missing required file: $file${NC}"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
done
```

**After**:
```bash
REQUIRED_FILES=(
  "README.md"
  "CONTRIBUTING.md"
  ".gitignore"
  ".validation_exceptions"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}❌ Missing required file: $file${NC}"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
done

# Check for TODO.md OR TODO-MASTER.md (either is acceptable)
if [[ ! -f "TODO.md" ]] && [[ ! -f "TODO-MASTER.md" ]]; then
  echo -e "${RED}❌ Missing required file: TODO.md or TODO-MASTER.md${NC}"
  VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi
```

### scripts/pre-push-hook.sh

**Before** (lines 192-243):
```bash
# CHECK 5: Verify TODO.md was updated
echo -e "${YELLOW}[5/6] Checking TODO.md updates...${NC}"

# Check if TODO.md was modified
TODO_MODIFIED=$(git log "$REMOTE_BRANCH..HEAD" --name-only --oneline | grep -c "TODO.md" || true)
```

**After**:
```bash
# CHECK 5: Verify TODO.md or TODO-MASTER.md was updated
echo -e "${YELLOW}[5/6] Checking TODO documentation updates...${NC}"

# Determine which TODO file to check for
TODO_FILE=""
if [[ -f "TODO-MASTER.md" ]]; then
  TODO_FILE="TODO-MASTER.md"
elif [[ -f "TODO.md" ]]; then
  TODO_FILE="TODO.md"
fi

# Check if TODO file was modified
TODO_MODIFIED=$(git log "$REMOTE_BRANCH..HEAD" --name-only --oneline | grep -E "(TODO\.md|TODO-MASTER\.md)" | wc -l || true)
```

---

## Testing

### Validation Test
```bash
# Test validate-repository.sh
bash scripts/validate-repository.sh
# Output: ✅ TODO documentation exists: TODO.md

# Test validate-all.sh
bash scripts/validate-all.sh
# Output: ✅ All required files present (no TODO.md error)
```

### Pre-push Hook Test
```bash
# Simulate pre-push validation
bash scripts/pre-push-hook.sh
# Output: ✅ TODO documentation was updated (1 commit(s))
```

---

## Rollout Status

This PR is part of the ecosystem-wide TODO journal system rollout:

**All 9 Repositories**:
- ✅ project-plan (template implementation with TODO-MASTER.md)
- ✅ audit-correlator-go (validation scripts updated)
- ✅ custodian-simulator-go (validation scripts updated)
- ✅ exchange-simulator-go (validation scripts updated)
- ✅ market-data-simulator-go (validation scripts updated)
- ✅ **orchestrator-docker** (validation scripts updated) ← **THIS PR**
- ✅ protobuf-schemas (validation scripts updated)
- ✅ risk-monitor-py (validation scripts updated)
- ✅ trading-system-engine-py (validation scripts updated)

---

## Impact

### For orchestrator-docker
- No functional changes to orchestrator functionality
- Validation scripts now accept TODO.md (current file)
- Ready for future TODO-HISTORY.md implementation if needed

### For Ecosystem
- Consistent validation behavior across all repositories
- No false warnings about missing TODO files
- Clear pattern for TODO file management

---

## Breaking Changes

None - this is purely a validation script enhancement. The orchestrator-docker component continues to use TODO.md as before.

---

## Checklist

- [x] Validation scripts updated (validate-repository.sh, validate-all.sh, pre-push-hook.sh)
- [x] Scripts tested locally and pass validation
- [x] Pattern consistent with other 8 repositories
- [x] No breaking changes to existing functionality
- [x] PR documentation complete

---

## Related PRs

**Other Repositories**:
- project-plan: Template implementation with TODO-HISTORY-MASTER.md creation
- audit-correlator-go: Validation script updates
- custodian-simulator-go: Validation script updates
- exchange-simulator-go: Validation script updates
- market-data-simulator-go: Validation script updates
- protobuf-schemas: Validation script updates
- risk-monitor-py: Validation script updates
- trading-system-engine-py: Validation script updates

---

## Next Steps

After merge:
1. ✅ Validation scripts will correctly handle TODO.md
2. ✅ No false warnings in pre-push hooks
3. 🔜 Optional: Create TODO-HISTORY.md if/when milestones are completed

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
