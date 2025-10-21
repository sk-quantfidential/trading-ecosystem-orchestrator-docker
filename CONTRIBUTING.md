# Contributing to Orchestrator Docker

## Purpose

This repository provides infrastructure and configuration for the Trading Ecosystem.

## Workflow

### 1. Branch Creation
**Branch Naming Convention**: `type/epic-XXX-9999-milestone-description`

Examples:
- `chore/epic-TSE-0001-foundation-update-schemas`
- `feat/epic-TSE-0001-foundation-add-docker-compose`

### 2. Changes
**Before committing**:
1. Validate configuration files
2. Test changes in local environment
3. Update documentation
4. Update TODO.md if working on milestone tasks

### 3. Commit Messages
Follow conventional commits with epic tracking:

```
type(epic-XXX/milestone): description

Detailed explanation if needed

Milestone: Milestone Name
```

## Pull Requests

Before creating PR:
1. ✅ Configuration validated
2. ✅ Documentation updated
3. ✅ PR documentation created in `docs/prs/` (if applicable)
4. ✅ TODO.md updated (if exists)
5. ✅ No markdown linting errors

## Questions?

Check project documentation in `project-plan` repository.
